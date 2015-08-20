package B::PVNV;

use strict;

use B qw/SVf_NOK SVp_NOK/;
use B::C::File qw/xpvnvsect svsect init/;
use B::C::Helpers::Symtable qw/savesym objsym/;

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
    my $nvx;
    my $ivx = B::C::ivx( $sv->IVX );    # here must be IVX!
    if ( $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {

        # it could be a double, or it could be 2 ints - union xpad_cop_seq
        $nvx = B::C::nvx( $sv->NV );
    }
    else {
        if ($B::C::C99) {
            $nvx = sprintf(
                ".xpad_cop_seq.xlow = %s, .xpad_cop_seq.xhigh = %s",
                B::C::ivx( $sv->COP_SEQ_RANGE_LOW ), B::C::ivx( $sv->COP_SEQ_RANGE_HIGH ),
            );
        }
        else {
            $nvx = B::C::nvx( $sv->NVX );
        }
    }

    # For some time the stringification works of NVX double to two ints worked ok.
    xpvnvsect()->comment('STASH, MAGIC, cur, len, IVX, NVX');
    xpvnvsect()->add( sprintf( "Nullhv, {0}, %u, %u, {%s}, {%s}", $cur, $len, $ivx, $nvx ) );

    unless ( $B::C::C99 or $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {
        warn "NV => run-time union xpad_cop_seq init\n" if $B::C::debug{sv};
        init()->add(
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xlow = %s;",
                xpvnvsect()->index, B::C::ivx( $sv->COP_SEQ_RANGE_LOW )
            ),

            # pad.c: PAD_MAX = I32_MAX (4294967295)
            # U suffix <= "warning: this decimal constant is unsigned only in ISO C90"
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xhigh = %s;",
                xpvnvsect()->index, B::C::ivx( $sv->COP_SEQ_RANGE_HIGH )
            )
        );
    }

    svsect()->add(
        sprintf(
            "&xpvnv_list[%d], %lu, 0x%x %s",
            xpvnvsect()->index, $sv->REFCNT, $sv->FLAGS,
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
    return savesym( $sv, "&" . $s );
}

1;
