#!./perl

#This file is intentionally written in UTF-8

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

plan 1;

use utf8;
use strict;
binmode STDOUT, ":utf8"; binmode STDERR, ":utf8";

{
    local $@;
    eval 'sub testme { my $ᨕ = "test"; { local $ᨕ = "new test"; print $ᨕ } }';
    like( $@, qr/Can't localize lexical variable \$ᨕ at /u, q!"Can't localize lexical" error is in UTF-8! );
}
