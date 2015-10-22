eval q/use Sub::Name; 1/ or die "no Sub::Name"; subname("main::bar", sub { 42 } ); print "ok\n";
### RESULT:ok
