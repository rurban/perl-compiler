package B::CV;

use strict;

use Config;
use B qw/cstring svref_2object CVf_ANON CVf_CONST main_cv/;
use B::C::File qw/init decl svsect xpvcvsect symsect/;
use B::C::Helpers::Symtable qw/objsym savesym delsym/;

my (%cvforward);
my $cv_index      = 0;
my $initsub_index = 0;
my $anonsub_index = 0;

sub is_lexsub {
    return 0;
}

sub Dummy_initxs { }

sub save {
    my ($cv) = @_;
    my $sym = objsym($cv);
    if ( defined($sym) ) {
        warn sprintf( "CV 0x%x already saved as $sym\n", $$cv ) if $$cv and $B::C::debug{cv};
        return $sym;
    }
    my $gv = $cv->GV;
    my ( $cvname, $cvstashname, $fullname );
    my $CvFLAGS = $cv->CvFLAGS;
    if ( $gv and $$gv ) {
        $cvstashname = $gv->STASH->NAME;
        $cvname      = $gv->NAME;
        $fullname    = $cvstashname . '::' . $cvname;
        warn sprintf(
            "CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
            $$cv, $$gv, $fullname, $CvFLAGS
        ) if $B::C::debug{cv};

        # XXX not needed, we already loaded utf8_heavy
        #return if $fullname eq 'utf8::AUTOLOAD';
        return '0' if $B::C::all_bc_subs{$fullname} or B::C::skip_pkg($cvstashname);
        $CvFLAGS &= ~0x400;    # no CVf_CVGV_RC otherwise we cannot set the GV
        B::C::mark_package( $cvstashname, 1 ) unless $B::C::include_package{$cvstashname};
    }
    elsif ( $cv->is_lexsub($gv) ) {
        $fullname = $cv->NAME_HEK;
        warn sprintf("CV NAME_HEK $fullname\n") if $B::C::debug{cv};
        if ( $fullname =~ /^(.*)::(.*?)$/ ) {
            $cvstashname = $1;
            $cvname      = $2;
        }
    }

    # XXX TODO need to save the gv stash::AUTOLOAD if exists
    my $root   = $cv->ROOT;
    my $cvxsub = $cv->XSUB;
    my $isconst;
    {
        no strict 'subs';
        $isconst = $CvFLAGS & CVf_CONST;
    }

    if ( !$isconst && $cvxsub && ( $cvname ne "INIT" ) ) {
        my $egv       = $gv->EGV;
        my $stashname = $egv->STASH->NAME;
        $fullname = $stashname . '::' . $cvname;
        if ( $cvname eq "bootstrap" and !$B::C::xsub{$stashname} ) {
            my $file = $gv->FILE;
            decl()->add("/* bootstrap $file */");
            warn "Bootstrap $stashname $file\n" if B::C::verbose();
            B::C::mark_package($stashname);

            # Without DynaLoader we must boot and link static
            if ( !$Config{usedl} ) {
                $B::C::xsub{$stashname} = 'Static';
            }

            # if it not isa('DynaLoader'), it should hopefully be XSLoaded
            # ( attributes being an exception, of course )
            elsif ( !UNIVERSAL::isa( $stashname, 'DynaLoader' ) ) {
                my $stashfile = $stashname;
                $stashfile =~ s/::/\//g;
                if ( $file =~ /XSLoader\.pm$/ ) {    # almost always the case
                    $file = $INC{ $stashfile . ".pm" };
                }
                unless ($file) {                     # do the reverse as DynaLoader: soname => pm
                    my ($laststash) = $stashname =~ /::([^:]+)$/;
                    $laststash = $stashname unless $laststash;
                    my $sofile = "auto/" . $stashfile . '/' . $laststash . '\.' . $Config{dlext};
                    for (@DynaLoader::dl_shared_objects) {
                        if (m{^(.+/)$sofile$}) {
                            $file = $1 . $stashfile . ".pm";
                            last;
                        }
                    }
                }
                $B::C::xsub{$stashname} = 'Dynamic-' . $file;
                B::C::force_saving_xsloader();
            }
            else {
                $B::C::xsub{$stashname} = 'Dynamic';

                # DynaLoader was for sure loaded, before so we execute the branch which
                # does walk_syms and add_hashINC
                B::C::mark_package( 'DynaLoader', 1 );
            }

            # INIT is removed from the symbol table, so this call must come
            # from PL_initav->save. Re-bootstrapping  will push INIT back in,
            # so nullop should be sent.
            warn $fullname . "\n" if $B::C::debug{sub};
            return qq/NULL/;
        }
        else {
            # XSUBs for IO::File, IO::Handle, IO::Socket, IO::Seekable and IO::Poll
            # are defined in IO.xs, so let's bootstrap it
            my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
            if ( grep { $stashname eq $_ } @IO ) {

                # mark_package('IO', 1);
                # $B::C::xsub{IO} = 'Dynamic-'. $INC{'IO.pm'}; # XSLoader (issue59)
                svref_2object( \&IO::bootstrap )->save;
                B::C::mark_package( 'IO::Handle',  1 );
                B::C::mark_package( 'SelectSaver', 1 );

                #for (@IO) { # mark all IO packages
                #  mark_package($_, 1);
                #}
            }
        }
        warn $fullname . "\n" if $B::C::debug{sub};
        unless ( B::C::in_static_core( $stashname, $cvname ) ) {
            no strict 'refs';
            warn sprintf( "XSUB $fullname CV 0x%x\n", $$cv )
              if $B::C::debug{cv};
            svref_2object( \*{"$stashname\::bootstrap"} )->save
              if $stashname;    # and defined ${"$stashname\::bootstrap"};
                                # delsym($cv);
            return qq/get_cv("$fullname", 0)/;
        }
        else {                  # Those cvs are already booted. Reuse their GP.
                                # Esp. on windows it is impossible to get at the XS function ptr
            warn sprintf( "core XSUB $fullname CV 0x%x\n", $$cv ) if $B::C::debug{cv};
            return qq/get_cv("$fullname", 0)/;
        }
    }
    if ( $cvxsub && $cvname eq "INIT" ) {
        no strict 'refs';
        warn $fullname . "\n" if $B::C::debug{sub};
        return svref_2object( \&Dummy_initxs )->save;
    }

    if ( $isconst and !( $CvFLAGS & CVf_ANON ) ) {
        my $stash = $gv->STASH;
        warn sprintf( "CV CONST 0x%x %s::%s\n", $$gv, $cvstashname, $cvname )
          if $B::C::debug{cv};

        # warn sprintf( "%s::%s\n", $cvstashname, $cvname) if $B::C::debug{sub};
        my $stsym = $stash->save;
        my $name  = cstring($cvname);
        my $sv    = $cv->XSUBANY;
        my $vsym  = $sv->save;
        my $cvi   = "cv" . $cv_index;
        decl()->add("Static CV* $cvi;");
        init()->add("$cvi = newCONSTSUB( $stsym, $name, (SV*)$vsym );");
        my $sym = savesym( $cv, $cvi );
        $cv_index++;
        return $sym;
    }

    # This define is forwarded to the real sv below
    # The new method, which saves a SV only works since 5.10 (? Does not work in newer perls)
    my $sv_ix = svsect()->index + 1;
    my $xpvcv_ix;
    my $new_cv_fw = 0;
    if ($new_cv_fw) {
        $sym = savesym( $cv, "CVIX$sv_ix" );
    }
    else {
        svsect()->add("CVIX$sv_ix");
        svsect()->debug( "&" . $fullname, $cv );
        $xpvcv_ix = xpvcvsect()->index + 1;
        xpvcvsect()->add("XPVCVIX$xpvcv_ix");

        # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
        $sym = savesym( $cv, "&sv_list[$sv_ix]" );
    }

    warn sprintf( "saving $fullname CV 0x%x as $sym\n", $$cv )
      if $B::C::debug{cv};

    # fixme: interesting have a look at it
    if ( $fullname eq 'utf8::SWASHNEW' ) {    # bypass utf8::AUTOLOAD, a new 5.13.9 mess
        require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};

        # sub utf8::AUTOLOAD {}; # How to ignore &utf8::AUTOLOAD with Carp? The symbol table is
        # already polluted. See issue 61 and force_heavy()
        svref_2object( \&{"utf8\::SWASHNEW"} )->save;
    }

    # fixme: can probably be removed
    if ( $fullname eq 'IO::Socket::SSL::SSL_Context::new' ) {
        if ( $IO::Socket::SSL::VERSION ge '1.956' and $IO::Socket::SSL::VERSION lt '1.984' ) {
            warn "Warning: Your IO::Socket::SSL version $IO::Socket::SSL::VERSION is too old to create\n" . "  a server. Need to upgrade IO::Socket::SSL to 1.984 [CPAN #95452]\n";
        }
    }

    if ( !$$root && !$cvxsub ) {
        my $reloaded;
        if ( $cvstashname =~ /^(bytes|utf8)$/ ) {    # no autoload, force compile-time
            B::C::force_heavy($cvstashname);
            $cv       = svref_2object( \&{"$cvstashname\::$cvname"} );
            $reloaded = 1;
        }
        elsif ( $fullname eq 'Coro::State::_jit' ) {    # 293
                                                        # need to force reload the jit src
            my ($pl) = grep { m|^Coro/jit-| } keys %INC;
            if ($pl) {
                delete $INC{$pl};
                require $pl;
                $cv       = svref_2object( \&{$fullname} );
                $reloaded = 1;
            }
        }
        if ($reloaded) {
            $gv = $cv->GV;
            warn sprintf(
                "Redefined CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
                $$cv, $$gv, $fullname, $CvFLAGS
            ) if $B::C::debug{cv};
            $sym    = savesym( $cv, $sym );
            $root   = $cv->ROOT;
            $cvxsub = $cv->XSUB;
        }
    }
    if ( !$$root && !$cvxsub ) {
        if ( my $auto = B::C::try_autoload( $cvstashname, $cvname ) ) {
            if ( ref $auto eq 'B::CV' ) {    # explicit goto or UNIVERSAL
                $root   = $auto->ROOT;
                $cvxsub = $auto->XSUB;
                if ($$auto) {

                    # XXX This has now created a wrong GV name!
                    my $oldcv = $cv;
                    $cv = $auto;             # This is new. i.e. via AUTOLOAD or UNIVERSAL, in another stash
                    my $gvnew = $cv->GV;
                    if ($$gvnew) {
                        if ( $cvstashname ne $gvnew->STASH->NAME or $cvname ne $gvnew->NAME ) {    # UNIVERSAL or AUTOLOAD
                            my $newname = $gvnew->STASH->NAME . "::" . $gvnew->NAME;
                            warn " New $newname autoloaded. remove old cv\n" if $B::C::debug{sub};    # and wrong GV?
                            unless ($new_cv_fw) {
                                svsect()->remove;
                                xpvcvsect()->remove;
                            }
                            delsym($oldcv);

                            no strict 'refs';
                            my $newsym = svref_2object( \*{$newname} )->save;
                            my $cvsym = defined objsym($cv) ? objsym($cv) : $cv->save($newname);
                            if ( my $oldsym = objsym($gv) ) {
                                warn "Alias polluted $oldsym to $newsym\n" if $B::C::debug{gv};
                                init()->add("$oldsym = $newsym;");
                                delsym($gv);
                            }    # else {
                                 #init()->add("GvCV_set(gv_fetchpv(\"$fullname\", GV_ADD, SVt_PV), (CV*)NULL);");
                                 #}
                            return $cvsym;
                        }
                    }
                    $sym = savesym( $cv, "&sv_list[$sv_ix]" );    # GOTO
                    warn "$fullname GOTO\n" if B::C::verbose();
                }
            }
            else {
                # Recalculated root and xsub
                $root   = $cv->ROOT;
                $cvxsub = $cv->XSUB;
                my $gv = $cv->GV;
                if ($$gv) {
                    if ( $cvstashname ne $gv->STASH->NAME or $cvname ne $gv->NAME ) {    # UNIVERSAL or AUTOLOAD
                        my $newname = $gv->STASH->NAME . "::" . $gv->NAME;
                        warn "Recalculated root and xsub $newname. remove old cv\n" if B::C::verbose();
                        svsect()->remove;
                        xpvcvsect()->remove;
                        delsym($cv);
                        return $cv->save($newname);
                    }
                }
            }
            if ( $$root || $cvxsub ) {
                warn "Successful forced autoload\n" if B::C::verbose() and $B::C::debug{cv};
            }
        }
    }
    if ( !$$root ) {
        if ( exists &$fullname ) {
            warn "Warning: Empty &" . $fullname . "\n" if $B::C::debug{sub};
            init()->add("/* empty CV $fullname */") if B::C::verbose() or $B::C::debug{sub};
        }
        elsif ( $cv->is_lexsub($gv) ) {

            # need to find the attached lexical sub (#130 + #341) at run-time
            # in the PadNAMES array. So keep the empty PVCV
            warn "lexsub &" . $fullname . " saved as empty $sym\n" if $B::C::debug{sub};
        }
        else {
            warn "Warning: &" . $fullname . " not found\n" if $B::C::debug{sub};
            init()->add("/* CV $fullname not found */") if B::C::verbose() or $B::C::debug{sub};

            # This block broke test 15, disabled
            if ( $sv_ix == svsect()->index and !$new_cv_fw ) {    # can delete, is the last SV
                warn "No definition for sub $fullname (unable to autoload), skip CV[$sv_ix]\n"
                  if $B::C::debug{cv};
                svsect()->remove;
                xpvcvsect()->remove;
                delsym($cv);

                # Empty CV (methods) must be skipped not to disturb method resolution
                # (e.g. t/testm.sh POSIX)
                return '0';
            }
            else {
                # interim &AUTOLOAD saved, cannot delete. e.g. Fcntl, POSIX
                warn "No definition for sub $fullname (unable to autoload), stub CV[$sv_ix]\n"
                  if $B::C::debug{cv} or B::C::verbose();

                # continue, must save the 2 symbols from above
            }
        }
    }

    my $startfield = 0;
    my $padlist    = $cv->PADLIST;
    $B::C::curcv = $cv;
    my $padlistsym = 'NULL';
    my $pv         = $cv->PV;
    my $xsub       = 0;
    my $xsubany    = "Nullany";
    if ($$root) {
        warn sprintf(
            "saving op tree for CV 0x%x, root=0x%x\n",
            $$cv, $$root
        ) if $B::C::debug{cv} and $B::C::debug{gv};
        my $ppname = "";
        if ( $cv->is_lexsub($gv) ) {
            my $name = $cv->can('NAME_HEK') ? $cv->NAME_HEK : "anonlex";
            $ppname   = "pp_lexsub_" . $name;
            $fullname = "<lex>" . $name;
        }
        elsif ( $gv and $$gv ) {
            my ( $stashname, $gvname );
            $stashname = $gv->STASH->NAME;
            $gvname    = $gv->NAME;
            $fullname  = $stashname . '::' . $gvname;
            $ppname    = ( ${ $gv->FORM } == $$cv ) ? "pp_form_" : "pp_sub_";
            if ( $gvname ne "__ANON__" ) {
                $ppname .= ( $stashname eq "main" ) ? $gvname : "$stashname\::$gvname";
                $ppname =~ s/::/__/g;
                $ppname =~ s/(\W)/sprintf("0x%x", ord($1))/ge;
                if ( $gvname eq "INIT" ) {
                    $ppname .= "_$initsub_index";
                    $initsub_index++;
                }
            }
        }
        if ( !$ppname ) {
            $ppname = "pp_anonsub_$anonsub_index";
            $anonsub_index++;
        }
        $startfield = B::C::saveoptree( $ppname, $root, $cv->START, $padlist->ARRAY );

        #warn sprintf( "done saving op tree for CV 0x%x, flags (%s), name %s, root=0x%x => start=%s\n",
        #  $$cv, $B::C::debug{flags}?$cv->flagspv:sprintf("0x%x",$cv->FLAGS), $ppname, $$root, $startfield )
        #  if $B::C::debug{cv};
        # XXX missing cv_start for AUTOLOAD on 5.8
        $startfield = objsym( $root->next ) unless $startfield;    # 5.8 autoload has only root
        $startfield = "0" unless $startfield;
        if ($$padlist) {

            # XXX readonly comppad names and symbols invalid
            #local $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
            warn sprintf( "saving PADLIST 0x%x for CV 0x%x\n", $$padlist, $$cv )
              if $B::C::debug{cv} and $B::C::debug{gv};

            # XXX avlen 2
            $padlistsym = $padlist->save( $fullname . ' :pad' );
            warn sprintf(
                "done saving %s 0x%x for CV 0x%x\n",
                $padlistsym, $$padlist, $$cv
            ) if $B::C::debug{cv} and $B::C::debug{gv};

            # do not record a forward for the pad only

            init()->add("CvPADLIST($sym) = $padlistsym;");
        }
        warn $fullname . "\n" if $B::C::debug{sub};
    }
    elsif ( $cv->is_lexsub($gv) ) {
        ;
    }
    elsif ( !exists &$fullname ) {
        warn $fullname . " not found\n" if $B::C::debug{sub};
        warn "No definition for sub $fullname (unable to autoload)\n"
          if $B::C::debug{cv};
        init()->add("/* $fullname not found */") if B::C::verbose() or $B::C::debug{sub};

        # XXX empty CV should not be saved. #159, #235
        # svsect()->remove( $sv_ix );
        # xpvcvsect()->remove( $xpvcv_ix );
        # delsym( $cv );
        if ( !$new_cv_fw ) {
            symsect()->add("XPVCVIX$xpvcv_ix\t0");
        }
        $CvFLAGS &= ~0x1000;                   # CVf_DYNFILE
        $CvFLAGS &= ~0x400 if $gv and $$gv;    #CVf_CVGV_RC
        symsect()->add(
            sprintf(
                "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
                $sv_ix, $xpvcv_ix, $cv->REFCNT, $CvFLAGS
            )
        );
        return qq/get_cv("$fullname", 0)/;
    }

    # Now it is time to record the CV
    if ($new_cv_fw) {
        $sv_ix = svsect()->index + 1;
        if ( !$cvforward{$sym} ) {    # avoid duplicates
            symsect()->add( sprintf( "$sym\t&sv_list[%d]", $sv_ix ) );    # forward the old CVIX to the new CV
            $cvforward{$sym}++;
        }
        $sym = savesym( $cv, "&sv_list[$sv_ix]" );
    }

    # $pv = '' unless defined $pv;    # Avoid use of undef warnings
    #warn sprintf( "CV prototype %s for CV 0x%x\n", cstring($pv), $$cv )
    #  if $pv and $B::C::debug{cv};
    my $proto = defined $pv ? cstring($pv) : 'NULL';
    my $pvsym = 'NULL';
    my $cur   = defined $pv ? $cv->CUR : 0;
    my $len   = $cur + 1;
    $len++ if B::C::IsCOW($cv);
    $len = 0 if $B::C::const_strings;

    # need to survive cv_undef as there is no protection against static CVs
    my $refcnt = $cv->REFCNT + 1;

    # GV cannot be initialized statically
    my $xcv_outside = ${ $cv->OUTSIDE };
    if ( $xcv_outside == ${ main_cv() } and !$B::C::MULTI ) {

        # Provide a temp. debugging hack for CvOUTSIDE. The address of the symbol &PL_main_cv
        # is known to the linker, the address of the value PL_main_cv not. This is set later
        # (below) at run-time.
        $xcv_outside = '&PL_main_cv';
    }
    elsif ( ref( $cv->OUTSIDE ) eq 'B::CV' ) {
        $xcv_outside = 0;    # just a placeholder for a run-time GV
    }

    $pvsym = B::C::save_hek($pv);

    # XXX issue 84: we need to check the cv->PV ptr not the value.
    # "" is different to NULL for prototypes
    $len = $cur ? $cur + 1 : 0;

    # TODO:
    # my $ourstash = "0";  # TODO stash name to bless it (test 16: "main::")

    # cv_undef wants to free it when CvDYNFILE(cv) is true.
    # E.g. DateTime: boot_POSIX. newXS reuses cv if autoloaded. So turn it off globally.
    $CvFLAGS &= ~0x1000;    # CVf_DYNFILE off
    my $xpvc = sprintf

      # stash magic cur len cvstash start root cvgv cvfile cvpadlist     outside outside_seq cvflags cvdepth
      (
        "Nullhv, {0}, %u, %u, %s, {%s}, {s\\_%x}, %s, %s, %s, (CV*)%s, %s, 0x%x, %d",
        $cur,        $len, "Nullhv",    #CvSTASH later
        $startfield, $$root,
        "0",                            #GV later
        "NULL",                         #cvfile later (now a HEK)
        $padlistsym,
        $xcv_outside,                   #if main_cv set later
        B::C::ivx( $cv->OUTSIDE_SEQ ),
        $CvFLAGS,
        $cv->DEPTH
      );

    # repro only with 5.15.* threaded -q (70c0620) Encode::Alias::define_alias
    warn "lexwarnsym in XPVCV OUTSIDE: $xpvc" if $xpvc =~ /, \(CV\*\)iv\d/;    # t/testc.sh -q -O3 227
    if ( !$new_cv_fw ) {
        symsect()->add("XPVCVIX$xpvcv_ix\t$xpvc");

        #symsect()->add
        #  (sprintf("CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}"),
        #	   $sv_ix, $xpvcv_ix, $cv->REFCNT, $cv->FLAGS
        #	  ));
    }
    else {
        xpvcvsect()->comment('STASH mg_u cur len CV_STASH START_U ROOT_U GV file PADLIST OUTSIDE outside_seq flags depth');
        xpvcvsect()->add($xpvc);
        svsect()->add(
            sprintf(
                "&xpvcv_list[%d], %lu, 0x%x, {0}",
                xpvcvsect()->index, $cv->REFCNT, $cv->FLAGS
            )
        );
        svsect()->debug( $fullname, $cv );
    }

    if ($$cv) {

        my $gvstash = $gv->STASH;

        # defer GvSTASH because with DEBUGGING it checks for GP but
        # there's no GP yet.
        # But with -fstash the gvstash is set later
        init()->add(
            sprintf(
                "GvXPVGV(s\\_%x)->xnv_u.xgv_stash = s\\_%x;",
                $$cv, $$gvstash
            )
        ) if $gvstash and !$B::C::stash;
        warn sprintf( "done saving GvSTASH 0x%x for CV 0x%x\n", $$gvstash, $$cv )
          if $gvstash
          and $B::C::debug{cv}
          and $B::C::debug{gv};

    }
    if ( $cv->OUTSIDE_SEQ ) {
        my $cop = $B::C::File::symtable{ sprintf( "s\\_%x", $cv->OUTSIDE_SEQ ) };
        init()->add( sprintf( "CvOUTSIDE_SEQ(%s) = %s;", $sym, $cop ) ) if $cop;
    }

    $xcv_outside = ${ $cv->OUTSIDE };
    if ( $xcv_outside == ${ main_cv() } or ref( $cv->OUTSIDE ) eq 'B::CV' ) {

        # patch CvOUTSIDE at run-time
        if ( $xcv_outside == ${ main_cv() } ) {
            init()->add(
                "CvOUTSIDE($sym) = PL_main_cv;",
                "SvREFCNT_inc(PL_main_cv);"
            );
        }
        else {
            init()->add( sprintf( "CvOUTSIDE($sym) = (CV*)s\\_%x;", $xcv_outside ) );
        }
    }

    if ( $gv and $$gv ) {

        #test 16: Can't call method "FETCH" on unblessed reference. gdb > b S_method_common
        warn sprintf( "Saving GV 0x%x for CV 0x%x\n", $$gv, $$cv ) if $B::C::debug{cv} and $B::C::debug{gv};
        $gv->save;

        init()->add( sprintf( "CvGV_set((CV*)%s, (GV*)%s);", $sym, objsym($gv) ) );

        # Since 5.13.3 and CvGV_set there are checks that the CV is not RC (refcounted).
        # Assertion "!CvCVGV_RC(cv)" failed: file "gv.c", line 219, function: Perl_cvgv_set
        # We init with CvFLAGS = 0 and set it later, as successfully done in the Bytecode compiler
        if ( $CvFLAGS & 0x0400 ) {    # CVf_CVGV_RC
            warn sprintf(
                "CvCVGV_RC turned off. CV flags=0x%x %s CvFLAGS=0x%x \n",
                $cv->FLAGS, $B::C::debug{flags} ? $cv->flagspv : "", $CvFLAGS & ~0x400
            ) if $B::C::debug{cv};
            init()->add(
                sprintf(
                    "CvFLAGS((CV*)%s) = 0x%x; %s", $sym, $CvFLAGS,
                    $B::C::debug{flags} ? "/* " . $cv->flagspv . " */" : ""
                )
            );
        }
        init()->add("CvSTART($sym) = $startfield;");    # XXX TODO someone is overwriting CvSTART also

        warn sprintf(
            "done saving GV 0x%x for CV 0x%x\n",
            $$gv, $$cv
        ) if $B::C::debug{cv} and $B::C::debug{gv};
    }
    unless ($B::C::optimize_cop) {
        if ($B::C::MULTI) {
            init()->add( B::C::savepvn( "CvFILE($sym)", $cv->FILE ) );
        }
        else {
            init()->add( sprintf( "CvFILE(%s) = %s;", $sym, cstring( $cv->FILE ) ) );
        }
    }
    my $stash = $cv->STASH;
    if ( $$stash and ref($stash) ) {

        # init()->add("/* saving STASH $fullname */\n" if $B::C::debug{cv};
        $stash->save($fullname);

        # $sym fixed test 27
        init()->add( sprintf( "CvSTASH_set((CV*)$sym, s\\_%x);", $$stash ) );

        warn sprintf( "done saving STASH 0x%x for CV 0x%x\n", $$stash, $$cv )
          if $B::C::debug{cv} and $B::C::debug{gv};
    }
    my $magic = $cv->MAGIC;
    if ( $magic and $$magic ) {
        $cv->save_magic($fullname);    # XXX will this work?
    }
    if ( !$new_cv_fw ) {
        symsect()->add(
            sprintf(
                "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
                $sv_ix, $xpvcv_ix, $cv->REFCNT, $cv->FLAGS
            )
        );
    }
    if ($cur) {
        warn sprintf( "Saving CV proto %s for CV $sym 0x%x\n", cstring($pv), $$cv ) if $B::C::debug{cv};
    }

    # issue 84: empty prototypes sub xx(){} vs sub xx{}
    if ( defined $pv ) {
        if ($cur) {
            init()->add( sprintf( "SvPVX(&sv_list[%d]) = HEK_KEY(%s);", $sv_ix, $pvsym ) );
        }
        elsif ( !$B::C::const_strings ) {    # not static, they are freed when redefined
            init()->add(
                sprintf(
                    "SvPVX(&sv_list[%d]) = savepvn(%s, %u);",
                    $sv_ix, $proto, $cur
                )
            );
        }
        else {
            init()->add(
                sprintf(
                    "SvPVX(&sv_list[%d]) = %s;",
                    $sv_ix, $proto
                )
            );
        }
    }

    return $sym;
}

1;
