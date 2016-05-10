package B::UV;

use strict;

use B::C::Flags ();

use B::C::Config;
use B::C::File qw/xpvuvsect svsect init/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Decimal qw/u32fmt/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    my $uvuformat = $B::C::Flags::Config{uvuformat};
    $uvuformat =~ s/"//g;    #" poor editor

    xpvuvsect()->comment("stash, magic, cur, len, xiv_u");

    my $uvx  = $sv->UVX;
    my $suff = 'U';
    $suff .= 'L' if $uvx > 2147483647;

    my $i = svsect()->index + 1;

    # since 5.24 we need to point the xpvuv to the head
    my $u32fmt = u32fmt();
    svsect()->add(
        sprintf(
            "NULL, $u32fmt, 0x%x, {.svu_uv=${uvx}${suff}}",
            $sv->REFCNT, $sv->FLAGS
        )
    );

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
        sv => "Saving IV(UV) 0x%x to xpvuv_list[%d], sv_list[%d], called from %s:%s\n",
        $sv->UVX, xpvuvsect()->index, $i, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(0) )[2] ] }
    );
    savesym( $sv, sprintf( "&sv_list[%d]", $i ) );
}

1;
