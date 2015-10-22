package Foo; use overload q("") => sub { "Foo" }; package main; my $foo = bless {}, "Foo"; print "ok " if "$foo" eq "Foo"; print "$foo\n";
### RESULT:ok Foo
