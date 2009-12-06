#!/bin/bash
# Usage: 
# for p in 5.6.2 5.8.9d 5.10.1 5.11.2; do make -q clean >/dev/null; perl$p Makefile.PL; t/testc.sh -q 26; t/testcc.sh -q 26; done
# use the actual perl from the Makefile (perld, perl5.10.0, perl5.8.8, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
#PERL=perl5.11.0
VERS=`echo $PERL|sed -e's,.*perl,,' -e's,.exe$,,'`
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib="-Mblib" # it is now 5.8 backwards compatible
if [ -z $Mblib ]; then VERS="${VERS}_global"; fi
OCMD="$PERL $Mblib -MO=Bytecode,"
QOCMD="$PERL $Mblib -MO=-qq,Bytecode,"
if [ "$VERS" = "5.6.2" ]; then QOCMD=$OCMD; fi
ICMD="$PERL $Mblib -MByteLoader"

function bcall {
    o=$1
    opt=${2:-s}
    ext=${3:-plc}
    echo ${QOCMD}-$opt,-o${o}${opt}_${VERS}.${ext} ${o}.pl
    ${QOCMD}-$opt,-o${o}${opt}_${VERS}.${ext} ${o}.pl
}
function btest {
    n=$1
    o="bytecode$n"
    if [ -z "$2" ]; then
        if [ "$n" = "08" ]; then n=8; fi 
        if [ "$n" = "09" ]; then n=9; fi
	echo "${tests[${n}]}" > ${o}.pl
        str="${tests[${n}]}"
    else 
	echo "$2" > ${o}.pl
    fi
    #bcall ${o} O6
    rm ${o}s_${VERS}.disasm ${o}_s_${VERS}.plc 2>/dev/null
    bcall ${o} s
    echo $PERL $Mblib script/disassemble ${o}s_${VERS}.plc \> ${o}s_${VERS}.disasm
    $PERL $Mblib script/disassemble ${o}s_${VERS}.plc > ${o}s_${VERS}.disasm
    mv ${o}s_${VERS}.disasm ${o}_s_${VERS}.disasm

    # annotated assembler
    bcall ${o} S asm 1
    # understand annotations
    echo $PERL $Mblib script/assemble ${o}S_${VERS}.asm \> ${o}S_${VERS}.plc
    $PERL $Mblib script/assemble ${o}S_${VERS}.asm > ${o}S_${VERS}.plc
    # full assembler roundtrips
    echo $PERL $Mblib script/disassemble ${o}S_${VERS}.plc \> ${o}S_${VERS}.disasm
    $PERL $Mblib script/disassemble ${o}S_${VERS}.plc > ${o}S_${VERS}.disasm
    echo $PERL $Mblib script/assemble ${o}S_${VERS}.disasm \> ${o}SD_${VERS}.plc
    $PERL $Mblib script/assemble ${o}S_${VERS}.disasm > ${o}SD_${VERS}.plc
    echo $PERL $Mblib script/disassemble ${o}SD_${VERS}.plc \> ${o}SDS_${VERS}.disasm
    $PERL $Mblib script/disassemble ${o}SD_${VERS}.plc > ${o}SDS_${VERS}.disasm

    bcall ${o} k
    $PERL $Mblib script/disassemble ${o}k_${VERS}.plc > ${o}k_${VERS}.disasm
    echo $PERL $Mblib -MO=Debug,-exec ${o}.pl -o ${o}_${VERS}.dbg
    $PERL $Mblib -MO=Debug,-exec ${o}.pl > ${o}_${VERS}.dbg
    # 5.8 has a bad concise
    echo $PERL $Mblib -MO=Concise,-exec ${o}.pl -o ${o}_${VERS}.concise
    $PERL $Mblib -MO=Concise,-exec ${o}.pl > ${o}_${VERS}.concise
    #bcall ${o} TI
    bcall ${o} H

    # -s ("scan") should be the new default
    echo ${OCMD}-s,-o${o}.plc ${o}.pl
    ${OCMD}-s,-o${o}.plc ${o}.pl || exit
    echo ${ICMD} ${o}.plc
    ${ICMD} ${o}.plc || ( echo ${ICMD} -Dv ${o}.plc; ${ICMD} -Dv ${o}.plc || exit )
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
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba';
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431';
tests[20]='$a="abcd123";$r=qr/\d/;print $a=~$r;'
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
# lvalue fails with CC -O1, and with -O2 differently
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}';
result[26]="26";

make

if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    btest $1
    shift
  done
else
  for b in $(seq -f"%02.0f" $ntests); do
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

# package
if false; then
echo "package MY::Test;" > bytecode1.pm
echo "print 'hi'" >> bytecode1.pm
echo ${OCMD}-m,-obytecode1.pmc bytecode1.pm
${OCMD}-obytecode1.pmc bytecode1.pm
fi
