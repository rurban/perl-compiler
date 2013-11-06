#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=144
# BM search for \0
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

#use B::C;
#my $todo = ($B::C::VERSION < '1.43' ? "TODO " : "");
#$todo = "" if $] >= 5.016 or $] < 5.010;
my $todo = "";
ctestok(1, "C", 'ccode144i', 'print "ok" if 12 == index("long message\0xx","\0")', "${todo}BM search for \\0");
