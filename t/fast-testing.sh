#!/bin/bash
# usage: t/fast-testing.sh [--watch]

test -f Makefile || perl Makefile.PL
V=$(perl -ane'print $F[2] if /^VERSION =/' Makefile)
R=$(git log -1 --pretty=format:"%h")
D=$(git describe --long --tags --dirty --always)
lock=fast-testing.lock
w=
echo $$ > $lock
trap "rm $lock; exit 255" SIGINT SIGTERM

# need to kill rogue processes since we cannot use run_cmd. it disturbs stdout/err order #
# bash-4 only
if [ x$1 = x--watch ]; then
    if ((BASH_VERSINFO[0] < 4)); then
        echo "only bash-3: no coproc watchdog processkiller"
    else
        #TODO check our tty
        eval "coproc (while true; do
sleep 1;
code=`ps axw|egrep ' \./(ccode|cccode|a |aa |a.out|perldoc)'|grep -v grep`
pid=`echo $code|perl -ane'print $F[0]'`
test -n \"$pid\" && (echo $code; sleep 1s; kill $pid 2>/dev/null);
sleep 5; done)"
        w=${COPROC_PID}
    fi
fi

# test locally, ~5:45hr (17*20min). with 1.46: 2:20hr-3hr
PERLCC_TIMEOUT=15 NO_AUTHOR=1 perlall -mq make '-S prove -b -j4'

if [ x$1 = x--watch ]; then
  kill -9 $w
fi

# creates log.modules files with date added
# perlall -m make '-Iblib/arch -Iblib/lib t/modules.t -no-subset -no-date t/top100'

logs=`find . -maxdepth 1 -newer $lock -name log.make-\*`
if [ -n "$logs" ]; then
    rdir=t/reports/$V/$D
    mkdir -p $rdir
    cp -p $logs $rdir/
    rename 's/log\.make-/log\.test-/' $rdir/log.make-*
    ./status_upd -ad $rdir >> status.$D
    git diff >> status.$D
    cp -p status.$D $rdir/
fi
rm $lock
