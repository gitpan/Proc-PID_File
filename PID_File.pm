package Proc::PID_File;
use Fcntl;
use Carp;

use vars '$VERSION';
$VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;

	if (!$args{path}) { croak "new: 'path' not specified!" }
	bless { path=>$args{path} }, $class;
}

sub create {
	my $self = shift;
	my $path = $self->{path};
	local *FH;

	sysopen FH, $path, O_RDWR|O_CREAT or return;
	flock FH, LOCK_EX;

	my $mtime = -M $path;
	my $pid = <FH>;

	my $new_pid = "$$\n";

	if ($mtime > 0 and $pid and kill 0, $pid) {
		$self->{previously_exists} = 1;
		return 1;
	} else {
		sysseek  FH, 0, 0;
		truncate FH, 0;
		syswrite FH, $new_pid, length($new_pid);
		close FH or return;
	}
}

sub previously_exists {
	my $self = shift;

	$self->{previously_exists};
}

sub delete {
	my $self = shift;
	my $path = $self->{path};
	local *FH;

	sysopen FH, $path, O_RDWR or return;
	flock FH,LOCK_EX;
	unlink $path or return;
	1;
}

1;
__END__

=head1 NAME

Proc::PID_File - manage PID files

=head1 SYNOPSIS

 use Proc::PID_File;

 $pid_file = Proc::PID_File->new(path=>"/var/log/mydaemon.pid");
 if (!$pid_file->create) { die "Can't create pid file"; }
 if ($pid_file->previously_exists) { die "I was already started."; }

 $SIG{INT} = $SIG{TERM} = sub { $pid_file->delete; exit; };

 # go ahead, daemonize...

=head1 DESCRIPTION

This module provides a simple interface to manage PID files. A PID file is a
place to store the process ID number of a process, created by the process
itself when it starts. A valid (i.e. not stale) PID file indicates that the
process instance is still alive, and can indicate that the program should
not start another instance when invoked. PID files are also used to record
the process ID number of daemon processes so that they can be signalled
(e.g. TERM-ed or HUP-ed).

=head1 AUTHOR

Copyright (C) 2000, Steven Haryanto <steven@haryan.to>. All rights reserved.

This module is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 HISTORY

000731 - first hack

