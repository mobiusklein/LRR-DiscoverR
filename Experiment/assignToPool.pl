use strict;
use warnings;
use FileHandle;
use DirHandle;
use v5.12;
use integer;

# defline => sequence
my %all_sequences;

# Get the file of sequences to be pooled into TRAIN and TEST
my %training_pool;
my %testing_pool;

sub parseFasta{
    my $infile = shift;
    my $fh = FileHandle->new($infile) or die "Unable to open input file";
    my $line;
    my $defline = '';
    my $sequence = '';
    while($line = <$fh>){
        chomp $line;
        if($line =~ /^>(.+)/){
            if($defline ne ''){
                # Capture the sequence structure
                flushSequence($defline, $sequence);
            }
            $defline = $1;
            $sequence = '';
        }
        else{
            $sequence .= $line;
        }
    }
    # Capture the last sequence in the file
    flushSequence($defline, $sequence);
    $fh->close();
}

# Removes the alignment dashes from a sequence's body
sub removeAlignDashes {
    my $alnSeq = shift;
    $alnSeq =~ s/-//g;
    return $alnSeq;
}

sub toFasta{
    my $defline = shift;
    my $sequence = shift;
    my $sep = $/;
    $sequence =~ s/(.{1,80})/$1$sep/g;
    my $fasta = '>'.$defline.$sep.$sequence.$sep;
    return $fasta;
}

# Saves the sequence components passed to the %all_sequences hash
sub flushSequence {
    my $defline = shift;
    my $sequence = shift;
    $all_sequences{$defline} = $sequence;
}

sub assignToPool {
    my %sequenceSet = %{(shift)};
    my $stackSize = int(rand(9) + 2) / 2;
    
    ## STATE VAR: 
    # TRUE => Training
    # FALSE => Testing
    my $whichPool = 1;

    my $count = 0;
    
    my @seqs = keys(%sequenceSet);
    foreach my $seq_name (@seqs){
        # Toggle groups
        if($count == $stackSize){
            $whichPool = !$whichPool;
            $count = 0;
        }
        if($whichPool){
            $training_pool{$seq_name} = $sequenceSet{$seq_name};
        } else {
            $testing_pool{$seq_name} = $sequenceSet{$seq_name};
        }
        $count++;
    }
    my @training_sequences = keys(%training_pool);
    my @testing_sequences = keys(%testing_pool);
    my $trial_id = time;
    my $trial_dir = 'Pool_'.$stackSize.'_'.$trial_id;
    mkdir($trial_dir);
    my $training_file = $trial_dir.'/TrainingSequences_'.$stackSize.'_'.$trial_id.'aln.fa';
    my $fh = FileHandle->new('>'.$training_file);
    print "Training Sequences going to $training_file.$/";
    for my $seq_id (@training_sequences){
        my $fasta_sequence = toFasta($seq_id, $training_pool{$seq_id});
        $fh->print($fasta_sequence);
    }
    $fh->close();
}



sub main {
    my $infile = shift;
    parseFasta($infile);
    assignToPool(\%all_sequences);
}

main shift;
