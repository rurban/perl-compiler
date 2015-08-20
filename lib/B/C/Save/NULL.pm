package B::NULL;

use strict;

use B::C::File qw/svsect init/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    # debug
    if ( $$sv == 0 ) {
        warn "NULL::save for sv = 0 called from @{[(caller(1))[3]]}\n" if B::C::verbose();
        return savesym( $sv, "(void*)Nullsv /* XXX */" );
    }

    my $i = svsect()->index + 1;
    warn "Saving SVt_NULL sv_list[$i]\n" if $B::C::debug{sv};
    svsect()->add( sprintf( "0, %lu, 0x%x, {0}", $sv->REFCNT, $sv->FLAGS ) );

    #svsect()->debug( $fullname, $sv ); # XXX where is this possible?
    if ( $B::C::debug{flags} and $B::C::DEBUG_LEAKING_SCALARS ) {    # add index to sv_debug_file to easily find the Nullsv
                                                                     # svsect()->debug( "ix added to sv_debug_file" );
        init()->add(
            sprintf(
                qq(sv_list[%d].sv_debug_file = savepv("NULL sv_list[%d] 0x%x");),
                svsect()->index, svsect()->index, $sv->FLAGS
            )
        );
    }
    savesym( $sv, sprintf( "&sv_list[%d]", svsect()->index ) );
}

1;
