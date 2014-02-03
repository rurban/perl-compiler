#!./perl

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

plan tests => 8;

# symbolic filehandles should only result in glob entries with FH constructors

$|=1;
my $a = "SYM000";
ok(!defined(fileno($a)));
ok(!defined *{$a});

select select $a;
ok(defined *{$a});

$a++;
ok(!close $a);
ok(!defined *{$a});

ok(open($a, ">&STDOUT"));
ok(defined *{$a});

ok(close $a);

