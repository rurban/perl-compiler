#!./perl -w

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

use Config;
plan tests => 2;

SKIP: {
    skip "setpgrp() is not available", 2 unless $Config{d_setpgrp};
    ok(!eval { package A;sub foo { die("got here") }; package main; A->foo(setpgrp())});
    ok($@ =~ /got here/, "setpgrp() should extend the stack before modifying it");
}
