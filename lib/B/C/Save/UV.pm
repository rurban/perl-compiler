package B::UV;

use strict;

use Config;

use B::C::File qw/xpvuvsect svsect/;
use B::C::Helpers qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    my $uvuformat = $Config{uvuformat};
    $uvuformat =~ s/"//g;    #" poor editor

    # issue 145 warn $sv->UVX, " ", sprintf("%Lu", $sv->UVX);
    xpvuvsect()->add( sprintf( "Nullhv, {0}, 0, 0, {%" . $uvuformat . "U}", $sv->UVX ) );

    svsect()->add(
        sprintf(
            "&xpvuv_list[%d], %lu, 0x%x" . ', {' . ( $B::C::C99 ? ".svu_pv=" : "" ) . 'NULL}',
            xpvuvsect()->index, $sv->REFCNT, $sv->FLAGS
        )
    );
    svsect()->debug( $fullname, $sv );
    warn sprintf(
        "Saving IV(UV) 0x%x to xpvuv_list[%d], sv_list[%d], called from %s:%s\n",
        $sv->UVX, xpvuvsect()->index, svsect()->index, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(0) )[2] ] }
    ) if $B::C::debug{sv};
    savesym( $sv, sprintf( "&sv_list[%d]", svsect()->index ) );
}

1;
