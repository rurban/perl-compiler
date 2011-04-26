#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=31
# B:CC Regex in pkg var fails on 5.6 and 5.10
use Test::More tests => 1;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $pm = "Ccode31i.pm";
open FH, ">", $pm;
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
# $]<5.007: same as test 33
ctestok(1, "CC", "ccode31i", $script,
      ($B::CC::VERSION < 1.08 or $]<5.007 or ($]>5.009 and $]<5.011)) # fails 5.6 and 5.10 only
      ? "B:CC Regex in pkg var fails"
      : undef);

END { unlink $pm; }
