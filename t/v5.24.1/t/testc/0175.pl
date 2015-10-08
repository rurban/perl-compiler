{ # note that moving the use in an eval block solve the problem use warnings NONFATAL => all; $SIG{__WARN__} = sub { "ok - expected warning\n" }; my $x = pack( "I,A", 4, "X" ); print "ok\n"; }
### RESULT:ok - expected warning
ok
