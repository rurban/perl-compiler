#!./perl
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

my @todo = (15,18,21,25..27,30); # 5.8
@todo =    (15,18,21,25..27,29,30) if $] < 5.007;
@todo =    (15,18,21,25,26,29,30)  if $] >= 5.010;
push @todo, (16) if $] >= 5.011;
push @todo, (12) if $] >= 5.010 and !$ITHREADS;

# skip core dump causing known limitations, like custom sort or runtime labels
my @skip = (25,30);

run_c_tests("CC,-O1", \@todo, \@skip);
