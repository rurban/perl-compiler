#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=29
use Test::More tests => 1;
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

# $ENV{LC_ALL} = 'C.UTF-8';
my $expected = "24610 ö";
system "$^X -Mblib blib/script/perlcc -o $name $name.pl";
unless (-e $name or -e "$name.exe") {
  print "ok 1 #skip perlcc failed. Try -Bdynamic or -Bstatic or fix your ldopts.\n";
  exit;
}
my $result = $^O eq 'MSWin32' ? `echo "ö" | $name.exe` : `echo "ö" | ./$name`;
ok($result eq $expected, "#TODO issue 29. $result ne $expected");

END {
  #unlink($name, "$name.pl", "$name.exe");
}
