#!/bin/sh
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
    ${ICMD} ${o}.plc || ( echo ${ICMD} -Dv ${o}.plc; ${ICMD} -Dv ${o}.plc || exit )
}

make

# 5.8: all PASS
# 5.10: FAIL: 2-5, 7, 11, 15. With -D 9-12 fail also.
# 5.11: FAIL: 2-5, 7, 11, 15-16 (all segfaulting in REGEX). With -D 9-12 fail also.
btest 1 "print 'hi'"
btest 2 "for (1,2,3) { print if /\d/ }"
btest 3 '$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
btest 4 '$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
btest 5 'split /a/,"bananarama"; print @_'
btest 6 "{package P; sub x {print 'ya'} x}"
btest 7 '@z = split /:/,"b:r:n:f:g"; print @z'
btest 8 'sub AUTOLOAD { print 1 } &{"a"}()'
btest 9 'my $l = 3; $x = sub { print $l }; &$x'
btest 10 'my $i = 1; my $foo = sub {$i = shift if @_}; &$foo(3); print "ok";'
btest 11 '$x="Cannot use"; print index $x, "Can"'
betst 12 'my $i=6; eval "print \$i\n"'
btest 13 'BEGIN { %h=(1=>2,3=>4) } print $h{3}'
btest 14 'open our $T,"a"; print "ok";'
btest 15 'print <DATA>
__DATA__
a
b'
btest 16 'BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
btest 17 'my $i=3; print 1 .. $i'
btest 18 'my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
btest 19 'print sort { my $p; $b <=> $a } 1,4,3'

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
