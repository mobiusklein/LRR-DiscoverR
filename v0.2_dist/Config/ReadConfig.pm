use strict;
use warnings;
use FileHandle;

sub ReadConfig{ 
	my $config_file = shift;
	my $fh = FileHandle->new($config_file);
	my $line;
	my $comment_char = '#';
	my $section_char = '=';
	my $current_section;
	my $options={};

	while ($line = <$fh>){
		$line =~ s/\n|\r//g;
		if ($line =~ m/^$comment_char/){
			next;
		}
		if ($line =~ m/^$section_char(.*)/){
			$current_section = $1;
			$options->{$current_section}={};
		}
		else{
			my ($label,$value) = split("=>",$line);
			$options->{$current_section}->{$label}=$value;
		}
	}
	return $options
}

sub GetDatabasePaths{
	my $opts = shift;
	my @dbs;
	foreach my $db (keys %{$opts->{'hmmdb_path'}}){
		push (@dbs,$opts->{'hmmdb_path'}->{$db});
	}
	return \@dbs;
}

1