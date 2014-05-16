#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=105
# v5.16 Missing bc imports
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use Config ();
my $ITHREADS  = $Config::Config{useithreads};

my $source = 'package A;
use Storable qw/dclone/;

my $a = \"";
dclone $a;
print q(ok)';

my $cmt = "BC missing import 5.16";
my $todo = "TODO BC dclone 5.16thr " if $] > 5.015 and $ITHREADS;
plctestok(1, "ccode105i", $source, $todo.$cmt);
