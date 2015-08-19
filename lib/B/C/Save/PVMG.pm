package B::PVMG;

use strict;

use Config;
use B qw/SVf_ROK SVf_READONLY HEf_SVKEY SVf_READONLY cstring cchar/;
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

sub save_magic {
    my ( $sv, $fullname ) = @_;
    my $sv_flags = $sv->FLAGS;
    if ( $B::C::debug{mg} ) {
        my $flagspv = "";
        $fullname = '' unless $fullname;
        $flagspv = $sv->flagspv if $B::C::debug{flags} and !$sv->MAGICAL;
        warn sprintf(
            "saving magic for %s $fullname (0x%x) flags=0x%x%s  - called from %s:%s\n",
            class($sv), $$sv, $sv_flags, $B::C::debug{flags} ? "(" . $flagspv . ")" : "",
            @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(1) )[2] ] }
        );
    }

    # crashes on STASH=0x18 with HV PERL_MAGIC_overload_table stash %version:: flags=0x3280000c
    # issue267 GetOpt::Long SVf_AMAGIC|SVs_RMG|SVf_OOK
    # crashes with %Class::MOP::Instance:: flags=0x2280000c also
    my $pkg = $sv->SvSTASH;
    if ($$pkg) {
        warn sprintf( "stash isa class(\"%s\") 0x%x\n", $pkg->NAME, $$pkg )
          if $B::C::debug{mg} or $B::C::debug{gv};

        $pkg->save($fullname);

        no strict 'refs';
        warn sprintf( "xmg_stash = \"%s\" (0x%x)\n", $pkg->NAME, $$pkg )
          if $B::C::debug{mg} or $B::C::debug{gv};

        # Q: Who is initializing our stash from XS? ->save is missing that.
        # A: We only need to init it when we need a CV
        # defer for XS loaded stashes with AMT magic
        init()->add( sprintf( "SvSTASH_set(s\\_%x, (HV*)s\\_%x);", $$sv, $$pkg ) );
        init()->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
        init()->add("++PL_sv_objcount;") unless ref($sv) eq "B::IO";

        # XXX
        #push_package($pkg->NAME);  # correct code, but adds lots of new stashes
    }

    # Protect our SVs against non-magic or SvPAD_OUR. Fixes tests 16 and 14 + 23
    if ( !$sv->MAGICAL ) {
        warn sprintf(
            "Skipping non-magical PVMG type=%d, flags=0x%x%s\n",
            $sv_flags && 0xff, $sv_flags, $B::C::debug{flags} ? "(" . $sv->flagspv . ")" : ""
        ) if $B::C::debug{mg};
        return '';
    }
    init()->add( sprintf( "SvREADONLY_off((SV*)s\\_%x);", $$sv ) ) if $sv_flags & SVf_READONLY;

    my @mgchain = $sv->MAGIC;
    my ( $mg, $type, $obj, $ptr, $len, $ptrsv );
    my $magic = '';
    foreach $mg (@mgchain) {
        $type = $mg->TYPE;
        $ptr  = $mg->PTR;
        $len  = $mg->LENGTH;
        $magic .= $type;
        if ( $B::C::debug{mg} ) {
            warn sprintf( "%s %s magic\n", $fullname, cchar($type) );

            #eval {
            #  warn sprintf( "magic %s (0x%x), obj %s (0x%x), type %s, ptr %s\n",
            #                class($sv), $$sv, class($obj), $$obj, cchar($type),
            #		      cstring($ptr) );
            #};
        }

        unless ( $type =~ /^[rDn]$/ ) {    # r - test 23 / D - Getopt::Long
                                           # 5.10: Can't call method "save" on unblessed reference
                                           #warn "Save MG ". $obj . "\n" if $PERL510;
                                           # 5.11 'P' fix in B::IV::save, IV => RV
            $obj = $mg->OBJ;
            $obj->save($fullname) if ( ref $obj ne 'SCALAR' );
            B::C::mark_threads()  if $type eq 'P';
        }

        if ( $len == HEf_SVKEY ) {

            # The pointer is an SV* ('s' sigelem e.g.)
            # XXX On 5.6 ptr might be a SCALAR ref to the PV, which was fixed later
            if ( ref($ptr) eq 'SCALAR' ) {
                $ptrsv = svref_2object($ptr)->save($fullname);
            }
            else {
                $ptrsv = $ptr->save($fullname);
            }
            warn "MG->PTR is an SV*\n" if $B::C::debug{mg};
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, (char *)%s, %d);",
                    $$sv, $$obj, cchar($type), $ptrsv, $len
                )
            );
        }

        # coverage $Template::Stash::PRIVATE
        elsif ( $type eq 'r' ) {    # qr magic, for 5.6 done in C.xs. test 20
            my $rx = $mg->REGEX;

            # stored by some PMOP *pm = cLOGOP->op_other (pp_ctl.c) in C.xs
            my $pmop = $B::C::Regexp{$rx};
            if ( !$pmop ) {
                warn "Warning: C.xs PMOP missing for QR\n";
            }
            else {
                my ( $resym, $relen );
                ( $resym, $relen ) = B::C::savere( $mg->precomp );

                my $pmsym = $pmop->save($fullname);
                push @B::C::static_free, $resym;
                init()->add(
                    split /\n/,
                    sprintf <<CODE1, $pmop->pmflags, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = CALLREGCOMP((SV* const)$resym, %d);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE1
            }
        }
        elsif ( $type eq 'D' ) {    # XXX regdata AV - coverage? i95, 903
                                    # see Perl_mg_copy() in mg.c
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
                    $$sv, $fullname eq 'main::-' ? 0 : $$sv, "'D'", cstring($ptr), $len
                )
            );
        }
        elsif ( $type eq 'n' ) {    # shared_scalar is from XS dist/threads-shared
                                    # XXX check if threads is loaded also? otherwise it is only stubbed
            B::C::mark_threads();
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, Nullsv, %s, %s, %d);",
                    $$sv, "'n'", cstring($ptr), $len
                )
            );
        }
        elsif ( $type eq 'c' ) {
            init()->add(
                sprintf(
                    "/* AMT overload table for the stash s\\_%x is generated dynamically */",
                    $$sv
                )
            );
        }
        elsif ( $type eq ':' ) {    # symtab magic
                                    # search $ptr in list of pmops and replace it. e.g. (char*)&pmop_list[0]
            my $pmop_ptr = unpack( "J", $mg->PTR );
            my $pmop = $B::C::Regexp{$pmop_ptr};
            warn sprintf( "pmop 0x%x not found in our B::C Regexp hash", $pmop_ptr )
              unless $pmop;
            my $pmsym = $pmop ? $pmop->save($fullname) : '&pmop_list[0]';
            init()->add(
                "{\tU32 elements;",    # toke.c: PL_multi_open == '?'
                sprintf( "\tMAGIC *mg = sv_magicext((SV*)s\\_%x, 0, ':', 0, 0, 0);", $$sv ),
                "\telements = mg->mg_len / sizeof(PMOP**);",
                "\tRenewc(mg->mg_ptr, elements + 1, PMOP*, char);",
                sprintf( "\t((OP**)mg->mg_ptr) [elements++] = %s;", $pmsym ),
                "\tmg->mg_len = elements * sizeof(PMOP**);", "}"
            );
        }
        else {
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
                    $$sv, $$obj, cchar($type), cstring($ptr), $len
                )
            );
        }
    }
    init()->add( sprintf( "SvREADONLY_on((SV*)s\\_%x);", $$sv ) ) if $sv_flags & SVf_READONLY;
    $magic;
}

1;
