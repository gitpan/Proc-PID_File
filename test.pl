# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Proc::PID_File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

unlink "test.pid";

sleep 1;

# object creation
$p = Proc::PID_File->new(path=>"test.pid");
print $p ? "ok":"not ok", " 2\n";
exit 1 if !$p;

# object init
if (!$p->init) {
	print "not ok 3";
	if ($!) { print ": $!\n" }
	print "\n";
	exit 1;
} else { print "ok 3\n" }

# active() test 1
print $p->active ? "not ok":"ok", " 4\n";

# 2nd object creation
$p2 = Proc::PID_File->new(path=>"test.pid");
print $p2 ? "ok":"not ok", " 5\n";
exit 1 if !$p2;

utime $^T-1, $^T-1, "test.pid";

# 2nd object init
if (!$p2->init) {
	print "not ok 6";
	if ($!) { print ": $!\n" }
	print "\n";
	exit 1;
} else { print "ok 6\n" }

# active() test 2
print $p2->active ? "ok":"not ok", " 7\n";

# test automatic file deletion
undef $p2;
print -f "test.pid" ? "ok":"not ok", " 8\n";
undef $p;
print -f "test.pid" ? "not ok":"ok", " 9\n";

