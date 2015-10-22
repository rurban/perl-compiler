package Foo; sub new { bless {}, shift } DESTROY { $_[0] = "foo" } package main; eval q{\\($x, $y, $z) = (1, 2, 3);}; my $m; $SIG{__DIE__} = sub { $m = shift }; { my $f = Foo->new } print "m: $m\n";
### RESULT:m: Modification of a read-only value attempted at ccode196.pl line 3.
