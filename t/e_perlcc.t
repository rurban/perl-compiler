# -*- cperl -*-
# t/e_perlcc.t - after c, before i(ssue*.t) and m(modules.t)
# test most perlcc options

use strict;
use Test::More tests => 71;
use Config;

my $usedl = $Config{usedl} eq 'define';
my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $exe = $^O eq 'MSWin32' ? 'a.exe' : 'a';
unlink ('a.out.c', $exe);
my $e = q("print q(ok)");

is(`$X -Mblib blib/script/perlcc -S -o a -r -e $e`, "ok", "-S -o -r -e");
ok(-e 'a.out.c', "-S => a.out.c file");
unlink ('a.out.c', $exe);

is(`$X -Mblib blib/script/perlcc -o a -r -e $e`, "ok", "-r -o -e");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
unlink ($exe);

is(`$X -Mblib blib/script/perlcc -r -e $e`, "ok", "-r -e");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
unlink ($exe);

system(qq($X -Mblib blib/script/perlcc -o a -e $e));
ok(-e 'a', '-o => -e a');
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
unlink ($exe);

# Try a simple XS module which exists in 5.6.2 and blead
$e = q("use Data::Dumper ();Data::Dumper::Dumpxs({});print q(ok)");
is(`$X -Mblib blib/script/perlcc -r -e $e`, "ok", "-r xs ".($usedl ? "dynamic" : "static"));
unlink ($exe);

is(`$X -Mblib blib/script/perlcc --staticxs -r -e $e`, "ok", "-r --staticxs xs");
ok(! -e 'a.out.c', "delete a.out.c file without -S");
ok(-e $exe, "keep executable"); #14
ok(! -e 'a.out.c.lst', "delete a.out.c.lst without -S");
unlink ($exe);
unlink ("a.out.c.lst");

is(`$X -Mblib blib/script/perlcc --staticxs -S -o a -r -e $e`, "ok",
   "-S -o -r --staticxs xs");
ok(-e 'a.out.c', "keep a.out.c file with -S");
ok(-e $exe, "keep executable");
ok(-e 'a.out.c.lst', "keep a.out.c.lst with -S"); #19
unlink ("a.out.c.lst");

is(`$X -Mblib blib/script/perlcc --staticxs -S -o a -r -e "print q(ok)"`, "ok",
   "-S -o -r --staticxs without xs");
ok(! -e 'a.out.c.lst', "no a.out.c.lst without xs");
unlink ("a.out.c.lst");

my $f = "a.pl";
open F,">",$f;
print F q(print q(ok));
close F;
$e = q("print q(ok)");

my $f = q("a.pl");
is(`$X -Mblib blib/script/perlcc -S -o a -r $f`, "ok", "-S -o -r file");
ok(-e 'a.out.c', "-S => a.out.c file");
unlink ('a.out.c', $exe);

is(`$X -Mblib blib/script/perlcc -o a -r $f`, "ok", "-r -o file");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
unlink ($exe);

is(`$X -Mblib blib/script/perlcc -o a $f`, "", "-o file");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
unlink ($exe);

is(`$X -Mblib blib/script/perlcc -S -o a $f`, "", "-S -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
unlink ($exe);

is(`$X -Mblib blib/script/perlcc -Sc -o a $f`, "", "-c -o file");
ok(-e 'a.out.c', "a.out.c file");
ok(! -e $exe, "no executable");
unlink ("a.out.c");

is(`$X -Mblib blib/script/perlcc -c -o a $f`, "", "-c -o file");
ok(! -e 'a.out.c', "no a.out.c file");
ok(! -e $exe, "no executable");

TODO: {
  local $TODO = "B::Stash imports too many";
  is(`$X -Mblib blib/script/perlcc -stash -r -o a $f`, "ok", "old-style -stash -o file");
  is(`$X -Mblib blib/script/perlcc --stash -r -oa $f`, "ok", "--stash -o file");
  ok(-e $exe, "executable");
  unlink ($exe);
}

is(`$X -Mblib blib/script/perlcc -t -o a $f`, "", "-t -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
unlink ($exe);

is(`$X -Mblib blib/script/perlcc -T -o a $f`, "", "-T -o file");
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok");
unlink ($exe);

# compiler verboseness
TODO: {
  local $TODO = "compiler --Wb=-v verbose should be passed to STDOUT";
  isnt(`$X -Mblib blib/script/perlcc --Wb=-O1,-v -o a $f`, "", "--Wb=-O1,-v -o file");
}
ok(-e $exe, "executable");
is($^O eq 'MSWin32' ? `a` : `./a`, "ok", "./a => ok"); #48
unlink ($exe);

is(`$X -Mblib blib/script/perlcc --Wb=-O1 -r $f`, "ok", "old-style -Wb=-O1");

# perlcc must be verbose
isnt(`$X -Mblib blib/script/perlcc -v 1 -o a $f`, "", "-v 1 -o file");
isnt(`$X -Mblib blib/script/perlcc -v 2 -o a $f`, "", "-v 2 -o file");
isnt(`$X -Mblib blib/script/perlcc -v 3 -o a $f`, "", "-v 3 -o file");
isnt(`$X -Mblib blib/script/perlcc -v 4 -o a $f`, "", "-v 4 -o file");

# switch bundling since 2.10
is(`$X -Mblib blib/script/perlcc -r -e$e`, "ok", "-e$e");
like(`$X -Mblib blib/script/perlcc -v1 -r -e$e`, '/ok$/m', "-v1");
is(`$X -Mblib blib/script/perlcc -oa -r -e$e`, "ok", "-oa");

is(`$X -Mblib blib/script/perlcc -OSr -oa $f`, "ok", "-OSr -o file");
ok(-e 'a.out.c', "-S => a.out.c file");
unlink ('a.out.c', $exe);

is(`$X -Mblib blib/script/perlcc -Or -oa $f`, "ok", "-Or -o file");
ok(! -e 'a.out.c', "no a.out.c file");
ok(-e $exe, "keep executable");
unlink ($exe);

# -BS: ignore -S
isnt(`$X -Mblib blib/script/perlcc -BSr -oa.plc -r -e $e`, "ok", "-BSr -o -e");
ok(-e 'a.plc', "a.plc file");
unlink ('a.plc');

is(`$X -Mblib blib/script/perlcc -Br -oa.plc $f`, "ok", "-Br -o file");
ok(-e 'a.plc', "a.plc file");

is(`$X -Mblib blib/script/perlcc -B -oa.plc -e$e`, "", "-B -o -e");
ok(-e 'a.plc', "a.plc");
is(`$X -Mblib a.plc`, "ok", "executable plc");
unlink ('a.plc');

unlink ($f);
