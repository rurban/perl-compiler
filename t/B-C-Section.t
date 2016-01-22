#!perl -w

use strict;
use warnings;

use 5.14.0;    # Inline packages

use B::C ();   # Before test::warnings;

use Test::More;
use Test::Trap;
use Test::Deep;

use FileHandle;
use B::C::Section;

my %symtable;

my $aaasect   = B::C::Section->new( 'aaa',   \%symtable, 0 );
my $bbbsect   = B::C::Section->new( 'bbb',   \%symtable, 0 );
my $xpvcvsect = B::C::Section->new( 'xpvcv', \%symtable, 0 );
my $svsect    = B::C::Section->new( 'sv',    \%symtable, 0 );

is( $aaasect->typename,   'AAA',              "Typename for aaasect is upper cased as expected" );
is( $svsect->typename,    'SV',               "Typename for svsect is upper cased as expected" );
is( $xpvcvsect->typename, 'XPVCV_or_similar', "Typename for xpvcvsect is special (XPVCV_or_similar)" );

my $expect = "0, 1, SVTYPEMASK|0x01000000, {0}\n";
is( $svsect->output("%s\n"), $expect, "svsect initializes with something automatically?" );
is( $svsect->index(),        0,       "Indext for svsect is right" );

$svsect->add("yabba dabba doo");
$expect .= "yabba dabba doo\n";
is( $svsect->output("%s\n"), $expect, "svsect retains what was added. with something automatically?" );
is( $svsect->index(),        1,       "Index for svsect is right" );

$svsect->remove;
$expect = "0, 1, SVTYPEMASK|0x01000000, {0}\n";
is( $svsect->output("%s\n"), $expect, "svsect retains what was added. with something automatically?" );
is( $svsect->index(),        0,       "Index for svsect is right after remove" );

is( $aaasect->comment,                  undef,       "comment Starts out blank" );
is( $aaasect->comment(qw/foo bar baz/), 'foobarbaz', "comment joins all passed args and stores/returns them." );
is( $aaasect->comment('flib'),          'flib',      "successive calls to comment overwrites/stores/returns the new stuff" );

is( $aaasect->comment_common('flib'), 'next, sibling, ppaddr, targ, type, opt, latefree, latefreed, attached, spare, flags, private, flib', "comment_common" );

package fakeop {
    sub new { return bless { 'flag' => $_[1] || 'fff' } }
    sub flagspv { return shift->{'flag'} }
};

B::C::Setup::Debug::enable_debug_level('flags');
my $op = fakeop->new;
note "TODO: This is WAY overly specific behavior...";
$bbbsect->add('abcd');
is( $bbbsect->debug($op), 'fff', "bbbsect->debug(op) returns flagspv()'s value from the op" );

B::C::Setup::Debug::init();
is( $bbbsect->debug($op),                   undef, "bbbsect->debug(op) returns nothing if the op has nothing." );
is( $bbbsect->{'dbg'}->[ $bbbsect->index ], 'fff', "  ... but the old value is still stored." );

B::C::Setup::Debug::enable_debug_level('flags');
$bbbsect->add('defg');
$op->{'flag'} = 'ggg';
is( $bbbsect->debug($op), 'ggg', "bbbsect->debug(op) adds a debug to the second add." );
cmp_deeply( $bbbsect->{'dbg'}, [qw/fff ggg/], "  ... And stores it in slot 1 in the array not altering the first." );

B::C::Setup::Debug::init();
is( $bbbsect->debug, undef, "bbbsect->debug does nothing when B::C::debug{flags} is off." );

# Start over. Let's test output now.
B::C::Setup::Debug::enable_verbose();
B::C::Setup::Debug::enable_debug_level('flags');
$bbbsect = B::C::Section->new( 'bbb', \%symtable, 'default_value_here' );
$bbbsect->add("abc");
$bbbsect->add("xyzs\\_134bcef33");
$bbbsect->debug( fakeop->new("A test debug statement.") );
$bbbsect->add("pdq");

my $string;
trap { $string = $bbbsect->output("%s\n") };
like( $trap->stderr, qr/Warning: unresolved bbb symbol s\\_134bcef33/, "Output warns it saw an unexpected symbol" );
is( $B::C::unresolved_count, 1, "unresolved count is logged" );
is( $string, "abc\nxyzdefault_value_here\npdq\n", "Test output with complicated adds" );

$B::C::unresolved_count = 0;
$symtable{'s\_134bcef33'} = "resolved";
is( $B::C::unresolved_count, 0, "unresolved count is logged" );
is( $bbbsect->output("%s\n"), "abc\nxyzresolved\npdq\n", "Test output with complicated adds and resolvable symbol table." );

is( $bbbsect->get('sv'),       $svsect,  "svsect can be found from \$bbsect->get" );
is( B::C::Section->get('aaa'), $aaasect, "aaasect can be found from B::C::Section->get" );

done_testing();
