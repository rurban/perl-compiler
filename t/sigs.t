# cperl or perl signatures
use strict;
BEGIN {
  unshift @INC, 't';
  require TestBC;
}
use Test::More;
use Config;

plan skip_all => "no sigs before 5.20" if $] < 5.020;
plan tests => 4;

my $src = 'sub x($x){ print $x } x("ok")';
my ($todo, $todocc) = ('','');

if (!$Config{usecperl}) {
  $todo   = 'TODO ' if $] >= 5.025;
  $todocc = 'TODO ' if $] > 5.023007;
  # experimental was first released with perl v5.19.11
  $src = <<EOF . $src;
use experimental "signatures";
no warnings "experimental::signatures";
EOF
}

ctestok(1,'C','ccodesigs', $src, $todo.'sigs C -O0');
ctestok(2,'C,-O3','ccodesigs', $src, $todo.'sigs C -O3');
plctestok(3,'ccodesigs', $src, $todo.'sigs BC -O3');
ctestok(4,'CC','ccodesigs', $src, $todocc.'sigs CC');
