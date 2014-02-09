#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=282
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use B::C ();
# passes on linux non-DEBUGGING
my $todo = ($B::C::VERSION ge '1.45' or $] > 5.019008) ? "" : "TODO ";

ctestok(1,'C,-O3','ccode282i',<<'EOF',$todo.'#282 ref assign hek assert');
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
