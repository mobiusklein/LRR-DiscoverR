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
    my $fasta = '>'.$defline.$/.$sequence.$/;
    return $fasta;
}

# Saves the sequence components passed to the %all_sequences hash
sub flushSequence {
    my $defline = shift;
    my $sequence = shift;
    $all_sequences{$defline} = $sequence;
}

sub assignToPool {
    # Takes a Hash as input
    my %sequenceSet = %{(shift)};

    # Randomly choose a number between 1 and 10 to 
    # control how many sequences are added to a given 
    # pool in a row.
    my $stackSize = int(rand(9) + 1);
    
    ## STATE VAR: 
    # TRUE => Training
    # FALSE => Testing
    my $whichPool = 1;

    # Track how many sequences have been added to 
    # the current pool
    my $count = 0;
    
    # Assign sequences to Training or Testing pools
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
    # Collect names of each sequence in each pool
    my @training_sequences = keys(%training_pool);
    my @testing_sequences = keys(%testing_pool);

    # Get a unique identifier from the current system time
    my $trial_id = time;

    # Create a new directory to house the sequence pool Fasta files
    my $trial_dir = 'Pool_'.$stackSize.'_'.$trial_id;
    mkdir($trial_dir);

    # Write Training pool to file
    my $training_file = $trial_dir.'/TrainingSequences_'.$stackSize.'_'.$trial_id.'aln.fa';
    my $fh = FileHandle->new('>'.$training_file);
    print "Training Sequences going to $training_file.$/";
    for my $seq_id (@training_sequences){
        my $fasta_sequence = toFasta($seq_id, $training_pool{$seq_id});
        $fh->print($fasta_sequence);
    }
    $fh->close();

    # Write Testing pool to file
    my $testing_file = $trial_dir.'/TestingSequences_'.$stackSize.'_'.$trial_id.'aln.fa';
    $fh = FileHandle->new('>'.$testing_file);
    print "Testing Sequences going to $testing_file.$/";
    for my $seq_id (@testing_sequences){
        my $fasta_sequence = toFasta($seq_id, removeAlignDashes($testing_pool{$seq_id}));
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