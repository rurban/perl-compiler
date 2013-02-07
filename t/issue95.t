#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=95
# methods not found in no ISA in any candidate. see t/testc.sh -DCsP,-v -O0 95
# not enough candidates.
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More;
eval "require IO::Socket::SSL;";
if ($@) {
  plan skip_all => "IO::Socket::SSL required for testing issue95" ;
} else {
  plan tests => 6;
}

my $issue = <<'EOF1';
use IO::Socket::INET   ();
use IO::Socket::SSL    ('inet4');
use Net::SSLeay        ();
use IO                 ();
use Socket             ();

my $handle = IO::Socket::SSL->new(SSL_verify_mode =>0);
$handle->blocking(0);
print "ok";
EOF1

my $typed = <<'EOF2';
use IO::Socket::SSL();
my IO::Handle $handle = IO::Socket::SSL->new(SSL_verify_mode =>0);
$handle->blocking(0);
print "ok";
EOF2

my $plain = <<'EOF3';
package dummy;
my $invoked_as_script = !caller();
__PACKAGE__->script(@ARGV) if $invoked_as_script;
sub script {my($package,@args)=@_;print "ok"}
EOF3

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
  ok($found, $cmt.' found');
}

compile_check(1,'C,-O3,-UB','ccode95i',$issue,"IO::Socket::blocking method");
compile_check(3,'C,-O3,-UB','ccode95i',$typed,'typed method'); #optimization NYI
ctestok(5,'C,-O3,-UB','ccode95i',$issue,($]>5.015?'TODO ':'').'run');
ctestok(6,'C,-O3,-UB','ccode95i',$plain,'find __PACKAGE__');
