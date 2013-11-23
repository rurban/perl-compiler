#!/bin/sh
# test locally
if `which perlall-maketest`; then
  perlall-maketest
else
  perlall -m maketest -v
fi

# creates log.modules files with date added
perlall -m make '-Iblib/arch -Iblib/lib t/modules.t -no-subset -no-date t/top100'
# t/todomod.pl

# test vm's
#perlall testvm --all

./status_upd -fqd
