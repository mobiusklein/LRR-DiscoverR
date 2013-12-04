use strict;
use warnings;
use FileHandle;

my $encoded_result_file = shift;

my $index_file = shift;

my $encoded_result_handle= FileHandle->new($encoded_result_file);

my $out_file_handle = FileHandle->new(">".$encoded_result_file.".reindexed");

my %index = %{&extract_index($index_file)};

my $line = <$encoded_result_handle>;
print $out_file_handle $line;
while ($line = <$encoded_result_handle>){
	chomp $line;
	my ($first_tab, @line_data) = split(/\t/,$line);
	my $replaced_query_name = $index{$first_tab}; 
	$replaced_query_name =~ s/^>//;
	print $out_file_handle $replaced_query_name,"\t";
	foreach my $line_data_element (@line_data){
		print $out_file_handle $line_data_element, "\t";
	}
	print $out_file_handle "\n";
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
