#!./perl -w

BEGIN {
    unshift @INC, 't/CORE-CPANEL/lib';
    require 't/CORE-CPANEL/test.pl';
}

use Config;
plan tests => 2;

SKIP: {
    skip "setpgrp() is not available", 2 unless $Config{d_setpgrp};
    ok(!eval { package A;sub foo { die("got here") }; package main; A->foo(setpgrp())});
    ok($@ =~ /got here/, "setpgrp() should extend the stack before modifying it");
}
