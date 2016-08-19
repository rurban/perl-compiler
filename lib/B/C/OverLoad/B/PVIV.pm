package B::PVIV;

use strict;
use B::C::Config;
use B::C::Save qw/savepvn/;
use B::C::File qw/xpvivsect svsect init/;
use B::C::Decimal qw/get_integer_value/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);

    if ( defined $sym ) {
        if ($B::C::in_endav) {
            debug( av => "in_endav: static_free without $sym" );
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );

    xpvivsect()->comment('STASH, MAGIC, cur, len, IVX');
    xpvivsect()->add(
        sprintf(
            "Nullhv, {0}, %u, {%u}, {%s}",
            $cur, $len, get_integer_value( $sv->IVX )
        )
    );    # IVTYPE long

    svsect()->add(
        sprintf(
            "&xpviv_list[%d], %u, 0x%x %s",
            xpvivsect()->index, $sv->REFCNT, $sv->FLAGS,
            ", {.svu_pv=(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( defined($pv) ) {

        if ( !$static ) {
            init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
        }
    }
    savesym( $sv, "&" . $s );
}

1;
