#!/bin/sh
# use the actual perl from the Makefile (perld, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
# if $] < 5.9 then remove -Mblib
# OCMD="$PERL -Mblib -MO=C,-DcACMSG,"
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib="-Mblib" # B::C is now 5.8 backwards compatible
OCMD="$PERL $Mblib -MO=C,-DcACMSG," 
CCMD="$PERL script/cc_harness -g"
LCMD=
#CCMD="gcc -pipe -DDEBUGGING -DPERL_USE_SAFE_PUTENV -U__STRICT_ANSI__ -fno-strict-aliasing -I/usr/lib/perl5/5.11/i686-cygwin/CORE -O0 -g"
#LCMD=" -Wl,--enable-auto-import -Wl,--export-all-symbols -L/usr/lib/perl5/5.11/i686-cygwin/CORE -lperl -ldl -lcrypt -lgdbm_compat"

function ctest {
    n=$1
    str=$2
    o="ccode$n"
    echo "$str" > $o.pl
    echo ${OCMD}-o$o.c $o.pl
    ${OCMD}-o$o.c $o.pl
    echo $CCMD $o.c -c -E -o $o.cee
    $CCMD $o.c -c -E -o $o.cee
    echo $CCMD $o.c $LCMD -o $o
    $CCMD $o.c $LCMD -o $o
    test -x $o || exit
    ./$o || exit
}

make
#1 crashes at printing an 0x0 PVX SV
ctest 1 "print 'hi'"
#ctest 2 'for (1,2,3) { print if /\d/ }'
#ctest 5 'split /a/,"bananarama"; print @_'
#ctest 6 "{ package P; sub x { print 'ya' } x }"
#ctest 10 'my $i = 1; my $foo = sub {$i = shift if @_}; &$foo(3); print "ok";'
#ctest 16 'BEGIN { tie @a, __PACKAGE__; sub TIEARRAY { bless{} } sub FETCH { 1 } }; print $a[1]'
