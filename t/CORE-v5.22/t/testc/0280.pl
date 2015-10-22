package M; $| = 1; sub DESTROY {eval {print "Farewell ",ref($_[0])};} package main; bless \$A::B, q{M}; *A:: = \*B::;
### RESULT:Farewell M
