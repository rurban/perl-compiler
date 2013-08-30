#!/bin/sh
p=$(perl -ane'print $F[2] if /^FULLPERL =/' Makefile);
log=log.critical-`basename $p`-g`git rev-parse HEAD|cut -c1-8`
test -f $log && mv $log $log~
# 91 = issue 59
tests="15 27 29 511 224 227 72 74 91 95"
echo $p | tee $log
git log --oneline -1 | tee $log

t/testc.sh -q -O0 $tests 2>&1 | tee -a $log
t/testc.sh -q -O3 $tests 2>&1 | tee -a $log
$p -Iblib/arch -Iblib/lib t/perldoc.t 2>&1 | tee -a $log
t/testm.sh -q DateTime 2>&1 | tee -a $log

git log --oneline -1 >> $log
git diff >> $log
$p -V >> $log
