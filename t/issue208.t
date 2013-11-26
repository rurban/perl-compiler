#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=208
# missing DESTROY call at DESTRUCT time 
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 2;
my $expected = $] >= 5.014 ? 'RUN MyKooh DESTRUCT OurKooh' : ' MyKooh  OurKooh';

ctest(1, $expected,'C','ccode208i',<<'EOF','TODO #208 missing DESTROY call at DESTRUCT time');
sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " }   my $k=bless {}, MyKooh;
sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" } our $k=bless {}, OurKooh;
EOF

ctest(2, $expected,'C,-O3','ccode208i',<<'EOF','TODO #208 -ffast-destruct');
sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " }   my $k=bless {}, MyKooh;
sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" } our $k=bless {}, OurKooh;
EOF
