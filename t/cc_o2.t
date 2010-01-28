#! /usr/bin/env perl
# better use testcc.sh -O2 for debugging
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

my @todo = (10,16,18,21,25..27,29,30); # 5.8
push @todo, (15)                     if $] < 5.007;
@todo    = (10,16,18,21,25,26,29,30) if $] >= 5.010;
push @todo, (12) if $^O eq 'MSWin32' and $Config{cc} =~ /^cl/i;
push @todo, (32)   if $] >= 5.011003;

# skip core dump causing known limitations, like custom sort or runtime labels
my @skip = (25,30);

run_c_tests("CC,-O2", \@todo, \@skip);
