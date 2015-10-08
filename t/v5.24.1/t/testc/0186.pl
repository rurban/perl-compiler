eval q/require B/; my $sub = do { package one; \&{"one"}; }; delete $one::{one}; my $x = "boom"; print "ok\n";
### RESULT:ok
