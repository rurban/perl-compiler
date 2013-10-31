#!./perl -w

BEGIN {
    chdir 't/CORE' if -d 't';
#     @INC = '../lib';
    use lib CORE; require 'test.pl';
}

plan tests => 1;

ok(defined [(1)x127,qr//,1]->[127], "qr// should extend the stack properly");
