#!./perl

use Errno;
BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

use strict;

plan tests => 2;

my $tmpfile = tempfile();

open(A,"+>$tmpfile");
print A "_";
seek(A,0,0);

my $b = "abcd"; 
$b = "";

read(A,$b,1,4);

close(A);

is($b,"\000\000\000\000_"); # otherwise probably "\000bcd_"

$! = 0;
no warnings 'unopened';
read(B,$b,1);
ok($! == &Errno::EBADF);
