#!./perl

use Errno;
INIT {
    unshift @INC, "./lib";
    require 't/CORE/test.pl';
}

plan(tests => 9);

ok( binmode(STDERR),            'STDERR made binary' );
ok( binmode(STDERR, ":unix"),   '  with unix discipline' );
ok( binmode(STDERR, ":raw"),    '  raw' );
ok( binmode(STDERR, ":crlf"),   '  and crlf' );

# If this one fails, we're in trouble.  So we just bail out.
ok( binmode(STDOUT),            'STDOUT made binary' )      || exit(1);
SKIP: {
    #skip('skip unix discipline without PerlIO layers', 1)
	# perlcc bug #152
    #unless find PerlIO::Layer 'perlio';
    ok( binmode(STDOUT, ":unix"),   '  with unix discipline' );
}
ok( binmode(STDOUT, ":raw"),    '  raw' );
ok( binmode(STDOUT, ":crlf"),   '  and crlf' );

SKIP: {
    skip("no EBADF", 1) unless exists &Errno::EBADF;

    no warnings 'io', 'once';
    $! = 0;
    binmode(B);
    # perlcc bug #150
    cmp_ok($!, '==', Errno::EBADF());
}
