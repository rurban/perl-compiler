#!./perl -w

#
# test method calls and autoloading.
#

INIT {
    unshift @INC, "./lib";
    require 't/CORE/test.pl';
}

use strict;
no warnings 'once';

plan(tests => 79);

@A::ISA = 'Z';
@Z::ISA = 'C';

sub C::d {"C::d"}
sub D::d {"D::d"}

# First, some basic checks of method-calling syntax:
my $obj = bless [], "Pack";
sub Pack::method { shift; join(",", "method", @_) }
my $mname = "method";

is(Pack->method("a","b","c"), "method,a,b,c");
is(Pack->$mname("a","b","c"), "method,a,b,c");
is(method Pack ("a","b","c"), "method,a,b,c");
is((method Pack "a","b","c"), "method,a,b,c");

is(Pack->method(), "method");
is(Pack->$mname(), "method");
is(method Pack (), "method");
is(Pack->method, "method");
is(Pack->$mname, "method");
is(method Pack, "method");

is($obj->method("a","b","c"), "method,a,b,c");
is($obj->$mname("a","b","c"), "method,a,b,c");
is((method $obj ("a","b","c")), "method,a,b,c");
is((method $obj "a","b","c"), "method,a,b,c");

is($obj->method(0), "method,0");
is($obj->method(1), "method,1");

is($obj->method(), "method");
is($obj->$mname(), "method");
is((method $obj ()), "method");
is($obj->method, "method");
is($obj->$mname, "method");
is(method $obj, "method");

is( A->d, "C::d");		# Update hash table;

*Z::d = \&D::d;			# Import now.
is(A->d, "D::d");		# Update hash table;

{
    local @A::ISA = qw(C);	# Update hash table with split() assignment
    is(A->d, "C::d");
    $#A::ISA = -1;
    is(eval { A->d } || "fail", "fail");
}
is(A->d, "D::d");

{
    local *Z::d;
    eval 'sub Z::d {"Z::d1"}';	# Import now.
    is(A->d, "Z::d1");	# Update hash table;
    undef &Z::d;
    is((eval { A->d }, ($@ =~ /Undefined subroutine/)), 1);
}

is(A->d, "D::d");		# Back to previous state

eval 'no warnings "redefine"; sub Z::d {"Z::d2"}';	# Import now.
is(A->d, "Z::d2");		# Update hash table;

# What follows is hardly guarantied to work, since the names in scripts
# are already linked to "pruned" globs. Say, `undef &Z::d' if it were
# after `delete $Z::{d}; sub Z::d {}' would reach an old subroutine.

# issue #159 https://code.google.com/p/perl-compiler/issues/detail?id=159
undef &Z::d;
delete $Z::{d};
is(A->d, "C::d");		# Update hash table;

eval 'sub Z::d {"Z::d3"}';	# Import now.
is(A->d, "Z::d3");		# Update hash table;

delete $Z::{d};
*dummy::dummy = sub {};		# Mark as updated
is(A->d, "C::d");

eval 'sub Z::d {"Z::d4"}';	# Import now.
is(A->d, "Z::d4");		# Update hash table;

delete $Z::{d};			# Should work without any help too
is(A->d, "C::d");

{
    local *C::d;
    is(eval { A->d } || "nope", "nope");
}
is(A->d, "C::d");

*A::x = *A::d;
A->d;
is(eval { A->x } || "nope", "nope", 'cache should not follow synonyms');

my $counter;

eval <<'EOF';
sub C::e;
BEGIN { *Z::e = \&C::e }	# Shouldn't prevent AUTOLOAD in original pkg
sub Y::f;
$counter = 0;

@X::ISA = 'Y';
@Y::ISA = 'Z';

sub Z::AUTOLOAD {
  my $c = ++$counter;
  my $method = $Z::AUTOLOAD;
  my $msg = "Z: In $method, $c";
  eval "sub $method { \$msg }";
  goto &$method;
}
sub C::AUTOLOAD {
  my $c = ++$counter;
  my $method = $C::AUTOLOAD; 
  my $msg = "C: In $method, $c";
  eval "sub $method { \$msg }";
  goto &$method;
}
EOF

is(A->e(), "C: In C::e, 1");	# We get a correct autoload
is(A->e(), "C: In C::e, 1");	# Which sticks

is(A->ee(), "Z: In A::ee, 2"); # We get a generic autoload, method in top
is(A->ee(), "Z: In A::ee, 2"); # Which sticks

is(Y->f(), "Z: In Y::f, 3");	# We vivify a correct method
is(Y->f(), "Z: In Y::f, 3");	# Which sticks

# This test is not intended to be reasonable. It is here just to let you
# know that you broke some old construction. Feel free to rewrite the test
# if your patch breaks it.

{
no warnings 'redefine';
*Z::AUTOLOAD = sub {
  use warnings;
  my $c = ++$counter;
  my $method = $::AUTOLOAD; 
  no strict 'refs';
  *$::AUTOLOAD = sub { "new Z: In $method, $c" };
  goto &$::AUTOLOAD;
};
}

is(A->eee(), "new Z: In A::eee, 4");	# We get a correct $autoload
is(A->eee(), "new Z: In A::eee, 4");	# Which sticks

{
    no strict 'refs';
    # this test added due to bug discovery (in 5.004_04, fb73857aa0bfa8ed)
    is(defined(@{"unknown_package::ISA"}) ? "defined" : "undefined", "undefined");
}

# test that failed subroutine calls don't affect method calls
{
    package A1;
    sub foo { "foo" }
    package A2;
    @A2::ISA = 'A1';
    package main;
    is(A2->foo(), "foo", "A2->foo 1");
    is(do { eval 'A2::foo()'; $@ ? 1 : 0}, 1);
    is(A2->foo(), "foo", "A2->foo 2");
}

## This test was totally misguided.  It passed before only because the
## code to determine if a package was loaded used to look for the hash
## %Foo::Bar instead of the package Foo::Bar:: -- and Config.pm just
## happens to export %Config.
#  {
#      is(do { use Config; eval 'Config->foo()';
#  	      $@ =~ /^\QCan't locate object method "foo" via package "Config" at/ ? 1 : $@}, 1);
#      is(do { use Config; eval '$d = bless {}, "Config"; $d->foo()';
#  	      $@ =~ /^\QCan't locate object method "foo" via package "Config" at/ ? 1 : $@}, 1);
#  }

# test error messages if method loading fails
my $e;

eval '$e = bless {}, "E::A"; E::A->foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::A" at/);
eval '$e = bless {}, "E::B"; $e->foo()';  
like ($@, qr/^\QCan't locate object method "foo" via package "E::B" at/);
# next 3: perlcc issue
eval 'E::C->foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::C" (perhaps /);

eval 'UNIVERSAL->E::D::foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::D" (perhaps /);
eval 'my $e = bless {}, "UNIVERSAL"; $e->E::E::foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::E" (perhaps /);

$e = bless {}, "E::F";  # force package to exist
eval 'UNIVERSAL->E::F::foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::F" at/);
eval '$e = bless {}, "UNIVERSAL"; $e->E::F::foo()';
like ($@, qr/^\QCan't locate object method "foo" via package "E::F" at/);

# TODO: we need some tests for the SUPER:: pseudoclass

# failed method call or UNIVERSAL::can() should not autovivify packages
is( $::{"Foo::"} || "none", "none");  # sanity check 1
is( $::{"Foo::"} || "none", "none");  # sanity check 2

is( UNIVERSAL::can("Foo", "boogie") ? "yes":"no", "no" );
is( $::{"Foo::"} || "none", "none");  # still missing?

is( Foo->UNIVERSAL::can("boogie")   ? "yes":"no", "no" );
is( $::{"Foo::"} || "none", "none");  # still missing?

is( Foo->can("boogie")              ? "yes":"no", "no" );
is( $::{"Foo::"} || "none", "none");  # still missing?

is( eval 'Foo->boogie(); 1'         ? "yes":"no", "no" );
is( $::{"Foo::"} || "none", "none");  # still missing?

is(do { eval 'Foo->boogie()';
	  $@ =~ /^\QCan't locate object method "boogie" via package "Foo" (perhaps / ? 1 : $@}, 1);

eval 'sub Foo::boogie { "yes, sir!" }';
is( $::{"Foo::"} ? "ok" : "none", "ok");  # should exist now
is( Foo->boogie(), "yes, sir!");

# TODO: universal.t should test NoSuchPackage->isa()/can()

# This is actually testing parsing of indirect objects and undefined subs
#   print foo("bar") where foo does not exist is not an indirect object.
#   print foo "bar"  where foo does not exist is an indirect object.
eval 'sub AUTOLOAD { "ok ", shift, "\n"; }';
ok(1, "AUTOLOAD parsing of indirect objects and undefined subs");

# Bug ID 20010902.002
is(
    eval q[
	my $x = 'x'; # Lexical or package variable, 5.6.1 panics.
	sub Foo::x : lvalue { $x }
	Foo->$x = 'ok';
    ] || $@, 'ok'
);

# An autoloaded, inherited DESTROY may be invoked differently than normal
# methods, and has been known to give rise to spurious warnings
# eg <200203121600.QAA11064@gizmo.fdgroup.co.uk>

{
    use warnings;
    my $w = '';
    local $SIG{__WARN__} = sub { $w = $_[0] };

    sub AutoDest::Base::AUTOLOAD {}
    @AutoDest::ISA = qw(AutoDest::Base);
    { my $x = bless {}, 'AutoDest'; }
    $w =~ s/\n//g;
    is($w, '');
}

# [ID 20020305.025] PACKAGE::SUPER doesn't work anymore

package main;
our @X;
package Amajor;
sub test {
    push @main::X, 'Amajor', @_;
}
package Bminor;
use base qw(Amajor);
package main;
sub Bminor::test {
    $_[0]->Bminor::SUPER::test('x', 'y');
    push @main::X, 'Bminor', @_;
}
Bminor->test('y', 'z');
is("@X", "Amajor Bminor x y Bminor Bminor y z");

package main;
for my $meth (['Bar', 'Foo::Bar'],
	      ['SUPER::Bar', 'main::SUPER::Bar'],
	      ['Xyz::SUPER::Bar', 'Xyz::SUPER::Bar'])
{
# perlcc wontfix 276 - This cannot work with B::C - https://code.google.com/p/perl-compiler/issues/detail?id=276
  if ( $0 =~ m/\.bin$/ ) {
    ok(1, "skip perlcc wontfix 276 UNIVERSAL::AUTOLOAD");
  } else {
    fresh_perl_is(<<EOT,
package UNIVERSAL; sub AUTOLOAD { my \$c = shift; print "\$c \$AUTOLOAD\\n" }
package Xyz;
package main; Foo->$meth->[0]();
EOT
	"Foo $meth->[1]",
	{ switches => [ '-w' ] },
	"check if UNIVERSAL::AUTOLOAD works with [ ".join(', ', @$meth).' ]',
    );
  }
}

# Test for #71952: crash when looking for a nonexistent destructor
# Regression introduced by fbb3ee5af3d4
{
    fresh_perl_is(<<'EOT',
sub M::DESTROY; bless {}, "M" ; print "survived\n";
EOT
    "survived",
    {},
	"no crash with a declared but missing DESTROY method"
    );
}

