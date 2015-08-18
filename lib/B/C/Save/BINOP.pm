package B::BINOP;

use B::C::File qw/binopsect/;

sub save {
    my ( $op, $level ) = @_;
    
    my $sym = B::objsym($op);
    return $sym if defined $sym;

    binopsect->comment("$opsect_common, first, last");
    binopsect->add(
        sprintf(
            "%s, s\\_%x, s\\_%x",
            $op->_save_common,
            ${ $op->first },
            ${ $op->last }
        )
    );
    binopsect->debug( $op->name, $op->flagspv );
    my $ix = binopsect->index;
    init->add( sprintf( "binop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = B::C::savesym( $op, "(OP*)&binop_list[$ix]" );
    B::C::do_labels( $op, 'first', 'last' );
    $sym;
}

1;