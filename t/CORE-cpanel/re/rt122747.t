#!./perl
use strict;
use warnings;

$| = 1;


BEGIN {
    unshift @INC, 't/CORE/lib', 't/CORE/ext/re';
    require 't/CORE/test.pl';
}

plan tests => 3;
use strict;

my(@body) = (
  "<mailto:xxxx.xxxx\@outlook.com>",
  "A\x{B9}ker\x{E8}eva xxxx.xxxx\@outlook.com \x{201D}",
);

for (@body) {
  s{ <? (?<!mailto:) \b ( [a-z0-9.]+ \@ \S+ ) \b
     (?: > | \s{1,10} (?!phone) [a-z]{2,11} : ) }{ }xgi;
  my $got= $1;
  is( $got, '.xxxx@outlook.com' );
}
ok("got to the end without dieing (note without DEBUGGING passing this test means nothing)");

