# -*- cperl -*-
# t/e_perlcc.t - after c, before i(ssue*.t) and m(modules.t)
# test most perlcc options

use strict;
use Test::More tests => 75;
use Config;

my $usedl = $Config{usedl} eq 'define';
my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $exe = $^O eq 'MSWin32' ? 'a.exe' : 'a';
my $redir = $^O eq 'MSWin32' ? '' : '2>&1';
#my $o = '';
#$o = "-Wb=-fno-warnings" if $] >= 5.013005;
#$o = "-Wb=-fno-fold,-fno-warnings" if $] >= 5.013009;
my $perlcc = "$X -Mblib blib/script/perlcc";
sub cleanup { unlink ('a.out.c', $exe, "a.out.c.lst", "a.c", "a.c.lst"); }
my $e = q("print q(ok)");

is(`$perlcc -S -o a -r -e $e`, "ok", "-S -o -r -e");
ok(-e 'a.out.c', "-S => a.out.c file");
cleanup;

is(`$perlcc -o a -r -e $e`, "ok", "-r -o -e");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
cleanup;

is(`$perlcc -r -e $e`, "ok", "-r -e");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
cleanup;

system(qq($perlcc -o a -e $e));
ok(-e 'a', '-o => -e a');
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
cleanup;

# Try a simple XS module which exists in 5.6.2 and blead
$e = q("use Data::Dumper ();Data::Dumper::Dumpxs({});print q(ok)");
is(`$perlcc -r -e $e`, "ok", "-r xs ".($usedl ? "dynamic" : "static"));
cleanup;

is(`$perlcc --staticxs -r -e $e`, "ok", "-r --staticxs xs");
ok(! -e 'a.out.c', "delete a.out.c file without -S");
ok(-e $exe, "keep executable"); #14
ok(! -e 'a.out.c.lst', "delete a.out.c.lst without -S");
cleanup;

is(`$perlcc --staticxs -S -o a -r -e $e`, "ok",
   "-S -o -r --staticxs xs");
ok(-e 'a.out.c', "keep a.out.c file with -S");
ok(-e $exe, "keep executable");
ok(-e 'a.out.c.lst', "keep a.out.c.lst with -S"); #19
cleanup;

is(`$perlcc --staticxs -S -o a -r -e "print q(ok)"`, "ok",
   "-S -o -r --staticxs without xs");
ok(! -e 'a.out.c.lst', "no a.out.c.lst without xs");
cleanup;

my $f = "a.pl";
open F,">",$f;
print F q(print q(ok));
close F;
$e = q("print q(ok)");

is(`$perlcc -S -o a -r $f`, "ok", "-S -o -r file");
ok(-e 'a.c', "-S => a.c file");
cleanup;

is(`$perlcc -o a -r $f`, "ok", "-r -o file");
ok(! -e 'a.c', "no a.c file");
ok(-e $exe, "keep executable");
cleanup;


is(`$perlcc -o a $f`, "", "-o file");
ok(! -e 'a.c', "no a.c file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
cleanup;

is(`$perlcc -S -o a $f`, "", "-S -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
cleanup;

is(`$perlcc -Sc -o a $f`, "", "-c -o file");
ok(-e 'a.c', "a.c file");
ok(! -e $exe, "no executable");
cleanup;

is(`$perlcc -c -o a $f`, "", "-c -o file");
ok(-e 'a.c', "a.c file");
ok(! -e $exe, "no executable");

TODO: {
  local $TODO = "B::Stash imports too many";
  is(`$perlcc -stash -r -o a $f`, "ok", "old-style -stash -o file");
  is(`$perlcc --stash -r -oa $f`, "ok", "--stash -o file");
  ok(-e $exe, "executable");
  cleanup;
}

is(`$perlcc -t -o a $f`, "", "-t -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
cleanup;

is(`$perlcc -T -o a $f`, "", "-T -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
cleanup;

# compiler verboseness
isnt(`$perlcc --Wb=-fno-fold,-v -o a $f $redir`, '/Writing output/m',
     "--Wb=-fno-fold,-v -o file");
like(`$perlcc -B --Wb=-DG,-v -o a $f $redir`, "/-PV-/m",
     "-B --Wb=-DG,-v -o file");
cleanup;
is(`$perlcc -Wb=-O1 -r $f`, "ok", "old-style -Wb=-O1");

# perlcc must be verbose
isnt(`$perlcc -v 1 -o a $f`, "", "-v 1 -o file");
isnt(`$perlcc -v1 -o a $f`, "", "-v1 -o file");
isnt(`$perlcc -v2 -o a $f`, "", "-v2 -o file");
isnt(`$perlcc -v3 -o a $f`, "", "-v3 -o file");
isnt(`$perlcc -v4 -o a $f`, "", "-v4 -o file");
like(`$perlcc -v5 $f $redir`, '/Writing output/m',
     "-v5 turns on -Wb=-v");
like(`$perlcc -v5 -B $f $redir`, '/-PV-/m',
     "-B -v5 turns on -Wb=-v");
like(`$perlcc -v6 $f $redir`, '/saving magic for AV/m',
     "-v6 turns on -Dfull");
like(`$perlcc -v6 -B $f $redir`, '/nextstate/m',
     "-B -v6 turns on -DM,-DG,-DA");
cleanup;

# switch bundling since 2.10
is(`$perlcc -r -e$e`, "ok", "-e$e");
cleanup;
like(`$perlcc -v1 -r -e$e`, '/ok$/m', "-v1");
cleanup;
is(`$perlcc -oa -r -e$e`, "ok", "-oa");
cleanup;

is(`$perlcc -OSr -oa $f`, "ok", "-OSr -o file");
ok(-e 'a.c', "-S => a.c file");
cleanup;

is(`$perlcc -Or -oa $f`, "ok", "-Or -o file");
ok(! -e 'a.c', "no a.c file");
ok(-e $exe, "keep executable");
cleanup;

# -BS: ignore -S
like(`$perlcc -BSr -oa.plc -e $e $redir`, '/-S ignored/', "-BSr -o -e");
ok(-e 'a.plc', "a.plc file");
cleanup;

is(`$perlcc -Br -oa.plc $f`, "ok", "-Br -o file");
ok(-e 'a.plc', "a.plc file");
cleanup;

is(`$perlcc -B -oa.plc -e$e`, "", "-B -o -e");
ok(-e 'a.plc', "a.plc");
is(`$X -Mblib a.plc`, "ok", "executable plc");
cleanup;

#TODO: -m

unlink ($f);
