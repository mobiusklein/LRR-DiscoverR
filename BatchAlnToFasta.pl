use strict;
use warnings;
use DirHandle;
use FileHandle;
use Cwd;

my $dir = shift;
print $dir."\n";

my $dir_handle = DirHandle->new($dir);

my @files;

if (defined($dir_handle)){
	while(defined($_ = $dir_handle->read)){
		if (($_ !~ m/^\.+/) and ($_ =~ m/\.aln$/)){
			print $dir."/".$_."\n";
			system("perl alnToFasta.pl ".$dir."/".$_." > ".$dir."/".$_.".fa");
		}
	}
}
