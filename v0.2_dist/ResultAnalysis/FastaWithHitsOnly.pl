use strict;
use warnings;
use FileHandle;

my $fasta_file = shift;
my $prediction_file = shift;

my $line;  
my %sequences; 
my $prediction_file_handle = FileHandle->new($prediction_file);
print "Reading in LRRs\n";
while($line = <$prediction_file_handle>){
	chomp $line ;
	my ($query, @stuff) = split(/\t/, $line);
	$sequences{$query}=1;
	#print $query,"\n";
}

$line = undef;

my $fasta_file_handle = FileHandle->new($fasta_file);
my $output_handle = FileHandle->new(">".$prediction_file."_hits_only.fa");
my $current_sequence = "undef";
my $seq_acc;

print "Reading in Fasta\n";
while($line = <$fasta_file_handle>){
	chomp $line;
	if ($line =~ m/>(.*)/){
		#print ($1)."\n";
		if(defined $sequences{$current_sequence}){
			print $output_handle ">$current_sequence\n";
			print $output_handle "$seq_acc\n";
		}
		$current_sequence = $1;
		$seq_acc = "";
	}
	else{
		$seq_acc = $seq_acc.$line;
	}
}
