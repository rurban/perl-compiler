#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=48
# B:CC takes wrong truth value for array assignment in boolean context
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $script = <<'EOF';
sub f { () }
print((my ($v) = f()) ? 1 : 2, "\n");
EOF

use B::CC;
ctest(1, '^2', "CC", "ccode48i", $script,
      $B::CC::VERSION < 1.08
        ? "fixed with B::CC 1.08 r614 (B-C-1.28)"
        : undef);

