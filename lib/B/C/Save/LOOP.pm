package B::LOOP;

use strict;

use B::C::File qw/loopsect init/;
use B::C::Helpers qw/do_labels/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;

    #warn sprintf("LOOP: redoop %s, nextop %s, lastop %s\n",
    #		 peekop($op->redoop), peekop($op->nextop),
    #		 peekop($op->lastop)) if $debug{op};
    loopsect()->comment_common("first, last, redoop, nextop, lastop");
    loopsect()->add(
        sprintf(
            "%s, s\\_%x, s\\_%x, s\\_%x, s\\_%x, s\\_%x",
            $op->_save_common,
            ${ $op->first },
            ${ $op->last },
            ${ $op->redoop },
            ${ $op->nextop },
            ${ $op->lastop }
        )
    );
    loopsect()->debug( $op->name, $op );
    my $ix = loopsect()->index;
    init()->add( sprintf( "loop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&loop_list[$ix]" );
    do_labels( $op, qw(first last redoop nextop lastop) );
    $sym;
}

1;
