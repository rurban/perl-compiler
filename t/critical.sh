#!/bin/sh
p=$(perl -ane'print $F[2] if /^FULLPERL =/' Makefile);
log=log.critical-`basename $p`-g`git rev-parse HEAD|cut -c1-8`
tests="15 27 29 51 70 72 73 74 75 91 95"
echo $p > $log
echo `git log --oneline -1` >> $log
echo `git diff` >> $log

t/testc.sh -q -O0 $tests 2>&1 | tee -a $log
t/testc.sh -q -O3 $tests 2>&1 | tee -a $log
$p -Iblib/arch -Iblib/lib t/perldoc.t 2>&1 | tee -a $log
