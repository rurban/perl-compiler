#!./perl

BEGIN {
    push @INC, "t/CORE/lib";
    require 't/CORE/test.pl';
}

is( 1 ? 1 : 0, 1, 'compile time, true' );
is( 0 ? 0 : 1, 1, 'compile time, false' );

$x = 1;
is(  $x ? 1 : 0, 1, 'run time, true');
is( !$x ? 0 : 1, 1, 'run time, false');

done_testing();
