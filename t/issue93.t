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
use Config;
my $i=0;

my $todo = <<'EOF';
# === compiled ===
my ($pid, $out, $in);
BEGIN {
  local(*FPID);
  $pid = open(FPID, 'echo <<EOF |'); #impossible
  open($out, '>&STDOUT');            #easy
  open(my $tmp, '>', 'pcc.tmp');     #hard to gather filename
  print $tmp "test\n";
  close $tmp;                        #ok closed, easy
  open($in, '<', 'pcc.tmp');         #hard to gather filename
}
# === run-time ===
print $out 'o';
kill 0, $pid; 			     # BAD! warn? die? how?
read $in, my $x, 4;
print 'k' if 'test' eq $x;
unlink 'pcc.tmp';
EOF

my $ok = <<'EOF';
my $out;open($out,'>&STDOUT');print $out qq(ok\n);
EOF

my $work = <<'EOF';
my $out;BEGIN{open($out,'>&STDOUT');}print $out qq(ok\n);
EOF

sub test3 {
  my $name = shift;
  my $script = shift;
  my $cmt = shift;
  my $todobc = (($name eq 'ccode93iw' and $] < 5.014)?"TODO needs 5.14 ":"");
  $todobc = 'TODO 5.18 ' if $] >= 5.018;
  plctestok($i*3+1, $name, $script,$todobc."BC $cmt");
  ctestok($i*3+2, "C", $name, $script, "C $cmt");
  ctestok($i*3+3, "CC", $name, $script, "CC $cmt");
  $i++;
}

TODO: {
  local $TODO = "recover IO state generally";
  test3('ccode93ib', $todo, 'various hard IO BEGIN problems');
}
test3('ccode93ig', $ok,   '&STDOUT at run-time');
TODO: {
  local $TODO = "recover STDIO state";
  test3('ccode93iw', $work, '&STDOUT restore');
}

END {unlink "pcc.tmp" if -f "pcc.tmp";}
