package B::C::Decimal;

use strict;

use B::C::Config ();
use B::C::Setup;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/get_integer_value get_double_value/;

my $POW    = ( $B::C::Config::Config{ivsize} * 4 - 1 );    # poor editor
my $INTMAX = ( 1 << $POW ) - 1;

# LL for 32bit -2147483648L or 64bit -9223372036854775808L
my $UL        = _ull();
my $IVDFORMAT = _ivdformat();

# previously known as 'sub ivx'
sub get_integer_value ($) {
    my $ivx = shift;

    # UL if > INT32_MAX = 2147483647
    my $sval = sprintf( "%${IVDFORMAT}%s", $ivx, $ivx > $INTMAX ? $UL : "" );
    if ( $ivx < -$INTMAX ) {
        $sval = sprintf( "%${IVDFORMAT}%s", $ivx, 'LL' );    # DateTime
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

my $DBLMAX    = "1.79769313486232e+308";
my $NVGFORMAT = _nvgformat();

my $LL = $B::C::Config::Config{d_longdbl} ? "LL" : "L";

sub get_double_value ($) {
    my $nvx = shift;

    # Handle infinite and NaN values
    if ( defined $nvx ) {
        if ( $B::C::Config::Config{d_isinf} ) {
            return 'INFINITY'  if $nvx =~ /^Inf/i;
            return '-INFINITY' if $nvx =~ /^-Inf/i;
        }
        return 'NAN' if $nvx =~ /^NaN/i and $B::C::Config::Config{d_isnan};
        # TODO NANL for long double
    }

    # my $DBLMAX = "1.18973149535723176502e+4932L"
    my $sval = sprintf( "%${NVGFORMAT}%s", $nvx, $nvx > $DBLMAX ? $LL : "" );
    if ( $nvx < -$DBLMAX ) {
        $sval = sprintf( "%${NVGFORMAT}%s", $nvx, $LL );
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

sub _ivdformat {
    my $format = $B::C::Config::Config{ivdformat};

    # QUESTION : is it still really required ?
    $format =~ s/"//g;    #" poor editor
    return $format;
}

sub _nvgformat {
    my $format = $B::C::Config::Config{nvgformat};

    # QUESTION : is it still really required ?
    $format =~ s/"//g;    #" poor editor
    if ( $format eq 'g' ) {    # a very poor choice to keep precision
                               # on intel 17-18, on ppc 31, on sparc64/s390 34
        $format = $B::C::Config::Config{uselongdouble} ? '.17Lg' : '.16g';
    }
    return $format;

}

sub _ull {
    return $B::C::Config::Config{ivsize} == 2 * $B::C::Config::Config{ptrsize} ? 'ULL' : 'UL';
}

1;
