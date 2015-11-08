#!./perl

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

use strict;
use warnings;

plan tests => 6;

use Fcntl qw(:seek);

{
    ok((open my $fh, "+>", undef), "open my \$fh, '+>', undef");
    print $fh "the right write stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right write stuff", "found the right stuff");
}

{
    ok((open my $fh, "+<", undef), "open my \$fh, '+<', undef");
    print $fh "the right read stuff";
    ok(seek($fh, 0, SEEK_SET), "seek to zero");
    my $data = <$fh>;
    is($data, "the right read stuff", "found the right stuff");
}




