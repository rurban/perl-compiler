#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=27
BEGIN {
  unshift @INC, 't';
  require 'test.pl';
}
use strict;
prepare_c_tests();
BEGIN {
  print "1..1\n";
}
# &Config::AUTOLOAD failed on Config::launcher at Config.pm line 72.
run_cc_test(1, "C", "require LWP::UserAgent;\nprint q(ok);", "ok",0,1,"#TODO issue27");
