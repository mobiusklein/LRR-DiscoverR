use strict;
use warnings;
use FileHandle;
use Getopt::Std;
use File::Basename;

my $tm_file = shift;
my $lrr_file = shift;

my $tm_fh = FileHandle->new($tm_file);
my $lrr_fh = FileHandle->new($lrr_file);

my %toTM;

my %toLRR;


my $opts = {};
getopt('nxk', $opts);

my $name_offset = 0;
my $name_splitter = 0;
if (defined($opts->{'n'})){
    $name_offset = $opts->{'n'};
#print "Setting name offset ",$name_offset,"\n";
}
if (defined($opts->{'x'})){
    $name_splitter = $opts->{'x'};
}

my $min_tm = (($opts->{'k'} ~~ undef) ? 4 : $opts->{'k'});
print $min_tm,"\n";

my $name_slicer = sub {
	my $name = shift;
	if ($name_splitter){
	    my @trimmings;
	    ($name, @trimmings) = split(/\s/,$name);
	}
	if ($name_offset > 0){
		return substr($name, 0, $name_offset);
	}
	return $name;
};
#print $name_offset,"\n";

## Holds the name of the sequence
my $hit_name = "";
## Holds the predicted domains of the sequence
my $domain_list = ""; 

## Extract the Transmembrane information from the output file of
## TM2.0
while (my $line = <$tm_fh>){
	chomp $line;
	## Detect a line with a sequence name on it
	if ($line =~ m/>(.+)/){
		$hit_name = $1;
	}
	## Detect a line with TM information on it
	elsif ($line =~ m/%pred\sNB\(0\):\s(.+)/){
		## The segment of the line listing the Inside, Outside, and Membrane domains
		$domain_list = $1;
		#$toTM{$hit_name} = {};
		## Counts the number of Membrane domains
		my $numMembraneDomains = ($domain_list =~ tr/M/M/);
		my $pos_first_transmembrane = "no TM";
		my $pos_last_transmembrane = "no TM";
		## Holds Membrane domain start points 
		my @pos_array;
		## Extracts the Membrane domain start points
		while($domain_list =~ m/M\s[0-9]+\s+([0-9]+)/g){
			push(@pos_array, $1);
		}
		## Gets the first TM point
		$pos_first_transmembrane = $pos_array[0];
		## Gets the last TM point 
		$pos_last_transmembrane = $pos_array[$#pos_array];
		if (!defined($pos_first_transmembrane)){
			$pos_first_transmembrane = "No TM";
			$pos_last_transmembrane = "No TM";
		}
		## Save information to the toTM hash as array ref
		$toTM{$name_slicer->($hit_name)} = [$domain_list, $numMembraneDomains, $pos_first_transmembrane, $pos_last_transmembrane, $hit_name];
		#print "$hit_name, ".$name_slicer->($hit_name)." -> $domain_list with $numMembraneDomains domains at $pos_first_transmembrane\n";
	}
}

## Reads in LRR information
## Skip header
my $skip = <$lrr_fh>;
while (my $line = <$lrr_fh>){
	#print $line;
	chomp $line;
	## Break the line up around Tabs
	my @line_data = split(/\t/, $line);
	## capture individual pieces of data
	my $sequence_name = $line_data[0];
	my $e_value = $line_data[3];
	my $start_env = $line_data[1];
	my $end_env = $line_data[2];
	## Store in a Hash Reference
	my $hit = { NAME => $sequence_name, E_VAL => $e_value, START => $start_env, END => $end_env};
	## If the sequence has not yet been enountered
	if (!defined($toLRR{$sequence_name})){
		## Associate it with an Array ref in the toLRR Hash
		$toLRR{$sequence_name}=[];
	} 
	## Add the current LRR hit to the array under the sequence in toLRR
	push(@{$toLRR{$sequence_name}}, \$hit);
	
}

## This section's code will merge the information from both files where they meet specific criterion.
## Sequences with $min_tm TM regions and LRRs that end before the first TM region will be written to file here.

my $output_file_name = $lrr_file.".gpcr_prediction_list.tsv";

my $lrr_gpcr_prediction_file = FileHandle->new(">".$output_file_name);

## Print the header for the result file
print $lrr_gpcr_prediction_file "sequence name\t# TM regions ~ First TM position ~ Last TM position: LRRs Domain Start	Domain End	E Value,\n";

## For each sequence with LRRs
foreach my $seq (keys %toLRR){
$seq = $name_slicer->($seq);
	## If the sequence has more TM regions than the minimum parameter
	if (${$toTM{$seq}}[1]-$min_tm > 0){
		
		print "Sequence: $seq	${$toTM{$seq}}[1]\n";
		## Print the sequence label
		my $nextline = $seq."\t${$toTM{$seq}}[1]~${$toTM{$seq}}[2]~${$toTM{$seq}}[3]:";
		my $initial_length = length($nextline);
		## For each LRR in that sequence
		foreach my $hit (@{$toLRR{$seq}}){
			## IF the LRR ends before the first TM region begins
			if(${$toTM{$seq}}[2]>$$hit->{END}){
			## Print that region to file
			 $nextline.="\t".$$hit->{START}."\t".$$hit->{END}."\t".$$hit->{E_VAL}.",";
			}
		}
		if (length($nextline)>$initial_length){
		print $lrr_gpcr_prediction_file $nextline."\n";
		}
		
	}
	else {
##	print "but the sequence had none to no Transmembrane regions.\n"; 
	}
}

