#!./perl

# There are few filetest operators that are portable enough to test.
# See pod/perlport.pod for details.

BEGIN {
    unshift @INC, 't/CORE-CPANEL/lib';
    require 't/CORE-CPANEL/test.pl';
}

plan 4;
use FileHandle;

my $str = "foo";
open my $fh, "<", \$str;
is <$fh>, "foo";

eval {
   $fh->seek(0, 0);
   is $fh->tell, 0;
   is <$fh>, "foo";
};

is $@, '';
