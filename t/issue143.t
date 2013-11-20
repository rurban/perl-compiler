#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=143
# wrong length after double regex compilation
use Test::More tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

ctestok(1, "C,-O3", 'ccode143i', <<'EOS', "wrong length after double regex compilation");
BEGIN {
  package Net::IDN::Encode;
  our $DOT = qr/[\.]/;
  my $RE  = qr/xx/;
  sub domain_to_ascii {
    my $x = shift || "";
    $x =~ m/$RE/o;
    return split( qr/($DOT)/o, $x);
  }
}
package main;
Net::IDN::Encode::domain_to_ascii(42);
print q(ok);
EOS

ctestok(2, "C,-O3", 'ccode143i', 'BEGIN{package Foo;our $DOT=qr/[.]/;};package main;print "ok\n" if "dot.dot" =~ m/($Foo::DOT)/');
ctestok(3, "C,-O3", 'ccode143i', 'BEGIN{$DOT=qr/[.]/}print "ok\n" if "dot.dot" =~ m/($DOT)/');
