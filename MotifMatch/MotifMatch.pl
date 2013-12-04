use strict;
use warnings; 
use FileHandle;

my $motif_file = shift;
my $align_file = shift;

my $motif_fh = new FileHandle;
my $align_fh = new FileHandle;

$motif_fh->open($motif_file);
$align_fh->open($align_file);

my %motif;
my %align;

my $line;
while ($line = <$motif_fh>){
$motif{name} = $line;
$motif{pattern}=<$motif_fh>;
}

while ($line = <$align_fh>){
$align{name} = $line;
$align{sequence} = <$align_fh>;
}
print STDERR $motif{name}, $motif{pattern}, "\n";
my $motif_pos = 0;
my $align_pos = 0;
my $score_string = "";

my $pattern_test = join('-*',split(//,$motif{pattern}));

print STDERR $pattern_test."\n";

if ($align{sequence} =~ m/$pattern_test/g){
	print STDERR "Match at  $-[0] - $+[0] \n";
	}

$align_pos = pos($align{sequence});
my $subsequence = substr($align{sequence},0,$align_pos);
print STDERR $subsequence,length($subsequence),"\n";

for (my $i = 0; $i < $-[0]; $i++){
	$score_string = $score_string."1";
}
my $num_twos = length($align{sequence})-$-[0];
for (my $i = 0; $i < $num_twos; $i++){
	$score_string = $score_string."2";
}

print STDERR length($score_string)," ", length($align{sequence}),"\n";
print $score_string."\n";

