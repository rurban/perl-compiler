package B::PVMG;

use strict;

use Config;
use B::C::Config;
use B qw/SVf_ROK SVf_READONLY HEf_SVKEY SVf_READONLY cstring cchar SVp_POK/;
use B::C::Save qw/savepvn savepv/;
use B::C::Decimal qw/get_integer_value get_double_value/;
use B::C::File qw/init svsect xpvmgsect xpvsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

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
    my ( $savesym, $cur, $len, $pv, $static ) = B::C::save_pv_or_rv( $sv, $fullname );
    if ($static) {    # 242: e.g. $1
        $static = 0;
        $len = $cur + 1 unless $len;
    }

    my ( $ivx, $nvx );

    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    if ( ref($sv) eq 'B::REGEXP' ) {
        return B::REGEXP::save( $sv, $fullname );
    }
    else {
        $ivx = get_integer_value( $sv->IVX );    # XXX How to detect HEK* namehek?
        $nvx = get_double_value( $sv->NVX );     # it cannot be xnv_u.xgv_stash ptr (BTW set by GvSTASH later)

        # See #305 Encode::XS: XS objects are often stored as SvIV(SvRV(obj)). The real
        # address needs to be patched after the XS object is initialized. But how detect them properly?
        # Detect ptr to extern symbol in shared library and remap it in init2
        # Safe and mandatory currently only Net-DNS-0.67 - 0.74.
        # svop const or pad OBJECT,IOK
        if (
            # fixme simply the or logic
            ( ( !USE_ITHREADS() and $fullname and $fullname =~ /^svop const|^padop|^Encode::Encoding| :pad\[1\]/ ) or USE_ITHREADS() )
            and $sv->IVX > 5000000    # some crazy heuristic for a so ptr (> image_base)
            and ref( $sv->SvSTASH ) ne 'B::SPECIAL'
          ) {
            $ivx = _patch_dlsym( $sv, $fullname, $ivx );
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
            : ( C99() ? ".svu_pv=(char*)" : "(char*)" ) . $savesym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( !$static ) {    # do not overwrite RV slot (#273)
                         # XXX comppadnames need &PL_sv_undef instead of 0 (?? which testcase?)
        init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    $sym = savesym( $sv, "&" . $s );
    $sv->save_magic($fullname);
    return $sym;
}

sub save_magic {
    my ( $sv, $fullname ) = @_;
    my $sv_flags = $sv->FLAGS;
    if ( debug('mg') ) {
        my $flagspv = "";
        $fullname = '' unless $fullname;
        $flagspv = $sv->flagspv if debug('flags') and !$sv->MAGICAL;
        debug(
            mg => "saving magic for %s %s (0x%x) flags=0x%x%s  - called from %s:%s\n",
            ref($sv), $fullname, $$sv, $sv_flags,
            debug('flags') ? "(" . $flagspv . ")" : "",
            @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(1) )[2] ] }
        );
    }

    # crashes on STASH=0x18 with HV PERL_MAGIC_overload_table stash %version:: flags=0x3280000c
    # issue267 GetOpt::Long SVf_AMAGIC|SVs_RMG|SVf_OOK
    # crashes with %Class::MOP::Instance:: flags=0x2280000c also
    if ( ref($sv) eq 'B::HV' and $sv->MAGICAL and $fullname =~ /::$/ ) {
        WARN sprintf( "skip SvSTASH for overloaded HV $fullname flags=0x%x\n", $sv->FLAGS );
    }
    else {
        my $pkg = $sv->SvSTASH;
        if ($$pkg) {
            debug( mg => "stash isa class(\"%s\") 0x%x\n", eval { $pkg->NAME }, $$pkg );

            $pkg->save($fullname);

            no strict 'refs';
            debug( mg => "xmg_stash = \"%s\" (0x%x)\n", eval { $pkg->NAME }, $$pkg );

            # Q: Who is initializing our stash from XS? ->save is missing that.
            # A: We only need to init it when we need a CV
            # defer for XS loaded stashes with AMT magic
            init()->add( sprintf( "SvSTASH_set(s\\_%x, (HV*)s\\_%x);", $$sv, $$pkg ) );
            init()->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
            init()->add("++PL_sv_objcount;") unless ref($sv) eq "B::IO";

            # XXX
            #push_package($pkg->NAME);  # correct code, but adds lots of new stashes
        }
    }

    # Protect our SVs against non-magic or SvPAD_OUR. Fixes tests 16 and 14 + 23
    if ( !$sv->MAGICAL ) {
        debug(
            mg => "Skipping non-magical PVMG type=%d, flags=0x%x%s\n",
            $sv_flags && 0xff, $sv_flags, debug('flags') ? "(" . $sv->flagspv . ")" : ""
        );
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

        debug( mg => "%s %s magic\n", $fullname, cchar($type) );

        #eval {
        #  warn sprintf( "magic %s (0x%x), obj %s (0x%x), type %s, ptr %s\n",
        #                class($sv), $$sv, class($obj), $$obj, cchar($type),
        #		      cstring($ptr) );
        #};

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
            debug( mg => "MG->PTR is an SV*" );
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
                ( $resym, $relen ) = _savere( $mg->precomp );

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

# TODO: This was added to PVMG because we thought it was only used in this op but
# as of 5.18, it's used in B::CV::save
sub _patch_dlsym {
    my ( $sv, $fullname, $ivx ) = @_;
    my $pkg = '';
    if ( ref($sv) eq 'B::PVMG' ) {
        my $stash = $sv->SvSTASH;
        $pkg = $stash->can('NAME') ? $stash->NAME : '';
    }
    my $name = $sv->FLAGS & SVp_POK() ? $sv->PVX : "";

    # Encode RT #94221
    if ( $name =~ /encoding$/ and $Encode::VERSION eq '2.58' ) {
        $name =~ s/-/_/g;
        $pkg = 'Encode' if $pkg eq 'Encode::XS';    # TODO foreign classes
        mark_package($pkg) if $fullname eq '(unknown)' and USE_ITHREADS();
        verbose("$pkg $Encode::VERSION with remap support for $name");
    }
    elsif ( $pkg eq 'Encode::XS' ) {
        $pkg = 'Encode';
        if ( $fullname eq 'Encode::Encoding{iso-8859-1}' ) {
            $name = "iso8859_1_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{null}' ) {
            $name = "null_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{ascii-ctrl}' ) {
            $name = "ascii_ctrl_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{ascii}' ) {
            $name = "ascii_encoding";
        }

        if ( $name and $name !~ /encoding$/ and $Encode::VERSION gt '2.58' and Encode::find_encoding($name) ) {
            my $enc = Encode::find_encoding($name);
            $pkg = ref($enc) if ref($enc) ne 'Encode::XS';
            $pkg =~ s/^(Encode::\w+)(::.*)/$1/;
            $name .= "_encoding";
            $name =~ s/-/_/g;
            verbose("$pkg $Encode::VERSION with remap support for $name");
            if ( $fullname eq '(unknown)' and USE_ITHREADS() ) {
                mark_package( $pkg, 1 );
                if ( $pkg ne 'Encode' ) {
                    svref_2object( \&{"$pkg\::bootstrap"} )->save;
                    mark_package( 'Encode', 1 );
                }
            }
        }
        else {
            for my $n ( Encode::encodings() ) {    # >=5.16 constsub without name
                my $enc = Encode::find_encoding($n);
                if ( $enc and ref($enc) ne 'Encode::XS' ) {    # resolve alias such as Encode::JP::JIS7=HASH(0x292a9d0)
                    $pkg = ref($enc);
                    $pkg =~ s/^(Encode::\w+)(::.*)/$1/;        # collapse to the @dl_module name
                    $enc = Encode->find_alias($n);
                }
                if ( $enc and ref($enc) eq 'Encode::XS' and $sv->IVX == $$enc ) {
                    $name = $n;
                    $name =~ s/-/_/g;
                    $name .= "_encoding" if $name !~ /_encoding$/;
                    if ( $fullname eq '(unknown)' and USE_ITHREADS() ) {
                        mark_package( $pkg, 1 );
                        if ( $pkg ne 'Encode' ) {
                            svref_2object( \&{"$pkg\::bootstrap"} )->save;
                            mark_package( 'Encode', 1 );
                        }
                    }
                    last;
                }
            }
            if ($name) {
                verbose("$pkg $Encode::VERSION remap found for constant $name");
            }
            else {
                verbose("Warning: Possible missing remap for compile-time XS symbol in $pkg $fullname $ivx [#305]");
            }
        }
    }

    # Encode-2.59 uses a different name without _encoding
    elsif ( $name !~ /encoding$/ and $Encode::VERSION gt '2.58' and Encode::find_encoding($name) ) {
        $name .= "_encoding";
        $name =~ s/-/_/g;
        $pkg = 'Encode' unless $pkg;
        verbose("$pkg $Encode::VERSION with remap support for $name");
    }

    # now that is a weak heuristic, which misses #305
    elsif ( defined($Net::DNS::VERSION)
        and $Net::DNS::VERSION =~ /^0\.(6[789]|7[1234])/ ) {
        if ( $fullname eq 'svop const' ) {
            $name = "ascii_encoding";
            $pkg = 'Encode' unless $pkg;
            WARN("Warning: Patch Net::DNS external XS symbol $pkg\::$name $ivx [RT #94069]");
        }
    }
    elsif ( $pkg eq 'Net::LibIDN' ) {
        $name = "idn_to_ascii";    # ??
    }

    # new API (only Encode so far)
    if ( $pkg and $name and $name =~ /^[a-zA-Z_0-9-]+$/ ) {    # valid symbol name
        verbose("Remap IOK|POK $pkg with $name");
        _save_remap( $pkg, $pkg, $name, $ivx, 0 );
        $ivx = "0UL /* $ivx => $name */";
        mark_package( $pkg, 1 ) if $fullname =~ /^(svop const|padop)/;
    }
    else {
        WARN("Warning: Possible missing remap for compile-time XS symbol in $pkg $fullname $ivx [#305]");
    }
    return $ivx;
}

sub _save_remap {
    my ( $key, $pkg, $name, $ivx, $mandatory ) = @_;
    my $id = xpvmgsect()->index + 1;

    #my $svid = svsect()->index + 1;
    verbose("init remap for $key\: $name in xpvmg_list[$id]");
    my $props = { NAME => $name, ID => $id, MANDATORY => $mandatory };
    $B::C::init2_remap{$key}{MG} = [] unless $B::C::init2_remap{$key}{'MG'};
    push @{ $B::C::init2_remap{$key}{MG} }, $props;

    return;
}

sub _savere {
    my $re = shift;
    my $flags = shift || 0;
    my $sym;
    my $pv  = $re;
    my $cur = length $pv;
    my $len = 0;            # length( pack "a*", $pv ) + 2;

    # QUESTION: this code looks dead
    #   at least not triggered by the core unit tests

    xpvsect()->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], 1, %x, {%s}", xpvsect()->index,
            0x4405, ( C99() ? ".svu_pv=" : "" ) . '(char*)' . savepv($pv)
        )
    );
    $sym = sprintf( "&sv_list[%d]", svsect()->index );

    return ( $sym, length( pack "a*", $re ) );
}

1;
