package B::UNOP_AUX;

use strict;

use Config;
use B::C::Config;
use B::C::File qw/unopauxsect init2 init decl free/;
use B::C::Helpers qw/do_labels is_constant/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Save qw(constpv);

sub save {
    my ( $op, $level ) = @_;
    my $sym = objsym($op);
    return $sym if defined $sym;

    my @aux_list = $op->aux_list($B::C::curcv);
    my $auxlen   = scalar @aux_list;

    unopauxsect()->comment_common("first, aux");

    my $ix = unopauxsect()->index + 1;
    unopauxsect()->add( sprintf( "%s, s\\_%x, unopaux_item$ix + 1", $op->_save_common, ${ $op->first } ) );
    unopauxsect()->debug( $op->name, $op->flagspv ) if debug('flags');

    # this cannot be a section, as the number of elements is variable
    my $i = 1;
    my $s = "Static UNOP_AUX_item unopaux_item${ix}[] = {\n\t{.uv=$auxlen}\t/* length prefix */\n";
    for my $item (@aux_list) {
        unless ( ref $item ) {

            # symbolize MDEREF action?
            $s .= sprintf( "\t,{.uv=0x%x} \t/* action|index: %u */\n", $item, $item );
        }
        else {
            # XXX check how literal int is returned by B
            # (const B::IV or B::UV or B::PAD), maybe even broken now.
            # testcase: $a[-1] -1 as B::IV not as -1, what for PAD_OFFSET
            my $itemsym = $item->save("unopaux_item${ix}[$i]");
            if ( is_constant($itemsym) ) {
                if ( ref $item eq 'B::IV' ) {
                    my $iv = $item->IVX;
                    $s .= "\t,{.iv=$iv}\n";
                }
                elsif ( ref $item eq 'B::UV' ) {    # also for PAD_OFFSET
                    my $uv = $item->UVX;
                    $s .= "\t,{.uv=$uv}\n";
                }
                else {                              # SV
                    $s .= "\t,{.sv=$itemsym}\n";
                }
            }
            else {
                # gv or other late inits
                $s .= "\t,{.sv=Nullsv} \t/* $itemsym */\n";
                init2()->add(" unopaux_item${ix}[$i].sv = (SV*)$itemsym;");
            }
        }
        $i++;
    }

    decl()->add("$s\n};");

    init()->add( sprintf( "unopaux_list[%d].op_ppaddr = %s;", $ix, $op->ppaddr ) ) unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&unopaux_list[$ix]" );
    free()->add("    ($sym)->op_type = OP_NULL;");
    do_labels( $op, 'first' );

    return $sym;
}

1;
