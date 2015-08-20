package B::PVLV;

use strict;

use B q/cchar/;

use B::C::File qw/xpvlvsect svsect init/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# Warning not covered by the (cpanel)core test suite...
# FIXME... add some test coverage for PVLV

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($B::C::in_endav) {
            warn "in_endav: static_free without $sym\n" if $B::C::debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $pvsym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );
    my ( $lvtarg, $lvtarg_sym );    # XXX missing

    xpvlvsect()->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    xpvlvsect()->add(
        sprintf(
            "Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %s, %u, %u, Nullsv, %s",
            $cur,         $len,         B::C::nvx( $sv->NVX ),
            $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE )
        )
    );
    svsect()->add(
        sprintf(
            "&xpvlv_list[%d], %lu, 0x%x, {(char*)%s}",
            xpvlvsect()->index, $sv->REFCNT, $sv->FLAGS, $pvsym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( !$static ) {

        init()->add( B::C::savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    $sv->save_magic($fullname);

    return savesym( $sv, "&" . $s );
}

1;
