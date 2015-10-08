{ open(my $NIL, qq{|/bin/echo 23}) or die "fork failed: $!"; $! = 1; close $NIL; if($! == 5) { print} }
### RESULT:23
