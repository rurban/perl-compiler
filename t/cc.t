#! /usr/bin/env perl
# better use testcc.sh for debugging
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

# 8,11,14..16,18..19 fail on 5.00505 + 5.6, old core failures (max 20)
my @todo = (18,21,25,27,30); #5.8.9
@todo    = (15,18,21,25,27,30) if $] < 5.007;
@todo    = (18,21,25,29,30)    if $] >= 5.010;
# 12: broken PP_EVAL in cc_runtime.h
push @todo, (12) if $] >= 5.010 and !$ITHREADS;

# skip core dumps, like custom sort or runtime labels
my @skip = (18,25,30);

run_c_tests("CC", \@todo, \@skip);
