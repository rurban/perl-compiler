package B::IV;

use B qw/SVf_ROK SVf_IOK SVp_IOK SVf_IVisUV/;
use B::C ();
use B::C::File qw/svsect xpvivsect/;
use B::C::Helpers qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    # Since 5.11 the RV is no special SV object anymore, just a IV (test 16)
    my $svflags = $sv->FLAGS;
    if ( $svflags & SVf_ROK ) {
        return $sv->B::RV::save($fullname);
    }
    if ( $svflags & SVf_IVisUV ) {
        return $sv->B::UV::save;
    }
    my $ivx = B::C::ivx( $sv->IVX );
    my $i   = svsect()->index + 1;
    if ( $svflags & 0xff and !( $svflags & ( SVf_IOK | SVp_IOK ) ) ) {    # Not nullified
        unless ( $svflags & 0x00010000 ) {                                # PADSTALE - out of scope lexical is !IOK
            warn sprintf( "Internal warning: IV !IOK $fullname sv_list[$i] 0x%x\n", $svflags );
        }
    }

    xpvivsect()->add( sprintf( "Nullhv, {0}, 0, 0, {%s}", $ivx ) );

    svsect()->add(
        sprintf(
            "&xpviv_list[%d], %lu, 0x%x" . ', {' . ( $B::C::C99 ? ".svu_pv=" : "" ) . 'NULL}',
            xpvivsect()->index, $sv->REFCNT, $svflags
        )
    );
    svsect()->debug( $fullname, $sv );
    warn sprintf(
        "Saving IV 0x%x to xpviv_list[%d], sv_list[%d], called from %s:%s\n",
        $sv->IVX, xpvivsect()->index, svsect()->index, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(0) )[2] ] }
    ) if $B::C::debug{sv};
    savesym( $sv, sprintf( "&sv_list[%d]", svsect()->index ) );
}

1;
