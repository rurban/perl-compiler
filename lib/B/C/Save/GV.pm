package B::GV;

use strict;

use Config;
use B qw/cstring svref_2object SVt_PVGV SVf_ROK/;
use B::C::File qw/init init2/;
use B::C::Helpers qw/mark_package/;
use B::C::Helpers::Symtable qw/objsym savesym/;

my %gptable;
my $gv_index = 0;

sub get_index {
    return $gv_index;
}

sub inc_index {
    return $gv_index++;
}

sub Save_HV()   { 1 }
sub Save_AV()   { 2 }
sub Save_SV()   { 4 }
sub Save_CV()   { 8 }
sub Save_FORM() { 16 }
sub Save_IO()   { 32 }

sub save {
    my ( $gv, $filter ) = @_;
    my $sym = objsym($gv);
    if ( defined($sym) ) {
        warn sprintf( "GV 0x%x already saved as $sym\n", $$gv ) if $B::C::debug{gv};
        return $sym;
    }
    else {
        my $ix = inc_index();
        $sym = savesym( $gv, "gv_list[$ix]" );
        warn sprintf( "Saving GV 0x%x as $sym\n", $$gv ) if $B::C::debug{gv};
    }

    warn sprintf(
        "  GV %s $sym type=%d, flags=0x%x %s\n", $gv->NAME,

        # B::SV::SvTYPE not with 5.6
        B::SV::SvTYPE($gv), $gv->FLAGS
    ) if $B::C::debug{gv};

    if ( $gv->FLAGS & 0x40000000 ) {    # SVpbm_VALID
        warn sprintf("  GV $sym isa FBM\n") if $B::C::debug{gv};
        return B::BM::save($gv);
    }

    my $gvname = $gv->NAME;
    my $package;
    if ( ref( $gv->STASH ) eq 'B::SPECIAL' ) {
        $package = '__ANON__';
        warn sprintf("GV STASH = SPECIAL $gvname\n") if $B::C::debug{gv};
    }
    else {
        $package = $gv->STASH->NAME;
    }
    return $sym if B::C::skip_pkg($package);

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
    if ( $fullname =~ /^threads::(tid|AUTOLOAD)$/ and B::C::USE_ITHREADS() ) {
        $filter = 8;
    }

    my $is_empty = $gv->is_empty;
    if ( !defined $gvname and $is_empty ) {    # 5.8 curpad name
        return q/(SV*)&PL_sv_undef/;
    }
    my $name    = $package eq 'main' ? cstring($gvname) : cstring($fullname);
    my $notqual = $package eq 'main' ? 'GV_NOTQUAL'     : '0';
    warn "  GV name is $fancyname\n" if $B::C::debug{gv};
    my $egvsym;
    my $is_special = ref($gv) eq 'B::SPECIAL';

    if ( $fullname =~ /^(bytes|utf8)::AUTOLOAD$/ ) {
        $gv = B::C::force_heavy($package);     # defer to run-time autoload, or compile it in?
        $sym = savesym( $gv, $sym );           # override new gv ptr to sym
    }
    if ( !$is_empty ) {
        my $egv = $gv->EGV;
        unless ( ref($egv) eq 'B::SPECIAL' or ref( $egv->STASH ) eq 'B::SPECIAL' ) {
            my $estash = $egv->STASH->NAME;
            if ( $$gv != $$egv ) {
                warn(
                    sprintf(
                        "EGV name is %s, saving it now\n",
                        $estash . "::" . $egv->NAME
                    )
                ) if $B::C::debug{gv};
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
        init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
        return $sym;
    }
    elsif ( $fullname eq 'main::0' ) {                 # dollar_0 already handled before, so don't overwrite it
        init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PV);]);
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
        return $sym;
    }

    # gv_fetchpv loads Errno resp. Tie::Hash::NamedCapture, but needs *INC #90
    #elsif ( $fullname eq 'main::!' or $fullname eq 'main::+' or $fullname eq 'main::-') {
    #  init2()->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PVGV);]); # defer until INC is setup
    #  init2()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    #  return $sym;
    #}
    my $svflags    = $gv->FLAGS;
    my $savefields = 0;

    my $gp;
    my $gvadd = $notqual ? "$notqual|GV_ADD" : "GV_ADD";
    if ( $gv->isGV_with_GP and !$is_coresym ) {
        $gp = $gv->GP;    # B limitation
                          # warn "XXX EGV='$egvsym' for IMPORTED_HV" if $gv->GvFLAGS & 0x40;
        if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
            warn(
                sprintf(
                    "Shared GV alias for *$fullname 0x%x%s %s to $egvsym\n",
                    $svflags, $B::C::debug{flags} ? "(" . $gv->flagspv . ")" : "",
                )
            ) if $B::C::debug{gv};

            # Shared glob *foo = *bar
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd|GV_ADDMULTI, SVt_PVGV);]);
            init()->add("GvGP_set($sym, GvGP($egvsym));");
            $is_empty = 1;
        }
        elsif ( $gp and exists $gptable{ 0 + $gp } ) {
            warn(
                sprintf(
                    "Shared GvGP for *$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $B::C::debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $B::C::debug{gv};
            init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
            init()->add( sprintf( "GvGP_set($sym, %s);", $gptable{ 0 + $gp } ) );
            $is_empty = 1;
        }
        elsif ( $gp and !$is_empty and $gvname =~ /::$/ ) {
            warn(
                sprintf(
                    "Shared GvGP for stash %$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $B::C::debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $B::C::debug{gv};
            init()->add(qq[$sym = gv_fetchpv($name, GV_ADD, SVt_PVHV);]);
            $gptable{ 0 + $gp } = "GvGP($sym)" if 0 + $gp;
        }
        elsif ( $gp and !$is_empty ) {
            warn(
                sprintf(
                    "New GV for *$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $B::C::debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $B::C::debug{gv};

            # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
            $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
            $gptable{ 0 + $gp } = "GvGP($sym)";
        }
        else {
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PVGV);]);
        }
    }
    elsif ( !$is_coresym ) {
        init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
    }
    my $gvflags = $gv->GvFLAGS;

    init()->add(
        sprintf(
            "SvFLAGS($sym) = 0x%x;%s", $svflags,
            $B::C::debug{flags} ? " /* " . $gv->flagspv . " */" : ""
        ),
        sprintf(
            "GvFLAGS($sym) = 0x%x; %s", $gvflags,
            $B::C::debug{flags} ? "/* " . $gv->flagspv(SVt_PVGV) . " */" : ""
        )
    );
    init()->add(
        sprintf(
            "GvLINE($sym) = %d;",
            (
                $gv->LINE > 2147483647    # S32 INT_MAX
                ? 4294967294 - $gv->LINE
                : $gv->LINE
            )
        )
    ) unless $is_empty;

    # walksymtable creates an extra reference to the GV (#197)
    if ( $gv->REFCNT > 1 ) {
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    }
    return $sym if $is_empty;

    my $gvrefcnt = $gv->GvREFCNT;
    if ( $gvrefcnt > 1 ) {
        init()->add( sprintf( "GvREFCNT($sym) += %u;", $gvrefcnt - 1 ) );
    }

    warn "check which savefields for \"$gvname\"\n" if $B::C::debug{gv};

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
            warn "Forcing bootstrap of $package\n" if B::C::verbose();
            eval { $package->bootstrap };
        }
        mark_package( 'attributes', 1 );
        $savefields &= ~Save_CV;
        $B::C::xsub{attributes} = 'Dynamic-' . $INC{'attributes.pm'};    # XSLoader
        $B::C::use_xsloader = 1;
    }

    my $gvsv;
    if ($savefields) {

        # Don't save subfields of special GVs (*_, *1, *# and so on)
        warn "GV::save saving subfields $savefields\n" if $B::C::debug{gv};
        $gvsv = $gv->SV;
        if ( $$gvsv && $savefields & Save_SV ) {
            warn "GV::save \$" . $sym . " $gvsv\n" if $B::C::debug{gv};
            my $core_svs = {                                             # special SV syms to assign to the right GvSV
                "\\" => 'PL_ors_sv',
                "/"  => 'PL_rs',
                "@"  => 'PL_errors',
            };
            for my $s ( sort keys %$core_svs ) {
                if ( $fullname eq 'main::' . $s ) {
                    savesym( $gvsv, $core_svs->{$s} );                   # TODO: This could bypass BEGIN settings (->save is ignored)
                }
            }
            if ( $gvname eq 'VERSION' and $B::C::xsub{$package} and $gvsv->FLAGS & SVf_ROK ) {
                warn "Strip overload from $package\::VERSION, fails to xs boot (issue 91)\n" if $B::C::debug{gv};
                my $rv     = $gvsv->object_2svref();
                my $origsv = $$rv;
                no strict 'refs';
                ${$fullname} = "$origsv";
                svref_2object( \${$fullname} )->save($fullname);
                init()->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
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
                init()->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
            }
            if ( $fullname eq 'main::$' ) {     # $$ = PerlProc_getpid() issue #108
                warn sprintf("  GV $sym \$\$ perlpid\n") if $B::C::debug{gv};
                init()->add("sv_setiv(GvSV($sym), (IV)PerlProc_getpid());");
            }
            warn "GV::save \$$fullname\n" if $B::C::debug{gv};
        }
        my $gvav = $gv->AV;
        if ( $$gvav && $savefields & Save_AV ) {
            warn "GV::save \@$fullname\n" if $B::C::debug{gv};
            $gvav->save($fullname);
            init()->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
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
                warn "GV::save \%$fullname\n" if $B::C::debug{gv};
                if ( $fullname eq 'main::!' ) {    # force loading Errno
                    init()->add("/* \%! force saving of Errno */");
                    mark_package( 'Config', 1 );    # Errno needs Config to set the EGV
                    B::C::walk_syms('Config');
                    mark_package( 'Errno', 1 );     # B::C needs Errno but does not import $!
                }
                elsif ( $fullname eq 'main::+' or $fullname eq 'main::-' ) {
                    init()->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");

                    mark_package( 'Config', 1 );    # DynaLoader needs Config to set the EGV
                    B::C::walk_syms('Config');
                    svref_2object( \&{'Tie::Hash::NamedCapture::bootstrap'} )->save;

                    mark_package( 'Tie::Hash::NamedCapture', 1 );
                }

                # XXX TODO 49: crash at BEGIN { %warnings::Bits = ... }
                if ( $fullname ne 'main::INC' ) {
                    $gvhv->save($fullname);
                    init()->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
                }
            }
        }
        my $gvcv = $gv->CV;
        if ( !$$gvcv and $savefields & Save_CV ) {
            warn "Empty CV $fullname, AUTOLOAD and try again\n" if $B::C::debug{gv};
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
        if (    $$gvcv
            and $savefields & Save_CV
            and ref($gvcv) eq 'B::CV'
            and ref( $gvcv->GV->EGV ) ne 'B::SPECIAL'
            and !B::C::skip_pkg($package) ) {
            my $origname = $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME;
            my $cvsym;
            if ( $gvcv->XSUB and $fullname ne $origname ) {    #XSUB CONSTSUB alias
                my $package = $gvcv->GV->EGV->STASH->NAME;
                $origname = cstring($origname);
                warn "Boot $package, XS CONSTSUB alias of $fullname to $origname\n" if $B::C::debug{pkg};
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
                init2()->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
            }
            elsif ($gp) {
                $origname = cstring($origname);
                if ( $fullname eq 'Internals::V' ) {
                    $gvcv = svref_2object( \&__ANON__::_V );
                }

                # TODO: may need fix CvGEN if >0 to re-validate the CV methods
                # on PERL510 (>0 + <subgeneration)
                warn "GV::save &$fullname...\n" if $B::C::debug{gv};
                $cvsym = $gvcv->save($fullname);

                # backpatch "$sym = gv_fetchpv($name, GV_ADD, SVt_PV)" to SVt_PVCV
                if ( $cvsym =~ /(\(char\*\))?get_cv\("/ ) {
                    if ( !$B::C::xsub{$package} and B::C::in_static_core( $package, $gvname ) ) {
                        my $in_gv;
                        for ( @{ init()->[-1]{current} } ) {
                            if ($in_gv) {
                                s/^.*\Q$sym\E.*=.*;//;
                                s/GvGP_set\(\Q$sym\E.*;//;
                            }
                            if (/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/) {
                                s/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/$sym = gv_fetchpv($name, GV_ADD, SVt_PVCV);/;
                                $in_gv++;
                                warn "removed $sym GP assignments $origname (core CV)\n" if $B::C::debug{gv};
                            }
                        }
                        init()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                    }
                    elsif ( $B::C::xsub{$package} ) {

                        # must save as a 'stub' so newXS() has a CV to populate later in dl_init()
                        warn "save stub CvGV for $sym GP assignments $origname (XS CV)\n" if $B::C::debug{gv};
                        init2()->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
                    }
                    else {
                        init2()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                    }
                }
                elsif ( $cvsym =~ /^(cv|&sv_list)/ ) {
                    init()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                }
                else {
                    warn "wrong CvGV for $sym $origname: $cvsym\n" if $B::C::debug{gv} or B::C::verbose();
                }
            }

            # special handling for backref magic
            if ( $cvsym and $cvsym !~ /(get_cv\("|NULL|lexwarn)/ and $gv->MAGICAL ) {
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

            # TODO implement heksect to place all heks at the beginning
            #heksect()->add($gv->FILE);
            #init()->add(sprintf("GvFILE_HEK($sym) = hek_list[%d];", heksect()->index));

            # XXX Maybe better leave it NULL or asis, than fighting broken
            if ( $B::C::stash and $fullname =~ /::$/ ) {

                # ignore stash hek asserts when adding the stash
                # he->shared_he_he.hent_hek == hek assertions (#46 with IO::Poll::)
            }
            else {
                init()->add( sprintf( "GvFILE_HEK($sym) = %s;", B::C::save_hek( $gv->FILE ) ) )
                  if !$B::C::optimize_cop;
            }

            # init()->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;

            my $gvform = $gv->FORM;
            if ( $$gvform && $savefields & Save_FORM ) {
                warn "GV::save GvFORM(*$fullname) ...\n" if $B::C::debug{gv};
                $gvform->save($fullname);
                init()->add( sprintf( "GvFORM($sym) = (CV*)s\\_%x;", $$gvform ) );

                # glob_assign_glob analog to CV
                init()->add( sprintf( "SvREFCNT_inc(s\\_%x);", $$gvform ) );
                warn "GV::save GvFORM(*$fullname) done\n" if $B::C::debug{gv};
            }
            my $gvio = $gv->IO;
            if ( $$gvio && $savefields & Save_IO ) {
                warn "GV::save GvIO(*$fullname)...\n" if $B::C::debug{gv};
                if ( $fullname =~ m/::DATA$/
                    && ( $fullname eq 'main::DATA' or $B::C::save_data_fh ) )    # -O2 or 5.8
                {
                    no strict 'refs';
                    my $fh = *{$fullname}{IO};
                    use strict 'refs';
                    warn "GV::save_data $sym, $fullname ...\n" if $B::C::debug{gv};
                    $gvio->save( $fullname, 'is_DATA' );
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                    $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
                }
                elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
                    $gvio->save( $fullname, 'is_DATA' );
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                    warn "Warning: __DATA__ handle $fullname not stored. Need -O2 or -fsave-data.\n";
                }
                else {
                    $gvio->save($fullname);
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                }
                warn "GV::save GvIO(*$fullname) done\n" if $B::C::debug{gv};
            }
            init()->add("");
        }
    }

    # Shouldn't need to do save_magic since gv_fetchpv handles that. Esp. < and IO not
    # $gv->save_magic($fullname) if $PERL510;
    warn "GV::save *$fullname done\n" if $B::C::debug{gv};
    return $sym;
}

1;
