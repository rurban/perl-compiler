#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=36
# B::CC fails on some loops
use Test::More tests => 5;
use strict;
use Config;
my $ITHREADS  = $Config{useithreads};
my $base = "ccode36i";

sub test {
  my ($num, $script, $todo) =  @_;
  my $name = $base."_$num";
  unlink($name, "$name.c", "$name.pl", "$name.exe");
  open F, ">", "$name.pl";
  print F $script;
  close F;

  my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my $b = $] > 5.008 ? "-qq,CC" : "CC";
  system "$runperl -Mblib -MO=$b,-o$name.c $name.pl";
  unless (-e "$name.c") {
    print "not ok 1 #B::CC failed\n";
    exit;
  }
  system "$runperl -Mblib blib/script/cc_harness -q -o$name $name.c";
  my $ok = -e $name or -e "$name.exe";
  if ($todo) {
  TODO: {
      local $TODO = $todo;
      ok($ok);
    }
  } else {
    ok($ok);
  }
  if ($ok) {
    unlink($name, "$name.c", "$name.pl", "$name.exe");
  }
}

# panic: leaveloop, no cxstack at /usr/local/lib/perl/5.10.1/B/CC.pm line 1977
my $script = <<'EOF';
sub f { shift == 2 }
sub test {
    while (1) {
        last if f(2);
    }
    while (1) {
        last if f(2);
    }
}
EOF

#fixed with B-C-1.28 r556 (B::CC 1.08)
use B::CC;
# The problem seems to be non deterministic.
# Some runs of B::CC succeed, some fail and others give a warning.
test($_, $script, $B::CC::VERSION < 1.08 ? "B::CC issue 36" : undef) for 1..5;
