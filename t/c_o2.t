#! /usr/bin/env perl
# better use testc.sh -O2 for debugging
BEGIN {
  #unless (-d ".svn") {
  #  print "1..0 #SKIP Only if -d .svn\n";
  #  exit;
  #}
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

my @todo  = todo_tests_default("c_o2");
my @skip = (15,27); # out of memory
push @skip, 29 if $] > 5.015; #hangs

run_c_tests("C,-O2", \@todo, \@skip);
