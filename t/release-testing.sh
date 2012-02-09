#!/bin/sh
# test locally
perlall -m --nogit maketest -v

# creates log.modules files with date added
perlall -m --nogit make '-Iblib/arch -Iblib/lib t/modules.t -no-subset -no-date t/top100'
# t/todomod.pl

# test vm's
#perlall testvm --all

./status_upd -fqd
