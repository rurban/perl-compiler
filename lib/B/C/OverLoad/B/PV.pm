package B::PV;

use strict;

use B qw/SVf_IsCOW SVf_ROK SVf_POK SVs_GMG SVs_SMG SVf_READONLY cstring SVs_OBJECT/;
use B::C::Config;
use B::C::Save qw/savepvn/;
use B::C::SaveCOW qw/savepv/;
use B::C::Save::Hek qw/save_hek/;
use B::C::File qw/xpvsect svsect init free/;
use B::C::Helpers::Symtable qw/savesym objsym/;
use B::C::Helpers qw/is_shared_hek/;

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

    my $shared_hek = is_shared_hek($sv);

    my ( $savesym, $cur, $len, $pv, $static, $flags ) = save_pv_once( $sv, $fullname );
    $static = 0 if !( $flags & SVf_ROK ) and $sv->PV and $sv->PV =~ /::bootstrap$/;

    # sv_free2 problem with !SvIMMORTAL and del_SV
    my $refcnt = $sv->REFCNT;
    if ( $fullname && $fullname eq 'svop const' ) {
        $refcnt = DEBUGGING() ? 1000 : 0x7fffffff;
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

sub save_pv_once {
    my ( $sv, $fullname ) = @_;

    my $rok = $sv->FLAGS & SVf_ROK;
    my $pok = $sv->FLAGS & SVf_POK;
    my $gmg = $sv->FLAGS & SVs_GMG;

    my $flags = $sv->FLAGS;

    my ( $cur, $len, $savesym, $pv ) = ( 0, 1, 'NULL', "" );
    my ( $static, $shared_hek ) = ( 1, is_shared_hek($sv) );
    my $empty_string;

    # overloaded VERSION symbols fail to xs boot: ExtUtils::CBuilder with Fcntl::VERSION (i91)
    # 5.6: Can't locate object method "RV" via package "B::PV" Carp::Clan
    if ($rok) {

        # this returns us a SV*. 5.8 expects a char* in xpvmg.xpv_pv
        debug( sv => "save_pv_once: B::RV::save_op(" . ( $sv || '' ) );
        $savesym = B::RV::save_op( $sv, $fullname );
        if ( $savesym =~ /get_cv/ ) {    # Moose::Util::TypeConstraints::Builtins::_RegexpRef
            $static  = 0;
            $pv      = $savesym;
            $savesym = 'NULL';
        }
    }
    else {
        if ($pok) {
            $pv = pack "a*", $sv->PV;    # XXX!
            $cur = ( $sv and $sv->can('CUR') and ref($sv) ne 'B::GV' ) ? $sv->CUR : length($pv);
        }
        else {
            if ( $gmg && $fullname ) {
                no strict 'refs';
                $pv = ( $fullname and ref($fullname) ) ? "${$fullname}" : '';
                $cur = length( pack "a*", $pv );
                $pok = 1;
            }
            else {
                ( $pv, $cur ) = ( "", 0 );
            }
        }

        if ( $shared_hek and $pok and !$cur ) {    #272 empty key
            debug( [qw/pv hv/], "use emptystring for empty shared key $fullname" );
            $empty_string = 1 unless $fullname =~ /unopaux_item.* const/;
            $static = 0;    # TODO WHAT WILL THIS DO???
        }

        $static = 0 if ( $sv->FLAGS & 0x40008000 == 0x40008000 );    # SVp_SCREAM|SVpbm_VALID

        if ($pok) {

            # but we can optimize static set-magic ISA entries. #263, #91
            if ( $B::C::const_strings and ref($sv) eq 'B::PVMG' and $sv->FLAGS & SVs_SMG ) {
                $static = 1;                                         # warn "static $fullname";
            }

            ( $savesym, $cur, $len ) = savepv($pv);
        }
        else {
            $len = 0;
        }
    }
    if ( $savesym eq 'NULL' ) {
        ( $savesym, $cur, $len ) = savepv('');
    }

    $len = 0 if $shared_hek;    # hek should have len 0

    $fullname = '' if !defined $fullname;
    debug(
        pv => "Saving pv %s %s cur=%d, len=%d, static=%d cow=%d %s",
        $savesym, cstring($pv), $cur, $len,
        $static, $static, $shared_hek ? "shared, $fullname" : $fullname
    );

    $flags |= SVf_IsCOW if !$rok;    # unless it's a reference!

    return ( $savesym, $cur, $len, $pv, $static, $flags );
}
1;
