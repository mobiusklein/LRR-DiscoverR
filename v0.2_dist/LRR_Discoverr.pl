use strict;
use warnings;
use FileHandle;
use File::Basename;
use Getopt::Std;
use Config::ReadConfig;

my $opts = {};
getopt('ce', $opts);
my $e_val = (undef ~~ $opts->{'e'})?  0.001 : $opts->{'e'};
my $cpu = (undef ~~ $opts->{'c'}) ? 1 : $opts->{'c'} ;

my $config = "Config/config";
my $unencoded_query_file = shift;
my $tmm_file = shift;

print "Reading Configuration file\n";
my $config_opts=ReadConfig($config);
my @hmmdbs=@{GetDatabasePaths($config_opts)};

print "Encoding Sequence IDs for better handling\n";
system("perl FileProcessing/SequenceNameToNumber.pl $unencoded_query_file");

my $query_file = $unencoded_query_file."_NameToNumber.fa";
my $decoding_index =$unencoded_query_file."_NameToNumber.index";

foreach my $hmmdb (@hmmdbs){
print "Running on $hmmdb\n";
my $dir_name= dirname($query_file)."/".basename($hmmdb)."_".basename($query_file);
mkdir $dir_name;
my $output_file = $dir_name."/".basename($query_file).".hmmscan";
my $dom_table_file =  $dir_name."/".basename($query_file)."_dom_table.hmmscan";

system("hmmscan -o $output_file --domtblout $dom_table_file -E $e_val --domE $e_val --incE $e_val --incdomE $e_val --cpu $cpu $hmmdb $query_file");
print "Filtering Domain Overlaps\n";
system("perl ResultAnalysis/FilterResultsByDomain.pl $dom_table_file");
print "Decoding Sequence IDs\n";
system("perl FileProcessing/IndexNumberToSequenceNameHMMResult.pl $dom_table_file".".reduced $decoding_index");
print "Crossreferencing LRRs with Transmembrane Regions\n";
system("perl ResultAnalysis/Transmembrane_LRR_Crosscheck.pl $tmm_file $dom_table_file".".reduced.reindexed");
print "Generating Fasta File of predicted sequences\n";
system("perl ResultAnalysis/FastaWithHitsOnly.pl $query_file $dom_table_file".".reduced.reindexed".".gpcr_prediction_list.tsv");
}