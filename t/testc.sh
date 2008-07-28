OCMD="perld -Mblib -MO=C,-DcACM,"
CCMD="gcc -DPERL_USE_SAFE_PUTENV -U__STRICT_ANSI__ -fno-strict-aliasing -I/usr/local/include -I/usr/lib/perl5/5.10/cygwin/CORE"
LCMD=" -Wl,--enable-auto-import -Wl,--export-all-symbols -Wl,--stack,8388608 -Wl,--enable-auto-image-base -L/usr/local/lib -L/usr/lib/perl5/5.10/cygwin/CORE -lperl -ldl -lcrypt -lgdbm_compat -lperl"

echo "print 'hi'" > ccode1.pl
echo ${OCMD}-occode1.c ccode1.pl
echo $CCMD ccode1.c $LCMD -o ccode1.exe
${OCMD}-occode1.c ccode1.pl
$CCMD ccode1.c $LCMD -o ccode1.exe

echo "for (1,2,3) { print if /\d/ }" > ccode2.pl
echo ${OCMD}-occode2.c ccode2.pl
echo $CCMD ccode2.c $LCMD -o ccode2.exe
${OCMD}-occode2.c ccode2.pl
$CCMD ccode2.c $LCMD -o ccode2.exe
