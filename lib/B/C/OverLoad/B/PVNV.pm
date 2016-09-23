package B::PVNV;

use strict;

use B qw/SVf_NOK SVp_NOK SVs_OBJECT/;
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
    my ( $savesym, $cur, $len, $pv, $static, $flags ) = B::PV::save_pv_or_rv( $sv, $fullname );
    my $nvx = '0.0';
    my $ivx = get_integer_value( $sv->IVX );    # here must be IVX!
    if ( $flags & ( SVf_NOK | SVp_NOK ) ) {

        # it could be a double, or it could be 2 ints - union xpad_cop_seq
        $nvx = get_double_value( $sv->NV );
    }

    # For some time the stringification works of NVX double to two ints worked ok.
    xpvnvsect()->comment('STASH, MAGIC, cur, len, IVX, NVX');
    xpvnvsect()->add( sprintf( "Nullhv, {0}, %u, {%u}, {%s}, {%s}", $cur, $len, $ivx, $nvx ) );

    svsect()->add(
        sprintf(
            "&xpvnv_list[%d], %Lu, 0x%x %s",
            xpvnvsect()->index, $sv->REFCNT, $flags,
            ", {.svu_pv=(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";

    push @B::C::static_free, "&" . $s if $flags & SVs_OBJECT;
    return savesym( $sv, "&" . $s );
}

1;