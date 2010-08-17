#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=27
BEGIN {
  unshift @INC, 't';
  require 'test.pl'; # for run_perl()
}
use strict;
prepare_c_tests();
run_cc_test(1, "C", "require LWP::UserAgent;\nprint q(ok);", "ok",0,0,"#TODO");
