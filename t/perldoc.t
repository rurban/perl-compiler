#! /usr/bin/env perl
# brian d foy: Compiled perlpod should be faster then uncompiled
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
  ? "$X -Iblib/arch -Iblib/lib blib/script/perlcc"
  : "$X -Mblib blib/script/perlcc";
# XXX bother File::Which?
die "1..1 # $perldoc not found\n" unless -f $perldoc;
plan tests => 7;

my $res = `$perlcc -o perldoc $perldoc`;
ok($^O eq 'MSWin32' ? -s 'perldoc.exe' : -s 'perldoc', "perldoc compiled");

my $t0 = [gettimeofday];
my $ori = `$perldoc -T -f wait`;
my $t1 = tv_interval( $t0, [gettimeofday]);

$t0 = [gettimeofday];
my $cc = `./perldoc -T -f wait`;
my $t2 = tv_interval( $t0, [gettimeofday]);
is($cc, $ori, "same result");

ok($t2 < $t1, "compiled faster than uncompiled");

$res = `$perlcc -Wb=-O2 -o perldoc_O2 $perldoc`;
ok($^O eq 'MSWin32' ? -s 'perldoc_O2.exe' : -s 'perldoc_O2', "perldoc compiled");

$t0 = [gettimeofday];
$cc = $^O eq 'MSWin32' ? `perldoc -T -f wait` : `./perldoc -T -f wait`;
my $t3 = tv_interval( $t0, [gettimeofday]);
is($cc, $ori, "same result");

ok($t3 <= $t2, "compiled -O2 not slower than -O0");
ok($t3 < $t1, "compiled -O2 faster than uncompiled");

END {
  my $exe = $^O eq 'MSWin32' ? '.exe' : '';
  unlink "perldoc$exe" if -e "perldoc$exe";
  unlink "perldoc_O2$exe" if -e "perldoc_O2$exe";
}
