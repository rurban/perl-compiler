#TODO destroy upgraded lexvar my $flag = 0; sub X::DESTROY { $flag = 1 } { my $x; # x only exists in that scope BEGIN { $x = 42 } # pre-initialized as IV $x = bless {}, "X"; # run-time upgrade and bless to call DESTROY # undef($x); # value should be free when exiting scope } print "ok\n" if $flag;
### RESULT:ok
