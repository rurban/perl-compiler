#!./perl
my $keep_c      = 0;	# set it to keep the pl, c and exe files
my $keep_c_fail = 1;	# set it to keep the pl, c and exe files on failures
# better use testc.sh for debugging
use Config;

BEGIN {
    if ($^O eq 'VMS') {
       print "1..0 # skip - B::C doesn't work on VMS\n";
       exit 0;
    }
    if ($ENV{PERL_CORE}){
	chdir('t') if -d 't';
	@INC = ('.', '../lib');
    } else {
	unshift @INC, 't';
	#push @INC, "blib/arch", "blib/lib";
    }
    if (($Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
    if ($Config{ccflags} =~ /-DPERL_COPY_ON_WRITE/) {
	print "1..0 # skip - no COW for now\n";
	exit 0;
    }
    require 'test.pl'; # for run_perl()
}
use strict;
my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $ITHREADS  = ($Config{useithreads});

my @tests = tests();
my @todo = (15); # 8,14-16 fail on 5.00505
#@todo = (15) if !$ITHREADS; # 5.8.8-nt only 15 fails
# 5.6.2 CORE: 8,15,16,22. 16 fixed with 1.04_24, 8 with 1.04_25
# 5.8.8 CORE: 1,3-8,10-12,14,15,17-24 / non-threaded: 5,7-12,14-20,22-23,25
@todo = (15,25) if $] < 5.007;
@todo = (10..20,22,23) if $] >= 5.010;
@todo = (5,10..20,22,23) if $] >= 5.011;

my %todo = map { $_ => 1 } @todo;

print "1..".($#tests+1)."\n";

my $cnt = 1;
for (@tests) {
  my $todo = $todo{$cnt} ? "#TODO" : "#";
  my ($script, $expect) = split />>>+\n/;
  run_cc_test($cnt++, "C,-O1", $script, $expect, $keep_c, $keep_c_fail, $todo);
}
