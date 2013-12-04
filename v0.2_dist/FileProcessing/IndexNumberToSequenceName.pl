use strict;
use warnings;
use FileHandle;

my $encoded_fasta_file = shift;

my $index_file = shift;

my $encoded_fasta_file_handle = FileHandle->new($encoded_fasta_file);

my $decoded_fasta_file = $encoded_fasta_file;

$decoded_fasta_file.= "_NumberToName.fa";

my $decoded_fasta_file_handle = FileHandle->new(">".$decoded_fasta_file);

my %index = %{&extract_index($index_file)};

my $line;

while($line = <$encoded_fasta_file_handle>){
	chomp $line;
	if($line =~ m/>(\%~encode[0-9]+)/){
		print $decoded_fasta_file_handle "$index{$1}\n";
	}
	else {
		print $decoded_fasta_file_handle $line,"\n";
	}
}




sub extract_index {
	my $index_file = shift;
	my $index_file_handle = FileHandle->new($index_file);
	my $line;
	my %index;
	while ($line = <$index_file_handle>){
		chomp $line;
		my ($numeric, $full) = split(/\t/, $line);
		$index{$numeric} = $full;
	}
	return \%index;
}

