package B::BM;

use strict;

use B qw/cstring/;
use B::C::File qw/init/;
use B::C::Helpers::Symtable qw/savesym objsym/;

sub save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);

    $sv = bless $sv, "B::BM";
    my $pv  = pack "a*", ( $sv->PV . "\0" . $sv->TABLE );
    my $cur = $sv->CUR;
    my $len = $cur + length( $sv->TABLE ) + 1;
    my $s;

    warn "Saving FBM for GV $sym\n" if $B::C::debug{gv};
    init()->add(
        sprintf("$sym = (GV*)newSV_type(SVt_PVGV);"),
        sprintf( "SvFLAGS($sym) = 0x%x;",  $sv->FLAGS ),
        sprintf( "SvREFCNT($sym) = %u;",   $sv->REFCNT + 1 ),
        sprintf( "SvPVX($sym) = %s;",      cstring($pv) ),
        sprintf( "SvCUR_set($sym, %d);",   $cur ),
        sprintf( "SvLEN_set($sym, %d);",   $len ),
        sprintf( "BmRARE($sym) = %d;",     $sv->RARE ),
        sprintf( "BmPREVIOUS($sym) = %d;", $sv->PREVIOUS ),
        sprintf( "BmUSEFUL($sym) = %d;",   $sv->USEFUL )
    );

    # Restore possible additional magic. fbm_compile adds just 'B'.
    $sv->save_magic($fullname);

    return $sym;
}

1;
