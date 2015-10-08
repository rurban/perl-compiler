package Foo::Bar; sub baz { 1 } package Foo; sub new { bless {}, shift } sub method { print "ok\n"; } package main; Foo::Bar::baz(); my $foo = sub { Foo->new }->(); $foo->method;
### RESULT:ok
