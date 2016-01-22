package B::UNOP_AUX;

use strict;

use B::C::Setup;
use B::C::File qw/unopauxsect init decl free/;
use B::C::Helpers qw/do_labels is_constant curcv/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Save qw(constpv);

sub save {
    my ( $op, $level ) = @_;
    my $sym = objsym($op);
    return $sym if defined $sym;

    $level ||= 0;

    my @aux_list = $op->aux_list_thr;
    my $auxlen   = scalar @aux_list;

    unopauxsect()->comment_common("first, aux");

    my $ix = unopauxsect()->index + 1;
    unopauxsect()->add( sprintf( "%s, s\\_%x, unopaux_item$ix + 1", $op->_save_common, ${ $op->first } ) );
    unopauxsect()->debug( $op->name, $op->flagspv ) if debug('flags');

    # This cannot be a section, as the number of elements is variable
    my $i      = 1;
    my $s      = "Static UNOP_AUX_item unopaux_item${ix}[] = {\n\t{.uv=$auxlen}\t/* length prefix */\n";
    my $action = 0;
    for my $item (@aux_list) {
        unless ( ref $item ) {

            # symbolize MDEREF action
            my $cmt = 'action';
            if ( verbose() ) {
                my $act = $item & 0xf;    # MDEREF_ACTION_MASK
                $cmt = 'AV_pop_rv2av_aelem'          if $act == 1;
                $cmt = 'AV_gvsv_vivify_rv2av_aelem'  if $act == 2;
                $cmt = 'AV_padsv_vivify_rv2av_aelem' if $act == 3;
                $cmt = 'AV_vivify_rv2av_aelem'       if $act == 4;
                $cmt = 'AV_padav_aelem'              if $act == 5;
                $cmt = 'AV_gvav_aelem'               if $act == 6;
                $cmt = 'HV_pop_rv2hv_helem'          if $act == 8;
                $cmt = 'HV_gvsv_vivify_rv2hv_helem'  if $act == 9;
                $cmt = 'HV_padsv_vivify_rv2hv_helem' if $act == 10;
                $cmt = 'HV_vivify_rv2hv_helem'       if $act == 11;
                $cmt = 'HV_padhv_helem'              if $act == 12;
                $cmt = 'HV_gvhv_helem'               if $act == 13;
                my $idx = $item & 0x30;    # MDEREF_INDEX_MASK
                $cmt .= ''             if $idx == 0x0;
                $cmt .= ' INDEX_const' if $idx == 0x10;
                $cmt .= ' INDEX_padsv' if $idx == 0x20;
                $cmt .= ' INDEX_gvsv'  if $idx == 0x30;
            }
            $action = $item;
            debug( hv => "mderef action $action $cmt" );
            $s .= sprintf( "\t,{.uv=0x%x} \t/* %s: %u */\n", $item, $cmt, $item );

        }
        else {
            # const and sv already at compile-time, gv deferred to init-time.
            # testcase: $a[-1] -1 as B::IV not as -1
            # hmm, if const ensure that candidate CONSTs have been HEKified. (pp_multideref assertion)
            # || SvTYPE(keysv) >= SVt_PVMG
            # || !SvOK(keysv)
            # || SvROK(keysv)
            # || SvIsCOW_shared_hash(keysv));
            my $constkey = ( $action & 0x30 ) == 0x10 ? 1 : 0;
            my $itemsym = $item->save( "unopaux_item${ix}[$i]" . ( $constkey ? " const" : "" ) );
            if ( is_constant($itemsym) ) {
                if ( ref $item eq 'B::IV' ) {
                    my $iv = $item->IVX;
                    $s .= "\t,{.iv = $iv}\n";
                }
                elsif ( ref $item eq 'B::UV' ) {    # also for PAD_OFFSET
                    my $uv = $item->UVX;
                    $s .= "\t,{.uv = $uv}\n";
                }
                else {                              # SV
                    $s .= "\t,{.sv = $itemsym}\n";
                }
            }
            else {
                # gv or other late inits
                $s .= "\t,{.sv=Nullsv} \t/* $itemsym */\n";
                init()->add("unopaux_item${ix}[$i].sv = (SV*)$itemsym;");
            }
        }
        $i++;
    }

    decl()->add("$s\n};");

    init()->add( sprintf( "unopaux_list[%d].op_ppaddr = %s;", $ix, $op->ppaddr ) ) unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&unopaux_list[$ix]" );
    free()->add("    ($sym)->op_type = OP_NULL;");
    do_labels( $op, $level + 1, 'first' );

    return $sym;
}

1;
