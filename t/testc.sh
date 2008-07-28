#!/bin/sh
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
  OCMD="$PERL $Mblib -MO=CC,-DcACMSG,-v,"
fi
CCMD="$PERL script/cc_harness -g"
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

# 58,510 c:  8-10 14-16
# 58,510 cc: 8-10, 12, 14-16, 18-19
# op_free(PL_main_root) hang fixed with opt_latefree.
# Still panic: illegal pad in pad_new: 0x18c4368[0x18cf6e8] at destruct

ctest 1 "print 'hi'"
ctest 2 'for (1,2,3) { print if /\d/ }'
# fixed SEGV at Perl_fbm_instr util.c:572 <= pp_subst
ctest 3 '$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
ctest 4 '$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
ctest 5 'split /a/,"bananarama"; print @_'
ctest 6 "{package P; sub x {print 'ya'} x}"
ctest 7 '@z = split /:/,"b:r:n:f:g"; print @z'

#All: Undefined subroutine &main::a called at ccode8.pl line 1.
ctest 8 'sub AUTOLOAD { print 1 } &{"a"}()'
#exit
ctest 9 'my $l = 3; $x = sub { print $l }; &$x'
ctest 10 'my $i = 1; my $foo = sub {$i = shift if @_}; &$foo(3); print "ok";'
ctest 11 '$x="Cannot use"; print index $x, "Can"'
ctest 12 'my $i=6; eval "print \$i\n"'
ctest 13 'BEGIN { %h=(1=>2,3=>4) } print $h{3}'
ctest 14 'open our $T,"a"; print "ok";'
ctest 15 'print <DATA>
__DATA__
a
b'
ctest 16 'BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
ctest 17 'my $i=3; print 1 .. $i'
ctest 18 'my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
ctest 19 'print sort { my $p; $b <=> $a } 1,4,3'
