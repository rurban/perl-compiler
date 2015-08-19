package B::PV;

use strict;

use B qw/SVf_ROK SVf_READONLY cstring/;
use B::C::File qw/xpvsect svsect init/;
use B::C::Helpers qw/savesym objsym/;

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
    my $flags = $sv->FLAGS;
    my $shared_hek = ( ( $flags & 0x09000000 ) == 0x09000000 );
    $shared_hek = $shared_hek ? 1 : B::C::IsCOW_hek($sv);
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );
    $static = 0 if !( $flags & SVf_ROK ) and $sv->PV and $sv->PV =~ /::bootstrap$/;
    my $refcnt = $sv->REFCNT;

    # static pv, do not destruct. test 13 with pv0 "3".

    if ( $B::C::const_strings and !$shared_hek and $flags & SVf_READONLY and !$len ) {
        $flags &= ~0x01000000;
        warn sprintf( "constpv turn off SVf_FAKE %s %s %s\n", $sym, cstring($pv), $fullname )
          if $B::C::debug{pv};
    }
    xpvsect()->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], %lu, 0x%x, {%s}",
            xpvsect()->index, $refcnt, $flags,
            $savesym eq 'NULL'
            ? '0'
            : ( $B::C::C99 ? ".svu_pv=(char*)" : "(char*)" ) . $savesym
        )
    );
    if ( defined($pv) and !$static ) {
        if ($shared_hek) {
            my $hek = B::C::save_hek($pv);
            init()->add( sprintf( "sv_list[%d].sv_u.svu_pv = HEK_KEY(%s);", svsect()->index, $hek ) )
              unless $hek eq 'NULL';
        }
        else {
            init()->add( B::C::savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", svsect()->index ), $pv, $sv, $cur ) );
        }
    }
    if ( $B::C::debug{flags} and $B::C::DEBUG_LEAKING_SCALARS ) {    # add sv_debug_file
        init()->add(
            sprintf(
                qq(sv_list[%d].sv_debug_file = %s" sv_list[%d] 0x%x";),
                svsect()->index, cstring($pv) eq '0' ? '"NULL"' : cstring($pv),
                svsect()->index, $sv->FLAGS
            )
        );
    }

    my $s = "sv_list[" . svsect()->index . "]";
    svsect()->debug( $fullname, $sv );

    return savesym( $sv, "&" . $s );
}

1;
