package B::PVIV;

use strict;

#use B::C ();
use B::C::File qw/xpvivsect svsect init/;
use B::C::Helpers qw/objsym savesym/;

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
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );

    xpvivsect()->comment('STASH, MAGIC, cur, len, IVX');
    xpvivsect()->add( sprintf( "Nullhv, {0}, %u, %u, {%s}", $cur, $len, B::C::ivx( $sv->IVX ) ) );    # IVTYPE long

    svsect()->add(
        sprintf(
            "&xpviv_list[%d], %u, 0x%x %s",
            xpvivsect()->index, $sv->REFCNT, $sv->FLAGS,
            ", {" . ( $B::C::C99 ? ".svu_pv=" : "" ) . "(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( defined($pv) ) {

        if ( !$static ) {
            init()->add( B::C::savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
        }
    }
    savesym( $sv, "&" . $s );
}

1;
