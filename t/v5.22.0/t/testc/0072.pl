package dummy;sub meth{print "ok"};package main;my dummy $o = bless {},"dummy"; $o->meth("const")
### RESULT:ok
