#!/bin/bash
# Usage: 
# for p in 5.6.2 5.8.9d 5.10.1 5.11.2; do make -q clean >/dev/null; perl$p Makefile.PL; t/testplc.sh -q -c; done
# use the actual perl from the Makefile (perld, perl5.10.0, perl5.8.8, perl5.11.0, ...)
function help {
  echo "t/testplc.sh [OPTIONS] [1-$ntests]"
  echo " -s                 skip all B:Debug, roundtrips and options"
  echo " -S                 skip all roundtrips and options but -S and Concise"
  echo " -c                 continue on errors"
  echo " -o                 orig. no -Mblib. only for 5.6 and 5.8"
  echo " -q                 quiet"
  echo " -v                 avoid -MO,-qq"
  echo " -h                 help"
  echo "t/testplc.sh -q -s -c <=> perl -Mblib t/bytecode.t"
  echo "Without arguments try all $ntests tests. Else the given test numbers."
}

PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
VERS=`echo $PERL|sed -e's,.*perl,,' -e's,.exe$,,'`
D="`$PERL -e'print (($] < 5.007) ? q(256) : q(v))'`"
v518=`$PERL -e'print (($] < 5.018)?0:1)'`

function init {
    # test what? core or our module?
    Mblib="`$PERL -e'print (($] < 5.008) ? q() : q(-Iblib/arch -Iblib/lib))'`"
    #Mblib=${Mblib:--Mblib} # B::C is now fully 5.6+5.8 backwards compatible
    OCMD="$PERL $Mblib -MO=Bytecode,"
    QOCMD="$PERL $Mblib -MO=-qq,Bytecode,"
    ICMD="$PERL $Mblib -MByteLoader"
    if [ "$D" = "256" ]; then QOCMD=$OCMD; fi
    if [ "$Mblib" = " " ]; then VERS="${VERS}_global"; fi
}

function pass {
    echo -e -n "\033[1;32mPASS \033[0;0m"
    echo $*
}
function fail {
    echo -e -n "\033[1;31mFAIL \033[0;0m"
    echo $*
}
function bcall {
    o=$1
    opt=${2:-s}
    ext=${3:-plc}
    optf=$(echo $opt|sed 's/,-//g')
    [ -n "$Q" ] || echo ${QOCMD}-$opt,-o${o}${optf}_${VERS}.${ext} ${o}.pl
    ${QOCMD}-$opt,-o${o}${optf}_${VERS}.${ext} ${o}.pl
}
function btest {
  n=$1
  o="bytecode$n"
  if [ -z "$2" ]; then
      if [ "$n" = "08" ]; then n=8; fi 
      if [ "$n" = "09" ]; then n=9; fi
      echo "${tests[${n}]}" > ${o}.pl
      test -z "${tests[${n}]}" && exit
      str="${tests[${n}]}"
  else 
      echo "$2" > ${o}.pl
  fi
  #bcall ${o} O6
  rm ${o}_s_${VERS}.plc 2>/dev/null
  
  # annotated assembler
  if [ -z "$SKIP" -o -n "$SKI" ]; then
    if [ "$Mblib" != " " ]; then 
	bcall ${o} S,-s asm 1
	bcall ${o} S,-k asm 1
	bcall ${o} S,-i,-b asm 1
    fi
  fi
  if [ "$Mblib" != " " -a -z "$SKIP" ]; then 
    m=${o}s_${VERS}
    rm ${m}.disasm ${o}_${VERS}.concise ${o}_${VERS}.dbg 2>/dev/null
    bcall ${o} s
    [ -n "$Q" ] || echo $PERL $Mblib script/disassemble $m.plc \> ${m}.disasm
    $PERL $Mblib script/disassemble $m.plc > ${m}.disasm
    [ -n "$Q" ] || echo ${ICMD} ${m}.plc
    res=$(${ICMD} ${m}.plc)
    if [ "X$res" != "X${result[$n]}" ]; then
      fail "./${m}.plc" "'$str' => '$res' Expected: '${result[$n]}'"
    fi

    # understand annotations
    m=${o}S_${VERS}
    [ -n "$Q" ] || echo $PERL $Mblib script/assemble ${o}s_${VERS}.disasm \> $m.plc
    $PERL $Mblib script/assemble ${o}s_${VERS}.disasm > $m.plc
    # full assembler roundtrips
    [ -n "$Q" ] || echo $PERL $Mblib script/disassemble $m.plc \> $m.disasm
    $PERL $Mblib script/disassemble $m.plc > $m.disasm
    md=${o}SD_${VERS}
    [ -n "$Q" ] || echo $PERL $Mblib script/assemble $m.disasm \> ${md}.plc
    $PERL $Mblib script/assemble $m.disasm > ${md}.plc
    [ -n "$Q" ] || echo $PERL $Mblib script/disassemble ${md}.plc \> ${o}SDS_${VERS}.disasm
    $PERL $Mblib script/disassemble ${md}.plc > ${o}SDS_${VERS}.disasm

    bcall ${o} i,-b
    m=${o}ib_${VERS}
    $PERL $Mblib script/disassemble ${m}.plc > ${m}.disasm
    [ -n "$Q" ] || echo ${ICMD} ${m}.plc
    res=$(${ICMD} ${m}.plc)
    if [ "X$res" = "X${result[$n]}" ]; then
      pass "./${m}.plc" "=> '$res'"
    else
      fail "./${m}.plc" "'$str' => '$res' Expected: '${result[$n]}'"
    fi

    bcall ${o} k
    m=${o}k_${VERS}
    $PERL $Mblib script/disassemble ${m}.plc > ${m}.disasm
    [ -n "$Q" ] || echo ${ICMD} ${m}.plc
    res=$(${ICMD} ${m}.plc)
    if [ "X$res" != "X${result[$n]}" ]; then
      fail "./${m}.plc" "'$str' => '$res' Expected: '${result[$n]}'"
    fi

    [ -n "$Q" ] || echo $PERL $Mblib -MO=${qq}Debug,-exec ${o}.pl -o ${o}_${VERS}.dbg
    [ -n "$Q" ] || $PERL $Mblib -MO=${qq}Debug,-exec ${o}.pl > ${o}_${VERS}.dbg
  fi
  if [ -z "$SKIP" -o -n "$SKI" ]; then
    # 5.8 has a bad concise
    [ -n "$Q" ] || echo $PERL $Mblib -MO=${qq}Concise,-exec ${o}.pl -o ${o}_${VERS}.concise
    $PERL $Mblib -MO=${qq}Concise,-exec ${o}.pl > ${o}_${VERS}.concise
  fi
  if [ -z "$SKIP" ]; then
    if [ "$Mblib" != " " ]; then 
      #bcall ${o} TI
      bcall ${o} H
      m="${o}H_${VERS}"
      [ -n "$Q" ] || echo $PERL $Mblib ${m}.plc
      res=$($PERL $Mblib ${m}.plc)
      if [ "X$res" != "X${result[$n]}" ]; then
          fail "./${m}.plc" "'$str' => '$res' Expected: '${result[$n]}'"
      fi
    fi
  fi
  if [ "$Mblib" != " " ]; then
    # -s ("scan") should be the new default
    [ -n "$Q" ] || echo ${OCMD}-s,-o${o}.plc ${o}.pl
    ${OCMD}-s,-o${o}.plc ${o}.pl || (test -z $CONT && exit)
  else
    # No -s with 5.6
    [ -n "$Q" ] || echo ${OCMD}-o${o}.plc ${o}.pl
    ${OCMD}-o${o}.plc ${o}.pl || (test -z $CONT && exit)
  fi
  [ -n "$Q" ] || echo $PERL $Mblib script/disassemble ${o}.plc -o ${o}.disasm
  $PERL $Mblib script/disassemble ${o}.plc > ${o}.disasm
  [ -n "$Q" ] || echo ${ICMD} ${o}.plc
  res=$(${ICMD} ${o}.plc)
  if [ "X$res" = "X${result[$n]}" ]; then
      pass "./${o}.plc" "=> '$res'"
  else
      fail "./${o}.plc" "'$str' => '$res' Expected: '${result[$n]}'"
      if [ -z "$Q" ]; then
          echo -n "Again with -Dv? (or Ctrl-Break)"
          read
          echo ${ICMD} -D$D ${o}.plc; ${ICMD} -D$D ${o}.plc
      fi
      test -z $CONT && exit
  fi
}

ntests=50
declare -a tests[$ntests]
declare -a result[$ntests]
tests[1]="print 'hi'"
result[1]='hi'
tests[2]="for (1,2,3) { print if /\d/ }"
result[2]='123'
tests[3]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
result[3]='zzz2y2y2';
tests[4]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
if [[ $v518 -gt 0 ]]; then result[4]='zzz2y2y2'; else result[4]='z2y2y2'; fi
tests[5]='print split /a/,"bananarama"'
result[5]='bnnrm'
tests[6]="{package P; sub x {print 'ya'} x}"
result[6]='ya'
tests[7]='@z = split /:/,"b:r:n:f:g"; print @z'
result[7]='brnfg'
tests[8]='sub AUTOLOAD { print 1 } &{"a"}()'
result[8]='1'
tests[9]='my $l = 3; $x = sub { print $l }; &$x'
result[9]='3'
tests[10]='my $i = 1;
my $foo = sub {
  $i = shift if @_
}; print $i;
print &$foo(3),$i;'
result[10]='133'
tests[11]='$x="Cannot use"; print index $x, "Can"'
result[11]='0'
tests[12]='my $i=6; eval "print \$i\n"'
result[12]='6'
tests[13]='BEGIN { %h=(1=>2,3=>4) } print $h{3}'
result[13]='4'
tests[14]='open our $T,"a"; print "ok";'
result[14]='ok'
tests[15]='print <DATA>
__DATA__
a
b'
result[15]='a
b'
tests[16]='BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
result[16]='1'
tests[17]='my $i=3; print 1 .. $i'
result[17]='123'
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba'
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431'
tests[20]='$a="abcd123";$r=qr/\d/;print $a=~$r;'
result[20]='1'
# broken on early alpha and 5.10
tests[21]='sub skip_on_odd{next NUMBER if $_[0]% 2}NUMBER:for($i=0;$i<5;$i++){skip_on_odd($i);print $i;}'
result[21]='024'
# broken in original perl 5.6
tests[22]='my $fh; BEGIN { open($fh,"<","/dev/null"); } print "ok";'
result[22]='ok'
# broken in perl 5.8
tests[23]='package MyMod; our $VERSION = 1.3; print "ok";'
result[23]='ok'
# works in original perl 5.6, broken with B::C in 5.6, 5.8
tests[24]='sub level1{return(level2()?"fail":"ok")} sub level2{0} print level1();'
result[24]='ok'
# enforce custom ncmp sort and count it. fails as CC in all. How to enforce icmp?
# <=5.6 qsort needs two more passes here than >=5.8 merge_sort
tests[25]='print sort { print $i++," "; $b <=> $a } 1..4'
result[25]="0 1 2 3`$PERL -e'print (($] < 5.007) ? q( 4 5) : q())'` 4321";
# lvalue fails with CC -O1, and with -O2 differently
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}'
result[26]="26";
# import test
tests[27]='use Fcntl (); print "ok" if ( Fcntl::O_CREAT() >= 64 && &Fcntl::O_CREAT >= 64 );'
result[27]='ok'
# require test
tests[28]='my($fname,$tmp_fh);while(!open($tmp_fh,">",($fname=q{cctest28_} . rand(999999999999)))){$bail++;die "Failed to create a tmp file after 500 tries" if $bail>500;}print {$tmp_fh} q{$x="ok";1;};close($tmp_fh);sleep 1;require $fname;unlink($fname);print $x;'
result[28]='ok'
# use test
tests[29]='use IO;print "ok"'
result[29]='ok'
# run-time context of ..
tests[30]='@a=(4,6,1,0,0,1);sub range{(shift @a)..(shift @a)}print range();while(@a){print scalar(range())}'
result[30]='456123E0'
# AUTOLOAD w/o goto
tests[31]='package DummyShell;sub AUTOLOAD{my $p=$AUTOLOAD;$p=~s/.*:://;print(join(" ",$p,@_),";");} date();who("am","i");ls("-l");'
result[31]='date;who am i;ls -l;'
# CC entertry/jmpenv_jump/leavetry
tests[32]='eval{print "1"};eval{die 1};print "2"'
result[32]='12'
# C qr test was broken in 5.6 -- needs to load an actual file to test. See test 20.
# used to error with Can't locate object method "save" via package "U??WVS?-" (perhaps you forgot to load "U??WVS?-"?) at /usr/lib/perl5/5.6.2/i686-linux/B/C.pm line 676.
# fails with new constant only. still not repro
tests[33]='BEGIN{unshift @INC,("t");} use qr_loaded_module; print "ok";'
result[33]='ok'
# init of magic hashes. %ENV has e magic since a0714e2c perl.c  
# (Steven Schubiger      2006-02-03 17:24:49 +0100 3967) i.e. 5.8.9 but not 5.8.8
tests[34]='my $x=$ENV{TMPDIR};print "ok"'
result[34]='ok'
# methodcall syntax
tests[35]='package dummy;sub meth{print "ok"};package main;dummy->meth(1)'
result[35]='ok'
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
usere="`$PERL -e'print (($] < 5.011) ? q(use re;) : q())'`"
tests[39]=$usere'$a=qr/x/;print ($] < 5.010?1:re::is_regexp($a))'
result[39]='1'
# => Undefined subroutine &re::is_regexp with B-C-1.19, even with -ure
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
# issue 79: Exporter:: stash missing in main::
#tests[46]='use Exporter; if (exists $main::{"Exporter::"}) { print "ok"; }'
tests[46]='use Exporter; print "ok" if %main::Exporter::'
#tests[46]='use Exporter; print "ok" if scalar(keys(%main::Exporter::))'
result[46]='ok'
# non-tied av->MAGICAL
tests[47]='@ISA=(q(ok));print $ISA[0];'
result[47]='ok'
# END block del_backref
tests[48]='my $s=q{ok};END{print $s}'
result[48]='ok'
# even this failed until r1000, overlarge AvFILL=3 endav
#tests[48]='print q(ok);END{}'
#result[48]='ok
# no-fold
tests[49]='print q(ok) if "test" =~ /es/i;'
result[49]='ok'
# @ISA issue 64
tests[50]='package Top;sub top{q(ok)};package Next;our @ISA=qw(Top);package main;print Next->top();'
result[50]='ok'
tests[51]='$SIG{__WARN__}=sub{print "ok"};warn 1;'
result[51]='ok'
# check if general signals work
tests[511]='BEGIN{$SIG{USR1}=sub{$w++;};} kill USR1 => $$; print q(ok) if $w'
result[511]='ok'
tests[68]='package A;sub test{use Data::Dumper();$_ =~ /^(.*?)\d+$/;"Some::Package"->new();}print q(ok);'
result[68]='ok'
#-------------
# issue27
tests[70]='require LWP::UserAgent;print q(ok);'
result[70]='ok'
# issue24
tests[71]='dbmopen(%H,q(f),0644);print q(ok);'
result[71]='ok'
tests[81]='sub int::check {1}    #create int package for types
sub x(int,int) { @_ } #cvproto
print "o" if prototype \&x eq "int,int";
sub y($) { @_ } #cvproto
print "k" if prototype \&y eq "\$";'
result[81]='ok'
tests[90]='my $s = q(test string);
$s =~ s/(?<first>test) (?<second>string)/\2 \1/g;
print q(o) if $s eq q(string test);
q(test string) =~ /(?<first>\w+) (?<second>\w+)/;
print q(k) if $+{first} eq q(test);'
result[90]='ok'
# IO handles
tests[93]='
my ($pid, $out, $in);
BEGIN {
  local(*FPID);
  $pid = open(FPID, "echo <<EOF |");    # DIE
  open($out, ">&STDOUT");		# EASY
  open(my $tmp, ">", "pcc.tmp");	# HARD to get filename, WARN
  print $tmp "test\n";
  close $tmp;				# OK closed
  open($in, "<", "pcc.tmp");		# HARD to get filename, WARN
}
# === run-time ===
print $out "o";
kill 0, $pid; 			     # BAD! warn? die?
print "k" if "test" eq read $in, my $x, 4;
unlink "pcc.tmp";
'
result[93]='ok'
tests[931]='my $f;BEGIN{open($f,"<README");}read $f,my $in, 2; print "ok"'
result[931]='ok'
tests[932]='my $f;BEGIN{open($f,">&STDOUT");}print $f "ok"'
result[932]='ok'
tests[97]='use v5.12; print q(ok);'
result[97]='ok'
tests[971]='use v5.6; print q(ok);'
result[971]='ok'
tests[98]='BEGIN{$^H{feature_say} = 1;}
sub test { eval(""); }
print q(ok);'
result[98]='ok'
tests[105]='package A; use Storable qw/dclone/; my $a = \""; dclone $a; print q(ok);'
result[105]='ok'
if [[ $v518 -gt 0 ]]; then
  tests[130]='no warnings "experimental::lexical_subs";use feature "lexical_subs";my sub p{q(ok)}; my $a=\&p;print p;'
  result[130]='ok'
fi
#issue 30
tests[230]='sub f1 { my($self) = @_; $self->f2;} sub f2 {} sub new {} print "@ARGV\n";'
result[230]=''
#issue 138
tests[138]='print map { chr $_ } qw/97 98 99/;'
result[138]='abc'
tests[261]='q(12-feb-2015) =~ m#(\d\d?)([\-\./])(feb|jan)(?:\2(\d\d+))?#; print $4'
result[261]='2015'
tests[264]='no warnings; warn "$a.\n"'
result[264]='.'

init

while getopts "qsScohv" opt
do
  if [ "$opt" = "q" ]; then
      Q=1
      OCMD="$QOCMD"
      qq="-qq,"
      if [ "$VERS" = "5.6.2" ]; then QOCMD=$OCMD; qq=""; fi
  fi
  if [ "$opt" = "v" ]; then
      Q=
      QOCMD="$OCMD"
      qq=""
  fi
  if [ "$opt" = "s" ]; then SKIP=1; fi
  if [ "$opt" = "o" ]; then Mblib=" "; SKIP=1; SKI=1; init; fi
  if [ "$opt" = "S" ]; then SKIP=1; SKI=1; fi
  if [ "$opt" = "c" ]; then CONT=1; shift; fi
  if [ "$opt" = "h" ]; then help; exit; fi
done

if [ -z "$Q" ]; then
    make
else
    make -s >/dev/null
fi

# need to shift the options
while [ -n "$1" -a "${1:0:1}" = "-" ]; do shift; done

if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    btest $1
    shift
  done
else
  for b in $(seq $ntests); do
    btest $b
  done
fi

# 5.8: all PASS
# 5.10: FAIL: 2-5, 7, 11, 15. With -D 9-12 fail also.
# 5.11: FAIL: 2-5, 7, 11, 15-16 (all segfaulting in REGEX). With -D 9-12 fail also.
# 5.11d: WRONG 4, FAIL: 9-11, 15-16
# 5.11d linux: WRONG 4, FAIL: 11, 16

#only if ByteLoader installed in @INC
if false; then
echo ${OCMD}-H,-obytecode2.plc bytecode2.pl
${OCMD}-H,-obytecode2.plc bytecode2.pl
chmod +x bytecode2.plc
echo ./bytecode2.plc
./bytecode2.plc
fi

# package pmc
if false; then
echo "package MY::Test;" > bytecode1.pm
echo "print 'hi'" >> bytecode1.pm
echo ${OCMD}-m,-obytecode1.pmc bytecode1.pm
${OCMD}-obytecode1.pmc bytecode1.pm
fi
