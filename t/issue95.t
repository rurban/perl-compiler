#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=95
# methods not found. see t/testc.sh -DCsP,-v -O0 95
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More;
eval "use IO::Socket::SSL";
if ($@) {
  plan skip_all => "IO::Socket::SSL required for testing issue95" ;
} else {
  plan tests => 5;
}

my $issue = <<'EOF';
use IO::Socket::INET   ();
use IO::Socket::SSL    ('inet4');
use Net::SSLeay        ();
use IO                 ();
use Socket             ();

my $handle = new IO::Socket::SSL;
$handle->blocking(0);
print "ok";
EOF

my $typed = <<'EOF';
use IO::Socket::SSL();
my IO::Socket::SSL $handle = new IO::Socket::SSL;
$handle->blocking(0);
print "ok";
EOF

sub compile_check {
  my ($num,$b,$base,$script,$cmt) = @_;
  my $name = $base."_$num";
  unlink("$name.c", "$name.pl");
  open F, ">", "$name.pl";
  print F $script;
  close F;
  my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  $b .= ',-DCmsp,-v';
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
  my $notfound = $stderr =~ /save package_pv "blocking" for method_name/;
  ok(!$notfound, $cmt.' mixed up as package');
  my $found = $stderr =~ /save found method_name "IO::Socket::blocking"/;
  ok(!$found, $cmt.' found');
}

compile_check(1,'C,-O3,-UB','ccode95i',$issue,"IO::Socket::blocking method");
compile_check(2,'C,-O3,-UB','ccode95i',$typed,'typed method'); #NYI
ctestok(3,'C,-O3,-UB','ccode95i',$issue,'TODO run');
