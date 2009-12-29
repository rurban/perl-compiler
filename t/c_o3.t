#! /usr/bin/env perl
# better use testc.sh for debugging
BEGIN {
  if ($ENV{PERL_CORE}){
    chdir('t') if -d 't';
    @INC = ('.', '../lib');
  } else {
    unshift @INC, 't';
  }
  require 'test.pl'; # for run_perl()
}
use strict;
#my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $ITHREADS  = ($Config{useithreads});

prepare_c_tests();

my @todo = ();   #5.8.9
@todo = (27)       if !$ITHREADS;
@todo = (15,27)    if $] < 5.007;
@todo = ()         if $] >= 5.010;
@todo = (15)       if $] >= 5.010 and !$ITHREADS;
@todo = (15,16)    if $] >= 5.011;

my @skip = (27); # out of memory

run_c_tests("C,-O3", \@todo, \@skip);
