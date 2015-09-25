package B::METHOP;

use strict;

use B qw/cstring SVf_FAKE/;
use B::C::File qw( methopsect init );
use B::C::Config;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Helpers qw/do_labels/;

sub B::METHOP::save {
    my ( $op, $level ) = @_;
    my $sym = objsym($op);
    return $sym if defined $sym;

    methopsect()->comment_common("first, rclass");
    my $union = $op->name eq 'method' ? "{.op_first=(OP*)s\\_%x}" : "{.op_meth_sv=(SV*)s\\_%x}";
    $union = "s\\_%x" unless C99();
    my $s = "%s, $union, " . ( USE_ITHREADS() ? "(PADOFFSET)%u" : "(SV*)%u" );
    methopsect()->add(
        sprintf(
            $s, $op->_save_common,
            $op->name eq 'method' ? ${ $op->first } : ${ $op->meth_sv },
            $op->rclass
        )
    );

    # $methopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
    my $ix = methopsect()->index;
    init()->add( sprintf( "methop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&methop_list[$ix]" );
    if ( $op->name eq 'method' ) {
        do_labels( $op, 'first', 'rclass' );
    }
    else {
        do_labels( $op, 'meth_sv', 'rclass' );
    }

    return $sym;
}

1;
