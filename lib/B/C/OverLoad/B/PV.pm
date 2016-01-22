package B::PV;

use strict;

use B qw/SVf_ROK SVf_READONLY SVf_IsCOW cstring SVs_OBJECT/;
use B::C::Setup;
use B::C::Save qw/savepvn/;
use B::C::Save::Hek qw/save_hek/;
use B::C::File qw/xpvsect svsect init/;
use B::C::Helpers::Symtable qw/savesym objsym/;

sub save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);

    if ( defined $sym ) {
        if ($B::C::in_endav) {
            debug( av => "in_endav: static_free without $sym" );
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my $flags = $sv->FLAGS;
    my $shared_hek = ( ( $flags & 0x09000000 ) == 0x09000000 );
    $shared_hek = $shared_hek ? 1 : B::C::IsCOW_hek($sv);
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );
    $static = 0 if !( $flags & SVf_ROK ) and $sv->PV and $sv->PV =~ /::bootstrap$/;

    # sv_free2 problem with !SvIMMORTAL and del_SV
    my $refcnt = $sv->REFCNT;
    if ( $fullname && $fullname eq 'svop const' ) {
        $refcnt = DEBUGGING() ? 1000 : 0x7fffffff;
    }

    # Remove COW flag
    if ( !$shared_hek and !$B::C::cow and B::C::IsCOW($sv) ) {
        $flags &= ~SVf_IsCOW;
        debug( pv => "turn off SVf_IsCOW %s %s %s", $sym, cstring($pv), $fullname );
    }

    # static pv, do not destruct. test 13 with pv0 "3".
    if ( $B::C::const_strings and !$shared_hek and $flags & SVf_READONLY and !$len ) {
        $flags &= ~0x01000000;
        debug( pv => "constpv turn off SVf_FAKE %s %s %s\n", $sym, cstring($pv), $fullname );
    }
    xpvsect()->comment("stash, magic, cur, len");
    xpvsect()->add( sprintf( "Nullhv, {0}, %u, {%u}", $cur, $len ) );
    svsect()->comment("any, refcnt, flags, sv_u");

    $savesym = $savesym eq 'NULL' ? '0' : ".svu_pv=(char*) $savesym";
    svsect()->add( sprintf( '&xpv_list[%d], %Lu, 0x%x, {%s}', xpvsect()->index, $refcnt, $flags, $savesym ) );
    my $svix = svsect()->index;
    if ( defined($pv) and !$static ) {
        if ($shared_hek) {
            my $hek = save_hek( $pv, $fullname );
            init()->add( sprintf( "sv_list[%d].sv_u.svu_pv = HEK_KEY(%s);", $svix, $hek ) )
              unless $hek eq 'NULL';
        }
        else {
            init()->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svix ), $pv, $sv, $cur ) );
        }
    }
    if ( debug('flags') and DEBUG_LEAKING_SCALARS() ) {    # add sv_debug_file
        init()->add(
            sprintf(
                qq(sv_list[%d].sv_debug_file = %s" sv_list[%d] 0x%x";),
                $svix, cstring($pv) eq '0' ? q{"NULL"} : cstring($pv),
                $svix, $sv->FLAGS
            )
        );
    }

    my $s = "sv_list[$svix]";
    svsect()->debug( $fullname, $sv );

    push @B::C::static_free, "&" . $s if $flags & SVs_OBJECT;
    return savesym( $sv, "&" . $s );
}

1;
