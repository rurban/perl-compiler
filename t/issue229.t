#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=229
# walker misses &main::yyy
BEGIN {
  unless (-d '.git') {
    print "1..0 #SKIP Only for author\n";
    exit;
  }
}
use strict;
use Test::More tests => 1;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $perlcc = "$X -Iblib/arch -Iblib/lib blib/script/perlcc";
my $result = `$perlcc -O3 -UB -r -e 'sub yyy () { "yyy" } print "ok\n" if( eval q{yyy} eq "yyy");'`;
is($result, "ok\n", "walker misses &main::yyy");
