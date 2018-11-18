#! /usr/bin/env perl
# test -cross=path
BEGIN {
  print "1..1\n";
}
use strict;
use Config;

sub check_cross {
  my ($file) = @_;
  my $f;
  unless (open($f, "<", $file)) {
    print "not ok # $file not found\n";
    return;
  }
  while (<$f>) {
    //;
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
check_cross('ccross.c');

system "$X -MO=$C,-O3,-cross=t/config.sh-arm-linux,-occross.c $pl";
check_cross('ccross.c');

$C = $] > 5.007 ? "-qq,CC" : "CC";
system "$X -MO=$C,-O,-cross=t/config.sh-arm-linux,-occross.c $pl";
check_cross('ccross.c');

system "$X script/perlcc -S --cross=t/config.sh-arm-linux -o ccross $pl";
check_cross('ccross.c');

if (`which arm-linux-gnueabihf-gcc`) {
  #require ExtUtils::Embed;
  my $opts = '-I'.$Config{archlib}.'/CORE';
  system("arm-linux-gnueabihf-gcc -c $opts ccross.c");
}

__DATA__
require vars;
vars->import($c);
print "ok\n";
