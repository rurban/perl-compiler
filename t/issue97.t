#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=97
# require without op_first in use v5.12
use strict;
my $name = "ccode97i";
use Test::More tests => 1;
use Config;

my $source = $] < 5.012 ? "use 5.006; print q(ok);" : "use v5.12; print q(ok);";

open F, ">", "$name.pl";
print F $source;
close F;

my $expected = "ok";
my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $Mblib = "-Iblib/arch -Iblib/lib";
if ($] < 5.008) {
  system "$runperl -MO=Bytecode,-o$name.plc $name.pl";
} else {
  system "$runperl $Mblib -MO=-qq,Bytecode,-H,-o$name.plc $name.pl";
}
unless (-e "$name.plc") {
  print "not ok 1 #B::Bytecode failed.\n";
  exit;
}
my $runexe = $] < 5.008
  ? "$runperl -MByteLoader $name.plc"
  : "$runperl $Mblib $name.plc";
my $result = `$runexe`;
$result =~ s/\n$//;

TODO: {
  local $TODO = "5.18thr bytecode" if $] >= 5.018 and  $] < 5.019005 and $Config{useithreads};
  ok($result eq $expected, "issue97 - BC require v5.12");
}

END {
  unlink($name, "$name.plc", "$name.pl")
    if $result eq $expected;
}
