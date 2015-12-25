package B::LEXWARN;

use strict;

use B::C::Config ();

use B qw/cstring/;
use B::C::File qw/init decl/;
use B::C::Save qw/inc_pv_index/;

# pre vs. post 5.8.9/5.9.4 logic for lexical warnings
our @ISA = qw(B::PV B::IV);

my %lexwarnsym;

sub save {
    my ( $sv, $fullname ) = @_;

    my $pv = $sv->PV;

    # check cache
    return @{ $lexwarnsym{$pv} } if $lexwarnsym{$pv};

    my $sym = sprintf( "lexwarn%d", inc_pv_index() );
    my $isint = 0;

    # if 8 use UVSIZE, if 4 use LONGSIZE
    my $t = ( $B::C::Config::Config{longsize} == 8 ) ? "J" : "L";
    my ($iv) = unpack( $t, $pv );    # unsigned longsize
    if ( $iv >= 0 and $iv <= 2 ) {   # specialWARN: single STRLEN
        decl()->add( sprintf( "Static const STRLEN* %s = %d;", $sym, $iv ) );
        $isint = 1;
    }
    else {                           # sizeof(STRLEN) + (WARNsize)
                                     # FIXME: should not we use the strlen_flags helper for length and cstring ?
        my $packedpv = pack( "$t a*", length($pv), $pv );
        decl()->add( sprintf( "Static const char %s[] = %s;", $sym, cstring($packedpv) ) );
    }

    # set cache
    $lexwarnsym{$pv} = [ $sym, $isint ];

    return ( $sym, $isint );
}

1;
