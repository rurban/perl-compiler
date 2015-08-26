package B::C::Save;

use strict;

use B qw(SVp_POK cstring);
use B::C::Config;
use B::C::File qw( xpvmgsect decl init );

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw/savepvn save_hek/;

my %hektable;
my $hek_index = 0;

# Shared global string in PL_strtab.
# Mostly GvNAME and GvFILE, but also CV prototypes or bareword hash keys.
sub save_hek {
    my $str     = shift;         # not cstring'ed
    my $dynamic = shift;         # not yet implemented. see lexsub CvNAME in CV::save
    my $len     = length $str;

    # force empty string for CV prototypes
    if ( !$len and !@_ ) { wantarray ? return ( "NULL", 0 ) : return "NULL"; }
    if ( defined $hektable{$str} ) {
        return wantarray
          ? ( $hektable{$str}, length( pack "a*", $hektable{$str} ) )
          : $hektable{$str};
    }
    my $cur = length( pack "a*", $str );

    if ( utf8::is_utf8($str) ) {
        my $pv = $str;
        utf8::encode($pv);
        $cur = -length $pv;
    }

    my $sym = sprintf( "hek%d", $hek_index++ );
    $hektable{$str} = $sym;
    my $cstr = cstring($str);
    decl()->add( sprintf( "Static HEK *%s;", $sym ) );

    debug( pv => "Saving hek %s %s cur=%d", $sym, $cstr, $cur );

    # randomized global shared hash keys:
    #   share_hek needs a non-zero hash parameter, unlike hv_store.
    #   Vulnerable to oCERT-2011-003 style DOS attacks?
    #   user-input (object fields) does not affect strtab, it is pretty safe.
    # But we need to randomize them to avoid run-time conflicts
    #   e.g. "Prototype mismatch: sub bytes::length (_) vs (_)"
    init()->add(
        sprintf(
            "%s = share_hek(%s, %d, %s);",
            $sym, $cstr, $cur, '0'
        )
    );
    return wantarray ? ( $sym, $cur ) : $sym;
}

sub savepvn {
    my ( $dest, $pv, $sv, $cur ) = @_;
    my @init;

    my $max_string_len = $B::C::max_string_len;    # FIXME to move here
                                                   # work with byte offsets/lengths
    $pv = pack "a*", $pv if defined $pv;
    if ( defined $max_string_len && length($pv) > $max_string_len ) {
        push @init, sprintf( "Newx(%s,%u,char);", $dest, length($pv) + 2 );
        my $offset = 0;
        while ( length $pv ) {
            my $str = substr $pv, 0, $max_string_len, '';
            push @init,
              sprintf(
                "Copy(%s,$dest+$offset,%u,char);",
                cstring($str), length($str)
              );
            $offset += length $str;
        }
        push @init, sprintf( "%s[%u] = '\\0';", $dest, $offset );
        debug( pv => "Copying overlong PV %s to %s\n", cstring($pv), $dest );
    }
    else {
        # If READONLY and FAKE use newSVpvn_share instead. (test 75)
        if ( $sv and ( ( $sv->FLAGS & 0x09000000 ) == 0x09000000 ) ) {
            debug( sv => "Saving shared HEK %s to %s\n", cstring($pv), $dest );
            my $hek = save_hek($pv);
            push @init, sprintf( "%s = HEK_KEY($hek);", $dest ) unless $hek eq 'NULL';
            if ( DEBUGGING() ) {    # we have to bypass a wrong HE->HEK assert in hv.c
                push @B::C::static_free, $dest;
            }
        }
        else {
            my $cstr = cstring($pv);
            my $cur ||= ( $sv and ref($sv) and $sv->can('CUR') and ref($sv) ne 'B::GV' ) ? $sv->CUR : length( pack "a*", $pv );
            if ( $sv and B::C::IsCOW($sv) ) {
                $pv .= "\0\001";
                $cstr = cstring($pv);
                $cur += 2;
            }
            debug( sv => "Saving PV %s:%d to %s", $cstr, $cur, $dest );
            $cur = 0 if $cstr eq "" and $cur == 7;    # 317
            push @init, sprintf( "%s = savepvn(%s, %u);", $dest, $cstr, $cur );
        }
    }
    return @init;
}

sub patch_dlsym {
    my ( $sv, $fullname, $ivx ) = @_;
    my $pkg = '';
    if ( ref($sv) eq 'B::PVMG' ) {
        my $stash = $sv->SvSTASH;
        $pkg = $stash->can('NAME') ? $stash->NAME : '';
    }
    my $name = $sv->FLAGS & SVp_POK ? $sv->PVX : "";

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
1;
