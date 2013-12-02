#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=235
# assert !CvCVGV_RC(cv) in function Perl_newATTRSUB. again
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;

use B::C;
my $when = "1.42_61";
ctest(1,'6','C,-O3,-UCarp','ccode235i',<<'EOF',($B::C::VERSION lt $when ? "TODO " : "").'#235 assert !CvCVGV_RC(cv)');
BEGIN{$INC{Carp.pm}++}
$d = pack("U*", 0xe3, 0x81, 0xAF); { use bytes; $ol = bytes::length($d) } print $ol
EOF
