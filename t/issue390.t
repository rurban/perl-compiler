#! /usr/bin/env perl
# GH #390 wrong PERL_MAGIC_backref REFCOUNTED mg_flags
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
my $todo = ($B::C::VERSION le '1.54_13') ? "TODO" : "";

ctestok(1,'C,-O3','ccode390i',<<'EOF',$todo.' \#390 backref REFCOUNTED flag');
print test(); print test();
sub test() {
    *test = sub ()  { "k" };
    "o";
}
EOF

