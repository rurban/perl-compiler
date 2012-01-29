#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=27
use strict;
BEGIN {
  unless (eval "require LWP::UserAgent;") {
    print "1..0 #skip LWP::UserAgent not installed\n";
    exit;
  }
}
use Test::More tests => 2;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $opt = '';
$opt .= ",-fno-warnings" if $] >= 5.013005;
$opt .= ",-fno-fold" if $] >= 5.013009;
$opt = "-Wb=".substr($opt,1) if $opt;

TODO: {
  local $TODO = 'require LWP::UserAgent still fails'
    if $] < 5.013 or $] > 5.015002; # cygwin-5.10.1,5.10.1d-nt,5.13.10*,...
  # Attempt to reload Config.pm aborted.
  # Global symbol "%Config" requires explicit package name at 5.8.9/Time/Local.pm line 36
  # 5.15: Undefined subroutine &utf8::SWASHNEW called at /usr/local/lib/perl5/5.15.3/constant.pm line 36
  # old: &Config::AUTOLOAD failed on Config::launcher at Config.pm line 72.
  is(`$X -Mblib blib/script/perlcc $opt -occodei27 -r -e"require LWP::UserAgent;print q(ok);"`, 'ok',
     "require LWP::UserAgent $opt");
}
# But works with -O2 just fine
is(`$X -Mblib blib/script/perlcc $opt -O2 -occodei27_o2 -r -e"require LWP::UserAgent;print q(ok);"`, 'ok',
   "-O2 require LWP::UserAgent $opt");

END {
  unlink qw(ccodei27_o2 ccodei27_o2.c);
  unlink qw(ccodei27 ccodei27.c);
}
