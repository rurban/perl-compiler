#!/usr/bin/perl
# check and adjust t/modules.t TODO list
use Term::ANSIColor ':constants';
print "press ",RED,"ENTER",RESET," after each module\n";
my $gfail;
for $t (`cat t/top100`) {
  chomp $t;
  local $Term::ANSIColor::AUTORESET = 1;
  local @ARGV = grep !/\.(err|bak)/, "t/modules.t", glob "log.modules-5.0*";
  my ($fail,$f,$f1);
  while (<>) {
    if (!$f or ($f ne $ARGV)) {
      $f = $f1 = $ARGV;
      $f1 =~ s/log.modules-//;
    }
    if (/ $t\s/) {
      my $reset;
      printf "%-20s: ", $f1;
      if (/fail / and !/TODO/) {
        $reset++; $fail++;
        print RED;
      }
      if (/pass / and /TODO/) {
        $reset++;
        print GREEN;
      }
      print $_;
      print RESET if $reset;
    }
  }
  print "--\n";
  my $enter = <STDIN> if $fail;
  $gfail += $fail if $fail;
}

print "$gfail fail\n";
