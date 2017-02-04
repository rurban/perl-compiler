# cperl or perl signatures
use strict;
BEGIN {
  unshift @INC, 't';
  require TestBC;
}
use Test::More;
use Config;

skip_all("no sigs before 5.18") if $] < 5.018;
plan tests => 2;

my $src = 'sub x($x){ print $x } x("ok")';

if (!$Config{usecperl} and $] >= 5.018) {
  $src = <<EOF . $src;
use experimental "signatures";
no warnings "experimental::signatures";
EOF
}

ctestok(1,'C','ccodesigs', $src, 'sigs');
ctestok(2,'C,-O3','ccodesigs', $src, 'sigs');
