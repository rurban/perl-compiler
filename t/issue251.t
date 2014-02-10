#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=251
# empty cvs, exists and defined &cv
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 5;
my $name = 'ccode251i';
use B::C ();
my $todo = ($B::C::VERSION ge '1.43_06') ? "" : "TODO ";

ctestok(1,'C,-O3',$name,<<'EOF', $todo.'#251 simple predeclaration');
sub f;$e=exists &f;$d=defined &f;print "ok" if "-$e-$d-" eq "-1--";
EOF

ctestok(2,'C,-O3',$name,<<'EOF', ($] >= 5.018 ? "TODO 5.18 " : "").$todo.'#251 lvalue predeclaration');
sub f :lvalue;$e=exists &f;$d=defined &f;print "ok" if "-$e-$d-" eq "-1--";
EOF

ctestok(3,'C,-O3',$name,<<'EOF', $todo.'#251 empty proto predeclaration');
sub f ();$e=exists &f;$d=defined &f;print "ok" if "-$e-$d-" eq "-1--";
EOF

ctestok(4,'C,-O3',$name,<<'EOF', $todo.'#251 proto predeclaration');
sub f ($);$e=exists &f;$d=defined &f;print "ok" if "-$e-$d-" eq "-1--";
EOF

ctestok(5,'C,-O3',$name,<<'EOF', '#251 regular cv definition');
sub f{1};$e=exists &f;$d=defined &f;print "ok" if "-$e-$d-" eq "-1-1-";
EOF

