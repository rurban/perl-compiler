#!./perl -w

BEGIN {
    require q(t/CORE-CPANEL/test.pl);
}

use strict;
plan (tests => 6);
use encoding 'johab';

ok(chr(0x7f) eq "\x7f");
ok(chr(0x80) eq "\x80");
ok(chr(0xff) eq "\xff");

for my $i (127, 128, 255) {
    ok(chr($i) eq pack('C', $i));
}

__END__
