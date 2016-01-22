package B::REGEXP;

use strict;

use B qw/cstring RXf_EVAL_SEEN/;
use B::C::Setup;
use B::C::File qw/init svsect xpvsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# post 5.11: When called from B::RV::save_op not from PMOP::save precomp
sub save {
    my ( $sv, $fullname ) = @_;

    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv  = $sv->PV;
    my $cur = $sv->CUR;

    # construct original PV
    $pv =~ s/^(\(\?\^[adluimsx-]*\:)(.*)\)$/$2/;
    $cur -= length( $sv->PV ) - length($pv);
    my $cstr = cstring($pv);

    # Unfortunately this XPV is needed temp. Later replaced by struct regexp.
    xpvsect()->add( sprintf( "Nullhv, {0}, %u, {%u}", $cur, 0 ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], %Lu, 0x%x, {NULL}",
            xpvsect()->index, $sv->REFCNT, $sv->FLAGS
        )
    );
    my $ix = svsect()->index;
    debug( rx => "Saving RX $cstr to sv_list[$ix]" );

    if ( $sv->EXTFLAGS & RXf_EVAL_SEEN ) {
        init()->add("PL_hints |= HINT_RE_EVAL;");
    }

    # replace sv_any->XPV with struct regexp. need pv and extflags
    init()->add( sprintf( 'SvANY(&sv_list[%d]) = SvANY(CALLREGCOMP(newSVpvn(%s, %d), 0x%x));', $ix, $cstr, $cur, $sv->EXTFLAGS ) );
    if ( $sv->EXTFLAGS & RXf_EVAL_SEEN ) {
        init()->add("PL_hints &= ~HINT_RE_EVAL;");
    }

    init()->add("sv_list[$ix].sv_u.svu_rx = (struct regexp*)sv_list[$ix].sv_any;");

    svsect()->debug( $fullname, $sv );
    $sym = savesym( $sv, sprintf( "&sv_list[%d]", $ix ) );
    $sv->save_magic($fullname);
    return $sym;
}

1;
