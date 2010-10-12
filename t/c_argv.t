#! /usr/bin/env perl
BEGIN {
  print "1..3\n";
}
use strict;
my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $Mblib = $] < 5.007 ? "-Iblib/arch -Iblib/lib" : "-Mblib";
$Mblib = '-Iblib\arch -Iblib\lib' if $] < 5.007 and $^O eq 'MSWin32';
my $pl = "ccode00.pl";
my $plc = $pl . "c";
my $d = <DATA>;

open F, ">", $pl;
print F $d;
close F;
system "$runperl $Mblib blib/script/perlcc -r $pl ok 1";

open F, ">", $pl;
my $d2 = $d;
$d2 =~ s/nok 1/nok 2/;
print F $d2;
close F;
system "$runperl $Mblib blib/script/perlcc -O -r $pl ok 2";

open F, ">", $pl;
my $d3 = $d;
$d3 =~ s/nok 1/nok 3/;
print F $d3;
close F;
system "$runperl $Mblib blib/script/perlcc -B -o $plc $pl";
# 5.6 has no -H (yet)
my $cmd = "$runperl " . ($] < 5.007 ? "-MByteLoader " : "$Mblib ") . "$plc ok 3";
system "$cmd";

END {
  unlink("a", "a.out", $pl, $plc);
}

__DATA__
print @ARGV?join(" ",@ARGV):"nok 1 # empty \@ARGV","\n";
