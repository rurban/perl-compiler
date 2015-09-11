#!./perl

#This file is intentionally written in UTF-8

BEGIN {
    push @INC, "t/CORE/lib";
    require 't/CORE/test.pl';
}

plan 1;

use utf8;
use strict;
use open qw( :utf8 :std );

{
    local $@;
    eval 'sub testme { my $ᨕ = "test"; { local $ᨕ = "new test"; print $ᨕ } }';
    like( $@, qr/Can't localize lexical variable \$ᨕ at /u, q!"Can't localize lexical" error is in UTF-8! );
}
