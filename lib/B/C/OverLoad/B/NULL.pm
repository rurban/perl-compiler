package B::NULL;

use strict;
use B::C::Config;
use B::C::File qw/svsect init/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;

    # debug
    if ( $$sv == 0 ) {
        verbose("NULL::save for sv = 0 called from @{[(caller(1))[3]]}");
        return savesym( $sv, "(void*)Nullsv" );
    }

    my $i = svsect()->index + 1;
    debug( sv => "Saving SVt_NULL sv_list[$i]" );
    svsect()->add( sprintf( "NULL, %Lu, 0x%x, {0}", $sv->REFCNT, $sv->FLAGS ) );

    #svsect()->debug( $fullname, $sv ); # XXX where is this possible?
    if ( debug('flags') and DEBUG_LEAKING_SCALARS() ) {    # add index to sv_debug_file to easily find the Nullsv
                                                           # svsect()->debug( "ix added to sv_debug_file" );
        init()->add( sprintf( 'sv_list[%d].sv_debug_file = savesharedpv("NULL sv_list[%d] 0x%x");', svsect()->index, svsect()->index, $sv->FLAGS ) );
    }

    return savesym( $sv, sprintf( "&sv_list[%d]", svsect()->index ) );
}

1;
