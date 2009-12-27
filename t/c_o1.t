#!./perl
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

my @todo = (); # 8,14-16 fail on 5.00505
# 11,15,28,29 fixed with 1.04_34
@todo = (27)       if !$ITHREADS;
# 5.6.2 CORE: 8,15,16,22. 16 fixed with 1.04_24, 8 with 1.04_25
# 5.8.8 CORE: 1,3-8,10-12,14,15,17-24 / non-threaded: 5,7-12,14-20,22-23,25
@todo = (15,27)    if $] < 5.007;
@todo = ()         if $] >= 5.010;
@todo = (15)       if $] >= 5.010 and !$ITHREADS;
@todo = (15,16)    if $] >= 5.011;

my @skip = (27); # out of memory

run_c_tests("C,-O1", \@todo, \@skip);
