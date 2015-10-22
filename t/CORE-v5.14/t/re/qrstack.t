#!./perl -w

BEGIN {
    require q(t/CORE/test.pl);
}

plan tests => 1;

ok(defined [(1)x127,qr//,1]->[127], "qr// should extend the stack properly");
