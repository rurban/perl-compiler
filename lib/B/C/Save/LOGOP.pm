package B::LOGOP;

use B::C ();
use B::C::File qw/objsym logopsect init savesym do_labels/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);

    return $sym if defined $sym;

    logopsect()->comment( B::C::opsect_common() . ", first, other" );
    logopsect()->add(
        sprintf(
            "%s, s\\_%x, s\\_%x",
            $op->_save_common,
            ${ $op->first },
            ${ $op->other }
        )
    );
    logopsect()->debug( $op->name, $op );
    my $ix = logopsect()->index;
    init()->add( sprintf( "logop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&logop_list[$ix]" );
    do_labels( $op, 'first', 'other' );
    return $sym;
}

1;
