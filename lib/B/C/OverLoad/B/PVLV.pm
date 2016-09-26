package B::PVLV;

use strict;

use B q/cchar/;

use B::C::Config;
use B::C::Save qw/savepvn/;
use B::C::File qw/xpvlvsect svsect init/;
use B::C::Decimal qw/ get_double_value/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# Warning not covered by the (cpanel)core test suite...
# FIXME... add some test coverage for PVLV

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

    my ( $pvsym, $cur, $len, $pv, $static, $flags ) = B::PV::save_pv_or_rv( $sv, $fullname );
    my ( $lvtarg, $lvtarg_sym );    # XXX missing

    xpvlvsect()->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    xpvlvsect()->add(
        sprintf(
            "Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %s, %u, %u, Nullsv, %s",
            $cur,         $len,         get_double_value( $sv->NVX ),
            $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE )
        )
    );
    svsect()->add(
        sprintf(
            "&xpvlv_list[%d], %Lu, 0x%x, {(char*)%s}",
            xpvlvsect()->index, $sv->REFCNT, $flags, $pvsym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    $sv->save_magic($fullname);

    return savesym( $sv, "&" . $s );
}

1;
