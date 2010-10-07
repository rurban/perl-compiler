#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=31
# B:CC Regex in pkg var fails
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

open FH, ">", "ccode31i.pm";
print FH <<'EOF';
package Ccode31i;
my $regex = qr/\w+/;
sub test {
   #print "$regex\n";
   print ("word" =~ m/^$regex$/o ? "ok\n" : "not ok\n");
}
1
EOF
close FH;

my $script = <<'EOF';
use lib '.';
use Ccode31i;
&Ccode31i::test();
EOF

use B::CC;
ctestok(1, "CC", "ccode31i", $script,
      $B::CC::VERSION <= 1.08
      ? "B:CC Regex in pkg var fails"
      : undef);

#unlink "ccode31i.pm";
