#! /usr/bin/env perl
use strict;
use Test::More tests => 4;
my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $Mblib = $^O eq 'MSWin32' ? '-Iblib\arch -Iblib\lib' : "-Iblib/arch -Iblib/lib";
my $exe = $^O eq 'MSWin32' ? 'c_argv.exe' : './c_argv';
my $pl = "c_argv.pl";
my $plc = $pl . "c";
my $d = <DATA>;

open F, ">", $pl;
print F $d;
close F;
is(`$runperl $Mblib blib/script/perlcc -O3 -o $exe -r $pl ok 1`, "ok 1\n",
   "perlcc -r file args");
unlink($exe);

open F, ">", $pl;
my $d2 = $d;
$d2 =~ s/ ok 1/ ok 2/;
print F $d2;
close F;
is(`$runperl $Mblib blib/script/perlcc -O -o $exe -r $pl ok 2`, "ok 2\n",
   "perlcc -O -r file args");
unlink($exe);

open F, ">", $pl;
my $d3 = $d;
$d3 =~ s/ ok 1/ ok 3/;
print F $d3;
close F;
is(`$runperl $Mblib blib/script/perlcc -B -r $pl ok 3`, "ok 3\n",
   "perlcc -B -r file args");

# issue 30
$d = '
sub f1 {
   my($self) = @_;
   $self->f2;
}
sub f2 {}
sub new {}
print "@ARGV\n";';

open F, ">", $pl;
print F $d;
close F;
`$runperl $Mblib blib/script/perlcc -o $exe $pl`;
is (`$exe a b c`, "a b c\n",
   "issue 30: perlcc -o $exe; $exe args");

END {
  unlink($exe, $pl, $plc);
}

__DATA__
print @ARGV?join(" ",@ARGV):"not ok 1 # empty \@ARGV","\n";
