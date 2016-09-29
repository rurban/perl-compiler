package B::C::HV;

my $hv_index = 0;

sub get_index {
    return $hv_index;
}

sub inc_index {
    return ++$hv_index;
}

1;

package B::HV;

use strict;

use B qw/cstring SVf_READONLY SVf_PROTECT SVs_OBJECT SVf_OOK SVf_AMAGIC/;
use B::C::Config;
use B::C::File qw/init xpvhvsect svsect sharedhe decl init1 init2/;
use B::C::Helpers qw/mark_package read_utf8_string strlen_flags is_using_mro/;
use B::C::Helpers::Symtable qw/objsym savesym/;
use B::C::Save qw/savestashpv/;
use B::C::Save::Hek qw/save_shared_he/;

my ($swash_ToCf);

sub swash_ToCf_value {
    return $swash_ToCf;
}

sub save {
    my ( $hv, $fullname ) = @_;

    $fullname = '' unless $fullname;
    my $sym = objsym($hv);
    return $sym if defined $sym;
    my $name     = $hv->NAME;
    my $is_stash = $name;
    my $magic;
    my $hv_max_plus_one = 8;    # Default.

    if ($name) {

        # It's a stash. See issue 79 + test 46
        debug(
            hv => "Saving stash HV \"%s\" from \"$fullname\" 0x%x MAX=%d\n",
            $name, $$hv, $hv->MAX
        );

        # A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
        # the only symptom is that sv_reset tries to reset the PMf_USED flag of
        # a trashed op but we look at the trashed op_type and segfault.
        my $no_gvadd = $name eq 'main' ? 1 : 0;

        $sym = savestashpv( $name, $no_gvadd );    # inc hv_index
        savesym( $hv, $sym );

        # fix overload stringify
        if ( $hv->FLAGS & SVf_AMAGIC and length($name) ) {
            init2()->add( sprintf( "mro_isa_changed_in(%s);  /* %s */", $sym, $name ) );
        }

        # Add aliases if namecount > 1 (GH #331)
        # There was no B API for the count or multiple enames, so I added one.
        my @enames = $hv->ENAMES;
        if ( @enames > 1 ) {
            debug( hv => "Saving for $name multiple enames: ", join( " ", @enames ) );
            my $name_count = $hv->name_count;

            # If the stash name is empty xhv_name_count is negative, and names[0] should
            # be already set. but we rather write it.
            init()->no_split;
            $hv_max_plus_one = $hv->MAX + 1;

            # unshift @enames, $name if $name_count < 0; # stashpv has already set names[0]
            init()->add(
                "if (!SvOOK($sym)) {",    # hv_auxinit is not exported
                "  HE **a;",
                "#ifdef PERL_USE_LARGE_HV_ALLOC",
                sprintf( "  Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(%d) + sizeof(struct xpvhv_aux), HE*);", $hv_max_plus_one ),
                "#else",
                sprintf( "  Newxz(a, %d + sizeof(struct xpvhv_aux), HE*);", $hv_max_plus_one ),
                "#endif",
                "  SvOOK_on($sym);",
                "}",
                "{",
                "  struct xpvhv_aux *aux = HvAUX($sym);",
                sprintf( "  Newx(aux->xhv_name_u.xhvnameu_names, %d, HEK*);", scalar $name_count ),
                sprintf( "  aux->xhv_name_count = %d;",                       $name_count )
            );
            my $i = 0;
            while (@enames) {
                my ( $cstring, $cur, $utf8 ) = strlen_flags( shift @enames );
                init()->add(
                    sprintf(
                        "  aux->xhv_name_u.xhvnameu_names[%u] = share_hek(%s, %d, 0);",
                        $i++, $cstring, $utf8 ? -$cur : $cur
                    )
                );
            }
            init()->add("}");
            init()->split;
        }

        # issue 79, test 46: save stashes to check for packages.
        # and via B::STASHGV we only save stashes for stashes.
        # For efficiency we skip most stash symbols unless -fstash.
        # However it should be now safe to save all stash symbols.
        # $fullname !~ /::$/ or
        if ( !$B::C::stash ) {    # -fno-stash: do not save stashes
            $magic = $hv->save_magic( '%' . $name . '::' );    #symtab magic set in PMOP #188 (#267)
            if ( is_using_mro() && mro::get_mro($name) eq 'c3' ) {
                B::C::make_c3($name);
            }

            if ( $magic and $magic =~ m/c/ ) {
                debug( mg => "defer AMT magic of $name" );

                # defer AMT magic of XS loaded hashes.
                #init1()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI);]);
            }
            return $sym;
        }
        return $sym if B::C::skip_pkg($name) or $name eq 'main';
        init()->add("SvREFCNT_inc($sym);");
        debug( hv => "Saving stash keys for HV \"$name\" from \"$fullname\"" );
    }

    # Ordinary HV or Stash
    # KEYS = 0, inc. dynamically below with hv_store

    xpvhvsect()->comment("stash mgu max keys");
    xpvhvsect()->add(
        sprintf(
            "Nullhv, {0}, %d, %d",
            $hv->MAX, 0
        )
    );

    my $flags = $hv->FLAGS & ~SVf_READONLY & ~SVf_PROTECT;

    svsect()->add(
        sprintf(
            "&xpvhv_list[%d], %Lu, 0x%x, {0}",
            xpvhvsect()->index, $hv->REFCNT, $flags
        )
    );

    # XXX failed at 16 (tied magic) for %main::
    if ( !$is_stash and ( $hv->FLAGS & SVf_OOK ) ) {
        $sym = sprintf( "&sv_list[%d]", svsect()->index );
        my $hv_max_plus_one = $hv->MAX + 1;

        # riter required, new _aux struct at the end of the HvARRAY. allocate ARRAY also.
        init()->add(
            "{\tHE **a;",
            "#ifdef PERL_USE_LARGE_HV_ALLOC",
            sprintf( "\tNewxz(a, PERL_HV_ARRAY_ALLOC_BYTES(%d) + sizeof(struct xpvhv_aux), HE*);", $hv_max_plus_one ),
            "#else",
            sprintf( "\tNewxz(a, %d + sizeof(struct xpvhv_aux), HE*);", $hv_max_plus_one ),
            "#endif",
            "\tHvARRAY($sym) = a;",
            sprintf( "\tHvRITER_set(%s, %d);", $sym, $hv->RITER ),
            "}"
        );
    }

    svsect()->debug( $fullname, $hv );
    my $sv_list_index = svsect()->index;
    debug(
        hv => "saving HV %%%s &sv_list[%d] 0x%x MAX=%d KEYS=%d",
        $fullname, $sv_list_index, $$hv, $hv->MAX, $hv->KEYS
    );

    # do not need ARRAY_utf8: 5.20 came up with the utf8 fix
    my @contents = $hv->ARRAY;

    # protect against recursive self-reference
    # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
    # value => rv => cv => ... => rv => same hash
    $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
    push @B::C::static_free, $sym if $hv->FLAGS & SVs_OBJECT;

    if (@contents) {
        local $B::C::const_strings = $B::C::const_strings;
        my ( $i, $length );
        $length = scalar(@contents);

        # Walk the values and save them into symbols
        for ( $i = 1; $i < @contents; $i += 2 ) {
            my $key = $contents[ $i - 1 ];    # string only
            my $sv  = $contents[$i];

            WARN( "HV recursion? with $fullname\{$key\} -> %s\n", $sv->RV ) if ref($sv) eq 'B::RV' and defined objsym($sv) and debug('hv');

            if ($is_stash) {
                if ( ref($sv) eq "B::GV" and $sv->NAME =~ /::$/ ) {
                    $sv = bless $sv, "B::STASHGV";    # do not expand stash GV's only other stashes
                    debug( hv => "saving STASH $fullname" . '{' . $key . "}" );
                    $contents[$i] = $sv->save( $fullname . '{' . $key . '}' );
                }
                else {
                    debug( hv => "skip STASH symbol *" . $fullname . $key );
                    $contents[$i] = undef;
                    $length -= 2;

                }
            }
            else {
                debug( hv => "saving HV \$" . $fullname . '{' . $key . "}" );
                $contents[$i] = $sv->save( $fullname . '{' . $key . '}' );    # Turn the hash value into a symbol
            }
        }

        my $hv_total_keys = 0;

        # If we didn't just clear all the values.
        if ($length) {                                                        # there may be skipped STASH symbols
            init()->no_split;
            init()->add(
                "{",
                "char *array;",
                "HE *entry;",
                "HE **oentry;",
                sprintf( "HV *hv = %s%s;", $sym =~ /^hv|\(HV/ ? '' : '(HV*)', $sym ),
                sprintf( "Newxz (array, PERL_HV_ARRAY_ALLOC_BYTES (%d), char);", $hv_max_plus_one ),
                sprintf( "HvARRAY (%s) = (HE **) array;",                        $sym ),
            );

            while (@contents) {
                my ( $key, $value ) = splice( @contents, 0, 2 );

                next unless defined $value;    # Skip values which we set to undef and didn't save the symbol.

                # Insert each key into the hash.
                {
                    my $hek_sym        = save_shared_he($key);
                    my $hek_sym_simple = $hek_sym;
                    $hek_sym_simple =~ s{^&}{};
                    init()->add(
                        "",
                        "entry = (HE*)safemalloc(sizeof(HE));",
                        sprintf( "HeKEY_hek(entry) = &(%s->shared_he_hek);", $hek_sym_simple ),
                        sprintf( "HeVAL (entry) = %s;",                      $value ),
                        sprintf( "oentry = &(HvARRAY (%s))[HEK_HASH(&(%s->shared_he_hek)) & (I32) %d];", $sym, $hek_sym_simple, $hv_max_plus_one ),
                        "HeNEXT(entry) = *oentry;",
                        "*oentry = entry;"
                    );
                    $hv_total_keys++;
                }

                # issue 272: if SvIsCOW(sv) && SvLEN(sv) == 0 => sharedhek (key == "")
                # >= 5.10: SvSHARED_HASH: PV offset to hek_hash

                debug( hv => "  HV key \"%s\" = %s\n", $key, $value );

                #if (   !$swash_ToCf
                #    and $fullname =~ /^utf8::SWASHNEW/
                #    and $cstring eq '"utf8\034unicore/To/Cf.pl\0340"'
                #    and $cur == 23 ) {
                #    $swash_ToCf = $value;
                #    verbose("Found PL_utf8_tofold ToCf swash $value");
                #}
            }
            init()->add("}");
            init()->split;
            init()->add( sprintf( "HvTOTALKEYS(%s) = %d;", $sym, $hv_total_keys ) );
        }
    }
    else {    # empty contents still needs to set keys=0
              # test 36, 140
        init()->add("HvTOTALKEYS($sym) = 0;");
    }
    $magic = $hv->save_magic($fullname);
    init()->add("SvREADONLY_on($sym);") if $hv->FLAGS & SVf_READONLY;
    if ( $magic =~ /c/ ) {

        # defer AMT magic of XS loaded stashes
        my ( $cname, $len, $utf8 ) = strlen_flags($name);
        init2()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI|$utf8);]);
    }

    if ( $name and is_using_mro() and mro::get_mro($name) eq 'c3' ) {
        B::C::make_c3($name);
    }
    return $sym;
}

1;
