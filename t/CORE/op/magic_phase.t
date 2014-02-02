#!./perl

use strict;
use warnings;

use vars '%compile_time';

# Test ${^GLOBAL_PHASE}
#
# Test::More, test.pl, etc assert plans in END, which happens before global
# destruction, so we don't want to use those here.

print "1..8\n";

sub ok ($$) {
    print "not " if !$_[0];
    print "ok";
    print " - $_[1]" if defined $_[1];
    print "\n";
}

BEGIN {
    $compile_time{BEGIN} = ${^GLOBAL_PHASE};
}

UNITCHECK {
    $compile_time{UNITCHECK} = ${^GLOBAL_PHASE};
}

CHECK {
    $compile_time{CHECK} = ${^GLOBAL_PHASE};
}

INIT {
    $compile_time{INIT} = ${^GLOBAL_PHASE};
}

for my $phase ( 'BEGIN', 'UNITCHECK', 'CHECK', 'INIT' ) {
    my $should_be = $phase =~ m/^(:?BEGIN|UNITCHECK)/ ? 'START' : $phase;
    ok( $compile_time{$phase} eq $should_be, $phase );

    # print STDERR "#     got: '$compile_time{$phase}'\n# expected: '$should_be'\n";
}

ok ${^GLOBAL_PHASE} eq 'RUN', 'RUN';

sub Moo::DESTROY {
    ok ${^GLOBAL_PHASE} eq 'RUN', 'DESTROY is run-time too, usually';
}

my $tiger = bless {}, Moo::;

sub Kooh::DESTROY {
    ok ${^GLOBAL_PHASE} eq 'DESTRUCT', 'DESTRUCT';
}

our $affe = bless {}, Kooh::;

END {
    ok ${^GLOBAL_PHASE} eq 'END', 'END';
}
