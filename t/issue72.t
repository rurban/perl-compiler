#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=72
# B:CC Encode::decode('UTF-8', ..) fails to compile
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $script = <<'EOF';
use Encode;
my $e = join(',',Encode->encodings());
my $x = 'abc';
my $a = Encode::decode('utf8', $x);
print "ok" if 'abc' eq Encode::decode('UTF-8', $x);
EOF

use B::CC;
ctestok(1, "CC", "ccode72i", $script,
      $B::CC::VERSION < 1.12
      ? "B:CC Encode::Alias fails to compile"
      : undef);
