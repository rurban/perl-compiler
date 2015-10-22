package dummy;my $i=0;sub meth{print $i++};package main;dummy->meth(1);my dummy $o = bless {},"dummy";$o->meth("const");my $meth="meth";$o->$meth("const");dummy->$meth("const");dummy::meth("dummy","const")
### RESULT:01234
