#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=80
# store cv prototypes
use Test::More tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
my $script = <<'EOF';
sub int::check {1}    #create int package for types
sub x(int,int) { @_ } #cvproto
print "o" if prototype \&x eq "int,int";
sub y($) { @_ } #cvproto
print "k" if prototype \&y eq "\$";
EOF

my $name='ccode80i';
open my $s, ">$name.pl";
print $s $script;
close $s;

my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
system($runperl,'-Mblib',"-MO=Bytecode,-o$name.plc","$name.pl");
my $runexe = qx($runperl -Mblib -MByteLoader $name.plc);
is($runexe, 'ok', 'Bytecode');

use B::C;
ctestok(2, "C", $name, $script,
	$B::C::VERSION < '1.37' ? "cvproto" : undef
       );

use B::CC;
ctestok(3, "CC", $name, $script, 
	$B::C::VERSION < '1.37' ? "cvproto" : undef
       );
