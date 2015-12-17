#! /usr/bin/env perl
# https://github.com/rurban/perl-compiler/issues/354
# defined hashref
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use Config;

my $pm = "Ccode354i.pm";
open FH, ">", $pm;
print FH <<'EOF';
package Ccode354i;
my %h = (
  abcd => { code => sub { return q{abcdef} }, },
);
sub check {
  my ($token) = @_;
  return qq{ok\n} if defined $h{ $token->{expansion} };
  return qq{KO\n};
}
1
EOF
close FH;

my $script = <<'EOF';
use Ccode354i (); 
my $token = { expansion => "abcd", };
print Ccode354i::check($token);
EOF

use B::C ();
my $cmt = '#354 defined hashref >=5.20';
# fails since 5.20
my $todo = ($] > 5.019 and $B::C::VERSION lt '1.53_02') ? "TODO " : "";

ctestok(1, 'C,-O3', 'ccode354i', $script, $todo.'C '.$cmt);

END { unlink $pm; }
