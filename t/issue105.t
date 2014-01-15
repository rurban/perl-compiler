#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=105
# v5.16 Missing bc imports
use strict;
my $name = "ccode105i";
use Test::More tests => 1;
use Config ();
my $ITHREADS  = $Config::Config{useithreads};

my $source = 'package A;
use Storable qw/dclone/;

my $a = \"";
dclone $a;
print q(ok)';

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
  local $TODO = "BC dclone missing import 5.16thr" if $] > 5.015 and $ITHREADS;
  # $TODO = "BC 5.18thr" if $] >= 5.018 and  $] < 5.019005 and $ITHREADS;
  ok($result eq $expected, "issue105 - 5.16 BC missing import");
}

END {
  unlink($name, "$name.plc", "$name.pl")
    if $result eq $expected;
}
