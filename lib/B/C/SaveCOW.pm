package B::C::Save;

use strict;

use B qw(cstring svref_2object);
use B::C::Config;
use B::C::File qw( decl );
use B::C::Helpers qw/cow_strlen_flags/;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw/savepv/;

my %strtable;

# Two different families of save functions
#   save_* vs save*

my $pv_index = -1;

sub inc_pv_index {
    return ++$pv_index;
}

my $max_string_len;

sub set_max_string_len {
    $max_string_len = shift;
}

sub savepv {
    my $pv    = shift;
    my ( $cstring, $cur, $len, $utf8 ) = cow_strlen_flags($pv);
    
    return @{$strtable{$cstring}} if defined $strtable{$cstring};
    my $pvsym = sprintf( "cowpv%d", inc_pv_index() );
    if ( defined $max_string_len && $cur > $max_string_len ) {
        my $chars = join ', ', map { cchar $_ } split //, pack( "a*", $pv );
        decl()->add( sprintf( "Static const char %s[] = { %s };", $pvsym, $chars ) );
        $strtable{$cstring} = [$pvsym, $cur, $len];
    }
    else {
        if ( $pv ne "0" ) {    # sic
            decl()->add( sprintf( "Static const char %s[] = %s;", $pvsym, $cstring ) );
            $strtable{$cstring} = [$pvsym, $cur, $len];
        }
    }
    return ($pvsym, $cur, $len); # NOTE: $cur is total size of the perl string. len would be the length of the C string.
}

1;
