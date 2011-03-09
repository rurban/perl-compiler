#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=27
use strict;
BEGIN {
  unless (eval "require LWP::UserAgent;") {
    print "1..0 #skip LWP::UserAgent not installed\n";
    exit;
  }
}
use Test::More tests => 1;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;


TODO: {
  local $TODO = 'require LWP::UserAgent still fails'; # cygwin-5.10.1,5.10.1d-nt,5.3.10*,...
  # &Config::AUTOLOAD failed on Config::launcher at Config.pm line 72.
  is(`$X -Mblib blib/script/perlcc -r -e"require LWP::UserAgent;print q(ok);"`, 'ok',
     "issue 27 - LWP::UserAgent");
}
