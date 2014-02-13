#!./perl

# This file is for concatenation tests that require test.pl.
#
# concat.t cannot use test.pl as it needs to avoid using concatenation in
# its ok() function.

BEGIN {
    unshift @INC, 't/CORE-CPANEL/lib';
    require 't/CORE-CPANEL/test.pl';
}

plan 1;

fresh_perl_is <<'end', "ok\n", {},
    use encoding 'utf8';
    map { "a" . $a } ((1)x5000);
    print "ok\n";
end
 "concat does not lose its stack pointer after utf8 upgrade [perl #78674]";
