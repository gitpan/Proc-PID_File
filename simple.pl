use blib;
use Proc::PID_File;

$p=Proc::PID_File->new(path=>'simple.pid');
$p->init or die "$!\n";
!$p->active or die "i'm already running!\n";

$SIG{TERM}=$SIG{INT}=sub{$p->delete if $p};
sleep 10;
