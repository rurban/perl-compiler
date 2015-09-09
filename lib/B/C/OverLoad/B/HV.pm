package B::HV;

use strict;

use Config;
use B qw/cstring SVf_READONLY/;
use B::C::Config;
use B::C::File qw/init xpvhvsect svsect decl/;
use B::C::Helpers qw/mark_package/;
use B::C::Helpers::Symtable qw/objsym savesym/;

my ($swash_ToCf);

sub swash_ToCf_value {
    return $swash_ToCf;
}

my $hv_index = 0;

sub SVf_OOK { 0x02000000 }

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
        #my $adpmroot = ${$hv->PMROOT}; # XXX When was this fixed?
        my $adpmroot = 0;
        decl()->add("Static HV *hv$hv_index;");

        my $cname = cstring($name);
        my $len   = length( pack "a*", $name );    # not yet 0-byte safe. HEK len really
                                                   # TODO utf8 stashes
        if ( $name eq 'main' ) {
            init()->add(qq[hv$hv_index = gv_stashpvn($cname, $len, 0);\t/* get main:: stash */]);
        }
        else {
            init()->add(qq[hv$hv_index = gv_stashpvn($cname, $len, GV_ADD);\t/* stash */]);
        }
        if ($adpmroot) {
            init()->add(
                sprintf(
                    "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;",
                    $adpmroot
                )
            );
        }
        $sym = savesym( $hv, "hv$hv_index" );
        $hv_index++;

        # issue 79, test 46: save stashes to check for packages.
        # and via B::STASHGV we only save stashes for stashes.
        # For efficiency we skip most stash symbols unless -fstash.
        # However it should be now safe to save all stash symbols.
        # $fullname !~ /::$/ or
        if ( !$B::C::stash ) {    # -fno-stash: do not save stashes
            $magic = $hv->save_magic( '%' . $name . '::' );    #symtab magic set in PMOP #188 (#267)
            if ( mro::get_mro($name) eq 'c3' ) {
                mark_package( 'mro', 1 );
            }

            #if ($magic =~ /c/) {
            # defer AMT magic of XS loaded hashes. #305 Encode::XS with tiehash magic
            #  init2()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI);]);
            #}
            return $sym;
        }
        return $sym if skip_pkg($name) or $name eq 'main';
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

    svsect()->add(
        sprintf(
            "&xpvhv_list[%d], %lu, 0x%x, {0}",
            xpvhvsect()->index, $hv->REFCNT,
            $hv->FLAGS & ~SVf_READONLY
        )
    );

    # XXX failed at 16 (tied magic) for %main::
    if ( !$is_stash and ( $hv->FLAGS & SVf_OOK ) ) {
        $sym = sprintf( "&sv_list[%d]", svsect()->index );
        my $hv_max = $hv->MAX + 1;

        # riter required, new _aux struct at the end of the HvARRAY. allocate ARRAY also.
        init()->add(
            "{\tHE **a; struct xpvhv_aux *aux;",
            "#ifdef PERL_USE_LARGE_HV_ALLOC",
            sprintf(
                "\tNewxz(a, PERL_HV_ARRAY_ALLOC_BYTES(%d) + sizeof(struct xpvhv_aux), HE*);",
                $hv_max
            ),
            "#else",
            sprintf( "\tNewxz(a, %d + sizeof(struct xpvhv_aux), HE*);", $hv_max ),
            "#endif",
            "\tHvARRAY($sym) = a;",
            sprintf( "\tHvRITER_set($sym, %d);", $hv->RITER ),
            "}"
        );
    }

    svsect()->debug( $fullname, $hv );
    my $sv_list_index = svsect()->index;
    debug(
        hv => "saving HV %%%s &sv_list[$sv_list_index] 0x%x MAX=%d KEYS=%d\n",
        $fullname, $$hv, $hv->MAX, $hv->KEYS
    );

    # XXX B does not keep the UTF8 flag [RT 120535] #200
    # shared heks only since 5.10, our fixed C.xs variant
    my @contents = ( $hv->can('ARRAY_utf8') ) ? $hv->ARRAY_utf8 : $hv->ARRAY;    # protect against recursive self-reference
                                                                                 # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
                                                                                 # value => rv => cv => ... => rv => same hash
    $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
    if (@contents) {
        local $B::C::const_strings = $B::C::const_strings;
        my ( $i, $length );
        $length = scalar(@contents);
        for ( $i = 1; $i < @contents; $i += 2 ) {
            my $key = $contents[ $i - 1 ];                                       # string only
            my $sv  = $contents[$i];
            WARN( "HV recursion? with $fullname\{$key\} -> %s\n", $sv->RV )
              if ref($sv) eq 'B::RV'

              #and $sv->RV->isa('B::CV')
              and defined objsym($sv)
              and debug('hv');
            if ($is_stash) {
                if ( ref($sv) eq "B::GV" and $sv->NAME =~ /::$/ ) {
                    $sv = bless $sv, "B::STASHGV";                               # do not expand stash GV's only other stashes
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
                $contents[$i] = $sv->save( $fullname . '{' . $key . '}' );
            }
        }
        if ($length) {    # there may be skipped STASH symbols
            init()->no_split;
            init()->add(
                "{",
                sprintf( "\tHV *hv = %s$sym;", $sym =~ /^hv|\(HV/ ? '' : '(HV*)' )
            );
            while (@contents) {
                my ( $key, $value ) = splice( @contents, 0, 2 );
                if ($value) {
                    $value = "(SV*)$value" if $value !~ /^&sv_list/;
                    my $cur = length( pack "a*", $key );

                    if ( utf8::is_utf8($key) ) {
                        my $pv = $key;
                        utf8::encode($pv);
                        $cur = 0 - length($pv);
                    }

                    # issue 272: if SvIsCOW(sv) && SvLEN(sv) == 0 => sharedhek (key == "")
                    # >= 5.10: SvSHARED_HASH: PV offset to hek_hash
                    init()->add(
                        sprintf(
                            "\thv_store(hv, %s, %d, %s, %s);",
                            cstring($key), $cur, $value, 0
                        )
                    );    # !! randomized hash keys
                    debug( hv => "  HV key \"%s\" = %s\n", $key, $value );
                    if (   !$swash_ToCf
                        and $fullname =~ /^utf8::SWASHNEW/
                        and cstring($key) eq '"utf8\034unicore/To/Cf.pl\0340"'
                        and $cur == 23 ) {
                        $swash_ToCf = $value;
                        verbose("Found PL_utf8_tofold ToCf swash $value");
                    }
                }
            }
            init()->add("}");
            init()->split;
            init()->add( sprintf( "HvTOTALKEYS($sym) = %d;", $length / 2 ) );
        }
    }
    else {    # empty contents still needs to set keys=0
              # test 36, 140
        init()->add("HvTOTALKEYS($sym) = 0;");
    }
    $magic = $hv->save_magic($fullname);
    init()->add("SvREADONLY_on($sym);") if $hv->FLAGS & SVf_READONLY;
    if ( $magic =~ /c/ ) {

        # defer AMT magic of XS loaded hashes
        my $cname = cstring($name);
        my $len = length( pack "a*", $name );    # not yet 0-byte safe. HEK len really
        init2()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI);]);
    }
    if ( $name and mro::get_mro($name) eq 'c3' ) {
        mark_package( 'mro', 1 );
    }
    return $sym;
}

1;
