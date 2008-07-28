#!/bin/sh
# use the actual perl from the Makefile (perld, perl5.10.0, perl5.8.8, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
VERS=`echo $PERL|sed -e's,.*perl,,' -e's,.exe$,,'`
#PERL=perl5.11.0
Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib="-Mblib" # it is now 5.8 backwards compatible
if [ -z $Mblib ]; then VERS="${VERS}_global"; fi
OCMD="$PERL $Mblib -MO=Bytecode,"
QOCMD="$PERL $Mblib -MO=-qq,Bytecode,"
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
    echo "$2" > ${o}.pl
    #bcall ${o} O6
    bcall ${o} s
    # annotated assembler
    bcall ${o} S asm 1
    # understand annotations
    echo $PERL $Mblib script/assemble ${o}S_${VERS}.asm ${o}S_${VERS}.plc
    $PERL $Mblib script/assemble ${o}S_${VERS}.asm ${o}S_${VERS}.plc
    echo $PERL $Mblib script/disassemble ${o}s_${VERS}.plc > ${o}s_${VERS}.disasm
    $PERL $Mblib script/disassemble ${o}s_${VERS}.plc > ${o}s_${VERS}.disasm
    # assembler roundtrip
    $PERL $Mblib script/disassemble ${o}S_${VERS}.plc > ${o}S_${VERS}.disasm
    $PERL $Mblib script/assemble ${o}S_${VERS}.disasm ${o}S_${VERS}.plc

    bcall ${o} k
    echo $PERL $Mblib -MO=Debug ${o}.pl -o ${o}_${VERS}.dbg
    $PERL $Mblib -MO=Debug ${o}.pl > ${o}_${VERS}.dbg
    echo $PERL $Mblib -MO=Concise ${o}.pl -o ${o}_${VERS}.concise
    $PERL $Mblib -MO=Concise ${o}.pl > ${o}_${VERS}.concise
    #bcall ${o} TI
    bcall ${o} H

    # -s ("scan") should be the new default
    echo ${OCMD}-s,-o${o}.plc ${o}.pl
    ${OCMD}-s,-o${o}.plc ${o}.pl || exit
    echo ${ICMD} ${o}.plc
    ${ICMD} ${o}.plc || ( ${ICMD} -Dtv ${o}.plc || exit )
}

make
btest 1 "print 'hi'"
#btest 2 "for (1,2,3) { print if /\d/ }"
#btest 5 'split /a/,"bananarama"; print @_'
#btest 6 "{ package P; sub x { print 'ya' } x }"
#btest 10 'my $i = 1; my $foo = sub {$i = shift if @_}; &$foo(3); print "ok";'
#btest 16 'BEGIN { tie @a, __PACKAGE__; sub TIEARRAY { bless{} } sub FETCH { 1 } }; print $a[1]'

#PMOP
if false; then
echo "for (1,2,3) { print if /\d/ }" > bytecode2.pl
echo ${OCMD}-obytecode2.plc bytecode2.pl
${OCMD}-obytecode2.plc,-DM bytecode2.pl
${OCMD}-S,-obytecode2S.asm bytecode2.pl
echo $PERL -Mblib -MO=Debug bytecode2.pl > bytecode2.dbg
$PERL -Mblib -MO=Debug bytecode2.pl > bytecode2.dbg
$PERL -Mblib -MO=Concise bytecode2.pl > bytecode2.concise
echo ${ICMD} bytecode2.plc
${ICMD} bytecode2.plc
fi

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
