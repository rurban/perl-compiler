#!./perl

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
    # help B
    use Tie::Hash::NamedCapture;
}

plan tests => 26;

#
# This file tries to test builtin override using CORE::GLOBAL
#
my $dirsep = "/";

INIT { package Foo; *main::getlogin = sub { "kilroy"; } }

eval q/is( getlogin, "kilroy" )/;

my $t = 42;
INIT { *CORE::GLOBAL::time = sub () { $t; } }

eval q/is( 45, time + 3 )/;

#
# require has special behaviour
#
my $r;
INIT { *CORE::GLOBAL::require = sub { $r = shift; 1; } }

eval q/require Foo/;
is( $r, "Foo.pm", 'Foo.pm' );


eval q/require Foo::Bar/;
is( $r, join($dirsep, "Foo", "Bar.pm") );

eval q/require 'Foo'/;
is( $r, "Foo", 'Foo' );

eval q/require 5.006/;
is( $r, "5.006", q/5.006/ );

eval q/require v5.6/;
ok( abs($r - 5.006) < 0.001 && $r eq "\x05\x06" );

eval "use Foo";
is( $r, "Foo.pm" );

eval "use Foo::Bar";
is( $r, join($dirsep, "Foo", "Bar.pm") );

eval "use 5.006";
is( $r, "5.006", q/5.006/ );

# localizing *CORE::GLOBAL::foo should revert to finding CORE::foo
{
    local(*CORE::GLOBAL::require);
    $r = '';
    eval "require NoNeXiSt;";
    ok( ! ( $r or $@ !~ /^Can't locate NoNeXiSt/i ) );
}

#
# readline() has special behaviour too
#

$r = 11;
INIT { *CORE::GLOBAL::readline = sub (;*) { ++$r }; }
eval q/
is( <FH>	, 12, 12 );
is( <$fh>	, 13, 13 );
my $pad_fh;
is( <$pad_fh>	, 14, 14 );
/;

# Non-global readline() override
INIT { *Rgs::readline = sub (;*) { --$r }; }
eval q/{
    package Rgs;
    ::is( <FH>	, 13, 13 );
    ::is( <$fh>	, 12, 12 );
    ::is( <$pad_fh>	, 11, 11 );
}/;

# Global readpipe() override
INIT { *CORE::GLOBAL::readpipe = sub ($) { "$_[0] " . --$r }; }
eval q|
is( `rm`,	    "rm 10", '``' );
is( qx/cp/,	    "cp 9", 'qx' );
|;

# Non-global readpipe() override
INIT { *Rgs::readpipe = sub ($) { ++$r . " $_[0]" }; }
eval q|{
    package Rgs;
    ::is( `rm`,		  "10 rm", '``' );
    ::is( qx/cp/,	  "11 cp", 'qx' );
}|;

# Verify that the parsing of overridden keywords isn't messed up
# by the indirect object notation
{
    local $SIG{__WARN__} = sub {
	::like( $_[0], qr/^ok overriden at/, "like" );
    };
    INIT { *OverridenWarn::warn = sub { CORE::warn "@_ overriden"; }; }
    package OverridenWarn;
    sub foo { "ok" }
    eval q|
    warn( OverridenWarn->foo() );
    warn OverridenWarn->foo();
    |;
}
INIT { *OverridenPop::pop = sub { ::is( $_[0][0], "ok" ) }; }
{
    package OverridenPop;
    sub foo { [ "ok" ] }
    eval q|
    pop( OverridenPop->foo() );
    pop OverridenPop->foo();
    |;
}

{
    eval {
        local *CORE::GLOBAL::require = sub {
            CORE::require($_[0]);
        };
        require 5;
        require Text::ParseWords;
    };
    is $@, '', '$@ empty';
}
