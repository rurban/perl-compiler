#!/bin/bash
# t/testc.sh -c -Du,-q -B static 2>&1 |tee c.log|grep FAIL
# for p in 5.6.2 5.8.8-nt 5.8.9d 5.10.1d 5.10.1d-nt 5.11.2d 5.11.2d-nt; do make -s clean; echo perl$p; perl$p Makefile.PL; t/testc.sh -q -O0 31; done
# quiet c only: t/testc.sh -q -O0
function help {
  echo "t/testc.sh [OPTIONS] [1-29]"
  echo " -D debugflags      for O=C or O=CC. Default: C,-DcOACMSGpu,-v resp. CC,-DoOscprSql,-v"
  echo " -O 0|1|2|3         optimization level"
  echo " -B static|dynamic  pass to cc_harness"
  echo " -c                 continue on errors"
  echo " -k                 keep temp. files on PASS"
  echo " -E                 dump preprocessed source file with cc -E as _E.c"
  echo " -o                 orig. no -Mblib. only for 5.6 and 5.8"
  echo " -a                 all. undo -Du. Unsilence scanning unused sub"
  echo " -q                 quiet"
  echo " -h                 help"
  echo "Without arguments try all 29 tests. Without Option -Ox try all three optimizations."
}

# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}

function init {
BASE=`basename $0`
# if $] < 5.9 you may want to remove -Mblib for testing the core lib. -o
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib=${Mblib:--Mblib} # B::C is now fully 5.6+5.8 backwards compatible
if [ -z $Mblib ]; then 
    VERS="${VERS}_global"; 
    OCMD="$PERL $Mblib -MO=C,-DcAC,"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-DrOsplt,"
    fi
else
    OCMD="$PERL $Mblib -MO=C,-DcOACMSGpu,-v,"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-DoOscprSql,-v,"
    fi
fi
OCMDO1="$(echo $OCMD|sed -e s/C,-D/C,-O1,-D/)"
OCMDO2="$(echo $OCMD|sed -e s/C,-D/C,-O2,-D/)"
OCMDO3="$(echo $OCMD|sed -e s/C,-D/C,-O3,-D/)"
OCMDO4="$(echo $OCMD|sed -e s/C,-D/C,-O4,-D/)"
CONT=
# 5.6: rather use -B static
#CCMD="$PERL script/cc_harness -g3"
# rest
CCMD="$PERL script/cc_harness -g3 -Bdynamic"
LCMD=
# On some perls I also had to add $archlib/DynaLoader/DynaLoader.a to libs in Config.pm
}

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

function runopt {
    o=$1
    optim=$2
    suff="_o${optim}"
    if [ "$optim" == "0" ]; then suff=""; fi
    rm ${o}${suff} ${o}${suff}.c 2> /dev/null
    if [ $optim == 1 ]; then CMD=$OCMDO1
     else if [ $optim == 2 ]; then CMD=$OCMDO2
      else if [ $optim == 3 ]; then CMD=$OCMDO3
       else if [ $optim == 4 ]; then CMD=$OCMDO4
        else CMD=$OCMD
       fi
      fi
     fi
    fi
    vcmd ${CMD}-o${o}${suff}.c $o.pl
    test -z $CPP || vcmd $CCMD ${o}${suff}.c -c -E -o ${o}${suff}_E.c
    vcmd $CCMD ${o}${suff}.c $LCMD -o ${o}${suff}
    test -x ${o}${suff} || (test -z $CONT && exit)
    if [ -z "$QUIET" ]; then echo "./${o}${suff}"
    else echo -n "./${o}${suff} "
    fi
    res=$(./${o}${suff}) || fail "./${o}${suff}" "errcode $?"
    if [ "X$res" = "X${result[$n]}" ]; then
	test "X$res" = "X${result[$n]}" && pass "./${o}${suff}" "=> '$res'"
        if [ -z $KEEP ]; then rm ${o}${suff}_E.c ${o}${suff}.c ${o}${suff} 2>/dev/null; fi
        true
    else
	fail "./${o}${suff}" "=> '$str' => '$res'. Expected: '${result[$n]}'"
        false
    fi
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
    if [ $OPTIM -ge 0 ]; then
	runopt "$o" "$OPTIM"
    else # -1
	rm $o.c $o ${o}_o.c ${o}_o 2> /dev/null
	vcmd ${OCMD}-o$o.c $o.pl
        test -s $o.c || (echo "empty $o.c"; test -z $CONT && exit)
	test -z $CPP || vcmd $CCMD $o.c -c -E -o ${o}_E.c
	vcmd $CCMD $o.c $LCMD -o $o
	test -x $o || (test -z $CONT && exit)
	if [ -z "$QUIET" ]; then echo "./$o"
	else echo -n "./$o "
        fi
	res=$(./$o) || (fail "./${o}${suff}" "'$?' = $?"; test -z $CONT && exit)
	if [ "X$res" = "X${result[$n]}" ]; then
	    pass "./$o" "'$str' => '$res'"
            if [ -z $KEEP ]; then rm ${o}_E.c ${o}.c ${o} 2>/dev/null; fi
	    runopt $o 1 && \
	    runopt $o 2
	    #runopt $o 3 && \
	    #runopt $o 4 && \
	    true
	else
	    fail "./$o" "'$str' => '$res' Expected: '${result[$n]}'"
	    test -z $CONT && exit
	fi
    fi
}

ntests=31
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
tests[5]='print split /a/,"bananarama"'
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
# lvalue sub
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}';
result[26]="26";
# import test, AUTOLOAD goto xsub
tests[27]='use Fcntl; print "ok" if ( &Fcntl::O_WRONLY );'
result[27]='ok'
# require $fname
tests[28]='my($fname,$tmp_fh);while(!open($tmp_fh,">",($fname=q{cctest_27.} . rand(999999999999)))){$bail++;die "Failed to create a tmp file after 500 tries" if ($bail>500);}print {$tmp_fh} q{$x="ok";1;};close($tmp_fh);require $fname;unlink($fname);print $x;'
result[28]='ok'
# use test
tests[29]='use IO;print "ok"'
result[29]='ok'
# run-time context of .., fails in CC
tests[30]='@a=(4,6,1,0,0,1);sub range{(shift @a)..(shift @a)}print range();while(@a){print scalar(range())}'
result[30]='456123E0'
# AUTOLOAD w/o goto xsub
tests[31]='package MockShell;sub AUTOLOAD{my $p=$AUTOLOAD;$p=~s/.*:://;print(join(" ",$p,@_),";");} package main; MockShell::date();MockShell::who("am","i");MockShell::ls("-l");'
result[31]='date;who am i;ls -l;'

init

# 
# getopts for -q -k -E -Du,-q -v -O2, -a -c
while getopts "hqackoED:B:O:" opt
do
  if [ "$opt" = "q" ]; then 
    QUIET=1
    # O from 5.6 does not support -qq
    qq="`$PERL -e'print (($] < 5.007) ? q() : q(-qq,))'`"
    # replace -D*,-v by -q 
    OCMD="$(echo $OCMD    |sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)" 
    OCMDO1="$(echo $OCMDO1|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO2="$(echo $OCMDO2|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO3="$(echo $OCMDO3|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO4="$(echo $OCMDO4|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    CCMD="$PERL script/cc_harness -q -g3 -Bdynamic"
  fi
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "c" ]; then CONT=1; fi
  if [ "$opt" = "k" ]; then KEEP=1; fi
  if [ "$opt" = "E" ]; then CPP=1; fi
  if [ "$opt" = "h" ]; then help; exit; fi
  # -D options: u,-q for quiet, no -D for verbose
  if [ "$opt" = "D" ]; then
    OCMD="$PERL $Mblib -MO=C,-D${OPTARG},"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-D${OPTARG},"
    fi
  fi
  # -B dynamic or -B static
  if [ "$opt" = "B" ]; then 
    CCMD="$PERL script/cc_harness -g3 -B${OPTARG}"
  fi
  if [ "$opt" = "O" ]; then OPTIM="$OPTARG"; fi
  if [ "$opt" = "a" ]; then # replace -Du, by -Do
    OCMD="$(echo $OCMD|sed -r -e 's/(-D.*)u,/\1o,/')" 
  fi
done
if [ -z $OPTIM ]; then OPTIM=-1; fi # all

if [ -z "$QUIET" ]; then
    make 
else
    make --silent >/dev/null
fi

# need to shift the options
while [ -n "$1" -a "${1:0:1}" = "-" ]; do shift; done

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

# 562  c:  15,25,27
# 58   c:  27,29_i
# 58  cc:  15,18,21,25,26_o,27,29
# 510  c:  15
# 510 cc:  11,15,29
# 511  c:  11,15,16,29

#  http://www.nntp.perl.org/group/perl.perl5.porters/2005/07/msg103315.html
#  FAIL for B::CC should be covered by test 18
