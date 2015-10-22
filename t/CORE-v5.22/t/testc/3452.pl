eval q/use Sub::Name; 1/ or die "no Sub::Name"; $bar="main::bar"; subname($bar, sub { 42 } ); print "ok\n";
### RESULT:ok
