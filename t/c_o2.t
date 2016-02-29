#! /usr/bin/env perl
# better use testc.sh -O2 for debugging
BEGIN {
  unless (-d '.git' and !$ENV{NO_AUTHOR}) {
    print "1..0 #SKIP Only if -d .git\n";
    exit;
  }
  if ($ENV{PERL_CORE}) {
    @INC = ('t', '../../lib');
  } else {
    unshift @INC, 't';
  }
  require TestBC;
}
use strict;
#my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
#my $ITHREADS  = ($Config{useithreads});

prepare_c_tests();

my @todo  = todo_tests_default("c_o2");
my @skip;
#push @skip, 29 if $] > 5.015; #hangs

run_c_tests("C,-O2", \@todo, \@skip);
