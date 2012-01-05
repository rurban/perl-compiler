#! /usr/bin/env perl
# brian d foy: "Compiled perlpod should be faster then uncompiled"
use Test::More;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

use Config;
use File::Spec;
use Time::HiRes qw(gettimeofday tv_interval);

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $perldoc = File::Spec->catfile($Config{installbin}, 'perldoc');
my $perlcc = $] < 5.008
  ? "$X -Iblib/arch -Iblib/lib blib/script/perlcc -uFile::Spec -uIO::Handle"
  : "$X -Mblib blib/script/perlcc -uFile::Spec -uIO::Handle";
my $exe = $Config{exe_ext};
my $perldocexe = "perldoc$exe";
# XXX bother File::Which?
die "1..1 # $perldoc not found\n" unless -f $perldoc;
plan tests => 7;

my $res = `$perlcc -o perldoc$exe $perldoc`;
ok(-s $perldocexe, "$perldocexe compiled");

my $t0 = [gettimeofday];
my $ori = `$X -S $perldoc -T -f wait`;
my $t1 = tv_interval( $t0, [gettimeofday]);

$t0 = [gettimeofday];
my $cc = `./perldoc -T -f wait`;
my $t2 = tv_interval( $t0, [gettimeofday]);
TODO: {
  # old perldoc 3.14_04-3.15_04: Can't locate object method "can" via package "Pod::Perldoc" at /usr/local/lib/perl5/5.14.1/Pod/Perldoc/GetOptsOO.pm line 34
  # dev perldoc 3.15_13: Can't locate object method "_is_mandoc" via package "Pod::Perldoc::ToMan"
  local $TODO = "compiled does not print yet" if $] >= 5.010;
  is($cc, $ori, "same result");
}

ok($t2 < $t1, "compiled faster than uncompiled: $t2 < $t1");

$res = `$perlcc -Wb=-O3 -o perldoc_O3$exe $perldoc`;
ok(-s "perldoc_O3$exe", "perldoc compiled");

$t0 = [gettimeofday];
$cc = $^O eq 'MSWin32' ? `perldoc$exe -T -f wait` : `./perldoc -T -f wait`;
my $t3 = tv_interval( $t0, [gettimeofday]);
TODO: {
  local $TODO = "compiled does not print yet" if $] >= 5.010;
  is($cc, $ori, "same result");
}

TODO: {
  local $TODO = "slow compiled -O3";
  ok($t3 <= $t2, "compiled -O3 not slower than -O0: $t3 <= $t2");
}
ok($t3 < $t1,  "compiled -O3 faster than uncompiled: $t3 < $t1");

END {
  unlink $perldocexe if -e $perldocexe;
  unlink "perldoc_O3$exe" if -e "perldoc_O3$exe";
}
