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
		print $_,"\n";
		if (($_ !~ m/^\.+/) and ($_ =~ m/\.aln\.fa$/)){
			print $dir."/".$_."\n";
			system("perl fastaToStockholm.pl ".$dir."/".$_." > ".$dir."/".$_.".stockholm");
		}
	}
}
