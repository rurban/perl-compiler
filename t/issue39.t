#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=39
# B::CC generated code aborts with "Bizarre copy of ARRAY in leavesub"
use Test::More tests => 1;
use strict;
BEGIN {
    unshift @INC, 't';
    require TestBC;
}

my $script = <<'EOF';
sub f1 { 0 }
sub f2 {
   my $x;
   if ( f1() ) {}
   if ($x) {} else { [$x]  }
}
my @a = f2();
print "ok";
EOF

TODO: {
  local $TODO = "broken with 5.24" if $] > 5.023007;
  ctestok(1, "CC", "ccode39i", $script,
          "CC Bizarre copy of ARRAY in leavesub fixed with r596");
}
