#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=51
# B:CC errors on nested if statement with test on multiple variables
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $script = <<'EOF';
my ($p1, $p2) = (80, 80);
if ($p1 <= 23 && 23 <= $p2) {
    print "telnet\n";
}
elsif ($p1 <= 80 && 80 <= $p2) {
    print "http\n";
}
else {
    print "fail\n"
}
EOF

ctest(1, '^http$', "CC", "ccode51i", $script,
      "nested if on multiple variables - issue51");

