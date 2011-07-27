#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=71
# Encode::decode fails in multiple ways with B::REGEXP unattached to PMOPs
use Test::More tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $script = <<'EOF';
package my;
our @a;
sub f { my($alias,$name)=splice(@_,0,2); push @a,$alias,$name; ref $alias and $name =~ $$alias }
package main;
*f=*my::f;
my $qr = qr/^(.*)$/;
print "ok" if f(\$qr => "test");
EOF

use B::C;
ctestok(1, "C", "ccode72i", $script,
	$B::C::VERSION < 1.36 ? "SvANY(REGEXP)=SvANY(CALLREGCOMP)" : undef
       );

$script = <<'EOF';
use Encode;
my $x = 'abc';
print "ok" if 'abc' eq Encode::decode('UTF-8', $x);
EOF

# rx: (?^i:^(?:US-?)ascii$)"
use B::C;
ctestok(2, "C", "ccode72i", $script,
	$B::C::VERSION < 1.36 ? "B:C reg_temp_copy from invalid r->offs" : undef
       );

use B::CC;
ctestok(3, "CC", "ccode72i", $script,
      $B::CC::VERSION < 1.12
      ? "B:CC Encode::decode fails to leave_scope with const PAD PV 'Encode'"
      : undef);
