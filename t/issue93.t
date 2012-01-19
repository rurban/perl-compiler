#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=93
# recover state of IO objects. Or not
# Another testcase is t/testm.sh Test::NoWarnings
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 6;
my $i=0;

my $todo = <<'EOF';
# === compiled ===
my ($pid, $out, $in);
BEGIN {
  local(*FPID);
  $pid = open(FPID, "echo <<EOF |");
  open($out, ">&STDOUT");
  open(my $tmp, ">", ".tmpfile");
  print $tmp "test\n";
  close $tmp;
  open($in, "<", ".tmpfile");
}
# === run-time ===
print $out 'ok';
kill 1, $pid; # BAD!
read $in, my $x, 4;
unlink ".tmpfile";
EOF

my $ok = <<'EOF';
my $out;open($out, ">&STDOUT");print $out 'ok';
EOF

sub test3 {
  my $name = shift;
  my $script = shift;
  my $cmt = join(''.@_);
  plctestok($i*3+1, $name, $script, "BC $cmt");
  ctestok($i*3+2, "C", $name, $script, "C $cmt");
  ctestok($i*3+3, "CC", $name, $script, "CC $cmt");
  $i++;
}

TODO: {
  local $TODO = "cannot restore IO yet", 3;
  test3('ccode91i', $todo, 'recover state of IO objects');
}
test3('ccode91i', $ok, '');
