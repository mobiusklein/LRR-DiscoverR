use strict;
use warnings;
use FileHandle;
use constant 
{
OVERLAP_START => 1,
OVERLAP_END => 2,
OVERLAP_CONTAIN => 3,
OVERLAP_WITHIN => 4,
NO_OVERLAP => 0
};

my $domain_table_file = shift;

my $fh = FileHandle->new($domain_table_file);
my $outfile = FileHandle->new(">".$domain_table_file.".reduced");

my @keys = ("query_name", "env_match_start","env_match_end","domain_e_val","model_name");

my $sequences = {};

my $line = <$fh>;
$line = <$fh>;
$line = <$fh>;
while ($line = <$fh>){
	chomp $line;
	## 0 - Model Name
	## 3 - Query Name
	## 11 - Domain E Value
	## 15 - HMM match start
	## 16 - HMM match end
	## 19 - ENV match start
	## 20 - ENV match end
	my @line_data = split(/\s+/, $line);
	my $hit_ref = {
		model_name => $line_data[0],
		query_name => $line_data[3],
		domain_e_val => $line_data[11],
		hmm_match_start => $line_data[15],
		hmm_match_end => $line_data[16],
		env_match_start => $line_data[19],
		env_match_end => $line_data[20]
		
	};
	
	## Sequence hit list
	if(!defined($sequences->{$hit_ref->{query_name}})){
		$sequences->{$hit_ref->{query_name}} = {};
	}
	
	## Prepare Model hit list
	if(!defined($sequences->{$hit_ref->{query_name}}->{$hit_ref->{model_name}})){
		$sequences->{$hit_ref->{query_name}}->{$hit_ref->{model_name}}=[];
		push @{$sequences->{$hit_ref->{query_name}}->{$hit_ref->{model_name}}}, $hit_ref;
	}
	else {
		## Holds the list of Domains found by the
		my @list_sort_by_e_value;
		## Current list of domains for this model
		my $model_list = $sequences->{$hit_ref->{query_name}}->{$hit_ref->{model_name}};
		my $length = @{$model_list};
		## Iterator for tracking where in the list of existing domain hits 
		## for later splicing
		my $position = 0;
		#print "$hit_ref->{model_name}: (Length: $length)\n";
		foreach my $current (@{$model_list}){
			#print "$hit_ref->{domain_e_val}  ~ $position = $current->{domain_e_val}\n";
			## If the e value of the new hit is better than the one currently being looked at
			if (compareEvalueLessThan($hit_ref, $current)){
				## Put the new hit on the sorted list,
				push @list_sort_by_e_value, $hit_ref;
				## then put all the remaining old hits on after it remaining
				## on the current model's list. Any better hits will already be 
				## on the sorted list from past iterations. 
				push @list_sort_by_e_value, @{$model_list}[$position..$length-1];
				#print (map{$_->{"domain_e_val"}.", "} @list_sort_by_e_value);
				#print "\n\n";
				## Use position as a flag as to whether anything changed. 
				$position = 0;
				last;
			}
			else {
				# print "Not better, incrementing position $position -> ";
				$position++;
				# print "$position\n";
				push @list_sort_by_e_value, $current;
			}
		}
		if ($position != 0){
			# print "Did not beat anything else, inserting last...\n";
			push @list_sort_by_e_value, $hit_ref;
			# print (map{$_->{"domain_e_val"}.", "} @list_sort_by_e_value);
			# print "\n\n";
		}
		## Make @list_sort_by_e_value the new list of domains
		$sequences->{$hit_ref->{query_name}}->{$hit_ref->{model_name}} = \@list_sort_by_e_value
	}
}


## List all results
printHeaderToFile();
foreach my $sequence (keys %$sequences){
	findBestMap($sequence);
}


sub findBestMap{
	my $sequence = shift;
	my $sequence_data = \%{$sequences->{$sequence}};
	my @models = keys %{$sequences->{$sequence}};
	my $num_domains = @models;
	#print "$sequence: Number of Domains: $num_domains\n";
	## A Structure listing each model's name (the key into the hash of $sequence) and an index
	## denoting which of its domains is being handled
	#@models = map {$_ = [$_, 0]} @models;
	
	## To access a given model, in $sequence_data, key models[x]->[0] provides the model, model[x]->[1] provides the current 
	## domain being considered. 
	
	reduceOverlapModelFit($sequence_data, @models);
	
	foreach my $model (@models){
		foreach my $domain (@{$sequence_data->{$model}}){
			printDomainToFile($domain);
		}
	}
}


sub reduceOverlapModelFit {
	my $sequence_data = shift;
	my @models = @_;
	my @final_domains;
	foreach my $model (@models){
		## List of domains for $model 
		## Number of domains for $model
		my $num_domains = @{$sequence_data->{$model}};
		MODEL: for (my $domain_index = 0; $domain_index<$num_domains;$domain_index++){
			#print "\n***\n";
			#printDomain($sequence_data->{$model}->[$domain_index]);
			## For each other model
			#print "Model=",$model,"\n";
			foreach my $other_model (@models){
				## if that other model is not $model,
				if ($model ne $other_model){
					#print "Other Model=",$sequence_data->{$other_model},"\t",$other_model,"\n";
					## Calculate the number of domains in $other_model
					my $num_other_domains = @{$sequence_data->{$other_model}};
					#print "Num Other Domains=".$num_other_domains."\n";
					## For each domain in other model, 
					for (my $other_domain_index = 0; $other_domain_index<$num_other_domains; $other_domain_index++){
						## Check if there is an overlap with the current domain
						#print "Domain Index= $domain_index\tOther Index= $other_domain_index\n";
						my $overlap_result = computeDomainOverlap($sequence_data->{$model}->[$domain_index], 
						$sequence_data->{$other_model}->[$other_domain_index]);
						## If the overlap takes the form of a a CONTAIN or WITHIN, 
						if(($overlap_result == OVERLAP_CONTAIN) or ($overlap_result == OVERLAP_WITHIN)){
							## Determine which domain has the better (smaller) e value
							if (compareEvalueLessThan($sequence_data->{$model}->[$domain_index],
							$sequence_data->{$other_model}->[$other_domain_index])){
								@{$sequence_data->{$other_model}} = @{$sequence_data->{$other_model}}[0..$other_domain_index-1,$other_domain_index+1..$num_other_domains-1];
								$num_other_domains--;
								$other_domain_index--;
							}
							else{
								@{$sequence_data->{$model}}=@{$sequence_data->{$model}}[0..$domain_index-1,$domain_index+1..$num_domains-1];
								$num_domains--;
								$domain_index--;
								## Skip to the next iteration of the outermost for loop, MODEL
								next MODEL;
							}
						}
					}
				}
			}
		}
	}
}

## Determine which end, if any, domain 1 overlaps with domain 2
sub computeDomainOverlap {
	my $dom1 = shift;
	my $dom2 = shift;
	
	my $error_padding = shift;
	
	if (undef ~~ $error_padding){
		$error_padding = 15;
	}
	
	my $dom1_start = $dom1->{"env_match_start"} - $error_padding;
	my $dom2_start = $dom2->{"env_match_start"} ;
	
	my $dom1_end = $dom1->{"env_match_end"} + $error_padding;
	my $dom2_end = $dom2->{"env_match_end"} ;
	
	if (($dom1_start > $dom2_end) or ($dom2_start > $dom1_end)) {
			#print "No Overlap\n";
			return NO_OVERLAP;
	}
	elsif ($dom1_start < $dom2_start) {
		#print "$dom1_start < $dom2_start\t";
		if ($dom1_end < $dom2_end){
			#print "$dom1_end < $dom2_end\t";
			#print "OVERLAP_START\n";
			return OVERLAP_START;
		}
		elsif ($dom1_end > $dom2_end){
			#print "$dom1_end > $dom2_end\t";
			#print "OVERLAP_CONTAIN\n";
			return OVERLAP_CONTAIN;
		}
	}
	elsif($dom1_start > $dom2_start){
		#print "$dom1_start > $dom2_start\t";
		if ($dom1_end > $dom2_end){
			#print "$dom1_end < $dom2_end\t";
			#print  "OVERLAP_END\n";
			return OVERLAP_END;
		}
		
		elsif ($dom1_end < $dom2_end){
			#print "$dom1_end > $dom2_end\t";
			#print "OVERLAP_WITHIN\n";
			return OVERLAP_WITHIN;
		}
	}
	else{
		#print "No Overlap\n";
		return NO_OVERLAP;
	}
}


# Math Helper
sub compareEvalueLessThan {
	my $val_1 = (shift)->{domain_e_val};
	my $val_2 = (shift)->{domain_e_val};
	#print "$val_1 < $val_2 ? ".($val_1 < $val_2 ? 'true' : 'false')." \n";
	return $val_1 < $val_2;
}

sub printDomain{
	my $domain_ref = shift;
	foreach my $field (keys %$domain_ref){
		print $field,"\t";
	}
	print "\n";
	foreach my $field (keys %$domain_ref){
		print $domain_ref->{$field},"\t";
	}
	print "\n";
}

sub printDomainToFile{
	my $domain_ref = shift;
	foreach my $field (@keys){
		print $outfile  $domain_ref->{$field},"\t";
	}
	print $outfile "\n";
}

sub printHeaderToFile{
	foreach my $field (@keys){
		print $outfile $field,"\t";
	}
	print $outfile  "\n";
}



