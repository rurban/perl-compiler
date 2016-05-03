package B::UV;

use strict;

use B::C::Flags ();

use B::C::Config;
use B::C::File qw/xpvuvsect svsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    my $uvuformat = $B::C::Flags::Config{uvuformat};
    $uvuformat =~ s/"//g;    #" poor editor

    xpvuvsect()->comment("stash, magic, cur, len, xiv_u");

    my $uvx = $sv->UVX;
    # issue 145 warn $sv->UVX, " ", sprintf("%Lu", $sv->UVX);
    xpvuvsect()->add( sprintf( "Nullhv, {0}, 0, 0, {%" . $uvuformat . "%s}", $uvx, 'LLU' ) );

    svsect()->add(
        sprintf(
            "&xpvuv_list[%d], %Lu, 0x%x" . ', {' . ( C99() ? ".svu_pv=" : "" ) . $uvx . '}',
            xpvuvsect()->index, $sv->REFCNT, $sv->FLAGS
        )
    );
    svsect()->debug( $fullname, $sv );
    debug(
        sv => "Saving IV(UV) 0x%x to xpvuv_list[%d], sv_list[%d], called from %s:%s\n",
        $sv->UVX, xpvuvsect()->index, svsect()->index, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(0) )[2] ] }
    );
    savesym( $sv, sprintf( "&sv_list[%d]", svsect()->index ) );
}

1;
