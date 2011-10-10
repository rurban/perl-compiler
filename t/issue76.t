#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=76
# Fix lexical warnings: warn->sv
use Test::More tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
my $script = <<'EOF';
use warnings;
{ 
  no warnings q(void); # issue76 lexwarn
  length "ok";
  print "ok"
}
EOF

ok("bytecode skip");

use B::C;
ctestok(2, "C", "ccode76i", $script,
	$B::C::VERSION < 1.36 ? "LEXWARN" : undef
       );

use B::CC;
ctestok(3, "CC", "ccode76i", $script);
