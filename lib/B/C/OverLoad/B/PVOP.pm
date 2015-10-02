package B::PVOP;

use strict;

use B qw/cstring/;

use B::C::File qw/loopsect pvopsect init/;
use B::C::Helpers qw/strlen_flags/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;
    loopsect()->comment_common("pv");

    # op_pv must be dynamic
    pvopsect()->add( sprintf( "%s, NULL", $op->_save_common ) );
    pvopsect()->debug( $op->name, $op );
    my $ix = pvopsect()->index;
    init()->add( sprintf( "pvop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;

    my ( $cstring, $cur, $utf8 ) = strlen_flags( $op->pv );    # utf8 ignored in a shared str?

    init()->add( sprintf( "pvop_list[$ix].op_pv = savesharedpvn(%s, %u);", $cstring, $cur ) );
    savesym( $op, "(OP*)&pvop_list[$ix]" );
}

1;
