#!/bin/bash
# Beware that the order of OPTIONS -q -c -D -B is hardcoded.
# t/testc.sh -c -D u,-q -B static 2>&1 |tee c.log|grep FAIL
#
# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
# if $] < 5.9 you may want to remove -Mblib for testing the core lib
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib="-Mblib" # B::C is now fully 5.6+5.8 backwards compatible
if [ -z $Mblib ]; then VERS="${VERS}_global"; fi
BASE=`basename $0`
OCMD="$PERL $Mblib -MO=C,-DcOACMSGpu,-v,"
if [ $BASE = "testcc.sh" ]; then 
  OCMD="$PERL $Mblib -MO=CC,-DoOscprSql,-v,"
fi
OCMDO1="$PERL $Mblib -MO=C,-O1," 
if [ $BASE = "testcc.sh" ]; then 
  OCMDO1="$PERL $Mblib -MO=CC,-O1,"
fi
OCMDO2="$PERL $Mblib -MO=C,-O2," 
if [ $BASE = "testcc.sh" ]; then 
  OCMDO2="$PERL $Mblib -MO=CC,-O2,"
fi
CONT=
# 5.6: rather use -B static
#CCMD="$PERL script/cc_harness -g3"
# rest
CCMD="$PERL script/cc_harness -g3 -Bdynamic"
LCMD=
# On some perls I also had to add $archlib/DynaLoader/DynaLoader.a to libs in Config.pm

function vcmd {
    test -n "$QUIET" || echo $*
    $*
}

function pass {
    #echo -n "$1 PASS "
    echo -e -n "\e[1;32mPASS \e[0;0m"
    shift
    echo $*
    echo
}
function fail {
    #echo -n "$1 FAIL "
    echo -e -n "\e[1;31mFAIL \e[0;0m"
    shift
    echo $*
    echo
}

function ctest {
    n=$1
    str=$2
    if [ $BASE = "testcc.sh" ]; then 
      o="cccode$n"
    else
      o="ccode$n"
    fi
    if [ -z "$str" ]; then
        if [ "$n" = "08" ]; then n=8; fi 
        if [ "$n" = "09" ]; then n=9; fi
	echo "${tests[${n}]}" > ${o}.pl
        str="${tests[${n}]}"
    else
	echo "$str" > ${o}.pl
    fi
    rm $o.c $o ${o}_o.c ${o}_o 2> /dev/null
    vcmd ${OCMD}-o$o.c $o.pl
    vcmd $CCMD $o.c -c -E -o ${o}_E.c
    vcmd $CCMD $o.c $LCMD -o $o
    test -x $o || (test -z $CONT && exit)
    echo "./$o"
    res=$(./$o) || (test -z $CONT && exit)
    if [ "X$res" = "X${result[$n]}" ]; then
	pass "./$o" "'$str' => '$res'"
	vcmd ${OCMDO1}-o${o}_o1.c $o.pl
	$CCMD ${o}_o1.c $LCMD -o ${o}_o1
	test -x ${o}_o1 || (test -z $CONT && exit)
	echo "./${o}_o1"
	res=$(./${o}_o1)
	if [ "X$res" = "X${result[$n]}" ]; then
	    test "X$res" = "X${result[$n]}" && pass "./${o}_o1" "=> '$res'"
	else
            fail "./${o}_o1" "=> '$res' Expected: '${result[$n]}'"
	fi
	vcmd ${OCMDO2}-o${o}_o2.c $o.pl
	$CCMD ${o}_o2.c $LCMD -o ${o}_o2
	test -x ${o}_o2 || (test -z $CONT && exit)
	echo "./${o}_o2"
	res=$(./${o}_o2)
	if [ "X$res" = "X${result[$n]}" ]; then
	    test "X$res" = "X${result[$n]}" && pass "./${o}_o2" "=> '$res'"
	else
            fail "./${o}_o2" "=> '$res' Expected: '${result[$n]}'"
	fi
	true
    else
        fail "./$o" "'$str' => '$res' Expected: '${result[$n]}'"
	test -z $CONT && exit
    fi
}

ntests=26
declare -a tests[$ntests]
declare -a result[$ntests]
tests[1]="print 'hi'"
result[1]='hi';
tests[2]="for (1,2,3) { print if /\d/ }"
result[2]='123';
tests[3]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
result[3]='zzz2y2y2';
tests[4]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
result[4]='z2y2y2';
tests[5]='split /a/,"bananarama"; print @_'
result[5]='bnnrm';
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
# custom key sort
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba';
# fool the sort optimizer by $p, pp_sort works ok on CC
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431';
# not repro: something like this is broken in original 5.6 (Net::DNS::ZoneFile::Fast)
tests[20]='$a="abcd123";my $r=qr/\d/;print $a =~ $r;'
result[20]='1';
# broken on early alpha and 5.10
tests[21]='sub skip_on_odd{next NUMBER if $_[0]% 2}NUMBER:for($i=0;$i<5;$i++){skip_on_odd($i);print $i;}'
result[21]='024';
# broken in original perl 5.6
tests[22]='my $fh; BEGIN { open($fh,"<","/dev/null"); } print "ok";';
result[22]='ok';
# broken in perl 5.8
tests[23]='package MyMod; our $VERSION = 1.3; print "ok";'
result[23]='ok'
# works in original perl 5.6, broken with latest B::C in 5.6, 5.8
tests[24]='sub level1{return(level2()?"fail":"ok")} sub level2{0} print level1();'
result[24]='ok'
# enforce custom ncmp sort and count it. fails as CC in all. How to enforce icmp?
# <=5.6 qsort needs two more passes here than >=5.8 merge_sort
tests[25]='print sort { print $i++," "; $b <=> $a } 1..4'
result[25]="0 1 2 3`$PERL -e'print (($] < 5.007) ? q( 4 5) : q())'` 4321";
# lvalue
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}';
result[26]="26";

# 
# TODO: getopts for -q -Du,-q -w -v
if [ "$1" = "-q" ]; then 
    QUIET=1
    # O from 5.6 does not support -qq
    qq="`$PERL -e'print (($] < 5.007) ? q() : q(-qq,))'`"
    # replace -D*,-v by -q 
    OCMD="$(echo $OCMD|sed -e 's/-D.*,-v,/-q,/' -e s/-MO=/-MO=$qq/)" 
    OCMDO1="$(echo $OCMDO1|sed -e s/-v,/-q,/ -e s/-MO=/-MO=$qq/)"
    OCMDO2="$(echo $OCMDO2|sed -e s/-v,/-q,/ -e s/-MO=/-MO=$qq/)"
    CCMD="$PERL script/cc_harness -q -g3 -Bdynamic"
    shift
fi
if [ "$1" = "-c" ]; then CONT=1; shift; fi
# -D options: u,-q for quiet, no -D for verbose
if [ "$1" = "-D" ]; then 
    OCMD="$PERL $Mblib -MO=C,-D${2},"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-D${2},"
    fi
    shift; shift
fi
# -B dynamic or -B static
if [ "$1" = "-B" ]; then 
    CCMD="$PERL script/cc_harness -g3 -B${2}"
    shift; shift
fi
if [ -z "$QUIET" ]; then
    make
else
    make -q >/dev/null
fi
if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    ctest $1
    shift
  done
else
  for b in $(seq -f"%02.0f" $ntests); do
    ctest $b
  done
fi

# 562  c:  15,24
# 58   c:  15,24 (resp. 14,15,23)
# 58  cc:  10_o,15,16_o,18-19,21,24
# 510  c:  7,11,14-15,20-21,23
# 510 cc:  +10_o,12,16_o,18,19

#  http://www.nntp.perl.org/group/perl.perl5.porters/2005/07/msg103315.html
#  FAIL for B::CC should be covered by test 18
