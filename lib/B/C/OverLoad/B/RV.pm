package B::RV;

use strict;

use B::C::Config;
use B::C::File qw/svsect init/;
use B::C::Helpers qw/is_constant/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# Since 5.11 also called by IV::save (SV -> IV)
sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;
    debug(
        sv => "Saving RV %s (0x%x) - called from %s:%s\n",
        ref($sv), $$sv, @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(1) )[2] ] }
    );

    my $rv = save_op( $sv, $fullname );
    return '0' unless $rv;

    svsect()->comment("any, refcnt, flags, sv_u");

    # 5.22 has a wrong RV->FLAGS (https://github.com/perl11/cperl/issues/63)
    my $flags = $sv->FLAGS;
    $flags = 0x801 if $flags & 9;    # not a GV but a ROK IV (21)

    # 5.10 has no struct xrv anymore, just sv_u.svu_rv. static or dynamic?
    # initializer element is computable at load time
    svsect()->add(
        sprintf(
            "ptr_undef, %Lu, 0x%x, {%s}", $sv->REFCNT, $flags,
            ( is_constant($rv) ? ".svu_rv=$rv" : "0 /* $rv */" )
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";

    init()->add( sprintf( "%s.sv_any = (void*)&%s - sizeof(void*);", $s, $s ) );              # 354 defined needs SvANY
    init()->add( sprintf( "%s.sv_u.svu_rv = (SV*)%s;", $s, $rv ) ) unless is_constant($rv);

    return savesym( $sv, "&" . $s );
}

# the save methods should probably be renamed visit
sub save_op {
    my ( $sv, $fullname ) = @_;

    $fullname ||= '(unknown)';

    my $rv = $sv->RV->save($fullname);
    $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

    return $rv;
}

1;
