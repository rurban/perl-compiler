#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=282
# glob_assign_glob: gp_free of the gp->FILE hek
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use Config;
my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
#use B::C ();
# passes on linux non-DEBUGGING, but fails on other system with better malloc libraries
# use after free
my $todo = ($] > 5.019008 or ((!$DEBUGGING or $] < 5.012) and $^O eq 'linux')) ? "" : "TODO ";

ctestok(1,'C,-O3','ccode282i',<<'EOF',$todo.'#282 ref assign hek assert/use-after-free');
use vars qw($glook $smek $foof);
$glook = 3;
$smek = 4;
$foof = "halt and cool down";
my $rv = \*smek;
*glook = $rv;
my $pv = "";
$pv = \*smek;
*foof = $pv; 
print "ok\n";
EOF
