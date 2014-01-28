#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=272
# the gp->hv slot is uninitialized
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use B::C ();
my $todo = ($B::C::VERSION ge '1.44' or $] > 5.019008) ? "" : "TODO ";

ctestok(1,'C,-O3','ccode272i',<<'EOF',$todo.'GP->HV/SV mishmash #272');
$d = q{ok}; $d{""} = qq{ok\n}; print $d{""}
EOF
