use strict;
use warnings;
use FileHandle;
use Getopt::Std;
use File::Basename;

my $tm_file = shift;

my $tm_fh = FileHandle->new($tm_file);

my %toTM;

my $hit_name = "";
## Holds the predicted domains of the sequence
my $domain_list = "";
while (my $line = <$tm_fh>){
	chomp $line;
	if ($line =~ m/>(.+)/){
		$hit_name = $1;
	}
	elsif ($line =~ m/%pred\sNB\(0\):\s(.+)/){
		$domain_list = $1;
		#$toTM{$hit_name} = {};
		my $numMembraneDomains = ($domain_list =~ tr/M/M/);
		my $pos_first_transmembrane = "no TM";
		my $pos_last_transmembrane = "no TM";
		my @pos_array;
		while($domain_list =~ m/M\s[0-9]+\s+([0-9]+)/g){
			push(@pos_array, $1);
		}
		$pos_first_transmembrane = $pos_array[0];
		$pos_last_transmembrane = $pos_array[$#pos_array];
		if (!defined($pos_first_transmembrane)){
			$pos_first_transmembrane = "No TM";
			$pos_last_transmembrane = "No TM";
		}
		$toTM{$hit_name} = [$domain_list, $numMembraneDomains, $pos_first_transmembrane, $pos_last_transmembrane, $hit_name];
		if ($numMembraneDomains > 3){
			print "$hit_name -> $domain_list with $numMembraneDomains domains at $pos_first_transmembrane\n";
		}
	}
}