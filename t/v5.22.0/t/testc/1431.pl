BEGIN{package Foo;our $DOT=qr/[.]/;};package main;print "ok\n" if "dot.dot" =~ m/($Foo::DOT)/
### RESULT:ok
