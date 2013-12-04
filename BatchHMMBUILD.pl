use strict;
use warnings;
use DirHandle;
use FileHandle;
use Cwd;

my $dir = shift;
print $dir."\n";

mkdir $dir."/HMMs";

my $dir_handle = DirHandle->new($dir);

my @files;

if (defined($dir_handle)){
	while(defined($_ = $dir_handle->read)){
		print $_,"\n";
		if (($_ !~ m/^\.+/) and ($_ =~ m/\.stockholm$/)){
			print $dir."/".$_."\n";
			my $hmm_name = $_;
			$hmm_name =~ s/\.fa|\.aln|\.stockholm//g;
			system("hmmbuild -n $_ ".$dir."/HMMs/".$hmm_name.".hmm ".$dir."/".$_);
		}
	}
}
