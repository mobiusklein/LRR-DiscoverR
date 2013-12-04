use strict;
use warnings; 
use FileHandle;
use File::Basename;


## A file containing a list of motifs in FASTA format
my $motif_file = shift;

## A file containing an aligned sequence in which
## to search for motif positions
my $model_file = shift;

## FileHandle for $motif_file
my $motif_fh = new FileHandle;

## FileHandle for $model_file
my $model_fh = new FileHandle;

$motif_fh->open($motif_file);
$model_fh->open($model_file);

## For storing the resulting output in a TSV file for later use
my $output_file = basename($model_file)."_".basename($motif_file)."_Offsets.tsv";
my $output_fh = FileHandle->new($output_file);

## Dictionary for motif name and regex
my %motif;

## Motifs in sequence-order of appearance in the motif file 
## and within the sequence in the align file. Important for
## iterating in order. 
my @ordered_motifs;

## Data Structure for holding the aligned sequence 
my %align;

## Parsed Line Holder
my $line;

## Loop through the motif file
while ($line = <$motif_fh>){
## Remove new line characters from $line
$line =~ s/\n|\r//g;

## If the line is empty, return to the top of the loop 
## and do not bother caching
if ($line eq ""){next;} 

## Otherwise, this must be the tag line for a motif, 
## so remember its name appeared in this order 
## by pushing it onto the @ordered_motifs list
push(@ordered_motifs, $line);

## If this is a motif tag line, the next line must 
## contain the motif. Store the next line in the file
## under the current value of $line. Effectively
## storing the motif (which must be all on one line)
## through its tagline in %motif dictionary
$motif{$line} = <$motif_fh>;

## Remove new line characters from the motif
$motif{$line} =~ s/\n|\r//g;
}


## Read through the align file. There is usually
## only going to be one sequence in this file, 
## but more are valid. 
while ($line = <$model_fh>){
## Remove new line characters from $line
$line =~ s/\n|\r//g;

## Skip empty lines
if ($line eq ""){next;}

## If this line was not empty, it must be a tagline,
## so the next line must be an aligned sequence (all on
## one line). Store the sequence under its tagline
$align{$line} = <$model_fh>;

## Remove new lines from the sequence.
$align{$line} =~ s/\n|\r//g;
}

## For each motif 
foreach my $key (@ordered_motifs){

## The position the motif starts at
my $motif_pos = 0;

## The position in the aligned sequence where the last motif ended
my $align_pos = 0;

## A string representation of the regex containing 0 or more "-" between
## each character in the motif
my $pattern_test = join('-*',split(//,$motif{$key}));

## Remove the trailing character from the pattern   <==== SUSPECTED WRONG
chomp $pattern_test;

## MUST FIND WAY TO CAPTURE PRECEDING 10 CHARACTERS



print STDERR $pattern_test."\n";
	## For each aligned sequence 
	foreach my $seq (keys %align){
	print STDERR "Searching for $key motif: $pattern_test\n";
		## If the regex is matched
		if ($align{$seq} =~ m/$pattern_test/g){
			##Then the motif appeared between $-[0] and $+[0]
			print STDERR "Match at  $-[0] - $+[0] \n";
			## Record where the motif began
			$motif_pos = $-[0];
			## Record where the motif ended
			$align_pos = pos($align{$seq});
			## Compute the substring from the point the motif ended to the end 
			## of the sequence
			my $subsequence = substr($align{$seq},$-[0]);
			print STDERR length($subsequence),"\n";
			## If there are 1 to 20 non-gap characters following the motif, 
			if ($subsequence =~ m/((-*[^-]){1,20})/){
				print STDERR "20 amino acids downstream of the motif's start site:\n";
				## Length of aligned section which contains 20 amino acids. 
				print STDERR "$1\n",length($1),"\n";
				## Count how many are present
				## and print to STDOUT the motif name, the position it began
				## and the length of the preceding padding (sum of gaps and aminoacids)
				print $output_fh "$key\t$motif_pos\t".length($1)."\n";
			}
		}
		else {
			print STDERR "#No matches found#\n\n";
		}
	}
}



