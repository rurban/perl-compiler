package B::BINOP;

use strict;

use B qw/opnumber/;
use B::C::Setup;
use B::C::File qw/binopsect init/;
use B::C::Helpers qw/do_labels/;
use B::C::Helpers::Symtable qw/savesym/;

my $OP_CUSTOM = opnumber('custom');

sub save {
    my ( $op, $level ) = @_;

    my $sym = B::objsym($op);
    return $sym if defined $sym;

    $level ||= 0;

    binopsect->comment_common("first, last");
    binopsect->add( sprintf( "%s, s\\_%x, s\\_%x", $op->_save_common, ${ $op->first }, ${ $op->last } ) );
    binopsect->debug( $op->name, $op->flagspv );
    my $ix = binopsect->index;

    my $ppaddr = $op->ppaddr;
    if ( $op->type == $OP_CUSTOM ) {
        my $ptr = $$op;
        if ( $op->name eq 'Devel_Peek_Dump' or $op->name eq 'Dump' ) {
            verbose('custom op Devel_Peek_Dump');
            $B::C::devel_peek_needed++;
            $ppaddr = 'S_pp_dump';
            init()->add( sprintf( "binop_list[%d].op_ppaddr = %s;", $ix, $ppaddr ) );
        }
        else {
            vebose( "Warning: Unknown custom op " . $op->name );
            $ppaddr = sprintf( 'Perl_custom_op_xop(aTHX_ INT2PTR(OP*, 0x%x))', $$op );
            init()->add( sprintf( "binop_list[%d].op_ppaddr = %s;", $ix, $ppaddr ) );
        }
    }
    else {
        init()->add( sprintf( "binop_list[%d].op_ppaddr = %s;", $ix, $ppaddr ) )
          unless $B::C::optimize_ppaddr;
    }

    $sym = savesym( $op, "(OP*)&binop_list[$ix]" );
    do_labels( $op, $level + 1, 'first', 'last' );

    return $sym;
}

1;
