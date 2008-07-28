#!./perl
my $keep_c      = 0;	# set it to keep the pl, c and exe files
my $keep_c_fail = 0;	# set it to keep the pl, c and exe files on failures
# better use testc.sh for debugging

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
	push @INC, "blib/arch", "blib/lib";
    }
    use Config;
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

undef $/;
open TEST, "< t/TESTS" or open TEST, "< TESTS";
my @tests = split /\n###+\n/, <TEST>;
close TEST;
my @todo;
if ($Config{ccflags} =~ /-DDEBUGGING/) {
  @todo = (8..10, 14..16);
  @todo = (2..7, 11..12, 17..19) if ($] > 5.009 and $Config{usethreads} eq 'undef');
  #@todo = (5, 7, 11..12, 17..19);
  #@todo = (2..12, 14..19) if $] > 5.009; #let it fail
} else {
  #@todo = (1..7, 11..13, 17..19);
  @todo = (8..10, 14..16);
  @todo = (2..7, 11) if $] > 5.009;
  #@todo = (2..12, 14..19) if $] > 5.009; #let it fail
}
my %todo = map { $_ => 1 } @todo;

print "1..".($#tests+1)."\n";

my $cnt = 1;
for (@tests) {
  my $todo = $todo{$cnt} ? " TODO " : "";
  my ($script, $expect) = split />>>+\n/;
  run_cc_test($cnt++, "C", $script, $expect, $keep_c, $keep_c_fail, $todo);
}
