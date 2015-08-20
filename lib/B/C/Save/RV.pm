package B::RV;

use strict;

use B::C::File qw/svsect init/;
use B::C::Helpers qw/save_rv/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# Since 5.11 also called by IV::save (SV -> IV)
sub B::RV::save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;
    warn sprintf(
        "Saving RV %s (0x%x) - called from %s:%s\n",
        class($sv), $$sv, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(1) )[2] ] }
    ) if $B::C::debug{sv};

    my $rv = save_rv( $sv, $fullname );
    return '0' unless $rv;

    # 5.10 has no struct xrv anymore, just sv_u.svu_rv. static or dynamic?
    # initializer element is computable at load time
    svsect()->add( sprintf( "ptr_undef, %lu, 0x%x, {0}", $sv->REFCNT, $sv->FLAGS ) );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    init()->add("$s.sv_u.svu_rv = (SV*)$rv;");

    return savesym( $sv, "&" . $s );
}

1;
