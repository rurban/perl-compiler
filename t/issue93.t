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
my $out;open($out,'>&STDOUT');print $out 'ok';
EOF
my $work = <<'EOF';
my $out;BEGIN{open($out,'>&STDOUT');}print $out 'ok';
EOF

sub test3 {
  my $name = shift;
  my $script = shift;
  my $cmt = shift;
  plctestok($i*3+1, $name, $script,
	    ($name eq 'ccode91iw' and $] < 5.014)?"TODO ":"")."BC $cmt");
  ctestok($i*3+2, "C", $name, $script, "C $cmt");
  ctestok($i*3+3, "CC", $name, $script, "CC $cmt");
  $i++;
}

TODO: {
  local $TODO = "recover state open files";
  test3('ccode91ib', $todo, 'various hard IO BEGIN problems');
}
test3('ccode91ig', $ok,   '&STDOUT at run-time');
test3('ccode91iw', $work, '&STDOUT restore');

END {unlink "pcc.tmp" if -f "pcc.tmp";}
