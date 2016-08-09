package B::METHOP;

use strict;

use B qw/cstring SVf_FAKE/;
use B::C::File qw( methopsect init );
use B::C::Config;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Helpers qw/do_labels/;

sub save {
    my ( $op, $level ) = @_;
    my $sym = objsym($op);
    return $sym if defined $sym;

    $level ||= 0;

    methopsect()->comment_common("first, rclass");

    my $union = $op->name eq 'method' ? "{.op_first=(OP*)%s}" : "{.op_meth_sv=(SV*)%s}";
    my $s = "%s, $union, " . ( USE_ITHREADS() ? "(PADOFFSET)%s" : "(SV*)%s" );    # rclass

    my $ix = methopsect()->index + 1;
    my $rclass = USE_ITHREADS() ? $op->rclass : $op->rclass->save("op_rclass_sv");
    if ( $rclass =~ /^&sv_list/ ) {
        init()->add( sprintf( "SvREFCNT_inc_simple_NN(%s); /* methop_list[%d].op_rclass_sv */", $rclass, $ix ) );

        # Put this simple PV into the PL_stashcache, it has no STASH,
        # and initialize the method cache.
        # TODO: backref magic for next, init the next::method cache
        init()->add( sprintf( "Perl_mro_method_changed_in(aTHX_ gv_stashsv(%s, GV_ADD));", $rclass ) );
    }
    my $first = $op->name eq 'method' ? $op->first->save : $op->meth_sv->save;
    if ( $first =~ /^&sv_list/ ) {
        init()->add( sprintf( "SvREFCNT_inc_simple_NN(%s); /* methop_list[%d].op_meth_sv */", $first, $ix ) );
    }
    $first = 'NULL' if !C99() and $first eq 'Nullsv';
    methopsect()->add( sprintf( $s, $op->_save_common, $first, $rclass ) );
    methopsect()->debug( $op->name, $op->flagspv ) if debug('flags');
    init()->add( sprintf( "methop_list[%d].op_ppaddr = %s;", $ix, $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&methop_list[$ix]" );
    if ( $op->name eq 'method' ) {
        do_labels( $op, $level + 1, 'first', 'rclass' );
    }
    else {
        do_labels( $op, $level + 1, 'meth_sv', 'rclass' );
    }

    return $sym;
}

1;
