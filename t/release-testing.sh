#!/bin/sh
# test locally
perlall -m --nogit maketest -v

# creates log.modules files with date added
for l in `git ls-tree --name-only master|grep log.modules`; do
    v=`perl -ne'm{^# path = .+perl(5.*)} and print $1' $l`
    [ -n $v ] && perlall=$v perlall -m make '-Iblib/arch -Iblib/lib t/modules.t -no-date t/top100'
done
# t/todomod.pl

# test vm's
#perlall testvm --all

./status_upd -fqd
