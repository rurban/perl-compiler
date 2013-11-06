#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=148
# Opening Bareword Filehandles for Writing Does not work
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $tmp = "ccode148i.tmp";
ctestok(1, "C", 'ccode148i', '$tmp="ccode148i.tmp";open(FH,">",$tmp);print FH "1\n";close FH;print "ok" if -s $tmp', "Bareword FH") and unlink $tmp;
