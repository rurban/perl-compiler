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

    my $flags = $pn->FLAGS;    # U8 + FAKE if OUTER. OUTER,STATE,LVALUE,TYPED,OUR
    $flags = $flags & 0xff;
    my $gen   = $pn->GEN;
    my $stash = $pn->OURSTASH;
    my $type  = $pn->TYPE;

    my $sn = $stash->save($fullname);
    my $tn = $type->save($fullname);

    my $refcnt = $pn->REFCNT;
    $refcnt++ if $refcnt < 1000;    # XXX protect from free, but allow SvREFCOUNT_IMMORTAL

    my $str  = $pn->PVX;
    my $cstr = cstring($str);              # a 5.22 padname is always utf8
    my $ix   = padnamesect()->index + 1;
    my $s    = "&padname_list[$ix]";

    my $pnstr = "((char*)$s)+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0])" ;

    # 5.22 needs the buffer to be at the end, and the pv pointing to it.
    # We allocate a static buffer, and for uniformity of the list pre-alloc size 60 (WIP, improve later)
    padnamesect()->comment(" pv, ourstash, type, low, high, refcnt, gen, len, flags, str");

    padnamesect()->add(
        sprintf(
            # ignore warning: initializer-string for array of chars is too long
            "%s, %s, {%s}, %u, %u, %s, %i, %u, 0x%x, %s",
            $ix              ? $pnstr : 'NULL',
            is_constant($sn) ? "(HV*)$sn"                                                         : 'Nullhv',
            is_constant($tn) ? "(HV*)$tn"                                                         : 'Nullhv',
            $pn->COP_SEQ_RANGE_LOW,
            $pn->COP_SEQ_RANGE_HIGH,
            $refcnt >= 1000 ? sprintf( "0x%x", $refcnt ) : "$refcnt /* +1 */",
            $gen, $pn->LEN, $flags, $cstr
        )
    );

    if ( $pn->LEN > 60 ) {

        # Houston we have a problem, need to allocate this padname dynamically. Not done yet
        # either dynamic or seperate structs per size MyPADNAME(5)
        die "Internal Error: Overlong name of lexical variable $cstr for $fullname [#229]";
    }

    padnamesect()->debug( $fullname . " " . $str, $pn->flagspv ) if debug('flags');

    init()->add("SvOURSTASH_set($s, $sn);")     unless $sn eq 'Nullsv';
    init()->add("PadnameTYPE($s) = (HV*) $tn;") unless $tn eq 'Nullsv';

    push @B::C::static_free, $s;

    return savesym( $pn, $s );
}

1;
