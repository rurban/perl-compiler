#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=44
# pp_aelemfast not implemented for local vars OPf_SPECIAL
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

# fails to compile non-threaded, wrong result threaded
my $script = <<'EOF';
my @a = (1,2);
print $a[0], "\n";
EOF

ctest(1, '^1$', "CC", "ccode44i", $script);
