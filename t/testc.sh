#!/bin/bash
# use the actual perl from the Makefile (perld, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
# if $] < 5.9 you may want to remove -Mblib
# OCMD="$PERL -Mblib -MO=C,-DcACMSG,"
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib="-Mblib" # B::C is now 5.8 backwards compatible
if [ -z $Mblib ]; then VERS="${VERS}_global"; fi
BASE=`basename $0`
OCMD="$PERL $Mblib -MO=C,-DcACMSG,-v," 
if [ $BASE = "testcc.sh" ]; then 
  OCMD="$PERL $Mblib -MO=CC,-DspqOlt,-v,"
fi
CCMD="$PERL script/cc_harness -g -Bdynamic"
LCMD=
#CCMD="gcc -pipe -DDEBUGGING -DPERL_USE_SAFE_PUTENV -U__STRICT_ANSI__ -fno-strict-aliasing -I/usr/lib/perl5/5.11/i686-cygwin/CORE -O0 -g"
#LCMD=" -Wl,--enable-auto-import -Wl,--export-all-symbols -L/usr/lib/perl5/5.11/i686-cygwin/CORE -lperl -ldl -lcrypt -lgdbm_compat"

function ctest {
    n=$1
    str=$2
    if [ $BASE = "testcc.sh" ]; then 
      o="cccode$n"
    else
      o="ccode$n"
    fi
    if [ -z "$str" ]; then 
	echo "${tests[${n}]}" > ${o}.pl
    else 
	echo "$str" > ${o}.pl
    fi
    echo ${OCMD}-o$o.c $o.pl
    ${OCMD}-o$o.c $o.pl
    echo $CCMD $o.c -c -E -o $o.cee
    $CCMD $o.c -c -E -o $o.cee
    echo $CCMD $o.c $LCMD -o $o
    $CCMD $o.c $LCMD -o $o
    test -x $o || exit
    ./$o || exit
}

declare -a tests[19]
declare -a result[19]
tests[1]="print 'hi'"
result[1]='hi';
tests[2]="for (1,2,3) { print if /\d/ }"
result[2]='123';
tests[3]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
result[3]='hi';
tests[4]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
result[4]='zzz2y2y2';
tests[5]='split /a/,"bananarama"; print @_'
result[5]='z2y2y2';
tests[6]="{package P; sub x {print 'ya'} x}"
result[6]='ya';
tests[7]='@z = split /:/,"b:r:n:f:g"; print @z'
result[7]='brnfg';
tests[8]='sub AUTOLOAD { print 1 } &{"a"}()'
result[8]='1';
tests[9]='my $l = 3; $x = sub { print $l }; &$x'
result[9]='3';
tests[10]='my $i = 1; 
my $foo = sub {
  $i = shift if @_
}; print $i; 
print &$foo(3),$i;'
result[10]='133';
tests[11]='$x="Cannot use"; print index $x, "Can"'
result[11]='0';
tests[12]='my $i=6; eval "print \$i\n"'
result[12]='6';
tests[13]='BEGIN { %h=(1=>2,3=>4) } print $h{3}'
result[13]='4';
tests[14]='open our $T,"a"; print "ok";'
result[14]='ok';
tests[15]='print <DATA>
__DATA__
a
b'
result[15]='a
b';
tests[16]='BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
result[16]='1';
tests[17]='my $i=3; print 1 .. $i'
result[17]='123';
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba';
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431';

make

if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    ctest $1
    shift
  done
else
  for b in $(seq 19); do
    ctest $b
  done
fi

# 58,510 c:  8-10 14-16
# 58,510 cc: 8-10, 12, 14-16, 18-19
# op_free(PL_main_root) hang fixed with opt_latefree.
# Still panic: illegal pad in pad_new: 0x18c4368[0x18cf6e8] at destruct

#All: Undefined subroutine &main::a called at ccode8.pl line 1.
#ctest 8 'sub AUTOLOAD { print 1 } &{"a"}()'
