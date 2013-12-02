#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=238 239
# format STDOUT: t/CORE/comp/form_scope.t + t/CORE/io/defout.t
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 2;

ctestok(1,'C,-O3','ccode238i',<<'EOF','#238 format STDOUT');
sub f ($);
sub f ($) {
my $test = $_[0];
write;
format STDOUT =
ok @<<<<<<<
$test
.
}

f('');
EOF

ctestok(2,'C,-O3','ccode238i',<<'EOF','TODO #239 format STDOUT');
my $x="1";
format STDOUT =
ok @<<<<<<<
$x
.
write;print "\n";
EOF
