package dummy;sub meth{print "ok"};package main;my $meth="meth";my $o = bless {},"dummy"; $o->$meth("const")
### RESULT:ok
