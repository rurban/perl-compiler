#!/usr/bin/env perl
# proof that moose types suck, they do only checks but no optimizations.
# see also #350
#
# with an older B::C < ~1.40 out of memory while compiling.
# endless recursion with B::HV::save
#  7  0x521293e4 in Perl_pp_entersub () at pp_hot.c:2806
#    GVGV::GV = 0x14c3ad0  "B::HV" :: "save",  DEPTH = 44817

{
    package Foo::Moose;
    use Moose;
    has bar => (is => 'rw');
     __PACKAGE__->meta->make_immutable;
}
{
    package TypedFoo::Moose;
    use Moose;
    has bar => (is => 'rw', isa => 'Int');
     __PACKAGE__->meta->make_immutable;
}
{
    package Foo::Manual;
    sub new { bless {} => shift }
    sub bar {
        my $self = shift;
        return $self->{bar} unless @_;
        $self->{bar} = shift;
    }
}
my $foo1 = Foo::Moose->new;
sub moose {
    $foo1->bar(32);
    my $x = $foo1->bar;
}
my $foo2 = TypedFoo::Moose->new;
sub moosetyped {
    $foo2->bar(32);
    my $x = $foo2->bar;
}
my $foo = Foo::Manual->new;
sub manual {
    $foo->bar(32);
    my $x = $foo->bar;
}
use Benchmark 'timethese';

print "Testing Perl $]\n";
timethese(
    50_000,
    {
        moose 		=> \&moose,
        moosetyped 	=> \&moosetyped,
        manual 		=> \&manual,
    }
);
