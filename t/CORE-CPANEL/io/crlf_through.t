#!./perl

BEGIN {
	require 't/CORE-CPANEL/test.pl';
}

no warnings 'once';
$main::use_crlf = 1;

my $script = './t/CORE-CPANEL/io/through.t';

die "No script: $script" unless -f $script;
do './t/CORE-CPANEL/io/through.t' or die "no kid script";
