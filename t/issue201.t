#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=201
# Subroutine import redefined at .../Config.pm line 38
BEGIN {
  unless (-d '.git') {
    print "1..0 #SKIP Only if -d .git\n";
    exit;
  }
}
use strict;
use Test::More tests => 2;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $perlcc = "$X -Iblib/arch -Iblib/lib blib/script/perlcc";

my $result = `$perlcc -r -e 'use Storable;*Storable::CAN_FLOCK=sub{1};print qq{ok\n}' 2>err`;
my $err = do { local $/; open my $fh, "err"; <$fh> };
is($err, "", "stderr");
is($result, "ok\n");
