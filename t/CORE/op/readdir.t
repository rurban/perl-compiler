#!./perl

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

use strict;
use warnings;
use vars qw($fh @fh %fh);

eval 'opendir(NOSUCH, "no/such/directory");';
skip_all($@) if $@;
plan (tests => 13);

for my $i (1..2000) {
    local *OP;
    opendir(OP, "t/CORE/op") or die "can't opendir: $!";
    # should auto-closedir() here
}

is(opendir(OP, "t/CORE/op"), 1);
my @D = grep(/^[^\.].*\.t$/i, readdir(OP));
closedir(OP);

my $expect;
{
    while (<DATA>) {
	++$expect if m!^t/CORE/op/[^/]+!;
    }
}

my ($min, $max) = ($expect - 10, $expect + 10);
within(scalar @D, $expect, 10, 'counting op/*.t');

my @R = sort @D;
my @G = sort <t/CORE/op/*.t>;
if ($G[0] =~ m#.*\](\w+\.t)#i) {
    # grep is to convert filespecs returned from glob under VMS to format
    # identical to that returned by readdir
    @G = grep(s#.*\](\w+\.t).*#op/$1#i,<t/CORE/op/*.t>);
}
while (@R && @G && $G[0] eq 't/CORE/op/'.$R[0]) {
	shift(@R);
	shift(@G);
}
is(scalar @R, 0, 'readdir results all accounted for');
is(scalar @G, 0, 'glob results all accounted for');

is(opendir($fh, "t/CORE/op"), 1);
is(ref $fh, 'GLOB');
is(opendir($fh[0], "t/CORE/op"), 1);
is(ref $fh[0], 'GLOB');
is(opendir($fh{abc}, "t/CORE/op"), 1);
is(ref $fh{abc}, 'GLOB');
isnt("$fh", "$fh[0]");
isnt("$fh", "$fh{abc}");

# See that perl does not segfault upon readdir($x="."); 
# http://rt.perl.org/rt3/Ticket/Display.html?id=68182
fresh_perl_like(<<'EOP', qr/^$|^Bad symbol for dirhandle at/, {}, 'RT #68182 - perlcc adjusted');
    my $x = ".";
    my @files = readdir($x);
EOP

#done_testing();

__DATA__
t/CORE/op/64bitint.t
t/CORE/op/alarm.t
t/CORE/op/anonsub.t
t/CORE/op/append.t
t/CORE/op/args.t
t/CORE/op/arith.t
t/CORE/op/array_base.t
t/CORE/op/array.t
t/CORE/op/assignwarn.t
t/CORE/op/attrhand.t
t/CORE/op/attrs.t
t/CORE/op/auto.t
t/CORE/op/avhv.t
t/CORE/op/bless.t
t/CORE/op/blocks.subtest.t
t/CORE/op/blocks.t
t/CORE/op/bop.t
t/CORE/op/caller.t
t/CORE/op/chars.t
t/CORE/op/chdir.t
t/CORE/op/chop.t
t/CORE/op/chr.t
t/CORE/op/closure.subtest.t
t/CORE/op/closure.t
t/CORE/op/cmp.t
t/CORE/op/concat2.subtest.t
t/CORE/op/concat2.t
t/CORE/op/concat.t
t/CORE/op/cond.t
t/CORE/op/context.t
t/CORE/op/cproto.t
t/CORE/op/crypt.t
t/CORE/op/dbm.subtest.t
t/CORE/op/dbm.t
t/CORE/op/defins.t
t/CORE/op/delete.t
t/CORE/op/die_except.t
t/CORE/op/die_exit.t
t/CORE/op/die_keeperr.t
t/CORE/op/die.t
t/CORE/op/die_unwind.t
t/CORE/op/dor.t
t/CORE/op/do.t
t/CORE/op/each_array.t
t/CORE/op/each.t
t/CORE/op/eval.subtest.t
t/CORE/op/eval.t
t/CORE/op/exec.t
t/CORE/op/exists_sub.t
t/CORE/op/exp.t
t/CORE/op/fh.t
t/CORE/op/filehandle.t
t/CORE/op/filetest_stack_ok.t
t/CORE/op/filetest.t
t/CORE/op/filetest_t.t
t/CORE/op/flip.t
t/CORE/op/fork.t
t/CORE/op/getpid.t
t/CORE/op/getppid.t
t/CORE/op/gmagic.t
t/CORE/op/goto.t
t/CORE/op/grent.t
t/CORE/op/grep.t
t/CORE/op/groups.t
t/CORE/op/gv.t
t/CORE/op/hashassign.t
t/CORE/op/hash.t
t/CORE/op/hashwarn.t
t/CORE/op/inccode.t
t/CORE/op/inccode-tie.t
t/CORE/op/incfilter.t
t/CORE/op/inc.t
t/CORE/op/index.subtest.t
t/CORE/op/index.t
t/CORE/op/index_thr.t
t/CORE/op/int.t
t/CORE/op/join.t
t/CORE/op/kill0.t
t/CORE/op/lc.t
t/CORE/op/lc_user.t
t/CORE/op/leaky-magic.subtest.t
t/CORE/op/leaky-magic.t
t/CORE/op/length.t
t/CORE/op/lex_assign.t
t/CORE/op/lex.t
t/CORE/op/lfs.t
t/CORE/op/list.t
t/CORE/op/localref.t
t/CORE/op/local.t
t/CORE/op/loopctl.t
t/CORE/op/lop.t
t/CORE/op/magic-27839.t
t/CORE/op/magic_phase.t
t/CORE/op/magic.subtest.t
t/CORE/op/magic.t
t/CORE/op/method.t
t/CORE/op/mkdir.t
t/CORE/op/mydef.t
t/CORE/op/my_stash.t
t/CORE/op/my.t
t/CORE/op/negate.t
t/CORE/op/not.t
t/CORE/op/numconvert.t
t/CORE/op/oct.t
t/CORE/op/ord.t
t/CORE/op/or.t
t/CORE/op/overload_integer.t
t/CORE/op/override.t
t/CORE/op/packagev.t
t/CORE/op/pack.t
t/CORE/op/pos.t
t/CORE/op/pow.t
t/CORE/op/print.subtest.t
t/CORE/op/print.t
t/CORE/op/protowarn.t
t/CORE/op/push.t
t/CORE/op/pwent.t
t/CORE/op/qq.t
t/CORE/op/qr.t
t/CORE/op/quotemeta.t
t/CORE/op/rand.t
t/CORE/op/range.t
t/CORE/op/readdir.subtest.t
t/CORE/op/readdir.t
t/CORE/op/readline.subtest.t
t/CORE/op/readline.t
t/CORE/op/read.t
t/CORE/op/recurse.t
t/CORE/op/ref.subtest.t
t/CORE/op/ref.t
t/CORE/op/repeat.t
t/CORE/op/require_errors.t
t/CORE/op/reset.t
t/CORE/op/reverse.t
t/CORE/op/runlevel.t
t/CORE/op/setpgrpstack.t
t/CORE/op/sigdispatch.t
t/CORE/op/sleep.t
t/CORE/op/smartkve.t
t/CORE/op/smartmatch.t
t/CORE/op/sort.t
t/CORE/op/splice.t
t/CORE/op/split.t
t/CORE/op/split_unicode.t
t/CORE/op/sprintf2.subtest.t
t/CORE/op/sprintf2.t
t/CORE/op/sprintf.t
t/CORE/op/srand.t
t/CORE/op/sselect.t
t/CORE/op/stash.subtest.t
t/CORE/op/stash.t
t/CORE/op/state.t
t/CORE/op/stat.t
t/CORE/op/study.t
t/CORE/op/studytied.t
t/CORE/op/sub_lval.subtest.t
t/CORE/op/sub_lval.t
t/CORE/op/sub.t
t/CORE/op/svleak.t
t/CORE/op/switch.t
t/CORE/op/symbolcache.t
t/CORE/op/sysio.t
t/CORE/op/taint.t
t/CORE/op/tiearray.t
t/CORE/op/tie_fetch_count.t
t/CORE/op/tiehandle.t
t/CORE/op/tie.t
t/CORE/op/time_loop.t
t/CORE/op/time.t
t/CORE/op/tr.subtest.t
t/CORE/op/tr.t
t/CORE/op/turkish.t
t/CORE/op/undef.t
t/CORE/op/universal.subtest.t
t/CORE/op/universal.t
t/CORE/op/unshift.t
t/CORE/op/upgrade.t
t/CORE/op/utf8cache.t
t/CORE/op/utf8decode.t
t/CORE/op/utf8magic.t
t/CORE/op/utfhash.t
t/CORE/op/utftaint.t
t/CORE/op/vec.t
t/CORE/op/ver.t
t/CORE/op/wantarray.t
t/CORE/op/warn.subtest.t
t/CORE/op/warn.t
t/CORE/op/while_readdir.t
t/CORE/op/write.t
t/CORE/op/yadayada.t
