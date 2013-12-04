use strict;
use warnings;
use FileHandle;
use File::Basename;


## File produced by DistanceToMotif.pl, TSV with 
## offsets for each motif
my $offset_file = shift;

## File containing training data, aligned sequences which include 
## the sequence used as input to DistanceToMotif.pl
my $alignment_file = shift;

my $alignment_file_base = basename($alignment_file);
my $alignment_file_dir = dirname($alignment_file);

## Create a directory to house the motif fragments
mkdir $alignment_file_dir."MotifFragments";

## Hash to contain details for each Motif
my %LRRS;

## Assign file handles to input files
my $alignment_file_handle = FileHandle->new($alignment_file);
my $offset_file_handle = new FileHandle;
$offset_file_handle->open($offset_file);



my $line;
## For each line in the offset file
while ($line = <$offset_file_handle>){
	chomp $line;
	## Extract the tab-delimited information, 
	## 1\t($lable) The name of the motif 
	## 2\t($start_pos) The starting position of the motif in the model sequence
	## 3\t($length) The number of positions to capture from the beginning of the motif (from start to end of back-padding)
	my ($label, $start_pos, $length) = split(/\t/,$line);
	## Remove new-line characters from the name of the motif
	$label =~ s/>|\n|\r//g;
	## in the LRR hash, store a structure that has three fields, 
	## START => $start_pos,
	## LENGTH => $length
	## FILE => A FileHandle for a file in the newly created directory from "mkdir $alignment_file_dir."MotifFragments";"
	## that is named after $label and $alignment_file_base, the name of the input file
	$LRRS{$label} = { START => $start_pos, LENGTH => $length, FILE => FileHandle->new(">$alignment_file_dir"."MotifFragments/$label"."_$alignment_file_base".".fa") };
}


## For testing purposes only
# foreach my $offset (keys %LRRS){
	# print "$offset, $LRRS{$offset}->{FILE}, $LRRS{$offset}->{START}, $LRRS{$offset}->{LENGTH}\n";
# }

print STDERR "Motif Offsets Read\n";
## Travels from sequence to sequence, and
## generates a substring for each Offset in
## $offset_file. 

## Assumes the sequence to be on one line

## Stateful parsing:
## State 0 = Looking for Tag Line
## State 1 = Looking for Hit Line
my $state = 0;

## Holds the last sequence tag line encountered
my $last_tag_line;

## For each sequence in alignment_file
while ($line = <$alignment_file_handle>){
	chomp $line;
	if ($line eq ''){next;}
	if ($line =~ m/^(>.*)/) {
		$last_tag_line = $line;
		#print STDERR "## $last_tag_line assigned to last_tag_line\n";
		$state = 1;
	}
	elsif($state == 1){
		#print STDERR "** Sequence Line \$line\n";
		foreach my $offset (keys %LRRS){
			#print $offset."\n";
			## Gets the offset fragment around the LRR motif from the Offset data
			my $slice_motif = substr($line, $LRRS{$offset}->{START}, $LRRS{$offset}->{LENGTH});
			print "Slice Motif: $slice_motif$/";
			## Remove blanks from the fragment
			$slice_motif =~ s/-//g;
			print STDERR "$last_tag_line for $offset has $slice_motif\n";
			if (length($slice_motif) > 0){
				## Prints to the associated motif file
				print {$LRRS{$offset}->{FILE}} $last_tag_line."\n";
				print {$LRRS{$offset}->{FILE}} $slice_motif."\n";
			}
		}
		$state = 0;
	}
}
