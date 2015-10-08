# WontFix my $destroyed = 0; sub X::DESTROY { $destroyed = 1 } { my $x; BEGIN {$x = sub { } } $x = bless {}, X; } print qq{ok\n} if $destroyed == 1;
### RESULT:ok
