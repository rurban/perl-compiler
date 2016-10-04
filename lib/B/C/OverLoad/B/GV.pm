package B::GV;

use strict;

use B qw/cstring svref_2object SVt_PVGV SVf_ROK SVf_UTF8/;

use B::C::Config;
use B::C::Save::Hek qw/save_hek/;
use B::C::Packages qw/is_package_used/;
use B::C::File qw/init init2 gvsect xpvgvsect/;
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

my $CORE_SYMS = {
    'main::ENV'    => 'PL_envgv',
    'main::ARGV'   => 'PL_argvgv',
    'main::INC'    => 'PL_incgv',
    'main::STDIN'  => 'PL_stdingv',
    'main::STDERR' => 'PL_stderrgv',
    "main::\010"   => 'PL_hintgv',     # ^H
    "main::_"      => 'PL_defgv',
    "main::@"      => 'PL_errgv',
    "main::\022"   => 'PL_replgv',     # ^R
};

sub get_package {
    my $gv = shift;

    if ( ref( $gv->STASH ) eq 'B::SPECIAL' ) {
        return '__ANON__';
    }

    return $gv->STASH->NAME;
}

sub is_coresym {
    my $gv = shift;

    return $CORE_SYMS->{ $gv->get_fullname() } ? 1 : 0;
}

sub get_fullname {
    my $gv = shift;

    return $gv->get_package() . "::" . $gv->NAME();
}

# FIXME todo and move later to B/GP.pm ?
sub B::GP::save {
    my ( $gp, $gv, $filter ) = @_;
    return 'NULL';

    my $gvname   = $gv->NAME;
    my $fullname = $gv->get_fullname;

    my $gpsym = objsym($gp);
    return $gpsym if defined $gpsym;

    # gp fields initializations
    # gp_cvgen: not set, no B api ( could be done in init section )
    my ( $gp_sv, $gp_io, $gp_cv, $gp_cvgen, $gp_hv, $gp_av, $gp_form, $gp_egv ) = ( 'NULL', 'NULL', 'NULL', 0, 'NULL', 'NULL', 'NULL', 'NULL' );

    # walksymtable creates an extra reference to the GV (#197)
    my $gp_refcount = $gv->GvREFCNT - 1;    # +1 for immortal ?

    my $gp_line = $gv->GvLINE;

    # present only in perl 5.22.0 and higher. this flag seems unused ( saving 0 for now should be similar )
    my $gp_flags = $gv->GvGPFLAGS;          # PERL_BITFIELD32 gp_flags:1; ~ unsigned gp_flags:1
    die("gp_flags seems used now ???") if $gp_flags;

    my $gp_file_hek = q{NULL};
    if ( ( !$B::C::stash or $fullname !~ /::$/ ) and $gv->FILEGV ne 'NULL' ) {    # and !$B::C::optimize_cop
        $gp_file_hek = $gv->FILEGV;                                               # Reini was using FILE instead of FILEGV ?
    }

    # getting the value when possible
    my $savefields = get_savefields( $gv, $gvname, $fullname, $filter );

    $gp_av = save_gv_av( $gv, $fullname ) if $savefields & Save_AV;

    # ....
    # ....

    gpsect()->comment('SV, gp_io, CV, cvgen, gp_refcount, HV, AV, CV, GV, line, flags, HEK* file');

    gpsect()->add(
        sprintf(
            "%s, %s, %s, %d, %u, %s, %s, %s, %s, %u, %d, %s",
            $gp_sv,   $gp_io,    $gp_cv, $gp_cvgen, $gp_refcount, $gp_hv, $gp_av, $gp_form, $gp_egv,
            $gp_line, $gp_flags, $gp_file_hek
        )
    );

    return savesym( $gp, "&gp_list[%d]", gpsect()->index );
}

sub save {
    my ( $gv, $filter ) = @_;

    {    # cache lookup
        my $gvsym = objsym($gv);
        return $gvsym if defined $gvsym;
        debug( gv => "Saving GV 0x%x as $gvsym", ref $gv ? $$gv : 0 );
    }

    # GV $sym isa FBM
    return B::BM::save($gv) if $gv->FLAGS & 0x40000000;    # SVpbm_VALID

    my $package = get_package($gv);
    return q/(SV*)&PL_sv_undef/ if B::C::skip_pkg($package);

    my $gpsym      = 'NULL';
    my $is_coresym = $gv->is_coresym();

    if ( $gv->isGV_with_GP and !$is_coresym ) {
        my $gp = $gv->GP;                                  # B limitation
        $gpsym = B::GP::save( $gp, $gv, $filter );         # might be $gp->save( )
    }

    # # head
    # HV*         xmg_stash;      /* class package */                     \
    # union _xmgu xmg_u;                                                  \
    # STRLEN      xpv_cur;        /* length of svu_pv as a C string */    \
    # union {                                                             \
    #     STRLEN  xpvlenu_len;    /* allocated size */                    \
    #     char *  xpvlenu_pv;     /* regexp string */                     \
    # } xpv_len_u
    # union _xivu xiv_u;
    # union _xnvu xnv_u;
    #my $stash = $gv->STASH;
    xpvgvsect()->comment("stash, magic, cur, len, xiv_u={.xivu_namehek=}, xnv_u={.xgv_stash=}");
    xpvgvsect()->add(
        sprintf(
            "Nullhv, {0}, 0, {.xpvlenu_len=0}, {.xivu_namehek=%s}, {.xgv_stash=%s}",
            'NULL', 'Nullhv'
        )
    );
    my $xpvgv = sprintf( 'xpvgv_list[%d]', xpvgvsect()->index );

    {
        my $gv_refcnt = $gv->REFCNT;    # TODO probably need more love for both refcnt (+1 ? extra flag immortal)
        my $gv_flags  = $gv->FLAGS;

        gvsect()->comment("XPVGV*  sv_any,  U32     sv_refcnt; U32     sv_flags; union   { gp* } sv_u # gp*");
        gvsect()->add( sprintf( "&%s, %u, 0x%x, %s", $xpvgv, $gv_refcnt, $gv_flags, $gpsym ) );
    }

    my $sym = savesym( $gv, sprintf( '&gv_list[%d]', gvsect()->index ) );
    my $gvsym = $sym;
    $gvsym =~ s{^&}{};

    #my ( $gv, $filter, $sym ) = @_;

    # my $ix = inc_index();
    # $sym = savesym( $gv, "gv_list[$ix]" );
    # debug( gv => "Saving GV 0x%x as $sym", ref $gv ? $$gv : 0 );

    my $gvname = $gv->NAME();

    my $package = $gv->get_package();

    # If we come across a stash hash, we therefore have code using it so we need to mark it was used so it won't be deleted.
    if ( $gvname =~ m/::$/ ) {
        my $pkg = $gvname;
        $pkg =~ s/::$//;
        mark_package_used($pkg);
    }

    my $fullname = $gv->get_fullname();

    my $is_empty = $gv->is_empty;
    if ( !defined $gvname and $is_empty ) {    # 5.8 curpad name
        return q/(SV*)&PL_sv_undef/;
    }
    my $name    = $package eq 'main' ? $gvname          : $fullname;
    my $cname   = $package eq 'main' ? cstring($gvname) : cstring($fullname);
    my $notqual = $package eq 'main' ? 'GV_NOTQUAL'     : '0';

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

    # those are already initialized in init_predump_symbols()
    # and init_main_stash()
    if ( $CORE_SYMS->{$fullname} ) {
        $sym = savesym( $gv, $CORE_SYMS->{$fullname} );
        $is_coresym++;
    }

    if ( $fullname =~ /^main::std(in|out|err)$/ ) {    # same as uppercase above
        init()->add(qq[$gvsym = *(GV*) gv_fetchpv($cname, $notqual, SVt_PVGV);]);
        return $sym;
    }
    elsif ( $fullname eq 'main::0' ) {                 # dollar_0 already handled before, so don't overwrite it
        init()->add(qq[$gvsym = *(GV*) gv_fetchpv($cname, $notqual, SVt_PV);]);
        return $sym;
    }

    # gv_fetchpv loads Errno resp. Tie::Hash::NamedCapture, but needs *INC #90
    #elsif ( $fullname eq 'main::!' or $fullname eq 'main::+' or $fullname eq 'main::-') {
    #  init1()->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PVGV);]); # defer until INC is setup
    #  return $sym;
    #}
    my $svflags = $gv->FLAGS;

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
            init()->add( "$gvsym = *(GV*) " . gv_fetchpv_string( $name, "$gvadd|GV_ADDMULTI", 'SVt_PVGV' ) . ";" );
            init()->add("GvGP_set($sym, GvGP($egvsym));");
            $is_empty = 1;
        }
        elsif ( $gp and exists $gptable{ 0 + $gp } ) {
            init()->add( "$gvsym = *(GV*)" . gv_fetchpv_string( $name, $notqual, 'SVt_PVGV' ) . ";" );
            init()->add( sprintf( "GvGP_set(%s, %s);", $sym, $gptable{ 0 + $gp } ) );
            $is_empty = 1;
        }
        elsif ( $gp and !$is_empty and $gvname =~ /::$/ ) {
            init()->add( "$gvsym = *(GV*)" . gv_fetchpv_string( $name, 'GV_ADD', 'SVt_PVHV' ) . ";" );
            $gptable{ 0 + $gp } = "GvGP($sym)" if 0 + $gp;
        }
        elsif ( $gp and !$is_empty ) {

            # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
            init()->add( "$gvsym = *(GV*)" . gv_fetchpv_string( $name, $gvadd, 'SVt_PV' ) . ";" );
            $gptable{ 0 + $gp } = "GvGP($sym)";
        }
        else {
            init()->add( "$gvsym = *(GV*)" . gv_fetchpv_string( $name, $gvadd, 'SVt_PVGV' ) . ";" );
        }
    }
    elsif ( !$is_coresym ) {
        init()->add( "$gvsym = *(GV*)" . gv_fetchpv_string( $name, $gvadd, 'SVt_PV' ) . ";" );
    }

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

    return $sym if $is_empty;

    debug( gv => "check which savefields for \"$gvname\"" );

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
        $B::C::xsub{attributes} = 'Dynamic-' . $INC{'attributes.pm'};    # XSLoader
        $B::C::use_xsloader = 1;
    }

    my $savefields = get_savefields( $gv, $gvname, $fullname, $filter );

    if ($savefields) {

        my $got;
        $got = save_gv_sv( $gv, $fullname, $sym, $package, $gvname ) if $savefields & Save_SV;
        return $got if $got;

        save_gv_av( $gv, $fullname, $sym ) if $savefields & Save_AV;

        save_gv_hv( $gv, $fullname, $sym, $gvname ) if $savefields & Save_HV;

        save_gv_cv( $gv, $savefields, $fullname, $package, $sym, $gp, $gvname, $name );

        save_gv_misc( $gp, $fullname, $gv, $sym, $savefields );

        save_gv_io( $gv, $fullname, $sym ) if $savefields & Save_IO;

    }

    # Shouldn't need to do save_magic since gv_fetchpv handles that. Esp. < and IO not
    # $gv->save_magic($fullname) if $PERL510;
    debug( gv => "GV::save *$fullname done" );
    return $sym;
}

sub get_savefields {
    my ( $gv, $gvname, $fullname, $filter ) = @_;

    # default savefields
    my $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;

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
    elsif ( $fullname eq 'main::_' or $fullname eq 'main::@' ) {
        $savefields = 0;
    }

    # avoid overly dynamic POSIX redefinition warnings: GH #335, #345
    if ( $fullname =~ m/^POSIX::M/ or $fullname eq 'attributes::bootstrap' ) {
        $savefields &= ~Save_CV;
    }

    # compute filter
    $filter = normalize_filter( $filter, $fullname );

    # apply filter
    if ( $filter and $filter =~ qr{^[0-9]$} ) {
        $savefields &= ~$filter;
    }

    debug( gv => "XXXX $fullname -> $savefields" );

    return $savefields;
}

sub normalize_filter {
    my ( $filter, $fullname ) = @_;

    if ( $filter and $filter =~ m/ :pad/ ) {
        $filter = 0;
    }

    # checked for defined'ness in Carp. So the GV must exist, the CV not
    if ( $fullname =~ /^threads::(tid|AUTOLOAD)$/ and USE_ITHREADS() ) {
        $filter = Save_CV;
    }

    # no need to assign any SV/AV/HV to them (172)
    if ( $fullname =~ /^DynaLoader::dl_(require_symbols|resolve_using|librefs)/ ) {
        $filter = Save_SV | Save_AV | Save_HV;
    }
    if ( $B::C::ro_inc and $fullname =~ /^main::([0-9])$/ ) {    # ignore PV regexp captures with -O2
        $filter = Save_SV;
    }

    return $filter;
}

sub gv_fetchpv_string {
    my ( $name, $flags, $type ) = @_;
    warn 'undefined flags' unless defined $flags;
    warn 'undefined type'  unless defined $type;
    my ( $cname, $cur, $utf8 ) = strlen_flags($name);

    $flags .= length($flags) ? "|$utf8" : $utf8 if $utf8;
    return "gv_fetchpvn_flags($cname, $cur, $flags, $type)";
}

my $CORE_SVS = {    # special SV syms to assign to the right GvSV

    "main::\\" => 'PL_ors_sv',
    "main::/"  => 'PL_rs',
    "main::@"  => 'PL_errors',
};

sub save_gv_sv {
    my ( $gv, $fullname, $sym, $package, $gvname ) = @_;

    my $gvsv = $gv->SV;
    return unless $$gvsv;

    if ( my $pl_core_sv = $CORE_SVS->{$fullname} ) {
        savesym( $gvsv, $pl_core_sv );
    }

    if ( $gvname eq 'VERSION' and $B::C::xsub{$package} and $gvsv->FLAGS & SVf_ROK ) {
        debug( gv => "Strip overload from $package\::VERSION, fails to xs boot (issue 91)" );
        my $rv     = $gvsv->object_2svref();
        my $origsv = $$rv;
        no strict 'refs';
        ${$fullname} = "$origsv";
        svref_2object( \${$fullname} )->save($fullname);
    }
    else {
        $gvsv->save($fullname);    #even NULL save it, because of gp_free nonsense
                                   # we need sv magic for the core_svs (PL_rs -> gv) (#314)
        if ( exists $CORE_SVS->{"main::$gvname"} ) {

            # ORS special case #318 (initially NULL)
            return $sym if $gvname eq "\\";

            $gvsv->save_magic($fullname) if ref($gvsv) eq 'B::PVMG';
            init()->add( sprintf( "SvREFCNT(s\\_%x) += 1;", $$gvsv ) );
        }
    }

    init()->add( sprintf( "GvSVn(%s) = (SV*)s\\_%x;", $sym, $$gvsv ) );

    if ( $fullname eq 'main::$' ) {    # $$ = PerlProc_getpid() issue #108
        init()->add("sv_setiv(GvSV($sym), (IV)PerlProc_getpid());");
    }

    return;
}

sub save_gv_io {
    my ( $gv, $fullname, $sym ) = @_;

    my $gvio = $gv->IO;
    return unless $$gvio;

    my $is_data;
    if ( $fullname eq 'main::DATA' or ( $fullname =~ m/::DATA$/ and $B::C::save_data_fh ) )    # -O2 or 5.8
    {
        no strict 'refs';
        my $fh = *{$fullname}{IO};
        use strict 'refs';
        $is_data = 'is_DATA';
        $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
    }
    elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
        $is_data = 'is_DATA';
        WARN("Warning: __DATA__ handle $fullname not stored. Need -O2 or -fsave-data.");
    }

    $gvio->save( $fullname, $is_data );
    init()->add( sprintf( "GvIOp(%s) = s\\_%x;", $sym, $$gvio ) );

    return;
}

sub save_gv_av {
    my ( $gv, $fullname ) = @_;
    return unless my $gvav = $gv->AV;

    my $sym = $gvav->save($fullname);

    if ( $fullname eq 'main::-' ) {    # TODO move this logic to AV::save ???
        init()->add(
            sprintf( "AvFILLp(s\\_%x) = -1;", $$gvav ),
            sprintf( "AvMAX(s\\_%x) = -1;",   $$gvav )
        );
    }

    return $sym;
}

sub save_gv_hv {
    my ( $gv, $fullname, $sym, $gvname ) = @_;

    return unless my $gvhv = $gv->HV;

    # Handle HV exceptions first...
    return if $fullname eq 'main::ENV' or $fullname eq 'main::INC';    # do not save %ENV

    debug( gv => "GV::save \%$fullname" );
    if ( $fullname eq 'main::!' ) {                                    # force loading Errno
        mark_package( 'Errno', 1 );                                    # B::C needs Errno but does not import $!
        return;
    }

    if ( $fullname eq 'main::+' or $fullname eq 'main::-' ) {
        init()->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");
        svref_2object( \&{'Tie::Hash::NamedCapture::bootstrap'} )->save;
        mark_package( 'Tie::Hash::NamedCapture', 1 );
        return;
    }

    # skip static %Encode::Encoding since 5.20. GH #200. sv_upgrade cannot upgrade itself.
    # Let it be initialized by boot_Encode/Encode_XSEncodingm with exceptions.
    # GH #200 and t/testc.sh 75
    if ( $fullname eq 'Encode::Encoding' ) {
        debug( gv => "skip some %Encode::Encoding - XS initialized" );
        my %tmp_Encode_Encoding = %Encode::Encoding;
        %Encode::Encoding = ();    # but we need some non-XS encoding keys
        foreach my $k (qw(utf8 utf-8-strict Unicode Internal Guess)) {
            $Encode::Encoding{$k} = $tmp_Encode_Encoding{$k} if exists $tmp_Encode_Encoding{$k};
        }
        $gvhv->save($fullname);
        init()->add(
            "/* deferred some XS enc pointers for \%Encode::Encoding */",
            sprintf( "GvHV(%s) = s\\_%x;", $sym, $$gvhv )
        );
        %Encode::Encoding = %tmp_Encode_Encoding;
        return;
    }

    # Regular saving process... (simple isn't it)
    $gvhv->save($fullname);
    init()->add( sprintf( "GvHV(%s) = s\\_%x;", $sym, $$gvhv ) );

    return;
}

# XXX issue 57: incomplete xs dependency detection
my %hack_xs_detect = (
    'Scalar::Util'  => 'List::Util',
    'Sub::Exporter' => 'Params::Util',
);

sub save_gv_cv {
    my ( $gv, $savefields, $fullname, $package, $sym, $gp, $gvname, $name ) = @_;
    my $gvcv = $gv->CV;

    return unless $savefields & Save_CV;
    return if B::C::skip_pkg($package);

    # Try to force AUTOLOAD and/or CLONE if $gvcv is missing.
    if ( !$$gvcv ) {
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

    return unless $$gvcv;
    return unless ref($gvcv) eq 'B::CV' and ref( $gvcv->GV ) ne 'B::SPECIAL' and ref( $gvcv->GV->EGV ) ne 'B::SPECIAL';

    my $package  = $gvcv->GV->EGV->STASH->NAME;
    my $oname    = $gvcv->GV->EGV->NAME;
    my $origname = $package . "::" . $oname;
    my $cvsym;

    # XS calls need to be loaded at init time.
    if ( $gvcv->XSUB and $oname ne '__ANON__' and $fullname ne $origname ) {    #XSUB CONSTSUB alias

        debug( pkg => "Boot $package, XS CONSTSUB alias of $fullname to $origname" );
        mark_package( $package, 1 );

        no strict 'refs';

        if ( $package and defined &{"$package\::bootstrap"} ) {
            svref_2object( \&{"$package\::bootstrap"} )->save

        }

        if ( my $dep = $hack_xs_detect{$package} ) {
            svref_2object( \&{"$dep\::bootstrap"} )->save;
        }

        # must save as a 'stub' so newXS() has a CV to populate
        init2()->add(
            sprintf( "if ((sv = (SV*)%s))",                                get_cv_string( $origname, "GV_ADD" ) ),
            sprintf( "    GvCV_set(%s, (CV*)SvREFCNT_inc_simple_NN(sv));", $sym )
        );
    }
    elsif ($gp) {
        if ( $fullname eq 'Internals::V' ) {
            $gvcv = svref_2object( \&__ANON__::_V );
        }

        $cvsym = $gvcv->save($fullname);

        my $gvsym = $sym;
        $gvsym =~ s{^&}{};

        # backpatch "$sym = gv_fetchpv($name, GV_ADD, SVt_PV)" to SVt_PVCV
        if ( $cvsym =~ /get_cv/ ) {
            if ( !$B::C::xsub{$package} and B::C::in_static_core( $package, $gvname ) ) {
                my $in_gv;
                for ( @{ init()->{current} } ) {
                    if ($in_gv) {
                        s/^.*\Q$gvsym\E.*=.*;//;
                        s/GvGP_set\(\Q$gvsym\E.*;//;
                    }
                    if (/^\Q$gvsym = *(GV*)gv_fetchpv($name, GV_ADD, SVt_PV);\E/) {
                        s/^\Q$gvsym = *(GV*)gv_fetchpv($name, GV_ADD, SVt_PV);\E/$gvsym = *(GV*)gv_fetchpv($name, GV_ADD, SVt_PVCV);/;
                        $in_gv++;
                        debug( gv => "removed $sym GP assignments $origname (core CV)" );
                    }
                }
                init()->add( sprintf( "GvCV_set(%s, (CV*)SvREFCNT_inc(%s));", $sym, $cvsym ) );
            }
            elsif ( $B::C::xsub{$package} ) {

                # must save as a 'stub' so newXS() has a CV to populate later in dl_init()
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
                    init2()->add_eval( sprintf( "DBI->_install_method('%s', 'DBI.pm', \$DBI::DBI_methods{%s}{%s})", $fullname, $dr, $fullname ) );
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

sub save_gv_misc {
    my ( $gp, $fullname, $gv, $sym, $savefields ) = @_;

    return unless $gp;
    return unless $savefields & Save_FORM;
    return unless my $gvform = $gv->FORM;

    $gvform->save($fullname);
    init()->add( sprintf( "GvFORM(%s) = (CV*)s\\_%x;", $sym, $$gvform ) );
    init()->add( sprintf( "SvREFCNT_inc(s\\_%x);", $$gvform ) );
    return;
}

1;
