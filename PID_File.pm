package Proc::PID_File;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(hold_pid_file release_the_pid_file);
use Fcntl qw(:DEFAULT :flock);

use strict;
use vars qw($VERSION);
$VERSION='0.05';

my $pid_obj;

sub hold_pid_file {
	my $path = shift;
	local *FH;

	sysopen FH, $path, O_RDWR|O_CREAT or die "Cannot open pid file `$path': $!\n";
	flock FH, LOCK_EX;

	my ($pid) = <FH> =~ /^(\d+)/;
	
	# print "pid=$pid, \$\$=$$\n";
	
	if ($pid and $pid != $$ and kill 0, $pid) {
		close FH;
		return $pid;
	} else {
		sysseek  FH, 0, 0;
		truncate FH, 0;
		syswrite FH, "$$\n", length("$$\n");
		close FH or die "Cannot write pid file `$path': $!\n";
		$pid_obj = new Proc::PID_File::Object($path);
		return 0;
	}
}

sub release_the_pid_file {
	die "No pid file held\n" unless defined($pid_obj);
	$pid_obj->{delete} = 0;
}


package Proc::PID_File::Object;
use Fcntl qw(:DEFAULT :flock);

sub new {
	my $class = shift;
	bless {delete=>1, path=>shift};
}

sub delete {
	my $self = shift;
	my $path = $self->{path};
	local *FH;

	sysopen FH, $path, O_RDWR or return;
	flock FH,LOCK_EX;
	unlink $path and close FH or return;
#	print "deleted";
	1;
}

sub DESTROY {
#	print "DESTROY called\n";
	my $self = shift;

	$self->delete if $self->{delete};
}

1;
__END__

=head1 NAME

Proc::PID_File - check whether a self process is already running

=head1 SYNOPSIS

 use Proc::PID_File;

 # example 1. a nonforking program that just wants to check whether its
 # instance is already running.

 die "Already running!\n" if 
 	hold_pid_file("/tmp/grab_lots_of_news_headlines.pid");
 # ...code...
 exit; # pid file will be automatically removed here
 

 # example 2. a forking program (the daemon is the child and the parent
 # immediately exists). it wants to check whether its instance is already
 # running.

 die "Already running!\n" if
 	hold_pid_file("/var/run/mydaemon.pid");
 fork && {
 	# the parent part
 	release_the_pid_file();
 	exit; # pid file won't be removed here
 }
 # the child part
 # ...code...
 exit; # pid file will be automatically removed here


 # example 3. a forking program (the parent stays active, launches children
 # to serve requests. children exit after serving some requests). it wants
 # to check whether its instance is already running.

 die "Already running!\n" if
   hold__pid_file("/var/run/mydaemon.pid");
 while (1) {
 	if ($request = get_request()) {
 		if (fork()==0) {
 			# the child part
 			release_the_pid_file();
 			# ...code...
 			exit; # pid file won't be removed here
 		}
 	}
 exit; # pid file will be removed here


 
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

=head1 FUNCTIONS

=over 4

=item * hold_pid_file($path)

The hold_pid_file() function is used by a process to write its own pid to
the pid file. If the file as specified by $path cannot be written because of
an I/O error, the function dies with an error message. If the pid file
cannot be written because it belongs to another living process (i.e., the
program's previous instance), then the function will return true (a positive
number which is the pid contained in the pid file). If the pid file has been
written successfully, the function returns 0.

hold_pid_file() also creates an object in the Proc::PID_File namespace
that is used for autodeletion of pid file (by means of the DESTROY method).
You usually do not need to know or use this object. This means that, after
you invoke hold_pid_file(), when the process exits, the pid file will be
automatically deleted. Unless release_the_pid_file() was invoked.

=item * release_the_pid_file()

The release_the_pid_file() function (FIXME: name too verbose?) sets that if
the object created by hold_pid_file() is destroyed, the pid file will not be
removed. In other words, the pid file will not be automatically deleted.
Useful in forking programs, when you do not want the pid file to be removed
by the one of the child or parent.

release_the_pid_file() will die if no pid file is currently being held
(i.e., you have not invoked hold_pid_file first).

=back

=head1 AUTHOR

Copyright (C) 2000-2002, Steven Haryanto <steven@haryan.to>. All rights
reserved.

This module is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 HISTORY

See Changes.
