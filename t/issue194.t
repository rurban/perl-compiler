#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=194
# #194 and #311
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;

ctestok(1,'C,-O3','ccode194i',<<'EOF',($B::C::VERSION lt '1.45_09' ? "TODO ":"").'#194 truncate $0');
$0 = q{cc good morning dave}; #print "pid: $$\n";
$s=`ps auxw | grep "$$" | grep "cc good" | grep -v grep`;
print $s =~ /cc good morning dave/ ? q(ok) : $s;
EOF
