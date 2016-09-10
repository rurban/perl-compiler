#! /usr/bin/env perl
# GH #391
use strict;
my @plan;
BEGIN {
  if ($ENV{PERL_CORE}) {
    unshift @INC, ('t', '../../lib');
  } else {
    unshift @INC, 't', "blib/arch", "blib/lib";
  }
  require TestBC;

  if ($^O eq 'MSWin32' and $ENV{APPVEYOR}) {
    @plan = (skip_all => 'Overlong tests, timeout on Appveyor CI');
  } else {
    @plan = (tests => 1);
  }
}
use Test::More @plan;
use B::C ();
my $todo = ($] >= 5.018 and $B::C::VERSION lt '1.52_18') ? "TODO 5.18-5.22" : "";

ctestok(1,'C,-O3','ccode391i',<<'EOF',$todo.'#391 doeval_compile');
use warnings 'closed';
eval "warn 'ok'"
EOF

