package B::PVNV;

use strict;

use B qw/SVf_NOK SVp_NOK/;
use B::C::Config;
use B::C::Save qw/savepvn/;
use B::C::Decimal qw/get_integer_value get_double_value/;
use B::C::File qw/xpvnvsect svsect init/;
use B::C::Helpers::Symtable qw/savesym objsym/;

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
    my $nvx;
    my $ivx = get_integer_value( $sv->IVX );    # here must be IVX!
    if ( $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {

        # it could be a double, or it could be 2 ints - union xpad_cop_seq
        $nvx = get_double_value( $sv->NV );
    }
    else {
        if ( C99() ) {
            $nvx = sprintf(
                ".xpad_cop_seq.xlow = %s, .xpad_cop_seq.xhigh = %s",
                get_integer_value( $sv->COP_SEQ_RANGE_LOW ), get_integer_value( $sv->COP_SEQ_RANGE_HIGH ),
            );
        }
        else {
            $nvx = get_double_value( $sv->NVX );
        }
    }

    # For some time the stringification works of NVX double to two ints worked ok.
    xpvnvsect()->comment('STASH, MAGIC, cur, len, IVX, NVX');
    xpvnvsect()->add( sprintf( "Nullhv, {0}, %u, {%u}, {%s}, {%s}", $cur, $len, $ivx, $nvx ) );

    unless ( C99() or $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {
        debug( sv => "NV => run-time union xpad_cop_seq init" );
        init()->add(
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xlow = %s;",
                xpvnvsect()->index, get_integer_value( $sv->COP_SEQ_RANGE_LOW )
            ),

            # pad.c: PAD_MAX = I32_MAX (4294967295)
            # U suffix <= "warning: this decimal constant is unsigned only in ISO C90"
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xhigh = %s;",
                xpvnvsect()->index, get_integer_value( $sv->COP_SEQ_RANGE_HIGH )
            )
        );
    }

    svsect()->add(
        sprintf(
            "&xpvnv_list[%d], %lu, 0x%x %s",
            xpvnvsect()->index, $sv->REFCNT, $sv->FLAGS,
            ", {" . ( C99() ? ".svu_pv=" : "" ) . "(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( defined($pv) ) {
        if ( !$static ) {
            init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
        }
    }
    return savesym( $sv, "&" . $s );
}

1;
