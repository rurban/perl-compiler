package B::SVOP;

use strict;

use B::C::File qw/svopsect init/;
use B::C::Helpers qw/objsym savesym do_labels/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;
    my $svsym = 'Nullsv';

    # XXX moose1 crash with 5.8.5-nt, Cwd::_perl_abs_path also
    if ( $op->name eq 'aelemfast' and $op->flags & 128 ) {    #OPf_SPECIAL
        $svsym = '&PL_sv_undef';                              # pad does not need to be saved
        warn sprintf( "SVOP->sv aelemfast pad %d\n", $op->flags ) if $B::C::debug{sv};
    }
    elsif ( $op->name eq 'gv'
        and $op->next
        and $op->next->name eq 'rv2cv'
        and $op->next->next
        and $op->next->next->name eq 'defined' ) {

        # 96 do not save a gvsv->cv if just checked for defined'ness
        my $gv   = $op->sv;
        my $gvsv = B::C::svop_name($op);
        if ( $gvsv !~ /^DynaLoader::/ ) {
            warn "skip saving defined(&$gvsv)\n" if $B::C::debug{gv};    # defer to run-time
            $svsym = '(SV*)' . $gv->save(8);                             # ~Save_CV in B::GV::save
        }
        else {
            $svsym = '(SV*)' . $gv->save();
        }
    }
    else {
        my $sv = $op->sv;
        $svsym = '(SV*)' . $sv->save( "svop " . $op->name );
        warn "Error: SVOP: " . $op->name . " $sv $svsym" if $svsym =~ /^\(SV\*\)lexwarn/;    #322
    }
    if ( $op->name eq 'method_named' ) {
        my $cv = B::C::method_named( B::C::svop_or_padop_pv($op), B::C::nextcop($op) );
        $cv->save if $cv;
    }
    my $is_const_addr = $svsym =~ m/Null|\&/;
    if ( $B::C::MULTI and $svsym =~ /\(SV\*\)\&PL_sv_(yes|no)/ ) {                           # t/testm.sh Test::Pod
        $is_const_addr = 0;
    }
    svopsect()->comment_common("sv");
    svopsect()->add(
        sprintf(
            "%s, %s",
            $op->_save_common, ( $is_const_addr ? $svsym : 'Nullsv' )
        )
    );
    svopsect()->debug( $op->name, $op );
    my $ix = svopsect()->index;
    init()->add( sprintf( "svop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    init()->add("svop_list[$ix].op_sv = $svsym;")
      unless $is_const_addr;
    savesym( $op, "(OP*)&svop_list[$ix]" );
}

1;
