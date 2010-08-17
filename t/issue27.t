#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=27
use Test::More tests => 1;
BEGIN {
  unshift @INC, 't';
  require 'test.pl';
}
use strict;
prepare_c_tests();
run_cc_test(1, "C", "require LWP::UserAgent;\nprint q(ok);", "ok",1,1,"#TODO");
