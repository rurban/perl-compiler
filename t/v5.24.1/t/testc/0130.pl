no warnings "experimental::lexical_subs";use feature "lexical_subs";my sub p{q(ok)}; my $a=\&p;print p;
### RESULT:ok
