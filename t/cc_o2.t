#! /usr/bin/env perl
# better use testcc.sh -O2 for debugging
BEGIN {
  use Config;
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

my @todo  = todo_tests_default("cc_o2");
# skip core dump causing known limitations, like custom sort or runtime labels
my @skip = (14,21,24,25,27,30,31,46,103,105);
# fails >=5.16 with -faelem

run_c_tests("CC,-O2", \@todo, \@skip);
