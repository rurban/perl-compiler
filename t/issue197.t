#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=197
# missing package DESTROY
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 3;

my $exp = "ok - dynamic destruction
ok - lexical destruction
ok - package destruction";

ctest(1,$exp,'C,-O3','ccode197i',<<'EOF','TODO #197 missing package DESTROY');
package FINALE;
{
    $ref3 = bless ["ok - package destruction"];
    my $ref2 = bless ["ok - lexical destruction\n"];
    local $ref1 = bless ["ok - dynamic destruction\n"];
    1;
}
DESTROY {
    print $_[0][0];
}
EOF

$exp = $] > 5.013005 ? "RUN MyKooh DESTRUCT OurKooh" : " MyKooh  OurKooh";

ctest(2,$exp,'C,-O3','ccode197i',<<'EOF','TODO #208 missing our DESTROY');
sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " }  my $k=bless {}, MyKooh;
sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" }our $k=bless {}, OurKooh;
EOF

# if the bless happens inside BEGIN: wontfix
ctestok(3,'C,-O3','ccode197i',<<'EOF','TODO #254 destroy a lexvar');
my $flag = 0;
sub  X::DESTROY { $flag = 1 }
{my $x; # x only exists in that scope
 BEGIN {$x = 42 } # initialize variable during compilation
 { $x = bless {}, "X" }
 # undef($x); # value should be free when exiting scope
}
print "ok\n" if $flag;
EOF
