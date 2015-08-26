package B::C::Save::Hek;

use strict;

use B qw(cstring);
use B::C::Config;
use B::C::File qw( decl init );

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw/save_hek/;

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

1;
