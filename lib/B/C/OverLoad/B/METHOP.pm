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
    my $rclass = USE_ITHREADS()        ? $op->rclass      : $op->rclass->save;
    my $first  = $op->name eq 'method' ? $op->first->save : $op->meth_sv->save;
    methopsect()->add( sprintf( $s, $op->_save_common, $first, $rclass ) );
    methopsect()->debug( $op->name, $op->flagspv ) if debug('flags');
    my $ix = methopsect()->index;
    if ( $first =~ /^&sv_list/ ) {
        init()->add( sprintf( "SvREFCNT_inc(%s); /* methop_list[%d].op_meth_sv */", $first, $ix ) );
    }
    if ( $rclass =~ /^&sv_list/ ) {
        init()->add( sprintf( "SvREFCNT_inc(%s); /* methop_list[%d].op_rclass_sv */", $rclass, $ix ) );
    }

    my $ix = methopsect()->index;
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
