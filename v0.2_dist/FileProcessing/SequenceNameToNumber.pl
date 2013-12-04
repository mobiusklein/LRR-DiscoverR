use strict;
use warnings;
use FileHandle;

my $input_file = shift;

my $input_file_handle = FileHandle->new($input_file);

my $output_file = $input_file;

$output_file.="_NameToNumber";

my $output_file_handle = FileHandle->new(">".$output_file.".fa");

my $dictionary_file_handle = FileHandle->new(">".$output_file.".index");

my $counter_index = 0;

my $line = "";

while ($line = <$input_file_handle>){
	chomp $line;
	if ($line =~ m/^>/){
		$counter_index++;
		print $dictionary_file_handle "\%~encode$counter_index\t$line\n";
		print $output_file_handle ">\%~encode$counter_index\n";
	}
	else {
		print $output_file_handle $line."\n";
		}
}