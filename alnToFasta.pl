use strict;
use warnings;
use FileHandle;

my $alnFile = shift;

my $fh = new FileHandle;

$fh->open($alnFile);

my $line;
$line = <$fh>;
print STDERR "Discard $line";
$line = <$fh>;
print STDERR "Discard $line";
$line = <$fh>;
print STDERR "Discard $line";

my %accHash = ();
$line = "";
while ($line = <$fh>){
	$line =~ s/\n|\r//g;
	#print "$line\n";
	my ($name, $alignment) = split(/\s+|\t+/,$line);
	if ((defined($name) and ($name ne "")) and (defined($alignment) and ($alignment ne ""))){
		if (!defined($accHash{$name})){ $accHash{$name} = ""; }
		$accHash{$name} = $accHash{$name}.$alignment;
	}
}

foreach my $key (keys %accHash){
	print ">$key\n$accHash{$key}\n\n";
}
