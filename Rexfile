use Rex -feature => [qw(1.4 exec_autodie)];
use Cwd;
use Rex::Commands::PerlSync;

desc 'Deploy to a server';
task deploy => sub {
	my ($opts, $args) = @_;
	my $build_dir = shift(@$args) // die 'please specify a remote directory';
	my $cwd = getcwd;

	say "== Deploying $cwd to $build_dir ==";

	file $build_dir, ensure => 'directory';
	sync_up $cwd, $build_dir, {
		exclude => [qw(.* *.db t sqitch* Rexfile*)]
	};
};

# ex: ft=perl

