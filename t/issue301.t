#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=301
# detect (maybe|next)::(method|can) mro method calls
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;

my $script = <<EOF;
use mro;
{
  package A;
  sub foo { 'A::foo' }
}
{
  package C;
  use base 'A';
  sub foo { (shift)->next::method() }
}
print qq{ok} if C->foo eq 'A::foo'
EOF

if ($] < 5.010) {
  $script =~ s/mro/NEXT/m;
  $script =~ s/next::/NEXT::/m;
  $script =~ s/method/foo/m;
}
# mro since 5.10 only
ctestok(1, 'C,-O3', 'ccode301i', $script, '#301 next::method detection');
