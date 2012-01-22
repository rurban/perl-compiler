#!/bin/sh
# test locally
perlall -m --nogit maketest -v
rmdir POSIX
rm -f rename

# creates log.modules files with date added
perlall -m --nogit make '-Mblib t/modules.t -no-subset -no-date t/top100'
#date=`date +%Y%m%d`
#for m in log.modules-5.*-$date-*; do n=`echo $m|sed 's,-[20][0-9]*-[0-9]*,,'`; mv $m $n; done

# t/todomod.pl

# test vm's
#perlall testvm --all

./status_upd -fqd
