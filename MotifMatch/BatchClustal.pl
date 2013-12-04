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
		if ($_ !~ m/^\.+/){
			print $_."\n";
			system("clustalw -infile ".$_."");
		}
	}
}
