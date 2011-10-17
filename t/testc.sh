#!/bin/bash
# t/testc.sh -c -Du,-q -B static 2>&1 |tee c.log|grep FAIL
# for p in 5.6.2 5.8.8-nt 5.8.9d 5.10.1d 5.10.1d-nt 5.11.2d 5.11.2d-nt; do make -s clean; echo perl$p; perl$p Makefile.PL; t/testc.sh -q -O0 31; done
# quiet c only: t/testc.sh -q -O0
function help {
  echo "t/testc.sh [OPTIONS] [1-$ntests]"
  echo " -D<debugflags>     for O=C or O=CC. Default: C,-DcOACMSGpu,-v resp. CC,-DoOscprSql,-v"
  echo " -O<0-4>            optimization level"
  echo " -f<opt>            special optimization"
  echo " -B<static|dynamic> pass to cc_harness"
  echo " -c                 continue on errors"
  echo " -k                 keep temp. files on PASS"
  echo " -E                 dump preprocessed source file with cc -E as _E.c"
  echo " -o                 orig. no -Mblib, use installed modules (5.6, 5.8)"
  echo " -a                 all. undo -Du. Unsilence scanning unused sub"
  echo " -q                 quiet"
  echo " -h                 help"
  echo "Without arguments try all $ntests tests. Without Option -Ox try -O0 to -O3 optimizations."
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
    if [ $BASE = "testcc.sh" ]; then # DrOsplt 
        OCMD="$PERL $Mblib -MO=CC,-DOsplt,"
    fi
else
    OCMD="$PERL $Mblib -MO=C,-DsGCp,-v,"
    if [ $BASE = "testcc.sh" ]; then # DoOscprSql
        OCMD="$PERL $Mblib -MO=CC,-DOscpSql,-v,"
    fi
fi
v513="`$PERL -e'print (($] < 5.013005) ? q() : q(-fno-fold,-fno-warnings,))'`"
OCMD=${OCMD}${v513}
CONT=
# 5.6: rather use -B static
#CCMD="$PERL script/cc_harness -g3"
# rest. -DALLOW_PERL_OPTIONS for -Dtlv
#CCMD="$PERL $Mblib script/cc_harness -g3 -DALLOW_PERL_OPTIONS"
CCMD="$PERL $Mblib script/cc_harness"
LCMD=
# On some perls I also had to add $archlib/DynaLoader/DynaLoader.a to libs in Config.pm
}

function vcmd {
    test -n "$QUIET" || echo $*
    $*
}

function pass {
    echo -e -n "\033[1;32mPASS \033[0;0m"
    echo $*
}
function fail {
    echo -e -n "\033[1;31mFAIL \033[0;0m"
    echo $*
}

function runopt {
    o=$1
    optim=$2
    OCMDO1="$(echo $OCMD|sed -e s/C,/C,-O$optim,/)"
    suff="_o${optim}"
    if [ "$optim" == "0" ]; then suff=""; fi
    rm ${o}${suff} ${o}${suff}.c 2> /dev/null
    if [ $optim -lt 5 ]; then CMD=$OCMDO1
    else CMD=$OCMD
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
    if [ -z "$str" ]; then
      true
    else
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
	    runopt $o 2  && \
	    runopt $o 3
	    #runopt $o 4 && \
	    true
	else
	    fail "./$o" "'$str' => '$res' Expected: '${result[$n]}'"
	    test -z $CONT && exit
	fi
      fi
    fi
}

ntests=50
declare -a tests[$ntests]
declare -a result[$ntests]
ncctests=23
declare -a cctests[$((100+$ncctests))]
declare -a ccresult[$((100+$ncctests))]
tests[1]='print "hi"'
result[1]='hi';
tests[2]='for (1,2,3) { print if /\d/ }'
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
tests[9]='my $l_i = 3; $x = sub { print $l_i }; &$x'
result[9]='3';
tests[10]='my $i_i = 1; 
my $foo = sub {
  $i_i = shift if @_
}; print $i_i; 
print &$foo(3),$i_i;'
result[10]='133';
# index: do fbm_compile or not
tests[11]='$x="Cannot use"; print index $x, "Can"'
result[11]='0';
tests[12]='my $i_i=6; eval "print \$i_i\n"'
result[12]='6';
tests[13]='BEGIN { %h=(1=>2,3=>4) } print $h{3}'
result[13]='4';
tests[14]='open our $T,"a"; print "ok";'
result[14]='ok';
# __DATA__ handles still broken non-threaded 5.10
tests[15]='print <DATA>
__DATA__
a
b'
result[15]='a
b';
tests[16]='BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
result[16]='1';
tests[17]='my $i_ir=3; print 1 .. $i_ir'
result[17]='123';
# custom key sort
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba';
# fool the sort optimizer by my $p, pp_sort works ok on CC
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431';
# not repro: something like this is broken in original 5.6 (Net::DNS::ZoneFile::Fast)
tests[20]='$a="abcd123";my $r=qr/\d/;print $a =~ $r;'
result[20]='1';
# broken on early alpha and 5.10: run-time labels.
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
# 5.12 got it backwards and added 4 more passes.
tests[25]='print sort { $i++; $b <=> $a } 1..4'
result[25]="4321";
# lvalue sub
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}';
result[26]="26";
# xsub constants (constant folded). newlib: 0x200, glibc: 0x100
tests[27]='use Fcntl ();my $a=Fcntl::O_CREAT(); print "ok" if ( $a >= 64 && &Fcntl::O_CREAT >= 64 );'
result[27]='ok'
# require $fname
tests[28]='my($fname,$tmp_fh);while(!open($tmp_fh,">",($fname=q{ccode28_} . rand(999999999999)))){$bail++;die "Failed to create a tmp file after 500 tries" if $bail>500;}print {$tmp_fh} q{$x="ok";1;};close($tmp_fh);sleep 1;require $fname;END{unlink($fname);};print $x;'
result[28]='ok'
# special old IO handling
tests[29]='use IO;print "ok"'
result[29]='ok'
# run-time context of .., fails in CC
tests[30]='@a=(4,6,1,0,0,1);sub range{(shift @a)..(shift @a)}print range();while(@a){print scalar(range())}'
result[30]='456123E0'
# AUTOLOAD w/o goto xsub
tests[31]='package MockShell;sub AUTOLOAD{my $p=$AUTOLOAD;$p=~s/.*:://;print(join(" ",$p,@_),";");} package main; MockShell::date();MockShell::who("am","i");MockShell::ls("-l");'
result[31]='date;who am i;ls -l;'
# CC entertry/jmpenv_jump/leavetry
tests[32]='eval{print "1"};eval{die 1};print "2";'
result[32]='12'
# C qr test was broken in 5.6 -- needs to load an actual file to test. See test 20.
# used to error with Can't locate object method "save" via package "U??WVS?-" (perhaps you forgot to load "U??WVS?-"?) at /usr/lib/perl5/5.6.2/i686-linux/B/C.pm line 676.
# fails with new constant only. still not repro (r-magic probably)
tests[33]='BEGIN{unshift @INC,("t");} use qr_loaded_module; print "ok"'
result[33]='ok'
# init of magic hashes. %ENV has e magic since a0714e2c perl.c
# (Steven Schubiger      2006-02-03 17:24:49 +0100 3967) i.e. 5.8.9 but not 5.8.8
tests[34]='my $x=$ENV{TMPDIR};print "ok"'
result[34]='ok'
# static method_named. fixed with 1.16
tests[35]='package dummy;my $i=0;sub meth{print $i++};package main;dummy->meth(1);my dummy $o = bless {},"dummy";$o->meth("const");my $meth="meth";$o->$meth("const");dummy->$meth("const");dummy::meth("dummy","const")'
result[35]='01234'
# HV self-ref
tests[36]='my ($rv, %hv); %hv = ( key => \$rv ); $rv = \%hv; print "ok";'
result[36]='ok'
# AV self-ref
tests[37]='my ($rv, @av); @av = ( \$rv ); $rv = \@av; print "ok";'
result[37]='ok'
# constant autoload loop crash test
tests[38]='for(1 .. 1024) { if (open(my $null_fh,"<","/dev/null")) { seek($null_fh,0,SEEK_SET); close($null_fh); $ok++; } }if ($ok == 1024) { print "ok"; }'
result[38]='ok'
# check re::is_regexp, and on 5.12 if being upgraded to SVt_REGEXP
# => Undefined subroutine &re::is_regexp with B-C-1.19, even with -ure
tests[39]='{$a=qr/x/;print($]<5.010?1:re::is_regexp($a))}'
result[39]='1'
# String with a null byte -- used to generate broken .c on 5.6.2 with static pvs
tests[40]='my $var="this string has a null \\000 byte in it";print "ok";'
result[40]='ok'
# Shared scalar, n magic. => Don't know how to handle magic of type \156.
usethreads="`$PERL -MConfig -e'print ($Config{useithreads} ? q(use threads;) : q())'`"
#usethreads='BEGIN{use Config; unless ($Config{useithreads}) {print "ok"; exit}} '
#;threads->create(sub{$s="ok"})->join;
# not yet testing n, only P
tests[41]=$usethreads'use threads::shared;{my $s="ok";share($s);print $s}'
result[41]='ok'
# Shared aggregate, P magic
tests[42]=$usethreads'use threads::shared;my %h : shared; print "ok"'
result[42]='ok'
# Aggregate element, n + p magic
tests[43]=$usethreads'use threads::shared;my @a : shared; $a[0]="ok"; print $a[0]'
result[43]='ok'
# perl #72922 (5.11.4 fails with magic_killbackrefs)
tests[44]='use Scalar::Util "weaken";my $re1=qr/foo/;my $re2=$re1;weaken($re2);print "ok" if $re3=qr/$re1/;'
result[44]='ok'
# test dynamic loading
tests[45]='use Data::Dumper ();Data::Dumper::Dumpxs({});print "ok";'
result[45]='ok'
# Exporter should end up in main:: stash when used in
tests[46]='use Exporter; if (exists $main::{"Exporter::"}) { print "ok"; }'
result[46]='ok'
# non-tied av->MAGICAL
tests[47]='@ISA=(q(ok));print $ISA[0];'
result[47]='ok'
# END block del_backref with bytecode only
tests[48]='my $s=q{ok};END{print $s}'
result[48]='ok'
# even this failed until r1000 (AvFILL 3 of END)
#tests[48]='print q{ok};END{}'
#result[48]='ok'
# no-fold
tests[49]='print q(ok) if "test" =~ /es/i;'
result[49]='ok'
# @ISA issue 64
tests[50]='package Top;sub top{q(ok)};package Next;our @ISA=qw(Top);package main;print Next->top();'
result[50]='ok'
#-------------
# issue27
tests[70]='require LWP::UserAgent;print q(ok);'
result[70]='ok'
#issue 24
tests[74]='dbmopen(%H,q(f),0644);print q(ok);'
result[74]='ok'
# object call: method_named with args.
tests[72]='package dummy;sub meth{print "ok"};package main;my dummy $o = bless {},"dummy"; $o->meth("const")'
result[72]='ok'
# object call: dynamic method_named with args.
tests[73]='package dummy;sub meth{print "ok"};package main;my $meth="meth";my $o = bless {},"dummy"; $o->$meth("const")'
result[73]='ok'
# issue71
tests[71]='
package my;
our @a;
sub f { 
  my($alias,$name)=@_;
  unshift(@a, $alias => $name);
  my $find = "ok"; 
  my $val = $a[1];
  if ( ref($alias) eq "Regexp" && $find =~ $alias ) {
    eval $val;
  }
  $find
}
package main;
*f=*my::f;
print "ok" if f(qr/^(.*)$/ => q("\L$1"));'
result[71]="ok"
# issue 71_2+3: cop_warnings issue76 and const destruction issue71
tests[75]='
use Encode;
my $x = "abc";
print "ok" if "abc" eq Encode::decode("UTF-8", $x);'
result[75]='ok'
tests[76]='use warnings;
{ no warnings q(void); # issue76 lexwarn
  length "ok";
  print "ok"
};'
result[76]='ok'

# from here on we test CC specifics only

# CC types and arith
tests[101]='my ($r_i,$i_i,$d_d)=(0,2,3.0); $r_i=$i_i*$i_i; $r_i*=$d_d; print $r_i;'
result[101]='12'
# CC cond_expr, stub, scope
tests[102]='if ($x eq "2"){}else{print "ok"}'
result[102]='ok'
# CC stringify, srefgen. TODO: use B; fails
tests[103]='require B; my $x=1e1; my $s="$x"; print ref B::svref_2object(\$s)'
result[103]='B::PV'
# CC reset
tests[104]='@a=(1..4);while($a=shift@a){print $a;}continue{$a=~/2/ and reset q(a);}'
result[104]='12'
# CC attrs. requires -MB::CC with pure perl
tests[105]='use blib;use B::CC;my int $r;my $i:int=2;our double $d=3.0; $r=$i*$i; $r*=$d; print $r;'
result[105]='12'

# issue35
tests[110]='sub new{}sub test{{my $x=1;my $y=$x+1;}my $x=2;if($x!=3){4;}}'
result[110]=''
# issue36
tests[111]='sub f{shift==2}sub test{while(1){last if f(2);}while(1){last if f(2);}}'
result[111]=''
# issue37
tests[112]='my $x;$x||=1;print "ok" if $x;'
result[112]='ok'
# issue38
tests[113]='my $x=2;$x=$x||3;print "ok" if $x==2;'
result[113]='ok'
# issue39
tests[114]='sub f1{0}sub f2{my $x;if(f1()){}if($x){}else{[$x]}}my @a=f2();print "ok";'
result[114]='ok'
# issue42
tests[115]='sub f1{1}f1();print do{7;2},"\n";'
result[115]='2'
# issue44
tests[116]='my @a=(1,2);print $a[0],"\n";'
result[116]='1'
# issue45
tests[117]='my $x;$x//=1;print "ok" if $x;'
result[117]='ok'
# issue46
tests[118]='my $pattern="x";"foo"=~/$pattern/o;print "ok";'
result[118]='ok'
# issue47
tests[119]='my $f=sub{while(1){return(1);}};print $f->(),"\n";'
result[119]='1'
# issue48
tests[120]='sub f{()}print((my ($v)=f())?1:2,"\n");'
result[120]='2'
# issue49
tests[121]='while(1){while(1){last;}last;}print "ok"'
result[121]='ok'
# issue51
tests[122]='my ($p1,$p2)=(80,80);if($p1<=23&&23<=$p2){print "telnet\n";}elsif ($p1 <= 80 && 80 <= $p2){print "http\n";}else{print "fail\n"}'
result[122]='http'
# issue52
tests[123]='my $x;my $y = 1;$x and $y == 2;print $y == 1 ? "ok\n" : "fail\n";'
result[123]='ok'

init

# 
# getopts for -q -k -E -Du,-q -v -O2, -a -c -fro-inc
while getopts "hackoED:B:O:f:q" opt
do
  if [ "$opt" = "q" ]; then 
    QUIET=1
    CCMD="$CCMD -q"
  fi
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "c" ]; then CONT=1; fi
  if [ "$opt" = "k" ]; then KEEP=1; fi
  if [ "$opt" = "E" ]; then CPP=1; fi
  if [ "$opt" = "h" ]; then help; exit; fi
  # -D options: u,-q for quiet, no -D for verbose, -D- for no gcc warnings
  if [ "$opt" = "D" ]; then
    OCMD="$PERL $Mblib -MO=C,-D${OPTARG},"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-D${OPTARG},"
    fi
    if [ -z "${OPTARG/-/}" ]; then
        CCMD="$CCMD -d"
    fi
  fi
  # -B dynamic or -B static
  if [ "$opt" = "B" ]; then 
    CCMD="$CCMD -B${OPTARG}"
  fi
  if [ "$opt" = "O" ]; then OPTIM="$OPTARG"; fi
  if [ "$opt" = "f" ]; then
    OCMD="$(echo $OCMD|sed -e "s/C,/C,-f$OPTARG,/")"
  fi
  if [ "$opt" = "a" ]; then # replace -Du, by -Do
    OCMD="$(echo $OCMD|sed -r -e 's/(-D.*)u,/\1o,/')" 
  fi
done

test "$(perl -V:gccversion)" = "gccversion='';" || CCMD="$CCMD -g3"
if [ -z $OPTIM ]; then OPTIM=-1; fi # all

if [ -z "$QUIET" ]; then
    make 
else
    # O from 5.6 does not support -qq
    qq="`$PERL -e'print (($] < 5.007) ? q() : q(-qq,))'`"
    # replace -D*,-v by -q 
    OCMD="$(echo $OCMD    |sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)" 
    OCMDO1="$(echo $OCMDO1|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO2="$(echo $OCMDO2|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO3="$(echo $OCMDO3|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO4="$(echo $OCMDO4|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    # gnu make?
    make --silent >/dev/null || make 2&>1 >/dev/null
fi

# need to shift the options
while [ -n "$1" -a "${1:0:1}" = "-" ]; do shift; done

if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    ctest $1
    shift
  done
else
  for b in $(seq $ntests); do
    ctest $b
  done
  if [ $BASE = "testcc.sh" ]; then
    for b in $(seq 101 $(($ncctests+100))); do
      ctest $b
    done
  fi
fi

# 562  c:  15,25,27
# 58   c:  27,29_i
# 58  cc:  15,18,21,25,26_o,27,29
# 510  c:  15
# 510 cc:  11,15,29
# 511  c:  11,15,16,29

#  http://www.nntp.perl.org/group/perl.perl5.porters/2005/07/msg103315.html
#  FAIL for B::CC should be covered by test 18
