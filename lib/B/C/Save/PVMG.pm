package B::PVMG;

use strict;

use Config;
use B qw/SVf_ROK/;
use B::C::File qw/init svsect xpvmgsect/;
use B::C::Helpers qw/objsym savesym/;

sub save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($B::C::in_endav) {
            warn "in_endav: static_free without $sym\n" if $B::C::debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );

    my ( $ivx, $nvx );

    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    if ( ref($sv) eq 'B::REGEXP' ) {
        return B::REGEXP::save( $sv, $fullname );
    }
    else {
        $ivx = B::C::ivx( $sv->IVX );    # XXX How to detect HEK* namehek?
        $nvx = B::C::nvx( $sv->NVX );    # it cannot be xnv_u.xgv_stash ptr (BTW set by GvSTASH later)

        # See #305 Encode::XS: XS objects are often stored as SvIV(SvRV(obj)). The real
        # address needs to be patched after the XS object is initialized. But how detect them properly?
        # Detect ptr to extern symbol in shared library and remap it in init2
        # Safe and mandatory currently only Net-DNS-0.67 - 0.74.
        # svop const or pad OBJECT,IOK
        if (
            # fixme simply the or logic
            ( ( !B::C::USE_ITHREADS() and $fullname and $fullname =~ /^svop const|^padop|^Encode::Encoding| :pad\[1\]/ ) or B::C::USE_ITHREADS() )
            and $sv->IVX > 5000000    # some crazy heuristic for a so ptr (> image_base)
            and ref( $sv->SvSTASH ) ne 'B::SPECIAL'
          ) {
            $ivx = B::C::patch_dlsym( $sv, $fullname, $ivx );
        }
    }

    if ( $sv->FLAGS & SVf_ROK ) {     # sv => sv->RV cannot be initialized static.
        init()->add( sprintf( "SvRV_set(&sv_list[%d], (SV*)%s);", svsect()->index + 1, $savesym ) )
          if $savesym ne '';
        $savesym = 'NULL';
        $static  = 1;
    }

    xpvmgsect()->comment("STASH, MAGIC, cur, len, xiv_u, xnv_u");
    xpvmgsect()->add(
        sprintf(
            "Nullhv, {0}, %u, %u, {%s}, {%s}",
            $cur, $len, $ivx, $nvx
        )
    );

    svsect()->add(
        sprintf(
            "&xpvmg_list[%d], %lu, 0x%x, {%s}",
            xpvmgsect()->index, $sv->REFCNT, $sv->FLAGS,
            $savesym eq 'NULL'
            ? '0'
            : ( $B::C::C99 ? ".svu_pv=(char*)" : "(char*)" ) . $savesym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( !$static ) {    # do not overwrite RV slot (#273)
                         # XXX comppadnames need &PL_sv_undef instead of 0 (?? which testcase?)
        init()->add( B::C::savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    $sym = savesym( $sv, "&" . $s );
    $sv->save_magic($fullname);
    return $sym;
}

1;
