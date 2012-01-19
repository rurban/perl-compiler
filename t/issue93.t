#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=93
# recover state of IO objects. Or not
# Another testcase is t/testm.sh Test::NoWarnings
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 9;
my $i=0;

my $todo = <<'EOF';
# === compiled ===
my ($pid, $out, $in);
BEGIN {
  local(*FPID);
  $pid = open(FPID, "echo <<EOF |"); #impossible
  open($out, ">&STDOUT");            #easy
  open(my $tmp, ">", ".tmpfile");    #hard to gather filename
  print $tmp "test\n";
  close $tmp;                        #ok closed, easy
  open($in, "<", ".tmpfile");        #hard to gather filename
}
# === run-time ===
print $out 'ok';
kill 0, $pid; 			     # BAD! warn? die?
read $in, my $x, 4;
unlink ".tmpfile";
EOF

my $ok = <<'EOF';
my $out;open($out,">&STDOUT");print $out 'ok';
EOF
my $work = <<'EOF';
my $out;BEGIN{open($out,">&STDOUT");}print $out 'ok';
EOF

sub test3 {
  my $name = shift;
  my $script = shift;
  my $cmt = shift;
  plctestok($i*3+1, $name, $script, "BC $cmt");
  ctestok($i*3+2, "C", $name, $script, "C $cmt");
  ctestok($i*3+3, "CC", $name, $script, "CC $cmt");
  $i++;
}

TODO: {
  local $TODO = "cannot restore IO yet", 3;
  test3('ccode91ib', $todo, 'recover state of IO objects (HARD)');
}
test3('ccode91ig', $ok, '&STDOUT at run-time');
TODO: {
  local $TODO = "cannot restore std handle aliases yet", 3;
  test3('ccode91iw', $work, '&STDOUT restore');
}

END {unlink ".tmpfile" if -f ".tmpfile";}
