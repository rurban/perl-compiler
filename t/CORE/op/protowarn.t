#!./perl

BEGIN { require 't/CORE/test.pl' }

use strict;
use warnings;

plan( tests => 12 );

use vars qw{ @warnings $sub $warn };

BEGIN {
    $warn = 'Illegal character in prototype';
}

sub one_warning_ok {
    cmp_ok(scalar(@warnings), '==', 1, 'One warning');
    cmp_ok(substr($warnings[0],0,length($warn)),'eq',$warn,'warning message');
    @warnings = ();
}

sub no_warnings_ok {
    cmp_ok(scalar(@warnings), '==', 0, 'No warnings');
    @warnings = ();
}

$SIG{'__WARN__'} = sub { push @warnings, @_ };
$| = 1;

@warnings = ();

eval q/$sub = sub (x) { }/;
one_warning_ok();


eval q{
    no warnings 'syntax';
    $sub = sub (x) { };
};

no_warnings_ok;


eval q{
    no warnings 'illegalproto';
    $sub = sub (x) { };
};

no_warnings_ok;

eval q{
    no warnings 'syntax';
    use warnings 'illegalproto';
    $sub = sub (x) { };
};

one_warning_ok;

$warn = q{Prototype after '@' for};
eval q/$sub = sub (@$) { }/;

one_warning_ok;

eval q{
    no warnings 'syntax';
    $sub = sub (@$) { };
};

no_warnings_ok;


eval q{
    no warnings 'illegalproto';
    $sub = sub (@$) { };
};

no_warnings_ok;

eval q{
    no warnings 'syntax';
    use warnings 'illegalproto';
    $sub = sub (@$) { };
};

one_warning_ok;

