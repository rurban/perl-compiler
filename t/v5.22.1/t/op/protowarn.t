#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, qw(. ../lib);
}

use strict;
use warnings;

BEGIN {
    require './test.pl';
}

plan( tests => 12 );

use vars qw{ @warnings $sub $warn };

BEGIN {
    $warn = 'Illegal character in prototype';
}

my @tests;

sub one_warning_ok {
    my $s    = scalar(@warnings);
    my $subs = substr( $warnings[0], 0, length($warn) );
    my $w    = $warn;
    push @tests, sub {
        cmp_ok( $s,    '==', 1,  'One warning' );
        cmp_ok( $subs, 'eq', $w, 'warning message' );
    };
    @warnings = ();
}

sub no_warnings_ok {
    my $s = scalar(@warnings);
    push @tests, sub {
        cmp_ok( $s, '==', 0, 'No warnings' );
    };
    @warnings = ();
}

BEGIN {
    $SIG{'__WARN__'} = sub { push @warnings, @_ };
    $| = 1;
}

BEGIN { @warnings = () }

$sub = sub (x) { };

BEGIN {
    one_warning_ok;
}

{
    no warnings 'syntax';
    $sub = sub (x) { };
}

BEGIN {
    no_warnings_ok;
}

{
    no warnings 'illegalproto';
    $sub = sub (x) { };
}

BEGIN {
    no_warnings_ok;
}

{
    no warnings 'syntax';
    use warnings 'illegalproto';
    $sub = sub (x) { };
}

BEGIN {
    one_warning_ok;
}

BEGIN {
    $warn = q{Prototype after '@' for};
}

$sub = sub (@$) { };

BEGIN {
    one_warning_ok;
}

{
    no warnings 'syntax';
    $sub = sub (@$) { };
}

BEGIN {
    no_warnings_ok;
}

{
    no warnings 'illegalproto';
    $sub = sub (@$) { };
}

BEGIN {
    no_warnings_ok;
}

{
    no warnings 'syntax';
    use warnings 'illegalproto';
    $sub = sub (@$) { };
}

BEGIN {
    one_warning_ok;
}

map { $_->() } @tests;
