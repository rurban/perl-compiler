package B::GV;

use strict;

use B qw/cstring svref_2object SVt_PVGV SVf_ROK SVf_UTF8/;

use B::C::Config;
use B::C::Save::Hek qw/save_hek/;
use B::C::Packages qw/is_package_used/;
use B::C::File qw/init init2/;
use B::C::Helpers qw/mark_package get_cv_string strlen_flags/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Optimizer::ForceHeavy qw/force_heavy/;
use B::C::Packages qw/mark_package_used/;

my %gptable;

sub get_index {
    return $B::C::gv_index;
}

sub inc_index {
    return $B::C::gv_index++;
}

sub Save_HV()   { 1 }
sub Save_AV()   { 2 }
sub Save_SV()   { 4 }
sub Save_CV()   { 8 }
sub Save_FORM() { 16 }
sub Save_IO()   { 32 }

sub savecv {
    my $gv      = shift;
    my $package = $gv->STASH->NAME;
    my $name    = $gv->NAME;
    my $cv      = $gv->CV;
    my $sv      = $gv->SV;
    my $av      = $gv->AV;
    my $hv      = $gv->HV;

    my $fullname = $package . "::" . $name;
    debug( gv => "Checking GV *%s 0x%x\n", cstring($fullname), ref $gv ? $$gv : 0 ) if verbose();

    # We may be looking at this package just because it is a branch in the
    # symbol table which is on the path to a package which we need to save
    # e.g. this is 'Getopt' and we need to save 'Getopt::Long'
    #
    return if ( $package ne 'main' and !is_package_used($package) );
    return if ( $package eq 'main'
        and $name =~ /^([^\w].*|_\<.*|INC|ARGV|SIG|ENV|BEGIN|main::|!)$/ );

    debug( gv => "Used GV \*$fullname 0x%x", ref $gv ? $$gv : 0 );
    return unless ( $$cv || $$av || $$sv || $$hv || $gv->IO || $gv->FORM );
    if ( $$cv and $name eq 'bootstrap' and $cv->XSUB ) {

        #return $cv->save($fullname);
        debug( gv => "Skip XS \&$fullname 0x%x", ref $cv ? $$cv : 0 );
        return;
    }
    if (
        $$cv and B::C::in_static_core( $package, $name ) and ref($cv) eq 'B::CV'    # 5.8,4 issue32
        and $cv->XSUB
      ) {
        debug( gv => "Skip internal XS $fullname" );

        # but prevent it from being deleted
        unless ( $B::C::dumped_package{$package} ) {

            #$B::C::dumped_package{$package} = 1;
            mark_package( $package, 1 );
        }
        return;
    }
    if ( $package eq 'B::C' ) {
        debug( gv => "Skip XS \&$fullname 0x%x\n", ref $cv ? $$cv : 0 );
        return;
    }

    if ( my $newgv = force_heavy( $package, $fullname ) ) {
        $gv = $newgv;
    }

    # XXX fails and should not be needed. The B::C part should be skipped 9 lines above, but be defensive
    return if $fullname eq 'B::walksymtable' or $fullname eq 'B::C::walksymtable';

    # Config is marked on any Config symbol. TIE and DESTROY are exceptions,
    # used by the compiler itself
    if ( $name eq 'Config' ) {
        mark_package( 'Config', 1 ) if !is_package_used('Config');
    }

    $B::C::dumped_package{$package} = 1 if !exists $B::C::dumped_package{$package} and $package !~ /::$/;
    debug( gv => "Saving GV \*$fullname 0x%x", ref $gv ? $$gv : 0 );
    $gv->save($fullname);
}

sub save {
    my ( $gv, $filter ) = @_;

    my $sym;    # gvsect->save();
    return save_legacy( $gv, $filter, $sym );
}

sub save_legacy {
    my ( $gv, $filter ) = @_;
    my $sym = objsym($gv);
    if ( defined($sym) ) {
        debug( gv => "GV 0x%x already saved as $sym", ref $gv ? $$gv : 0 );
        return $sym;
    }
    else {
        my $ix = inc_index();
        $sym = savesym( $gv, "gv_list[$ix]" );
        debug( gv => "Saving GV 0x%x as $sym", ref $gv ? $$gv : 0 );
    }

    my $gvname = $gv->NAME();

    debug(
        gv => "  GV %s $sym type=%d, flags=0x%x",
        $gvname,

        # B::SV::SvTYPE not with 5.6
        B::SV::SvTYPE($gv), $gv->FLAGS
    );

    if ( $gv->FLAGS & 0x40000000 ) {    # SVpbm_VALID
        debug( gv => "  GV $sym isa FBM" );
        return B::BM::save($gv);
    }

    my $package;
    if ( ref( $gv->STASH ) eq 'B::SPECIAL' ) {
        $package = '__ANON__';
        debug( gv => "GV STASH = SPECIAL $gvname" );
    }
    else {
        $package = $gv->STASH->NAME;
    }
    return q/(SV*)&PL_sv_undef/ if B::C::skip_pkg($package);

    # If we come across a stash hash, we therefore have code using it so we need to mark it was used so it won't be deleted.
    if ( $gvname =~ m/::$/ ) {
        my $package = $gvname;
        $package =~ s/::$//;
        mark_package_used($package);
    }

    my $fullname = $package . "::" . $gvname;
    my $fancyname;
    if ( $filter and $filter =~ m/ :pad/ ) {
        $fancyname = cstring($filter);
        $filter    = 0;
    }
    else {
        $fancyname = cstring($fullname);
    }

    # checked for defined'ness in Carp. So the GV must exist, the CV not
    if ( $fullname =~ /^threads::(tid|AUTOLOAD)$/ and USE_ITHREADS() ) {
        $filter = Save_CV;
    }

    # no need to assign any SV/AV/HV to them (172)
    if ( $fullname =~ /^DynaLoader::dl_(require_symbols|resolve_using|librefs)/ ) {
        $filter = Save_SV + Save_AV + Save_HV;
    }

    # skip static %Encode::Encoding since 5.20. GH #200.
    # Let it be initialized by boot_Encode/Encode_XSEncoding
    # if ( $fullname eq 'Encode::Encoding' ) {
    #     $filter = Save_HV;
    # }

    my $is_empty = $gv->is_empty;
    if ( !defined $gvname and $is_empty ) {    # 5.8 curpad name
        return q/(SV*)&PL_sv_undef/;
    }
    my $name    = $package eq 'main' ? $gvname          : $fullname;
    my $cname   = $package eq 'main' ? cstring($gvname) : cstring($fullname);
    my $notqual = $package eq 'main' ? 'GV_NOTQUAL'     : '0';
    debug( gv => "  GV name is $fancyname" );
    my $egvsym;
    my $is_special = ref($gv) eq 'B::SPECIAL';

    # FIXME: diff here with upstream
    if ( my $newgv = force_heavy( $package, $fullname ) ) {
        $gv = $newgv;                          # defer to run-time autoload, or compile it in?
        $sym = savesym( $gv, $sym );           # override new gv ptr to sym
    }
    if ( !$is_empty ) {
        my $egv = $gv->EGV;
        unless ( ref($egv) eq 'B::SPECIAL' or ref( $egv->STASH ) eq 'B::SPECIAL' ) {
            my $estash = $egv->STASH->NAME;
            if ( $$gv != $$egv ) {

                # debug(
                #      gv => "EGV name is %s, saving it now\n",
                #      $estash . "::" . $egv->NAME
                # );
                $egvsym = $egv->save;
            }
        }
    }

    my $core_syms = {
        ENV    => 'PL_envgv',
        ARGV   => 'PL_argvgv',
        INC    => 'PL_incgv',
        STDIN  => 'PL_stdingv',
        STDERR => 'PL_stderrgv',
        "\010" => 'PL_hintgv',     # ^H
        "_"    => 'PL_defgv',
        "@"    => 'PL_errgv',
        "\022" => 'PL_replgv',     # ^R
    };
    my $is_coresym;

    # those are already initialized in init_predump_symbols()
    # and init_main_stash()
    for my $s ( sort keys %$core_syms ) {
        if ( $fullname eq 'main::' . $s ) {
            $sym = savesym( $gv, $core_syms->{$s} );

            # init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
            # return $sym;
            $is_coresym++;
        }
    }
    if ( $fullname =~ /^main::std(in|out|err)$/ ) {    # same as uppercase above
        init()->add(qq[$sym = gv_fetchpv($cname, $notqual, SVt_PVGV);]);
        init()->add( sprintf( "SvREFCNT(%s) = %u;", $sym, $gv->REFCNT ) );
        return $sym;
    }
    elsif ( $fullname eq 'main::0' ) {                 # dollar_0 already handled before, so don't overwrite it
        init()->add(qq[$sym = gv_fetchpv($cname, $notqual, SVt_PV);]);
        init()->add( sprintf( "SvREFCNT(%s) = %u;", $sym, $gv->REFCNT ) );
        return $sym;
    }
    elsif ( $B::C::ro_inc and $fullname =~ /^main::([0-9])$/ ) {    # ignore PV regexp captures with -O2
        $filter = Save_SV;
    }

    # gv_fetchpv loads Errno resp. Tie::Hash::NamedCapture, but needs *INC #90
    #elsif ( $fullname eq 'main::!' or $fullname eq 'main::+' or $fullname eq 'main::-') {
    #  init1()->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PVGV);]); # defer until INC is setup
    #  init1()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    #  return $sym;
    #}
    my $svflags    = $gv->FLAGS;
    my $savefields = 0;

    my $gp;
    my $gvadd = $notqual ? "$notqual|GV_ADD" : "GV_ADD";
    if ( $gv->isGV_with_GP and !$is_coresym ) {
        $gp = $gv->GP;    # B limitation
        if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
            debug(
                gv => "Shared GV alias for *%s 0x%x%s to %s",
                $fullname, $svflags, debug('flags') ? "(" . $gv->flagspv . ")" : "", $egvsym
            );

            # Shared glob *foo = *bar
            init()->add( "$sym = " . gv_fetchpv_string( $name, "$gvadd|GV_ADDMULTI", 'SVt_PVGV' ) . ";" );
            init()->add("GvGP_set($sym, GvGP($egvsym));");
            $is_empty = 1;
        }
        elsif ( $gp and exists $gptable{ 0 + $gp } ) {
            debug(
                gv => "Shared GvGP for *%s 0x%x%s %s GP:0x%x",
                $fullname, $svflags, debug('flags') ? "(" . $gv->flagspv . ")" : "",
                $gv->FILE, $gp
            );
            init()->add( "$sym = " . gv_fetchpv_string( $name, $notqual, 'SVt_PVGV' ) . ";" );
            init()->add( sprintf( "GvGP_set(%s, %s);", $sym, $gptable{ 0 + $gp } ) );
            $is_empty = 1;
        }
        elsif ( $gp and !$is_empty and $gvname =~ /::$/ ) {
            debug(
                gv => "Shared GvGP for stash %%%s 0x%x%s %s GP:0x%x",
                $fullname, $svflags, debug('flags') ? "(" . $gv->flagspv . ")" : "",
                $gv->FILE, $gp
            );
            init()->add( "$sym = " . gv_fetchpv_string( $name, 'GV_ADD', 'SVt_PVHV' ) . ";" );
            $gptable{ 0 + $gp } = "GvGP($sym)" if 0 + $gp;
        }
        elsif ( $gp and !$is_empty ) {
            debug(
                gv => "New GV for *%s 0x%x%s %s GP:0x%x",
                $fullname, $svflags, debug('flags') ? "(" . $gv->flagspv . ")" : "",
                $gv->FILE, $gp
            );

            # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
            init()->add( "$sym = " . gv_fetchpv_string( $name, $gvadd, 'SVt_PV' ) . ";" );
            $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
            $gptable{ 0 + $gp } = "GvGP($sym)";
        }
        else {
            init()->add( "$sym = " . gv_fetchpv_string( $name, $gvadd, 'SVt_PVGV' ) . ";" );
        }
    }
    elsif ( !$is_coresym ) {
        init()->add( "$sym = " . gv_fetchpv_string( $name, $gvadd, 'SVt_PV' ) . ";" );
    }
    my $gvflags = $gv->GvFLAGS;

    init()->add(
        sprintf(
            "SvFLAGS(%s) = 0x%x;%s", $sym, $svflags,
            debug('flags') ? " /* " . $gv->flagspv . " */" : ""
        ),
        sprintf(
            "GvFLAGS(%s) = 0x%x; %s", $sym, $gvflags,
            debug('flags') ? "/* " . $gv->flagspv(SVt_PVGV) . " */" : ""
        )
    );
    init()->add(
        sprintf(
            'GvLINE(%s) = %d;',
            $sym,
            (
                $gv->LINE > 2147483647    # S32 INT_MAX
                ? 4294967294 - $gv->LINE
                : $gv->LINE
            )
        )
    ) unless $is_empty;

    # walksymtable creates an extra reference to the GV (#197)
    if ( $gv->REFCNT > 1 ) {
        init()->add( sprintf( "SvREFCNT(%s) = %u;", $sym, $gv->REFCNT ) );
    }
    return $sym if $is_empty;

    my $gvrefcnt = $gv->GvREFCNT;
    if ( $gvrefcnt > 1 ) {
        init()->add( sprintf( "GvREFCNT(%s) += %u;", $sym, $gvrefcnt - 1 ) );
    }

    debug( gv => "check which savefields for \"$gvname\"" );

    # some non-alphabetic globs require some parts to be saved
    # ( ex. %!, but not $! )
    if ( $gvname !~ /^([^A-Za-z]|STDIN|STDOUT|STDERR|ARGV|SIG|ENV)$/ ) {
        $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname eq 'main::!' ) {    #Errno
        $savefields = Save_HV | Save_SV | Save_CV;
    }
    elsif ( $fullname eq 'main::ENV' or $fullname eq 'main::SIG' ) {
        $savefields = Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname eq 'main::ARGV' ) {
        $savefields = Save_HV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname =~ /^main::STD(IN|OUT|ERR)$/ ) {
        $savefields = Save_FORM | Save_IO;
    }
    $savefields &= ~$filter if ( $filter
        and $filter !~ m/ :pad/
        and $filter =~ /^\d+$/
        and $filter > 0
        and $filter < 64 );

    # issue 79: Only save stashes for stashes.
    # But not other values to avoid recursion into unneeded territory.
    # We walk via savecv, not via stashes.
    if ( ref($gv) eq 'B::STASHGV' and $gvname !~ /::$/ ) {
        return $sym;
    }

    # attributes::bootstrap is created in perl_parse.
    # Saving it would overwrite it, because perl_init() is
    # called after perl_parse(). But we need to xsload it.
    if ( $fullname eq 'attributes::bootstrap' ) {
        unless ( defined( &{ $package . '::bootstrap' } ) ) {
            verbose("Forcing bootstrap of $package");
            eval { $package->bootstrap };
        }
        mark_package( 'attributes', 1 );
        $savefields &= ~Save_CV;
        $B::C::xsub{attributes} = 'Dynamic-' . $INC{'attributes.pm'};    # XSLoader
        $B::C::use_xsloader = 1;
    }

    # avoid overly dynamic POSIX redefinition warnings: GH #335, #345
    if ( $fullname =~ m/^POSIX::M/ ) {
        $savefields &= ~Save_CV;
    }
    my $gvsv;
    if ($savefields) {

        my $got;
        $got = save_gv_cv( $gv, $savefields, $fullname, $sym, $package, $gvname );
        return $got if $got;

        my $gvav = $gv->AV;
        if ( $$gvav && $savefields & Save_AV ) {
            debug( gv => "GV::save \@$fullname" );
            $gvav->save($fullname);
            init()->add( sprintf( "GvAV(%s) = s\\_%x;", $sym, $$gvav ) );
            if ( $fullname eq 'main::-' ) {
                init()->add(
                    sprintf( "AvFILLp(s\\_%x) = -1;", $$gvav ),
                    sprintf( "AvMAX(s\\_%x) = -1;",   $$gvav )
                );
            }
        }
        my $gvhv = $gv->HV;
        if ( $$gvhv && $savefields & Save_HV ) {
            if ( $fullname ne 'main::ENV' ) {
                debug( gv => "GV::save \%$fullname" );
                if ( $fullname eq 'main::!' ) {    # force loading Errno
                    init()->add("/* \%! force saving of Errno */");
                    mark_package( 'Errno', 1 );    # B::C needs Errno but does not import $!
                }
                elsif ( $fullname eq 'main::+' or $fullname eq 'main::-' ) {
                    init()->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");

                    svref_2object( \&{'Tie::Hash::NamedCapture::bootstrap'} )->save;

                    mark_package( 'Tie::Hash::NamedCapture', 1 );
                }

                # skip static %Encode::Encoding since 5.20. GH #200. sv_upgrade cannot upgrade itself.
                # Let it be initialized by boot_Encode/Encode_XSEncodingm with exceptions.
                # GH #200 and t/testc.sh 75
                if ( $fullname eq 'Encode::Encoding' ) {
                    debug( gv => "skip some %Encode::Encoding - XS initialized" );
                    my %tmp_Encode_Encoding = %Encode::Encoding;
                    %Encode::Encoding = ();    # but we need some non-XS encoding keys
                    for my $k (qw(utf8 utf-8-strict Unicode Internal Guess)) {
                        $Encode::Encoding{$k} = $tmp_Encode_Encoding{$k} if exists $tmp_Encode_Encoding{$k};
                    }
                    $gvhv->save($fullname);
                    init()->add(
                        "/* deferred some XS enc pointers for \%Encode::Encoding */",
                        sprintf( "GvHV(%s) = s\\_%x;", $sym, $$gvhv )
                    );
                    %Encode::Encoding = %tmp_Encode_Encoding;
                }

                # XXX TODO 49: crash at BEGIN { %warnings::Bits = ... }
                elsif ( $fullname ne 'main::INC' ) {
                    $gvhv->save($fullname);
                    init()->add( sprintf( "GvHV(%s) = s\\_%x;", $sym, $$gvhv ) );
                }
            }
        }
        my $gvcv = $gv->CV;
        if ( !$$gvcv and $savefields & Save_CV ) {
            debug( gv => "Empty CV $fullname, AUTOLOAD and try again" );
            no strict 'refs';

            # Fix test 31, catch unreferenced AUTOLOAD. The downside:
            # It stores the whole optree and all its children.
            # Similar with test 39: re::is_regexp
            svref_2object( \*{"$package\::AUTOLOAD"} )->save
              if $package and exists ${"$package\::"}{AUTOLOAD};
            svref_2object( \*{"$package\::CLONE"} )->save
              if $package and exists ${"$package\::"}{CLONE};
            $gvcv = $gv->CV;    # try again
        }

        # Can't locate object method "EGV" via package "B::SPECIAL" at /usr/local/cpanel/3rdparty/perl/520/lib/perl5/cpanel_lib/i386-linux-64int/B/C/OverLoad/B/GV.pm line 450.
        if (    $$gvcv
            and $savefields & Save_CV
            and ref($gvcv) eq 'B::CV'
            and ref( $gvcv->GV ) ne 'B::SPECIAL'
            and ref( $gvcv->GV->EGV ) ne 'B::SPECIAL'
            and !B::C::skip_pkg($package) ) {
            my $package  = $gvcv->GV->EGV->STASH->NAME;
            my $oname    = $gvcv->GV->EGV->NAME;
            my $origname = $package . "::" . $oname;
            my $cvsym;
            if ( $gvcv->XSUB and $oname ne '__ANON__' and $fullname ne $origname ) {    #XSUB CONSTSUB alias

                debug( pkg => "Boot $package, XS CONSTSUB alias of $fullname to $origname" );
                mark_package( $package, 1 );
                {
                    no strict 'refs';
                    svref_2object( \&{"$package\::bootstrap"} )->save
                      if $package and defined &{"$package\::bootstrap"};
                }

                # XXX issue 57: incomplete xs dependency detection
                my %hack_xs_detect = (
                    'Scalar::Util'  => 'List::Util',
                    'Sub::Exporter' => 'Params::Util',
                );
                if ( my $dep = $hack_xs_detect{$package} ) {
                    svref_2object( \&{"$dep\::bootstrap"} )->save;
                }

                # must save as a 'stub' so newXS() has a CV to populate
                debug( gv => "save stub CvGV for $sym GP assignments $origname" );
                init2()->add(
                    sprintf( "if ((sv = (SV*)%s))",                                get_cv_string( $origname, "GV_ADD" ) ),
                    sprintf( "    GvCV_set(%s, (CV*)SvREFCNT_inc_simple_NN(sv));", $sym )
                );
            }
            elsif ($gp) {
                if ( $fullname eq 'Internals::V' ) {
                    $gvcv = svref_2object( \&__ANON__::_V );
                }

                # TODO: may need fix CvGEN if >0 to re-validate the CV methods
                # on PERL510 (>0 + <subgeneration)
                debug( gv => "GV::save &$fullname..." );
                $cvsym = $gvcv->save($fullname);

                # backpatch "$sym = gv_fetchpv($name, GV_ADD, SVt_PV)" to SVt_PVCV
                if ( $cvsym =~ /get_cv/ ) {
                    if ( !$B::C::xsub{$package} and B::C::in_static_core( $package, $gvname ) ) {
                        my $in_gv;
                        for ( @{ init()->{current} } ) {
                            if ($in_gv) {
                                s/^.*\Q$sym\E.*=.*;//;
                                s/GvGP_set\(\Q$sym\E.*;//;
                            }
                            if (/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/) {
                                s/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/$sym = gv_fetchpv($name, GV_ADD, SVt_PVCV);/;
                                $in_gv++;
                                debug( gv => "removed $sym GP assignments $origname (core CV)" );
                            }
                        }
                        init()->add( sprintf( "GvCV_set(%s, (CV*)SvREFCNT_inc(%s));", $sym, $cvsym ) );
                    }
                    elsif ( $B::C::xsub{$package} ) {

                        # must save as a 'stub' so newXS() has a CV to populate later in dl_init()
                        debug( gv => "save stub CvGV for $sym GP assignments $origname (XS CV)" );
                        my $get_cv = get_cv_string( $oname ne "__ANON__" ? $origname : $fullname, "GV_ADD" );
                        init2()->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN($get_cv));");
                        init2()->add(
                            sprintf( "if ((sv = (SV*)%s))",                                $get_cv ),
                            sprintf( "    GvCV_set(%s, (CV*)SvREFCNT_inc_simple_NN(sv));", $sym )
                        );
                    }
                    else {
                        init()->add( sprintf( "GvCV_set(%s, (CV*)(%s));", $sym, $cvsym ) );
                    }

                    if ( $gvcv->XSUBANY ) {

                        # some XSUB's set this field. but which part?
                        my $xsubany = $gvcv->XSUBANY;
                        if ( $package =~ /^DBI::(common|db|dr|st)/ ) {

                            # DBI uses the any_ptr for dbi_ima_t *ima, and all dr,st,db,fd,xx handles
                            # for which several ptrs need to be patched. #359
                            # the ima is internal only
                            my $dr = $1;
                            debug( cv => "eval_pv: DBI->_install_method(%s-) (XSUBANY=0x%x)", $fullname, $xsubany );
                            init2()->add_eval(
                                sprintf(
                                    "DBI->_install_method('%s', 'DBI.pm', \$DBI::DBI_methods{%s}{%s})",
                                    $fullname, $dr, $fullname
                                )
                            );
                        }
                        elsif ( $package eq 'Tie::Hash::NamedCapture' ) {

                            # pretty high _ALIAS CvXSUBANY.any_i32 values
                        }
                        else {
                            # try if it points to an already registered symbol
                            my $anyptr = objsym( \$xsubany );    # ...refactored...
                            if ( $anyptr and $xsubany > 1000 ) { # not a XsubAliases
                                init2()->add( sprintf( "CvXSUBANY(GvCV(%s)).any_ptr = &%s;", $sym, $anyptr ) );
                            }    # some heuristics TODO. long or ptr? TODO 32bit
                            elsif ( $xsubany > 0x100000 and ( $xsubany < 0xffffff00 or $xsubany > 0xffffffff ) ) {
                                if ( $package eq 'POSIX' and $gvname =~ /^is/ ) {

                                    # need valid XSANY.any_dptr
                                    init2()->add( sprintf( "CvXSUBANY(GvCV(%s)).any_dptr = (void*)&%s;", $sym, $gvname ) );
                                }
                                elsif ( $package eq 'List::MoreUtils' and $gvname =~ /_iterator$/ ) {    # should be only the 2 iterators
                                    init2()->add("CvXSUBANY(GvCV($sym)).any_ptr = (void*)&XS_List__MoreUtils__${gvname};");
                                }
                                else {
                                    verbose( sprintf( "TODO: Skipping %s->XSUBANY = 0x%x", $fullname, $xsubany ) );
                                    init2()->add( sprintf( "/* TODO CvXSUBANY(GvCV(%s)).any_ptr = 0x%lx; */", $sym, $xsubany ) );
                                }
                            }
                            elsif ( $package eq 'Fcntl' ) {

                                # S_ macro values
                            }
                            else {
                                # most likely any_i32 values for the XsubAliases provided by xsubpp
                                init2()->add( sprintf( "/* CvXSUBANY(GvCV(%s)).any_i32 = 0x%x; XSUB Alias */", $sym, $xsubany ) );
                            }
                        }
                    }
                }
                elsif ( $cvsym =~ /^(cv|&sv_list)/ ) {
                    init()->add( sprintf( "GvCV_set(%s, (CV*)(%s));", $sym, $cvsym ) );
                }
                else {
                    WARN("wrong CvGV for $sym $origname: $cvsym") if debug('gv') or verbose();
                }
            }

            # special handling for backref magic
            if ( $cvsym and $cvsym !~ /(get_cv|NULL|lexwarn)/ and $gv->MAGICAL ) {
                my @magic = $gv->MAGIC;
                foreach my $mg (@magic) {
                    init()->add(
                        "sv_magic((SV*)$sym, (SV*)$cvsym, '<', 0, 0);",
                        "CvCVGV_RC_off($cvsym);"
                    ) if $mg->TYPE eq '<';
                }
            }
        }
        if ($gp) {

            if ( !$B::C::stash or $fullname !~ /::$/ ) {

                my $file = save_hek( $gv->FILE );
                init()->add( sprintf( "GvFILE_HEK(%s) = %s;", $sym, $file ) )
                  if $file ne 'NULL' and !$B::C::optimize_cop;
            }

            # init()->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;

            my $gvform = $gv->FORM;
            if ( $$gvform && $savefields & Save_FORM ) {
                debug( gv => "GV::save GvFORM(*$fullname) ..." );
                $gvform->save($fullname);
                init()->add( sprintf( "GvFORM(%s) = (CV*)s\\_%x;", $sym, $$gvform ) );

                # glob_assign_glob analog to CV
                init()->add( sprintf( "SvREFCNT_inc(s\\_%x);", $$gvform ) );
                debug( gv => "GV::save GvFORM(*$fullname) done" );
            }

            save_io( $gv, $fullname, $sym ) if $savefields & Save_IO;

        }
    }

    # Shouldn't need to do save_magic since gv_fetchpv handles that. Esp. < and IO not
    # $gv->save_magic($fullname) if $PERL510;
    debug( gv => "GV::save *$fullname done" );
    return $sym;
}

sub gv_fetchpv_string {
    my ( $name, $flags, $type ) = @_;
    warn 'undefined flags' unless defined $flags;
    warn 'undefined type'  unless defined $type;
    my ( $cname, $cur, $utf8 ) = strlen_flags($name);

    $flags .= length($flags) ? "|$utf8" : $utf8 if $utf8;
    return "gv_fetchpvn_flags($cname, $cur, $flags, $type)";
}

sub save_gv_cv {
    my ( $gv, $savefields, $fullname, $sym, $package, $gvname ) = @_;

    # Don't save subfields of special GVs (*_, *1, *# and so on)
    debug( gv => "GV::save saving subfields $savefields" );
    my $gvsv = $gv->SV;
    if ( $$gvsv && $savefields & Save_SV ) {
        debug( gv => "GV::save \$" . $sym . " $gvsv" );
        my $core_svs = {    # special SV syms to assign to the right GvSV
            "\\" => 'PL_ors_sv',
            "/"  => 'PL_rs',
            "@"  => 'PL_errors',
        };
        for my $s ( sort keys %$core_svs ) {
            if ( $fullname eq 'main::' . $s ) {
                savesym( $gvsv, $core_svs->{$s} );    # TODO: This could bypass BEGIN settings (->save is ignored)
            }
        }
        if ( $gvname eq 'VERSION' and $B::C::xsub{$package} and $gvsv->FLAGS & SVf_ROK ) {
            debug( gv => "Strip overload from $package\::VERSION, fails to xs boot (issue 91)" );
            my $rv     = $gvsv->object_2svref();
            my $origsv = $$rv;
            no strict 'refs';
            ${$fullname} = "$origsv";
            svref_2object( \${$fullname} )->save($fullname);
            init()->add( sprintf( "GvSVn(%s) = (SV*)s\\_%x;", $sym, $$gvsv ) );
        }
        else {
            $gvsv->save($fullname);    #even NULL save it, because of gp_free nonsense
                                       # we need sv magic for the core_svs (PL_rs -> gv) (#314)
            if ( exists $core_svs->{$gvname} ) {
                if ( $gvname eq "\\" ) {    # ORS special case #318 (initially NULL)
                    return $sym;
                }
                else {
                    $gvsv->save_magic($fullname) if ref($gvsv) eq 'B::PVMG';
                    init()->add( sprintf( "SvREFCNT(s\\_%x) += 1;", $$gvsv ) );
                }
            }
            init()->add( sprintf( "GvSVn(%s) = (SV*)s\\_%x;", $sym, $$gvsv ) );
        }
        if ( $fullname eq 'main::$' ) {     # $$ = PerlProc_getpid() issue #108
            debug( gv => "  GV $sym \$\$ perlpid" );
            init()->add("sv_setiv(GvSV($sym), (IV)PerlProc_getpid());");
        }
        debug( gv => "GV::save \$$fullname" );
    }
    return;
}

sub save_io {
    my ( $gv, $fullname, $sym ) = @_;

    my $gvio = $gv->IO;

    debug( gv => "GV::save GvIO(*$fullname)..." );
    if ( $fullname =~ m/::DATA$/
        && ( $fullname eq 'main::DATA' or $B::C::save_data_fh ) )    # -O2 or 5.8
    {
        no strict 'refs';
        my $fh = *{$fullname}{IO};
        use strict 'refs';
        debug( gv => "GV::save_data $sym, $fullname ..." );
        $gvio->save( $fullname, 'is_DATA' );
        $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
    }
    elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
        $gvio->save( $fullname, 'is_DATA' );
    }
    else {
        $gvio->save($fullname);

    }

    init()->add( sprintf( "GvIOp(%s) = s\\_%x;", $sym, $$gvio ) );
    debug( gv => "GV::save GvIO(*$fullname) done" );

    return;
}

1;
