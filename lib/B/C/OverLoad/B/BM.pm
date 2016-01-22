package B::BM;

use strict;

use B qw/cstring/;
use B::C::Setup;
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

    debug( gv => "Saving FBM for GV $sym" );
    init()->add(
        sprintf( "%s = (GV*)newSV_type(SVt_PVGV);", $sym ),
        sprintf( "SvFLAGS(%s) = 0x%x;",  $sym, $sv->FLAGS ),
        sprintf( "SvREFCNT(%s) = %u;",   $sym, $sv->REFCNT + 1 ),
        sprintf( "SvPVX(%s) = %s;",      $sym, cstring($pv) ),
        sprintf( "SvCUR_set(%s, %d);",   $sym, $cur ),
        sprintf( "SvLEN_set(%s, %d);",   $sym, $len ),
        sprintf( "BmRARE(%s) = %d;",     $sym, $sv->RARE ),
        sprintf( "BmPREVIOUS(%s) = %d;", $sym, $sv->PREVIOUS ),
        sprintf( "BmUSEFUL(%s) = %d;",   $sym, $sv->USEFUL )
    );

    # Restore possible additional magic. fbm_compile adds just 'B'.
    $sv->save_magic($fullname);

    return $sym;
}

1;
