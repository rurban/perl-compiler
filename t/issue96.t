#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=96
# defined gvsv should not store the gvsv
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More;
plan tests => 2;

my $script = 'defined($B::VERSION) && print q(ok)';

sub compile_check {
  my ($num,$b,$base,$script,$cmt) = @_;
  my $name = $base."_$num";
  unlink("$name.c", "$name.pl");
  open F, ">", "$name.pl";
  print F $script;
  close F;
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  my ($result,$out,$stderr) =
    run_cmd("$X -Iblib/arch -Iblib/lib -MO=$b,-o$name.c $name.pl", 20);
  unless (-e "$name.c") {
    print "not ok $num # $name B::$b failed\n";
    exit;
  }
  # check stderr for "blocking not found"
  #diag length $stderr," ",length $out;
  if (!$stderr and $out) {
    $stderr = $out;
  }
  $stderr =~ s/main::stderr.*//s;
  # With PADOP (threaded) the ->sv is wrong, returning a B::SPECIAL object of the targ, instead of PADSV
  like($stderr,qr/skip saving gvsv\((B::VERSION|)\) defined/, "should detect and skip B::VERSION");
  unlike($stderr,qr/GV::save \*B::VERSION done/, "should not save *B::VERSION");
}

compile_check(1,'C,-O3,-DG','ccode96i',$script,"");
