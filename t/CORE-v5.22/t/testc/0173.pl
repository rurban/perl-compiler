# WontFix use constant BEGIN => 42; print "ok 1\n" if BEGIN == 42; use constant INIT => 42; print "ok 2\n" if INIT == 42; use constant CHECK => 42; print "ok 3\n" if CHECK == 42;
### RESULT:Prototype mismatch: sub main::BEGIN () vs none at ./ccode173.pl line 2.
Constant subroutine BEGIN redefined at ./ccode173.pl line 2.
ok 1
ok 2
ok 3
