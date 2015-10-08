#WONTFIX lexical $_ in re-eval {my $s="toto";my $_="titi";{$s =~ /to(?{ print "-$_-$s-\n";})to/;}}
### RESULT:-titi-toto-
