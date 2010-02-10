#! /usr/bin/env perl
# better use testc.sh -O2 for debugging
BEGIN {
  if ($ENV{PERL_CORE}){
    chdir('t') if -d 't';
    @INC = ('.', '../lib');
  } else {
    unshift @INC, 't';
    #push @INC, "blib/arch", "blib/lib";
  }
  require 'test.pl'; # for run_perl()
}
use strict;
#my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $ITHREADS  = ($Config{useithreads});

prepare_c_tests();

my @todo = (39); #5.8.9
@todo = (27,39)  if !$ITHREADS;
@todo = (15,27)  if $] < 5.007;
@todo = (39)     if $] >= 5.010;
@todo = (15,39)  if $] >= 5.010 and !$ITHREADS;
push @todo, (32) if $] >= 5.011003;

my @skip = (27); # out of memory

run_c_tests("C,-O2", \@todo, \@skip);
