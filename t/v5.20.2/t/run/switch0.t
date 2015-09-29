#!./perl -0

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

plan tests => 1;

is(ord $/, 0, '$/ set to 0 via switch');
