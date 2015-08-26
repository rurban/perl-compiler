package B::C::Decimal;

use strict;
use Config;

use B::C::Config;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/get_integer_value get_double_value/;

my $POW = ( $Config{ivsize} * 4 - 1 );    # poor editor

# previously known as 'sub ivx'
sub get_integer_value ($) {
    my $ivx       = shift;
    my $ivdformat = $Config{ivdformat};
    $ivdformat =~ s/"//g;                 #" poor editor
    my $intmax = ( 1 << $POW ) - 1;
    my $L      = 'L';

    # LL for 32bit -2147483648L or 64bit -9223372036854775808L
    $L = 'LL' if $Config{ivsize} == 2 * $Config{ptrsize};

    # UL if > INT32_MAX = 2147483647
    my $sval = sprintf( "%${ivdformat}%s", $ivx, $ivx > $intmax ? "U$L" : "" );
    if ( $ivx < -$intmax ) {
        $sval = sprintf( "%${ivdformat}%s", $ivx, 'LL' );    # DateTime
    }
    if ( $INC{'POSIX.pm'} ) {

        # i262: LONG_MIN -9223372036854775808L integer constant is so large that it is unsigned
        if ( $ivx == POSIX::LONG_MIN() ) {
            $sval = "PERL_LONG_MIN";
        }
        elsif ( $ivx == POSIX::LONG_MAX() ) {
            $sval = "PERL_LONG_MAX";
        }

        #elsif ($ivx == POSIX::HUGE_VAL()) {
        #  $sval = "HUGE_VAL";
        #}
    }
    $sval = '0' if $sval =~ /(NAN|inf)$/i;
    return $sval;
}

# protect from warning: floating constant exceeds range of ‘double’ [-Woverflow]
# previously known as 'sub nvx'

my $dblmax = "1.79769313486232e+308";

sub get_double_value ($) {
    my $nvx       = shift;
    my $nvgformat = $Config{nvgformat};
    $nvgformat =~ s/"//g;    #" poor editor

    # my $ldblmax = "1.18973149535723176502e+4932L"
    my $ll = $Config{d_longdbl} ? "LL" : "L";
    if ( $nvgformat eq 'g' ) {    # a very poor choice to keep precision
                                  # on intel 17-18, on ppc 31, on sparc64/s390 34
        $nvgformat = $Config{uselongdouble} ? '.17Lg' : '.16g';
    }
    my $sval = sprintf( "%${nvgformat}%s", $nvx, $nvx > $dblmax ? $ll : "" );
    if ( $nvx < -$dblmax ) {
        $sval = sprintf( "%${nvgformat}%s", $nvx, $ll );
    }
    if ( $INC{'POSIX.pm'} ) {
        if ( $nvx == POSIX::DBL_MIN() ) {
            $sval = "DBL_MIN";
        }
        elsif ( $nvx == POSIX::DBL_MAX() ) {    #1.797693134862316e+308
            $sval = "DBL_MAX";
        }
    }
    $sval = '0' if $sval =~ /(NAN|inf)$/i;
    $sval .= '.00' if $sval =~ /^-?\d+$/;
    return $sval;
}

1;
