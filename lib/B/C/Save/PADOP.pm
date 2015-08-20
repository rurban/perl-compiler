package B::PADOP;

use strict;

use B qw/comppadlist/;

use B::C::File qw/padopsect init/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $op, $level ) = @_;

    die "xxxx";

    my $sym = objsym($op);
    return $sym if defined $sym;
    my $skip_defined;
    if ( $op->name eq 'method_named' ) {
        my $cv = B::C::method_named( B::C::svop_or_padop_pv($op), B::C::nextcop($op) );
        $cv->save if $cv;
    }
    elsif ( $op->name eq 'gv'
        and $op->next
        and $op->next->name eq 'rv2cv'
        and $op->next->next
        and $op->next->next->name eq 'defined' ) {

        # 96 do not save a gvsv->cv if just checked for defined'ness
        $skip_defined++;
    }

    # This is saved by curpad syms at the end. But with __DATA__ handles it is better to save earlier
    if ( $op->name eq 'padsv' or $op->name eq 'gvsv' or $op->name eq 'gv' ) {
        my @c   = comppadlist->ARRAY;
        my @pad = $c[1]->ARRAY;
        my $ix  = $op->can('padix') ? $op->padix : $op->targ;
        my $sv  = $pad[$ix];
        if ( $sv and $$sv ) {
            my $name = B::C::padop_name( $op, $B::C::curcv );
            if ( $skip_defined and $name !~ /^DynaLoader::/ ) {
                warn "skip saving defined(&$name)\n" if $B::C::debug{gv};    # defer to run-time
            }
            else {
                $sv->save( "padop " . ( $name ? $name : '' ) );
            }
        }
    }
    padopsect()->comment_common("padix");
    padopsect()->add( sprintf( "%s, %d", $op->_save_common, $op->padix ) );
    padopsect()->debug( $op->name, $op );
    my $ix = padopsect()->index;
    init()->add( sprintf( "padop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;

    return savesym( $op, "(OP*)&padop_list[$ix]" );
}

1;
