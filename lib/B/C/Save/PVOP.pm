package B::PVOP;

use B qw/cstring/;
use B::C ();
use B::C::File qw/objsym savesym loopsect pvopsect init /;
use utf8 ();

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
    my $pv = pack "a*", $op->pv;
    my $cur = length($pv);

    if ( utf8::is_utf8($pv) ) {
        utf8::encode($pv);
        $cur = length $pv;
    }

    init()->add( sprintf( "pvop_list[$ix].op_pv = savepvn(%s, %u);", cstring($pv), $cur ) );
    savesym( $op, "(OP*)&pvop_list[$ix]" );
}

1;
