package Proc::PID_File;
use Fcntl qw(:DEFAULT :flock);
use Carp;

use strict;
use vars qw($VERSION);
$VERSION='0.04';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;

	if (!exists($args{path})) {
		croak "new: argument 'path' not specified";
	}

	bless {
		path => $args{path},
		initialized => 0,
		active => 0,
	}, $class;
}

sub init {
	my $self = shift;
	my $path = $self->{path};
	local *FH;

	return 1 if $self->{initialized};

	sysopen FH, $path, O_RDWR|O_CREAT or return;
	flock FH, LOCK_EX;

	my $mtime = $^T - (stat $path)[9];
	my ($pid) = <FH> =~ /^(\d+)/;
	
#	print "\$mtime is $mtime, \$\$ = $$, \$pid = $pid, kill(0, \$pid) = ${\(kill 0,$pid)}\n";

	if ($mtime > 0 and $pid and kill 0, $pid) { # active PID file
		$self->{active} = $pid;
		close FH or return;
	} else {
		sysseek  FH, 0, 0;
		truncate FH, 0;
		syswrite FH, "$$\n", length("$$\n");
		close FH or return;
	}
	$self->{initialized} = 1;
	$self->{pid} = $$;
}

# synonym
sub initialize { init(@_) }

# compatibility with 0.01
sub create { init(@_) }

sub active {
	my $self = shift;
	if (!defined($self->{initialized})) { croak "active: call 'init()' first" }
	return $self->{active};
}

# synonym
sub is_active { active(@_) }

# compatibility with 0.01
sub previously_exists { active(@_) }

sub delete {
	my $self = shift;
	my $path = $self->{path};
	local *FH;

	sysopen FH, $path, O_RDWR or return;
	flock FH,LOCK_EX;
	unlink $path and close FH or return;
	1;
}

sub DESTROY {
#	print "DESTROY called\n";
	my $self = shift;

	$self->delete unless ($self->{pid} != $$ or $self->{active});
}

1;
__END__

=head1 NAME

Proc::PID_File - check whether a self process is already running

=head1 SYNOPSIS

 use Proc::PID_File;

 $Pid_File = Proc::PID_File->new(path=>"/var/run/mydaemon.pid");
 if (!$Pid_File->init)  { die "Can't open/create pid file: $!" }
 if ($Pid_File->active) { die "mydaemon is already running" }

 # go ahead, daemonize...

=head1 DESCRIPTION

A pid file is a file that contain, guess what, pid. Pids are written down to
files so that:

=over 4

=item *

a program can know whether an instance of itself is currently running

=item *

other processes can know the pid of a running program

=back

This module can be used so that your script can do the former.

If a pid file is created by the init() method, it will be automatically
deleted when the object is destroyed (the forked child's object will not
delete the pid file -- since 0.03).

=head1 AUTHOR

Copyright (C) 2000-1, Steven Haryanto <steven@haryan.to>. All rights
reserved.

This module is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 HISTORY

000731 - first hack

010522 - incorporate a couple of suggestions. thanks to HASANT and Brad
         Hilton.
