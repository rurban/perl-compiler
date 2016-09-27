package B::PVIV;

use strict;
use B::C::Config;
use B::C::Save qw/savepvn/;
use B::C::File qw/xpvivsect svsect init/;
use B::C::Decimal qw/get_integer_value/;
use B::C::Helpers::Symtable qw/objsym savesym/;

use B qw{SVf_IOK SVf_ROK SVf_POK SVp_POK SVp_IOK SVf_IsCOW};

sub SVt_MASK {
    return 0xf;    # smallest bitmask that covers all types
}

sub is_simple_pviv {
    my $sv = shift;

    my $flags = $sv->FLAGS;

    # remove insignificant flags for us as a PVIV
    $flags &= ~SVf_IsCOW if $flags & SVp_POK;
    $flags &= ~SVf_IOK;
    $flags &= ~SVf_POK;
    $flags &= ~SVp_IOK;
    $flags &= ~SVp_POK;

    # remove the type
    $flags &= ~SVt_MASK();

    return $flags == 0;
}

# we need to keep them in memory to do not reuse the same memory location
my @EXTRA;

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

    my $iok = $sv->FLAGS & SVf_IOK;
    my $pok = $sv->FLAGS & SVf_POK;

    # idea unit tests...
    # do not downgrade it if it has some weird magic
    #debug( pv => "###### $fullname, $sv, POK $pok IOK $iok: IV %d PV %s", $sv->IVX || 0, $sv->PV . "");
    if ( is_simple_pviv($sv) ) {
        if (  !$pok && $iok
            or $iok && $sv->PV =~ qr{^[0-9]+$}
            or $pok && !$iok && $sv->PV eq ( $sv->IVX || 0 ) ) {    # PVIV used as IV let's downgrade it as an IV
            push @EXTRA, int get_integer_value( $sv->IVX );
            my $sviv = B::svref_2object( \$EXTRA[-1] );
            return B::IV::save( $sviv, $fullname );
        }
        elsif ( $pok && $sv->PV =~ qr{^[0-9]+$} && length( $sv->PV ) <= 18 ) {    # use Config{...}

            # downgrade a PV that looks like an IV (and not too long) to a simple IV
            push @EXTRA, int( "" . $sv->PV );
            my $sviv = B::svref_2object( \$EXTRA[-1] );
            return B::IV::save( $sviv, $fullname );
        }
        elsif ($pok) {                                                            # maybe do not downgrade it to PV if the string is only 0-9 ??
                                                                                  # downgrade the PVIV as a regular PV
            push @EXTRA, "" . $sv->PV;
            my $svpv = B::svref_2object( \$EXTRA[-1] );
            return B::PV::save( $svpv, $fullname );
        }
    }

    # save the PVIV

    my ( $savesym, $cur, $len, $pv, $static, $flags ) = B::PV::save_pv_or_rv( $sv, $fullname );

    xpvivsect()->comment('STASH, MAGIC, cur, len, IVX');
    xpvivsect()->add(
        sprintf(
            "Nullhv, {0}, %u, {%u}, {%s}",
            $cur, $len, get_integer_value( $sv->IVX )
        )
    );    # IVTYPE long

    # save the pv
    svsect()->add(
        sprintf(
            "&xpviv_list[%d], %u, 0x%x, {.svu_pv=(char*) %s}",
            xpvivsect()->index, $sv->REFCNT, $flags, $savesym
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    return savesym( $sv, "&" . $s );
}

1;
