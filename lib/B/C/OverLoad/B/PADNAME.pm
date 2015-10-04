package B::PADNAME;

use strict;

use B qw/cstring SVf_FAKE/;
use B::C::File qw( padnamesect init );
use B::C::Config;
use B::C::Helpers::Symtable qw/savesym objsym/;

sub B::PADNAME::save {
    my ( $pn, $fullname ) = @_;
    my $sym = objsym($pn);

    if ( defined $sym ) {
        if ($B::C::in_endav) {
            debug( av => "in_endav: static_free without $sym" );
            @B::C::static_free = grep { $_ ne $sym } @B::C::static_free;
        }
        return $sym;
    }

    my $flags = $pn->FLAGS;      # U8 + FAKE
    my $gen   = 0;
    my $stash = $pn->OURSTASH;
    my $type  = $pn->TYPE;
    padnamesect()->comment(" pv, ourstash, type, low, high, refcnt, gen, len, flags");
    padnamesect()->add(
        sprintf(
            "%s, NULL, {NULL}, %uU, %uU, %uU, %uU, %uU, 0x%x",
            cstring( $pn->PVX ),
            $flags & SVf_FAKE ? $pn->COP_SEQ_RANGE_LOW  : 0,
            $flags & SVf_FAKE ? $pn->COP_SEQ_RANGE_HIGH : 0,
            $pn->REFCNT + 1,     # XXX protect from free
            $gen, $pn->LEN,
            $flags & 0xff
        )
    );
    my $s  = "&padname_list[" . padnamesect()->index . "]";
    my $sn = $stash->save($fullname);
    my $tn = $type->save($fullname);
    init()->add("SvOURSTASH_set($s, $sn);") unless $sn eq 'Nullsv';
    init()->add("PadnameTYPE($s) = (HV*) $tn;")   unless $tn eq 'Nullsv';
    push @B::C::static_free, $s;

    savesym( $pn, $s );
}

1;
