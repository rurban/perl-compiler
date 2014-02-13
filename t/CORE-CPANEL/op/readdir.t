#!./perl

BEGIN {
    unshift @INC, 't/CORE-CPANEL/lib';
    require 't/CORE-CPANEL/test.pl';
}

use strict;
use warnings;
use vars qw($fh @fh %fh);

eval 'opendir(NOSUCH, "no/such/directory");';
skip_all($@) if $@;

for my $i (1..2000) {
    local *OP;
    opendir(OP, "t/CORE-CPANEL/op") or die "can't opendir: $!";
    # should auto-closedir() here
}

is(opendir(OP, "t/CORE-CPANEL/op"), 1);
my @D = grep(/^[^\.].*\.t$/i, readdir(OP));
closedir(OP);

my $expect;
{
    while (<DATA>) {
	++$expect if m!^t/CORE-CPANEL/op/[^/]+!;
    }
}

my ($min, $max) = ($expect - 10, $expect + 10);
within(scalar @D, $expect, 10, 'counting op/*.t');

my @R = sort @D;
my @G = sort <t/CORE-CPANEL/op/*.t>;
if ($G[0] =~ m#.*\](\w+\.t)#i) {
    # grep is to convert filespecs returned from glob under VMS to format
    # identical to that returned by readdir
    @G = grep(s#.*\](\w+\.t).*#op/$1#i,<t/CORE-CPANEL/op/*.t>);
}
while (@R && @G && $G[0] eq 't/CORE-CPANEL/op/'.$R[0]) {
	shift(@R);
	shift(@G);
}
is(scalar @R, 0, 'readdir results all accounted for');
is(scalar @G, 0, 'glob results all accounted for');

is(opendir($fh, "t/CORE-CPANEL/op"), 1);
is(ref $fh, 'GLOB');
is(opendir($fh[0], "t/CORE-CPANEL/op"), 1);
is(ref $fh[0], 'GLOB');
is(opendir($fh{abc}, "t/CORE-CPANEL/op"), 1);
is(ref $fh{abc}, 'GLOB');
isnt("$fh", "$fh[0]");
isnt("$fh", "$fh{abc}");

# See that perl does not segfault upon readdir($x="."); 
# http://rt.perl.org/rt3/Ticket/Display.html?id=68182
fresh_perl_like(<<'EOP', qr/^Bad symbol for dirhandle at/, {}, 'RT #68182');
    my $x = ".";
    my @files = readdir($x);
EOP

done_testing();

__DATA__
t/CORE-CPANEL/op/64bitint.t
t/CORE-CPANEL/op/alarm.t
t/CORE-CPANEL/op/anonsub.t
t/CORE-CPANEL/op/append.t
t/CORE-CPANEL/op/args.t
t/CORE-CPANEL/op/arith.t
t/CORE-CPANEL/op/array_base.t
t/CORE-CPANEL/op/array.t
t/CORE-CPANEL/op/assignwarn.t
t/CORE-CPANEL/op/attrhand.t
t/CORE-CPANEL/op/attrs.t
t/CORE-CPANEL/op/auto.t
t/CORE-CPANEL/op/avhv.t
t/CORE-CPANEL/op/bless.t
t/CORE-CPANEL/op/blocks.subtest.t
t/CORE-CPANEL/op/blocks.t
t/CORE-CPANEL/op/bop.t
t/CORE-CPANEL/op/caller.t
t/CORE-CPANEL/op/chars.t
t/CORE-CPANEL/op/chdir.t
t/CORE-CPANEL/op/chop.t
t/CORE-CPANEL/op/chr.t
t/CORE-CPANEL/op/closure.subtest.t
t/CORE-CPANEL/op/closure.t
t/CORE-CPANEL/op/cmp.t
t/CORE-CPANEL/op/concat2.subtest.t
t/CORE-CPANEL/op/concat2.t
t/CORE-CPANEL/op/concat.t
t/CORE-CPANEL/op/cond.t
t/CORE-CPANEL/op/context.t
t/CORE-CPANEL/op/cproto.t
t/CORE-CPANEL/op/crypt.t
t/CORE-CPANEL/op/dbm.subtest.t
t/CORE-CPANEL/op/dbm.t
t/CORE-CPANEL/op/defins.t
t/CORE-CPANEL/op/delete.t
t/CORE-CPANEL/op/die_except.t
t/CORE-CPANEL/op/die_exit.t
t/CORE-CPANEL/op/die_keeperr.t
t/CORE-CPANEL/op/die.t
t/CORE-CPANEL/op/die_unwind.t
t/CORE-CPANEL/op/dor.t
t/CORE-CPANEL/op/do.t
t/CORE-CPANEL/op/each_array.t
t/CORE-CPANEL/op/each.t
t/CORE-CPANEL/op/eval.subtest.t
t/CORE-CPANEL/op/eval.t
t/CORE-CPANEL/op/exec.t
t/CORE-CPANEL/op/exists_sub.t
t/CORE-CPANEL/op/exp.t
t/CORE-CPANEL/op/fh.t
t/CORE-CPANEL/op/filehandle.t
t/CORE-CPANEL/op/filetest_stack_ok.t
t/CORE-CPANEL/op/filetest.t
t/CORE-CPANEL/op/filetest_t.t
t/CORE-CPANEL/op/flip.t
t/CORE-CPANEL/op/fork.t
t/CORE-CPANEL/op/getpid.t
t/CORE-CPANEL/op/getppid.t
t/CORE-CPANEL/op/gmagic.t
t/CORE-CPANEL/op/goto.t
t/CORE-CPANEL/op/grent.t
t/CORE-CPANEL/op/grep.t
t/CORE-CPANEL/op/groups.t
t/CORE-CPANEL/op/gv.t
t/CORE-CPANEL/op/hashassign.t
t/CORE-CPANEL/op/hash.t
t/CORE-CPANEL/op/hashwarn.t
t/CORE-CPANEL/op/inccode.t
t/CORE-CPANEL/op/inccode-tie.t
t/CORE-CPANEL/op/incfilter.t
t/CORE-CPANEL/op/inc.t
t/CORE-CPANEL/op/index.subtest.t
t/CORE-CPANEL/op/index.t
t/CORE-CPANEL/op/index_thr.t
t/CORE-CPANEL/op/int.t
t/CORE-CPANEL/op/join.t
t/CORE-CPANEL/op/kill0.t
t/CORE-CPANEL/op/lc.t
t/CORE-CPANEL/op/lc_user.t
t/CORE-CPANEL/op/leaky-magic.subtest.t
t/CORE-CPANEL/op/leaky-magic.t
t/CORE-CPANEL/op/length.t
t/CORE-CPANEL/op/lex_assign.t
t/CORE-CPANEL/op/lex.t
t/CORE-CPANEL/op/lfs.t
t/CORE-CPANEL/op/list.t
t/CORE-CPANEL/op/localref.t
t/CORE-CPANEL/op/local.t
t/CORE-CPANEL/op/loopctl.t
t/CORE-CPANEL/op/lop.t
t/CORE-CPANEL/op/magic-27839.t
t/CORE-CPANEL/op/magic_phase.t
t/CORE-CPANEL/op/magic.subtest.t
t/CORE-CPANEL/op/magic.t
t/CORE-CPANEL/op/method.t
t/CORE-CPANEL/op/mkdir.t
t/CORE-CPANEL/op/mydef.t
t/CORE-CPANEL/op/my_stash.t
t/CORE-CPANEL/op/my.t
t/CORE-CPANEL/op/negate.t
t/CORE-CPANEL/op/not.t
t/CORE-CPANEL/op/numconvert.t
t/CORE-CPANEL/op/oct.t
t/CORE-CPANEL/op/ord.t
t/CORE-CPANEL/op/or.t
t/CORE-CPANEL/op/overload_integer.t
t/CORE-CPANEL/op/override.t
t/CORE-CPANEL/op/packagev.t
t/CORE-CPANEL/op/pack.t
t/CORE-CPANEL/op/pos.t
t/CORE-CPANEL/op/pow.t
t/CORE-CPANEL/op/print.subtest.t
t/CORE-CPANEL/op/print.t
t/CORE-CPANEL/op/protowarn.t
t/CORE-CPANEL/op/push.t
t/CORE-CPANEL/op/pwent.t
t/CORE-CPANEL/op/qq.t
t/CORE-CPANEL/op/qr.t
t/CORE-CPANEL/op/quotemeta.t
t/CORE-CPANEL/op/rand.t
t/CORE-CPANEL/op/range.t
t/CORE-CPANEL/op/readdir.subtest.t
t/CORE-CPANEL/op/readdir.t
t/CORE-CPANEL/op/readline.subtest.t
t/CORE-CPANEL/op/readline.t
t/CORE-CPANEL/op/read.t
t/CORE-CPANEL/op/recurse.t
t/CORE-CPANEL/op/ref.subtest.t
t/CORE-CPANEL/op/ref.t
t/CORE-CPANEL/op/repeat.t
t/CORE-CPANEL/op/require_errors.t
t/CORE-CPANEL/op/reset.t
t/CORE-CPANEL/op/reverse.t
t/CORE-CPANEL/op/runlevel.t
t/CORE-CPANEL/op/setpgrpstack.t
t/CORE-CPANEL/op/sigdispatch.t
t/CORE-CPANEL/op/sleep.t
t/CORE-CPANEL/op/smartkve.t
t/CORE-CPANEL/op/smartmatch.t
t/CORE-CPANEL/op/sort.t
t/CORE-CPANEL/op/splice.t
t/CORE-CPANEL/op/split.t
t/CORE-CPANEL/op/split_unicode.t
t/CORE-CPANEL/op/sprintf2.subtest.t
t/CORE-CPANEL/op/sprintf2.t
t/CORE-CPANEL/op/sprintf.t
t/CORE-CPANEL/op/srand.t
t/CORE-CPANEL/op/sselect.t
t/CORE-CPANEL/op/stash.subtest.t
t/CORE-CPANEL/op/stash.t
t/CORE-CPANEL/op/state.t
t/CORE-CPANEL/op/stat.t
t/CORE-CPANEL/op/study.t
t/CORE-CPANEL/op/studytied.t
t/CORE-CPANEL/op/sub_lval.subtest.t
t/CORE-CPANEL/op/sub_lval.t
t/CORE-CPANEL/op/sub.t
t/CORE-CPANEL/op/svleak.t
t/CORE-CPANEL/op/switch.t
t/CORE-CPANEL/op/symbolcache.t
t/CORE-CPANEL/op/sysio.t
t/CORE-CPANEL/op/taint.t
t/CORE-CPANEL/op/tiearray.t
t/CORE-CPANEL/op/tie_fetch_count.t
t/CORE-CPANEL/op/tiehandle.t
t/CORE-CPANEL/op/tie.t
t/CORE-CPANEL/op/time_loop.t
t/CORE-CPANEL/op/time.t
t/CORE-CPANEL/op/tr.subtest.t
t/CORE-CPANEL/op/tr.t
t/CORE-CPANEL/op/turkish.t
t/CORE-CPANEL/op/undef.t
t/CORE-CPANEL/op/universal.subtest.t
t/CORE-CPANEL/op/universal.t
t/CORE-CPANEL/op/unshift.t
t/CORE-CPANEL/op/upgrade.t
t/CORE-CPANEL/op/utf8cache.t
t/CORE-CPANEL/op/utf8decode.t
t/CORE-CPANEL/op/utf8magic.t
t/CORE-CPANEL/op/utfhash.t
t/CORE-CPANEL/op/utftaint.t
t/CORE-CPANEL/op/vec.t
t/CORE-CPANEL/op/ver.t
t/CORE-CPANEL/op/wantarray.t
t/CORE-CPANEL/op/warn.subtest.t
t/CORE-CPANEL/op/warn.t
t/CORE-CPANEL/op/while_readdir.t
t/CORE-CPANEL/op/write.t
t/CORE-CPANEL/op/yadayada.t
