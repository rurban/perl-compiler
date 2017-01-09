# https://github.com/rurban/perl-compiler/issues/403
# fixed with B-C 1.54_17
use strict;
BEGIN {
  unshift @INC, 't';
  require TestBC;
}
use Test::More tests => 1;
use Config;

ctestok(1,'C,-O3','ccode403i',<<'EOF', 'use constant AV');
use constant _OPTIONS => ( 'o', 'k' );
eval q{ print join "", _OPTIONS(); };
EOF

