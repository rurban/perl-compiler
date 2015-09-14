#!./perl

require 't/CORE/test.pl';

plan(2);
ok(1);

my $tmpfile = 'tmpfile';
open (tmp,'>', $tmpfile) || die "Can't create Cmd_while.tmp.";
print tmp "something\n";
close(tmp) or die "Could not close: $!";

ok(1);
