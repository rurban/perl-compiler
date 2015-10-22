#!perl -w

# Tests if $$ and getppid return consistent values across threads

BEGIN {
    unshift @INC, "./lib";
    require 't/CORE/test.pl';
}

use strict;
use Config;

INIT {
    plan tests => 3;
    eval 'use threads; use threads::shared';
    skip_all("unable to load thread modules") if $@;
}

my ($pid, $ppid) = ($$, getppid());
my $pid2 : shared = 0;
my $ppid2 : shared = 0;

new threads( sub { ($pid2, $ppid2) = ($$, getppid()); } ) -> join();

is($pid,  $pid2,  'pids');
is($ppid, $ppid2, 'ppids');
