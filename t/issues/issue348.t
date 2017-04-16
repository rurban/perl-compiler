#!perl

package Foo::Bar;

sub baz {
    return 1;
}

package Foo;

sub new {
    my ($class) = @_;

    return bless {}, $class;
}

sub method {
    return 1;
}

package main;

Foo::Bar::baz();

my $foo = sub {
    Foo->new
}->();

print "1..1\n";
printf "%s - Package Foo considered while walking anonymous subroutine\n", $foo->method ? 'ok' : 'not ok';
