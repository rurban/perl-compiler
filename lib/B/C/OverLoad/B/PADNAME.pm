package B::PADNAME;

use strict;

use B qw/cstring SVf_FAKE/;
use B::C::File qw( padnamesect init );
use B::C::Config;
use B::C::Helpers qw/is_constant/;
use B::C::Helpers::Symtable qw/savesym objsym/;

sub save {
    my ( $pn, $fullname ) = @_;
    my $sym = objsym($pn);

    if ( defined $sym ) {
        if ($B::C::in_endav) {
            debug( av => "in_endav: static_free without $sym" );
            @B::C::static_free = grep { $_ ne $sym } @B::C::static_free;
        }
        return $sym;
    }

    my $flags = $pn->FLAGS;    # U8 + FAKE if OUTER
    $flags = $flags & 0xff;
    my $is_fake = $pn->FLAGS & SVf_FAKE;
    my $gen     = $pn->GEN;
    my $stash   = $pn->OURSTASH;
    my $type    = $pn->TYPE;

    my $sn = $stash->save($fullname);
    my $tn = $type->save($fullname);

    my $refcnt = $pn->REFCNT;
    $refcnt++ if $refcnt < 1000;    # XXX protect from free, but allow SvREFCOUNT_IMMORTAL
    padnamesect()->comment(" pv, ourstash, type, low, high, refcnt, gen, len, flags");
    padnamesect()->add(
        sprintf(
            "%s, %s, {%s}, %u, %u, %s, %i, %u, 0x%x",
            cstring( $pn->PVX ),
            is_constant($sn) ? "(HV*)$sn"              : 'Nullhv',
            is_constant($tn) ? "(HV*)$tn"              : 'Nullhv',
            $is_fake         ? $pn->COP_SEQ_RANGE_LOW  : 0,
            $is_fake         ? $pn->COP_SEQ_RANGE_HIGH : 0,
            $refcnt >= 1000 ? sprintf( "0x%x", $refcnt ) : "$refcnt /* +1 */",
            $gen, $pn->LEN, $flags
        )
    );
    my $s = "&padname_list[" . padnamesect()->index . "]";

    padnamesect()->debug( $fullname, $pn->flagspv ) if debug('flags');

    init()->add("SvOURSTASH_set($s, $sn);")     unless $sn eq 'Nullsv';
    init()->add("PadnameTYPE($s) = (HV*) $tn;") unless $tn eq 'Nullsv';
    push @B::C::static_free, $s;

    return savesym( $pn, $s );
}

1;
