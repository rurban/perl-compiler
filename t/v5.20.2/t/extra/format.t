#!./perl

# view https://github.com/rurban/perl-compiler/issues/216

print "1..1\n";

my $x = "ok 1";
format A_FORMAT =
@<<<<<<<
$x
.

*STDOUT = *A_FORMAT{FORMAT};
write;
