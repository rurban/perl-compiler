package Foo::Moose; use Moose; has bar => (is => "rw", isa => "Int"); package main; my $moose = Foo::Moose->new; print "ok" if 32 == $moose->bar(32);
### RESULT:ok
