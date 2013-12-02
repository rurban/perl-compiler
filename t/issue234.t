#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=234
# new-cog
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;

ctest(1,'^4$','C,-O3','ccode234i',<<'EOF','TODO #234 -O3 pv2iv conversion for ranges: "-3" .. "0"');
$c = 0; for ("-3" .. "0") { $c++ } ; print "$c"
EOF
