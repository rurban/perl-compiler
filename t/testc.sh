OCMD="perl5.11.0 -Mblib -MO=C,-DcACMSG,"
CCMD="gcc -pipe -DDEBUGGING -DPERL_USE_SAFE_PUTENV -U__STRICT_ANSI__ -fno-strict-aliasing -I/usr/lib/perl5/5.11/i686-cygwin/CORE -O0 -g"
LCMD=" -Wl,--enable-auto-import -Wl,--export-all-symbols -L/usr/lib/perl5/5.11/i686-cygwin/CORE -lperl -ldl -lcrypt -lgdbm_compat"

make
echo "print 'hi'" > ccode1.pl
echo ${OCMD}-occode1.c ccode1.pl
${OCMD}-occode1.c ccode1.pl
echo $CCMD ccode1.c $LCMD -o ccode1.exe
$CCMD ccode1.c $LCMD -o ccode1.exe
$CCMD ccode1.c -E -o ccode1.cee

test -e ccode1.exe || exit
echo "for (1,2,3) { print if /\d/ }" > ccode2.pl
echo ${OCMD}-occode2.c ccode2.pl
${OCMD}-occode2.c ccode2.pl
echo $CCMD ccode2.c $LCMD -o ccode2.exe
$CCMD ccode2.c $LCMD -o ccode2.exe
$CCMD ccode2.c -E -o ccode2.cee
