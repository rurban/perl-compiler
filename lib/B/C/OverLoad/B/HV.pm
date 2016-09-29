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

sub swash_ToCf_value {    # NO idea what it s ??
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

            my $hv_max_plus_one = $hv->MAX + 1;

            # If the stash name is empty xhv_name_count is negative, and names[0] should
            # be already set. but we rather write it.
            init()->no_split;

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

    # reduce the content
    # remove values from contents we are not going to save
    my @hash_content_to_save;
    my @contents = $hv->ARRAY;
    if (@contents) {
        local $B::C::const_strings = $B::C::const_strings;
        my ( $i, $length );
        $length = scalar(@contents);

        # Walk the values and save them into symbols
        for ( $i = 1; $i < @contents; $i += 2 ) {
            my $key = $contents[ $i - 1 ];    # string only
            my $sv  = $contents[$i];
            my $value;

            WARN( "HV recursion? with $fullname\{$key\} -> %s\n", $sv->RV ) if ref($sv) eq 'B::RV' and defined objsym($sv) and debug('hv');

            if ($is_stash) {
                if ( ref($sv) eq "B::GV" and $sv->NAME =~ /::$/ ) {
                    $sv = bless $sv, "B::STASHGV";    # do not expand stash GV's only other stashes
                    debug( hv => "saving STASH $fullname" . '{' . $key . "}" );
                    $value = $sv->save( $fullname . '{' . $key . '}' );
                }
            }
            else {
                debug( hv => "saving HV \$" . $fullname . '{' . $key . "}" );
                $value = $sv->save( $fullname . '{' . $key . '}' );    # Turn the hash value into a symbol
            }

            push @hash_content_to_save, [ $key, $value ] if defined $value;
        }
    }

    # Ordinary HV or Stash
    # KEYS = 0, inc. dynamically below with hv_store

    my $hv_total_keys = scalar(@hash_content_to_save);
    my $max           = get_max_hash_from_keys($hv_total_keys);
    xpvhvsect()->comment("HV* xmg_stash, union _xmgu mgu, STRLEN xhv_keys, STRLEN xhv_max");
    xpvhvsect()->add( sprintf( "Nullhv, {0}, %d, %d", $hv_total_keys, $max ) );

    my $flags = $hv->FLAGS & ~SVf_READONLY & ~SVf_PROTECT;

    svsect()->add(
        sprintf(
            "&xpvhv_list[%d], %Lu, 0x%x, {0}",
            xpvhvsect()->index, $hv->REFCNT, $flags
        )
    );
    my $sv_list_index = svsect()->index;

    # protect against recursive self-reference
    # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
    # value => rv => cv => ... => rv => same hash
    $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
    push @B::C::static_free, $sym if $hv->FLAGS & SVs_OBJECT;

    if (@hash_content_to_save) {
        init()->no_split;
        init()->add(
            "{",
            "char *array;",
            "HE *entry;",
            "HE **oentry;",

            # malloc the hash array + the xpvhv_aux which is part of it
            sprintf( "Newxz (array, PERL_HV_ARRAY_ALLOC_BYTES (%d) + sizeof(struct xpvhv_aux), char);", $max + 1 ),

            # setting the hash array to the HV (in sv_list) in sv_any
            sprintf( "HvARRAY (%s) = (HE **) array;", $sym ),
        );

        #my $i = 0;
        #my %hash_kv = ( map { $i++, $_ } @hash_content_to_save );

        foreach my $elt (@hash_content_to_save) {    # loop on the array # FIXME to improve: add randomization
            my ( $key, $value ) = @$elt;

            # Insert each key into the hash.
            {
                my $hek_sym = save_shared_he($key);

                my $C_CODE = <<'EOS';

                    entry            = (HE*) safemalloc(sizeof(HE));
                    HeKEY_hek(entry) = &(~HEK_SYM~->shared_he_hek);
                    HeVAL (entry)    = ~VALUE~;
                    oentry           = &(HvARRAY (~SYM~))[HEK_HASH(&(~HEK_SYM~->shared_he_hek)) & (I32) ~MAX~];
                    HeNEXT(entry)    = *oentry;
                    *oentry          = entry;
EOS

                # lazy template
                my %macro = (
                    HEK_SYM => $hek_sym,
                    VALUE   => $value,
                    SYM     => $sym,
                    MAX     => $max,
                );
                $C_CODE =~ s{(~([^~]+)~)}{$macro{$2}}g;

                init()->add($C_CODE);
            }

            # issue 272: if SvIsCOW(sv) && SvLEN(sv) == 0 => sharedhek (key == "")
            # >= 5.10: SvSHARED_HASH: PV offset to hek_hash

            debug( hv => q{ HV key "%s" = %s}, $key, $value );

            #if (   !$swash_ToCf
            #    and $fullname =~ /^utf8::SWASHNEW/
            #    and $cstring eq '"utf8\034unicore/To/Cf.pl\0340"'
            #    and $cur == 23 ) {
            #    $swash_ToCf = $value; ????
            #    verbose("Found PL_utf8_tofold ToCf swash $value");
            #}
        }

        # save the iterator in hv_aux (and malloc it)
        if ( !$is_stash and ( $hv->FLAGS & SVf_OOK ) ) {

            # hv_auxinit is doing the malloc for us, could use Newxz if not public
            init()->add( sprintf( "HvRITER_set(%s, %d);", $sym, $hv->RITER ) ),    # could use -1 ?
        }

        init()->add("}");
        init()->split;
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

sub get_max_hash_from_keys {
    my $keys = shift;

    my $default = 7;
    return $default unless $keys;    # default hash max value

    return 2**( int( log($keys) / log(2) ) + 1 ) - 1;
}

1;
