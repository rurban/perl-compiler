#!./perl

BEGIN {
	require 't/CORE/test.pl';
}

no warnings 'once';
$main::use_crlf = 1;

my $script = './t/CORE/io/through.t';

die "No script: $script" unless -f $script;
do './t/CORE/io/through.t' or die "no kid script";
