#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=29
use Test::More tests => 2;
use strict;

my $name = "ccode_i29";
my $script = <<'EOF';
use open qw(:std :utf8);
$_ = <>;
print unpack('U*', $_), " ";
print $_ if /\w/;
EOF

open F, ">", "$name.pl";
print F $script;
close F;

$ENV{LC_ALL} = 'C.UTF-8';
my $expected = "24610 ö";
my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
system "$runperl -Mblib blib/script/perlcc -o $name $name.pl";
unless (-e $name or -e "$name.exe") {
  print "ok 1 #skip perlcc failed. Try -Bdynamic or -Bstatic or fix your ldopts.\n";
  exit;
}
my $runexe = $^O eq 'MSWin32' ? "$name.exe" : "./$name";
my $result = `echo "ö" | $runexe`;
$result =~ s/\n$//;
ok($result eq $expected, "#TODO B::C issue 29: '$result' ne '$expected'");

system "$runperl -Mblib blib/script/perlcc -B -o $name.plc $name.pl";
unless (-e $name or -e "$name.exe") {
  print "ok 1 #skip perlcc failed. Try -Bdynamic or -Bstatic or fix your ldopts.\n";
  exit;
}
$runexe = "$runperl -Mblib -MByteloader $name.plc";
$result = `echo "ö" | $runexe`;
$result =~ s/\n$//;
ok($result eq $expected, "#Bytecode issue 29: '$result' eq '$expected'");

END {
  #unlink($name, "$name.plc", "$name.pl", "$name.exe");
}
