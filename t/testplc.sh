#!/bin/sh
PERL=perl5.11.0
OCMD="$PERL -Mblib -MO=Bytecode,"
ICMD="$PERL -Mblib -MByteLoader"

make

#basics
if false; then
echo "print 'hi'" > bytecode1.pl
echo ${OCMD}-obytecode1.plc bytecode1.pl
${OCMD}-obytecode1.plc bytecode1.pl
${OCMD}-O6,-obytecode1O6.plc bytecode1.pl
${OCMD}-k,-obytecode1k.plc bytecode1.pl
${OCMD}-S,-obytecode1S.asm bytecode1.pl
echo $PERL -Mblib -MO=Debug bytecode1.pl > bytecode1.dbg
$PERL -Mblib -MO=Debug bytecode1.pl > bytecode1.dbg
$PERL -Mblib -MO=Concise bytecode1.pl > bytecode1.concise
$PERL -Mblib script/assemble bytecode1S.asm bytecode1S.plc
$PERL -Mblib script/disassemble bytecode1k.plc > bytecode1k.asm
${OCMD}-TI,-obytecode1TI.plc bytecode1.pl
${OCMD}-H,-obytecode1H.plc bytecode1.pl
echo ${ICMD} bytecode1.plc
${ICMD} bytecode1.plc
fi

#PMOP
if true; then
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
#only if ByteLoader installed
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