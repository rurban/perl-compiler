package B::LISTOP;

use strict;

use B qw/cstring/;

use B::C::File qw/init listopsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Helpers qw/do_labels/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;
    listopsect()->comment_common("first, last");
    listopsect()->add(
        sprintf(
            "%s, s\\_%x, s\\_%x",
            $op->_save_common,
            ${ $op->first },
            ${ $op->last }
        )
    );
    listopsect()->debug( $op->name, $op );
    my $ix = listopsect()->index;
    init()->add( sprintf( "listop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&listop_list[$ix]" );

    if ( $op->type == $B::C::OP_DBMOPEN ) {

        # resolves it at compile-time, not at run-time
        B::C::mark_package('AnyDBM_File');    # to save $INC{AnyDBM_File}
        require AnyDBM_File unless $B::C::savINC{'AnyDBM_File.pm'};
        $B::C::curINC{'AnyDBM_File.pm'} = $INC{'AnyDBM_File.pm'};
        AnyDBM_File->import;                  # strip the @ISA
        my $dbm = $AnyDBM_File::ISA[0];       # take the winner (only)
        svref_2object( \&{"$dbm\::bootstrap"} )->save;
        svref_2object( \&{"$dbm\::TIEHASH"} )->save;    # called by pp_dbmopen
        B::C::add_to_currINC( "$dbm.pm" => $INC{"$dbm.pm"} );
    }
    elsif ( $op->type == $B::C::OP_FORMLINE and $B::C::const_strings ) {    # -O3 ~
                                                                            # non-static only for all const strings containing ~ #277
        my $sv;
        my $fop  = $op;
        my $svop = $op->first;
        while ( $svop != $op and ref($svop) ne 'B::NULL' ) {
            if ( $svop->name == 'const' and $svop->can('sv') ) {
                $sv = $svop->sv;
            }
            if ( $sv and $sv->can("PV") and $sv->PV =~ /~/m ) {
                local $B::C::const_strings;
                warn "force non-static formline arg ", cstring( $sv->PV ), "\n" if $B::C::debug{pv};
                $svop->save("svop const");
            }
            $svop = $svop->next;
        }
    }
    do_labels( $op, 'first', 'last' );
    $sym;
}

1;
