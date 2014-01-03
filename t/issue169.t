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
my $todo = ($B::C::VERSION ge '1.42_71') ? "" : "TODO ";

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
