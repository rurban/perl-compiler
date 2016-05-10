package B::IV;

use strict;

use B qw/SVf_ROK SVf_IOK SVp_IOK SVf_IVisUV/;
use B::C::Config;
use B::C::File qw/init svsect xpvivsect/;
use B::C::Decimal qw/get_integer_value/;
use B::C::Helpers::Symtable qw/objsym savesym/;

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
        return $sv->B::UV::save($fullname);
    }
    my $ivx = get_integer_value( $sv->IVX );
    my $i   = svsect()->index + 1;
    if ( $svflags & 0xff and !( $svflags & ( SVf_IOK | SVp_IOK ) ) ) {    # Not nullified
        unless (
            ( $svflags & 0x00010000 )                                     # PADSTALE - out of scope lexical is !IOK
            or ( $svflags & 0x60002 )
          ) {
            warn sprintf( "Internal warning: IV !IOK $fullname sv_list[$i] 0x%x\n", $svflags );
        }
    }

    svsect()->add( sprintf( "NULL, %lu, 0x%x, {.svu_iv=%s}", $sv->REFCNT, $svflags, $ivx ) );

    #32bit  - sizeof(void*), 64bit: - 2*ptrsize
    if ( $B::C::Flags::Config{ptrsize} == 4 ) {
        init()->add( sprintf( "sv_list[%d].sv_any = (void*)&sv_list[%d] - sizeof(void*);", $i, $i ) );
    }
    else {
        init()->add(
            sprintf(
                "sv_list[%d].sv_any = (char*)&sv_list[%d] - %d;", $i, $i,
                2 * $B::C::Flags::Config{ptrsize}
            )
        );
    }

    svsect()->debug( $fullname, $sv );
    debug(
        sv => "Saving IV 0x%x to xpviv_list[%d], sv_list[%d], called from %s:%s\n",
        $sv->IVX, xpvivsect()->index, $i, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(0) )[2] ] }
    );
    savesym( $sv, sprintf( "&sv_list[%d]", $i ) );
}

1;
