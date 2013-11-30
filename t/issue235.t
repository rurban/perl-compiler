#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=235
# assert !CvCVGV_RC(cv) in function Perl_newATTRSUB. again
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
ctest(1,'6','C,-O3','ccode235i',<<'EOF','TODO #235 assert !CvCVGV_RC(cv)');
$d = pack("U*", 0xe3, 0x81, 0xAF); { use bytes; $ol = bytes::length($d) } print $ol
EOF
