#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=81
# store cv prototypes (illegal wth cperl)
use Test::More;
plan skip_all => "illegal prototypes with cperl" if $^V =~ /c$/;
plan tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require TestBC;
}
my $name='ccode81i';
my $script = <<'EOF';
sub int::check {1}    #create int package for types
sub x(int,int) { @_ } #cvproto
print "o" if prototype \&x eq "int,int";
sub y($) { @_ } #cvproto
print "k" if prototype \&y eq "\$";
EOF

use B::C;
my $todo = ($B::C::VERSION lt '1.37' ? "TODO " : "");
my $todocc = ($B::C::VERSION lt '1.42_61' ? "TODO " : "");
plctestok(1, $name, $script, "${todo}BC cvproto");
ctestok(2, "C", $name, $script, "${todo}C cvproto");

$todocc = "TODO 5.24 " if $] > 5.023007;
ctestok(3, "CC", $name, $script, "${todocc}CC cvproto");

