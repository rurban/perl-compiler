#!./perl -w

package bar;
sub search { shift =~ m?bar? ? 1 : 0 }
sub reset_zlopp { reset }

package foo;
sub ZZIP { shift =~ m?ZZIP? ? 1 : 0 }

package main;

print "1..1\n";

foo::ZZIP("ZZIP");
bar::reset_zlopp();
print !foo::ZZIP("ZZIP") ? "ok\n" : "not ok\n";
