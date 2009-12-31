#! /usr/bin/env perl
BEGIN {
  print "1..3\n";
}
use strict;
my $pl = "ccode00.pl";
my $plc = $pl . "c";
my $d = <DATA>;

open F, ">", $pl;
print F $d;
close F;
system "$^X -Mblib script/perlcc -r $pl ok 1";

open F, ">", $pl;
my $d2 = $d;
$d2 =~ s/nok 1/nok 2/;
print F $d2;
close F;
system "$^X -Mblib script/perlcc -O -r $pl ok 2";

open F, ">", $pl;
my $d3 = $d;
$d3 =~ s/nok 1/nok 3/;
print F $d3;
close F;
system "$^X -Mblib script/perlcc -B -o $plc $pl";
# 5.6 has no -H (yet)
my $cmd = "$^X -Mblib " . ($] < 5.007 ? "-MByteLoader " : "") . "$plc ok 3";
system "$cmd";

END {
  unlink("a", "a.out", $pl, $plc);
}

__DATA__
print @ARGV?join(" ",@ARGV):"nok 1 # empty \@ARGV","\n";
