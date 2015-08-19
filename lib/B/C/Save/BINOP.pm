package B::BINOP;

use B::C ();
use B::C::File qw/binopsect init/;
use B::C::Helpers qw/savesym do_labels/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = B::objsym($op);
    return $sym if defined $sym;

    binopsect->comment_common("first, last");
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
    $sym = savesym( $op, "(OP*)&binop_list[$ix]" );
    do_labels( $op, 'first', 'last' );
    $sym;
}

1;
