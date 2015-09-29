#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    *ARGV = *DATA;
    plan(tests => 3);
}

pass("first test");
is( scalar <>, "ok 2\n", "read from aliased DATA filehandle");
pass("last test");

__DATA__
ok 2
