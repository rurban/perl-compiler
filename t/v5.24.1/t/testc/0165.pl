use warnings; sub recurse1 { unshift @_, "x"; no warnings "recursion"; goto &recurse2; } sub recurse2 { my $x = shift; $_[0] a t +1 + recurse1($_[0] - 1) : 0 } print "ok\n" if recurse1(500) == 500;
### RESULT:ok
