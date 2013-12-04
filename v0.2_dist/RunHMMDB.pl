use strict;
use warnings;
use FileHandle;
use File::Basename;
use Getopt::Std;

my $opts = {};
getopt('ce', $opts);


my $e_val = (undef ~~ $opts->{'e'})?  0.001 : $opts->{'e'};
my $cpu = (undef ~~ $opts->{'c'}) ? 1 : $opts->{'c'} ;
my $hmmdb = shift;
my $query_file = shift;
my $dir_name= dirname($query_file)."/".basename($hmmdb)."_".basename($query_file);
print $dir_name,"\n";
mkdir $dir_name;
my $output_file = $dir_name."/".basename($query_file).".hmmscan";
my $table_file =  $dir_name."/".basename($query_file)."_table.hmmscan";
my $dom_table_file =  $dir_name."/".basename($query_file)."_dom_table.hmmscan";


system("hmmscan -o $output_file --tblout $table_file --domtblout $dom_table_file -E $e_val --domE $e_val --incE $e_val --incdomE $e_val --cpu $cpu $hmmdb $query_file");
system("perl ResultAnalysis/FilterResultsByDomain.pl $dom_table_file");

