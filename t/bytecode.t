#! /usr/bin/env perl
my $keep_pl       = 0;	# set it to keep the src pl files
my $keep_plc      = 0;	# set it to keep the bytecode files
my $keep_plc_fail = 1;	# set it to keep the bytecode files on failures
my $do_coverage   = undef; # do bytecode insn coverage
my $verbose       = $ENV{TEST_VERBOSE}; # better use t/testplc.sh for debugging
use Config;
# Debugging Note: perl5.6.2 has no -Dvl, use -D260 (256+4) instead. v mapped to f

BEGIN {
  if ($^O eq 'VMS') {
    print "1..0 # skip - Bytecode/ByteLoader doesn't work on VMS\n";
    exit 0;
  }
  if ($ENV{PERL_CORE}){
    chdir('t') if -d 't';
    @INC = ('.', '../lib');
  } else {
    unshift @INC, 't';
    push @INC, "blib/arch", "blib/lib";
  }
  if (($Config{'extensions'} !~ /\bB\b/) ){
    print "1..0 # Skip -- Perl configured without B module\n";
    exit 0;
  }
  #if ($Config{ccflags} =~ /-DPERL_COPY_ON_WRITE/) {
  #  print "1..0 # skip - no COW for now\n";
  #  exit 0;
  #}
  require 'test.pl'; # for run_perl()
}
use strict;
my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $ITHREADS  = ($Config{useithreads});
my $AUTHOR    = -d ".svn";

my @tests = tests();
my $numtests = $#tests+1;
$numtests++ if $DEBUGGING and $do_coverage;

print "1..$numtests\n";

my $cnt = 1;
my $test;
my %insncov; # insn coverage
if ($DEBUGGING) {
  # op coverage either via Assembler debug, or via ByteLoader -Dv on a -DDEBUGGING perl
  if ($do_coverage) {
    use B::Asmdata q(@insn_name);
    for (0..@insn_name) { $insncov{$_} = 0; }
  }
}
my @todo = (44); # 33 fixed with r802
@todo = (3,6,8..10,12,15,16,18,26..28,31,33,35,38,41..44,46)
  if $] < 5.007; # CORE failures, our Bytecode 56 compiler not yet backported
push @todo, (39)    if $] > 5.007 and $] < 5.010;
push @todo, (42,43) if $] > 5.011003 and $] < 5.013;
push @todo, (42)    if $ITHREADS and $] == 5.010001; # XXX WTF???
push @todo, (32)    if $] > 5.011;
push @todo, (28)    if $] > 5.013;	# del_backref
push @todo, (41..43)if !$ITHREADS;
push @todo, (32)    if !$ITHREADS and $] >= 5.010 and $] < 5.013; # del_backref fixed with r790. not?
push @todo, (27,43) if !$ITHREADS and $] >= 5.010;
push @todo, (42)    if !$ITHREADS and $] >= 5.013;
push @todo, (27)    if $Config{ptrsize} == 8;
# cannot store labels on windows 5.12: 21
push @todo, (21) if $^O =~ /MSWin32|cygwin|AIX/ and $] > 5.011003 and $] < 5.013;

my @skip = (); #(20,27,29) if $] >= 5.010;
push @skip, (42..43) if !$ITHREADS;

my %todo = map { $_ => 1 } @todo;
my %skip = map { $_ => 1 } @skip;
my $Mblib = $] >= 5.008 ? "-Mblib" : ""; # test also the CORE B in older perls?
my $backend = "Bytecode";
unless ($Mblib) { # check for -Mblib from the testsuite
  if (grep { m{blib(/|\\)arch$} } @INC) {
    $Mblib = "-Iblib/arch -Iblib/lib";  # force -Mblib via cmdline, but silent!
  }
}
else {
  $backend = "-qq,Bytecode,-q" unless $ENV{TEST_VERBOSE};
}
#$Bytecode = $] >= 5.007 ? 'Bytecode' : 'Bytecode56';
#$Mblib = '' if $] < 5.007; # override harness on 5.6. No Bytecode for 5.6 for now.
for (@tests) {
  my $todo = $todo{$cnt} ? "#TODO " : "#";
  my ($got, @insn);
  if ($todo{$cnt} and $skip{$cnt}) { # and !$AUTHOR
    print sprintf("ok %d # skip\n", $cnt);
    next;
  }
  my ($script, $expect) = split />>>+\n/;
  $expect =~ s/\n$//;
  $test = "bytecode$cnt.pl";
  open T, ">$test"; print T $script; close T;
  unlink "${test}c" if -e "${test}c";
  $got = run_perl(switches => [ "$Mblib -MO=$backend,-o${test}c" ],
		  verbose  => $verbose, # for DEBUGGING
		  nolib    => $ENV{PERL_CORE} ? 0 : 1, # include ../lib only in CORE
		  stderr   => 1, # to capture the "bytecode.pl syntax ok"
		  timeout  => 10,
		  progfile => $test);
  unless ($?) {
    # test coverage if -Dv is allowed
    if ($do_coverage and $DEBUGGING) {
      my $cov = run_perl(progfile => "${test}c", # run the .plc
			 nolib    => $ENV{PERL_CORE} ? 0 : 1,
			 stderr   => 1,
			 timeout  => 20,
			 switches => [ "$Mblib -MByteLoader -Dv" ]);
      for (map { /\(insn (\d+)\)/ ? $1 : undef }
	     grep /\(insn (\d+)\)/, split(/\n/, $cov)) {
	$insncov{$_}++;
      }
    }
    $got = run_perl(progfile => "${test}c", # run the .plc
                    verbose  => $ENV{TEST_VERBOSE}, # for debugging
		    nolib    => $ENV{PERL_CORE} ? 0 : 1,
		    stderr   => 1,
		    timeout  => 5,
		    switches => [ "$Mblib -MByteLoader" ]);
    unless ($?) {
      if ($cnt == 25 and $expect eq '0 1 2 3 4321' and $] < 5.008) {
        $expect = '0 1 2 3 4 5 4321';
      }
      if ($got =~ /^$expect$/) {
	print "ok $cnt", $todo eq '#' ? "\n" : "$todo\n";
	next;
      } else {
        # test failed, double check uncompiled
        $got = run_perl(verbose  => $ENV{TEST_VERBOSE}, # for debugging
                        nolib    => $ENV{PERL_CORE} ? 0 : 1, # include ../lib only in CORE
                        stderr   => 1, # to capture the "ccode.pl syntax ok"
                        timeout  => 5,
                        progfile => $test);
        if (! $? and $got =~ /^$expect$/) {
          $keep_plc = $keep_plc_fail unless $keep_plc;
          print "not ok $cnt $todo wanted: $expect, got: $got\n";
          next;
        } else {
          print "ok $cnt # skip also fails uncompiled\n";
          next;
        }
      }
    }
  }
  print "not ok $cnt $todo wanted: $expect, \$\? = $?, got: $got\n";
} continue {
  1 while unlink($keep_pl ? () : $test, $keep_plc ? () : "${test}c");
  $cnt++;
}

# DEBUGGING coverage test, see STATUS for the missing test ops.
# The real coverage tests are in asmdata.t
if ($do_coverage and $DEBUGGING) {
  my $zeros = '';
  use B::Asmdata q(@insn_name);
  for (0..$#insn_name) { $zeros .= ($insn_name[$_]."($_) ") unless $insncov{$_} };
  if ($zeros) { print "not ok ",$cnt++," # TODO no coverage for: $zeros"; }
  else { print "ok ",$cnt++," # TODO coverage unexpectedly passed";}
}
