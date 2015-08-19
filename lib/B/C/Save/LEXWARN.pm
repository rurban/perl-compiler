package B::LEXWARN;

use strict;

use Config;
use B qw/cstring/;
use B::C::File qw/init decl/;

# pre vs. post 5.8.9/5.9.4 logic for lexical warnings
our @ISA = qw(B::PV B::IV);

my %lexwarnsym;

sub save {
    my ( $sv, $fullname ) = @_;

    my $pv = $sv->PV;

    # check cache
    return $lexwarnsym{$pv} if $lexwarnsym{$pv};

    my $sym = sprintf( "lexwarn%d", $B::C::pv_index++ );

    # if 8 use UVSIZE, if 4 use LONGSIZE
    my $t = ( $Config{longsize} == 8 ) ? "J" : "L";
    my ($iv) = unpack( $t, $pv );    # unsigned longsize
    if ( $iv >= 0 and $iv <= 2 ) {   # specialWARN: single STRLEN
        decl()->add( sprintf( "Static const STRLEN* %s = %d;", $sym, $iv ) );
    }
    else {                           # sizeof(STRLEN) + (WARNsize)
        my $packedpv = pack( "$t a*", length($pv), $pv );
        decl()->add( sprintf( "Static const char %s[] = %s;", $sym, cstring($packedpv) ) );
    }

    # set cache
    $lexwarnsym{$pv} = $sym;

    return $sym;
}

1;
