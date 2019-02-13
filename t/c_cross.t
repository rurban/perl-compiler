#! /usr/bin/env perl
# test -cross=path
use strict;
use Config;
use Test::More;
plan tests => 9;

# This should exist for the last test:
my $crossarch = '/usr/lib/cperl/5.29.1/armv4l-linux/CORE';

sub check_cross {
  my ($file) = @_;
  my $f;
  unless (open($f, "<", $file)) {
    ok(0, "$file $!");
    return;
  }
  # perlpath in config.sh-arm-linux
  while (<$f>) {
    if (m{"", GV_ADD\|GV_NOTQUAL\), "(.+)"\);}) {
      is ($1, "/usr/bin/perl", "perlpath");
      next;
    }
    if (m{/\* cross \@INC \*/}) {
      $_ = <$f>;
      $_ = <$f>;
      like($_, qr{/armv4l-linux}, 'cross \@INC');
      next;
    }
  }
  close $f;
}

my $pl = "t/cross.pl";
my $d = <DATA>;
open F, ">", $pl;
print F $d;
close F;
my $exe = $^O eq 'MSWin32' ? 'ccross.exe' : './ccross';
my $C = $] > 5.007 ? "-qq,C" : "C";
my $X = $^X =~ m/\s/ ? qq{"$^X" -Iblib/arch -Iblib/lib} : "$^X -Iblib/arch -Iblib/lib";

system "$X -MO=$C,-cross=t/config.sh-arm-linux,-occross.c $pl";

# now grep the result for the right $^X, $^O and @INC
check_cross('ccross.c', 1);

system "$X -MO=$C,-O3,-cross=t/config.sh-arm-linux,-occross.c $pl";
check_cross('ccross.c');

$C = $] > 5.007 ? "-qq,CC" : "CC";
system "$X -MO=$C,-O,-cross=t/config.sh-arm-linux,-occross.c $pl";
check_cross('ccross.c');

system "$X script/perlcc -S --cross=t/config.sh-arm-linux -o ccross $pl";
check_cross('ccross.c');

if (-d $crossarch and `which arm-linux-gnueabihf-gcc`) {
  my $opts = "-I$crossarch";
  system("arm-linux-gnueabihf-gcc -c $opts ccross.c");
} else {
  ok (1, "skip no arm-linux-gnueabihf-gcc or $crossarch");
}

unlink $pl;

__DATA__
require vars;
vars->import($c);
print "ok\n";
