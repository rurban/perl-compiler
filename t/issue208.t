#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=208
# missing DESTROY call at DESTRUCT time 
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 2;
my $script = <<'EOF';
sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " }   my $k=bless {}, MyKooh;
sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" } our $k=bless {}, OurKooh;
EOF
my $expected = ($] >= 5.014 ? 'RUN MyKooh DESTRUCT OurKooh' : ' MyKooh  OurKooh');

# fixed with 1.42_66, 5.16+5.18
use B::C ();
my $todo = ($] > 5.015 and $B::C::VERSION gt '1.42_65') ? "" : "TODO ";
ctest(1, $expected,'C','ccode208i',$script,$todo.'#208 missing DESTROY call at DESTRUCT time');
ctest(2, $expected,'C,-O3','ccode208i',$script,'TODO #208 -ffast-destruct');
