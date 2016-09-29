#!/bin/env perl
my $p;
BEGIN {
	$p = {
		a => 1,
		b => 2,
		c => 3,
	};
	my @a = ( 1..1000 );
	$p = { %$p, @a };

}



print ref($p) . "\n";

print "a => $p->{a}\n";
print "b => $p->{b}\n";
print "c => $p->{c}\n";
print scalar(%$p) . "\n";
print join( " - ", keys(%$p), "\n");