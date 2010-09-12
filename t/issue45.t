#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=45
# dorassign //= with old B::CC and newer perls
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $script = <<'EOF';
my $x;
$x //= 1;
print "ok" if $x;
EOF

use B::CC;
SKIP: {
  skip "dorassign was added with perl 5.10.0", 1 if $] < 5.010;
  ctestok(1, "CC", "ccode45i", $script,
	  $B::CC::VERSION < 1.09 ? "dorassign" : undef);
}
