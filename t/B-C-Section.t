#!perl -w

use strict;
use warnings;

use 5.14.0;    # Inline packages

use B::C ();   # Before test::warnings;

use Test::More;
use Test::Warnings qw/warning/;
use Test::Deep;

use FileHandle;
use IO::String ();
use B::C::Section;

my %symtable;

my $aaasect   = B::C::Section->new( 'aaa',   \%symtable, 0 );
my $bbbsect   = B::C::Section->new( 'bbb',   \%symtable, 0 );
my $xpvcvsect = B::C::Section->new( 'xpvcv', \%symtable, 0 );
my $svsect    = B::C::Section->new( 'sv',    \%symtable, 0 );

is( $aaasect->typename,   'AAA',              "Typename for aaasect is upper cased as expected" );
is( $svsect->typename,    'SV',               "Typename for svsect is upper cased as expected" );
is( $xpvcvsect->typename, 'XPVCV_or_similar', "Typename for xpvcvsect is special (XPVCV_or_similar)" );

my $string = '';
my $fh     = IO::String->new($string);

$svsect->output( $fh, "%s\n" );
my $expect = "0, 1, SVTYPEMASK|0x01000000, {0}\n";
is( $string,          $expect, "svsect initializes with something automatically?" );
is( $svsect->index(), 0,       "Indext for svsect is right" );

# Zero out the testing output string.
$fh->seek( 0, 0 );
$fh->truncate;

$svsect->add("yabba dabba doo");
$expect .= "yabba dabba doo\n";
$svsect->output( $fh, "%s\n" );
is( $string,          $expect, "svsect retains what was added. with something automatically?" );
is( $svsect->index(), 1,       "Index for svsect is right" );

# Zero out the testing output string.
$fh->seek( 0, 0 );
$fh->truncate;

$svsect->remove;
$expect = "0, 1, SVTYPEMASK|0x01000000, {0}\n";
$svsect->output( $fh, "%s\n" );
is( $string,          $expect, "svsect retains what was added. with something automatically?" );
is( $svsect->index(), 0,       "Index for svsect is right after remove" );

is( $aaasect->comment,                  undef,       "comment Starts out blank" );
is( $aaasect->comment(qw/foo bar baz/), 'foobarbaz', "comment joins all passed args and stores/returns them." );
is( $aaasect->comment('flib'),          'flib',      "successive calls to comment overwrites/stores/returns the new stuff" );

is( $aaasect->comment_common('flib'), 'next, sibling, ppaddr, targ, type, opt, latefree, latefreed, attached, spare, flags, private, flib', "comment_common" );

package fakeop {
    sub new { return bless { 'flag' => $_[1] || 'fff' } }
    sub flagspv { return shift->{'flag'} }
};

$B::C::debug{'flags'} = 1;
my $op = fakeop->new;
note "TODO: This is WAY overly specific behavior...";
$bbbsect->add('abcd');
is( $bbbsect->debug($op), 'fff', "bbbsect->debug(op) returns flagspv()'s value from the op" );

delete $op->{'flag'};
is( $bbbsect->debug($op),                         undef, "bbbsect->debug(op) returns nothing if the op has nothing." );
is( $bbbsect->[-1]->{'dbg'}->[ $bbbsect->index ], 'fff', "  ... but the old value is still stored." );

$bbbsect->add('defg');
$op->{'flag'} = 'ggg';
is( $bbbsect->debug($op), 'ggg', "bbbsect->debug(op) adds a debug to the second add." );
cmp_deeply( $bbbsect->[-1]->{'dbg'}, [qw/fff ggg/], "  ... And stores it in slot 1 in the array not altering the first." );

$B::C::debug{'flags'} = 0;
is( $bbbsect->debug, undef, "bbbsect->debug does nothing when B::C::debug{flags} is off." );

# Zero out the testing output string.
$fh->seek( 0, 0 );
$fh->truncate;

# Start over. Let's test output now.
$B::C::verbose      = 1;
$B::C::debug{flags} = 1;
$bbbsect            = B::C::Section->new( 'bbb', \%symtable, 'default_value_here' );
$bbbsect->add("abc");
$bbbsect->add("xyzs\\_134bcef33");
$bbbsect->debug( fakeop->new("A test debug statement.") );
$bbbsect->add("pdq");

is( warning { $bbbsect->output( $fh, "%s\n" ) }, "Warning: unresolved bbb symbol s\\_134bcef33\n", "Output warns it saw an unexpected symbol" );
is( $B::C::unresolved_count, 1, "unresolved count is logged" );
is( $string, "abc\nxyzdefault_value_here\npdq\n", "Test output with complicated adds" );

# Zero out the testing output string.
$fh->seek( 0, 0 );
$fh->truncate;
$B::C::unresolved_count = 0;

$symtable{'s\_134bcef33'} = "resolved";
$bbbsect->output( $fh, "%s\n" );
is( $B::C::unresolved_count, 0, "unresolved count is logged" );
is( $string, "abc\nxyzdefault_value_here\npdq\n", "Test output with complicated adds and resolvable symbol table." );

done_testing();
