#!./perl -w

require 't/CORE/test.pl';
use strict;

{
    package End;
    sub DESTROY { $_[0]->() }
    sub main::end(&) {
	my($cleanup) = @_;
	return bless(sub { $cleanup->() }, "End");
    }
}

my($val, $err);

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	1;
}; $err = $@;
is($val, 1);
is($err, "");

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
is($val, undef);
# perlcc issue 215 - https://code.google.com/p/perl-compiler/issues/detail?id=215
is($err, "t3\n");

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	local $@ = "t2\n";
	1;
}; $err = $@;
is($val, 1);
is($err, "");

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	local $@ = "t2\n";
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
is($val, undef);
# perlcc issue 215 - https://code.google.com/p/perl-compiler/issues/detail?id=215
is($err, "t3\n");

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $@ = "t2\n"; };
	1;
}; $err = $@;
is($val, 1);
is($err, "");

$@ = "t0\n";
$val = eval {
	$@ = "t1\n";
	my $c = end { $@ = "t2\n"; };
	do {
		die "t3\n";
	};
	1;
}; $err = $@;
is($val, undef);
# perlcc issue 215 - https://code.google.com/p/perl-compiler/issues/detail?id=215
is($err, "t3\n");

done_testing();
