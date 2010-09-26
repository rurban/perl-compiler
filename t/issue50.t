#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=50
# B::CC UV for <<
use Test::More tests => 6;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

use Config;
sub check {
    my $m = shift;
    ok($m > 0, sprintf("%lx $m", $m));
}

my $ivsize = $Config{ivsize};
my $maxuv = 0xffffffff if $ivsize == 4;
$maxuv    = 0xffffffffffffffff if $ivsize == 8;
$maxuv    = 0xffff if $ivsize == 2;
die "1..1 skipped, unknown ivsize\n" unless $maxuv;
my $maxiv = 0x7fffffff if $ivsize == 4;
$maxiv    = 0x7fffffffffffffff if $ivsize == 8;
$maxiv    = 0x7fff if $ivsize == 2;

check($maxuv);
check(($maxuv & $maxiv) << 1);

my $mask =  $maxuv;
check($mask);
my $mask1 = ($mask & $maxiv) << 1;
check($mask1);
$mask1 &= $maxuv;
check($mask1);

ctestok(6, "CC", "ccode50i",
      "my \$m=$maxuv;my \$n=(\$m & $maxiv) << 1; print(\$n>0?'ok':'nok');",
      "perlcc UV << issue50");
