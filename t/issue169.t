#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=183
# Attribute::Handlers
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 1;
use B::C ();
my $todo = ($B::C::VERSION gt '1.43') ? "" : "TODO ";

ctestok(1,'C,-O3','ccode169i',<<'EOF',$todo.'#169 Attribute::Handlers');
package MyTest;

use Attribute::Handlers;

sub Check :ATTR {
    #print "called\n";
    print "o" if ref $_[4] eq 'ARRAY' && join(',', @{$_[4]}) eq join(',', qw/a b c/);
}

sub a_sub :Check(qw/a b c/) {
    return "k";
}

print a_sub()."\n";
EOF

ctestok(2,'C,-O3','ccode169i',<<'EOF',$todo.'#278 run-time attributes::get');
our $anon1;
eval q/$anon1 = sub : method { $_[0]++ }/;
use attributes;
@attrs = eval q/attributes::get $anon1/;
print qq{ok\n} if "@attrs" eq "method";
#print "@attrs"
EOF

ctestok(3,'C,-O3','ccode169i',<<'EOF','#278 compile-time attributes::get');
use attributes;
our $anon = sub : method { $_[0]++ };
@attrs = attributes::get $anon;
print qq{ok\n} if "@attrs" eq "method";
EOF
