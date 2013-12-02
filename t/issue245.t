#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=245
# unicode value not preserved when passed to a function with -O3
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;

use B::C;
my $when = "1.42_62";
ctest(1,"a: 223 ; b: 223
a: 223 ; b: 223 [ from foo ]",
      'C,-O3','ccode232i',
      <<'EOF', ($B::C::VERSION lt $when ? "TODO " : "").'#245 unicode value not preserved when passed to a function with -O3');
sub foo {
    my ( $a, $b ) = @_;
    print "a: ".ord($a)." ; b: ".ord($b)." [ from foo ]\n";
}
print "a: ". ord(lc("\x{1E9E}"))." ; ";
print "b: ". ord("\x{df}")."\n";
foo(lc("\x{1E9E}"), "\x{df}");
EOF
