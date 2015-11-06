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

    # op_pv must be dynamic
    loopsect()->comment_common("pv");

    pvopsect()->add( sprintf( "%s, NULL", $op->_save_common ) );
    pvopsect()->debug( $op->name, $op );
    my $ix = pvopsect()->index;
    init()->add( sprintf( "pvop_list[%d].op_ppaddr = %s;", $ix, $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;

    my ($cstring,$cur,$utf8) = strlen_flags($op->pv); # utf8 in op_private as OPpPV_IS_UTF8 (0x80)

    init()->add( sprintf( "pvop_list[%d].op_pv = savesharedpvn(%s, %u);", $ix, $cstring, $cur ) );
    savesym( $op, "(OP*)&pvop_list[$ix]" );
}

1;
