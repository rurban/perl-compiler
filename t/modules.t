# -*- cperl -*-
# t/modules.t [OPTIONS] [t/mymodules]
# check if some common CPAN modules exist and
# can be compiled successfully. Only B::C is fatal,
# CC and Bytecode optional. Use -all for all three (optional), and
# -log for the reports (now default).
#
# OPTIONS:
#  -all     - run also B::CC and B::Bytecode
#  -subset  - run only random 10 of all modules. default if ! -d .svn
#  -t       - run also tests
#  -log     - save log file. default on top100 and without subset
#
# The list in t/mymodules comes from two bigger projects.
# Recommended general lists are Task::Kensho and http://ali.as/top100/
# We are using top100 from the latter.
# We are NOT running the full module testsuite yet with -t, we can do that
# in another author test to burn CPU for a few hours resp. days.
#
# Reports:
# for p in 5.6.2d-nt 5.8.9 5.10.1 5.11.4d 5.11.4d-nt; do make -S clean; perl$p Makefile.PL; make; perl$p -Mblib t/modules.t -log; done
#
# How to installed skip modules:
# grep ^skip log.modules-bla|cut -c6-| xargs perlbla -S cpan
# or t/testm.sh -s

use strict;
use Test::More;

# try some simple XS module which exists in 5.6.2 and blead
# otherwise we'll get a bogus 40% failure rate

BEGIN {
  # check whether linking with xs works at all
  my $result = `$^X -Mblib blib/script/perlcc -e 'use Sys::Hostname;'`;
  unless (-e 'a' or -e 'a.out') {
    plan skip_all => "perlcc cannot link Sys::Hostname (XS module). Most likely wrong ldopts.";
    exit;
  }
  unshift @INC, 't';
}

our %modules;
our $keep = '';
our $log = 0;
use modules;
require "test.pl";

# Possible binary files.
my $binary_file = 'a';
$binary_file = 'a.out' if -e 'a.out';
unlink 'a', 'a.out';

my $opts_to_test = 1;
my $do_test;
$opts_to_test = 3 if grep /^-all$/, @ARGV;
$do_test = 1 if grep /^-t$/, @ARGV;

# Determine list of modules to action.
diag "scanning installed modules";
our @modules = get_module_list();
my $test_count = scalar @modules * $opts_to_test * ($do_test ? 5 : 4);
# $test_count -= 4 * $opts_to_test * (scalar @modules - scalar(keys %modules));
plan tests => $test_count;

use Config;
use B::C;
use POSIX qw(strftime);

eval { require IPC::Run; };
my $have_IPC_Run = defined $IPC::Run::VERSION;
log_diag("Warning: IPC::Run is not available. Error trapping will be limited, no timeouts.")
  unless $have_IPC_Run;

my @opts = ("");				  # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV;  # all 3 compilers
my $perlversion = perlversion();
$log = 1 if -d '.svn';
$log = 0 if @ARGV;
$log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

if ($log) {
  $log = @ARGV ? "log.modules-$perlversion-".strftime("%Y%m%d-%H%M%S",localtime)
    : "log.modules-$perlversion";
  if (-e $log) {
    use File::Copy;
    copy $log, "$log.bak";
  }
  open(LOG, ">", "$log");
  close LOG;
}
unless (is_subset) {
  my $svnrev = "";
  if (-d '.svn') {
    $svnrev = `svn info|grep Revision:`;
    chomp $svnrev;
    $svnrev =~ s/Revision:\s+/r/;
  }
  log_diag("B::C::VERSION = $B::C::VERSION $svnrev");
  log_diag("perlversion = $perlversion");
  log_diag("path = $^X");
  my $bits = 8 * $Config{ptrsize};
  log_diag("platform = $^O $bits"."bit");
  log_diag($Config{'useithreads'} ? "threaded perl" : "non-threaded perl");
}

my $module_count = 0;
my ($skip, $pass, $fail, $todo) = (0,0,0,0);

MODULE:
for my $module (@modules) {
  $module_count++;
  local($\, $,);   # guard against -l and other things that screw with
                   # print
 SKIP: {
    # if is a special module that can't be required like others
    unless ($modules{$module}) {
      $skip++;
      log_pass("skip", "$module", 0);

      skip("$module not installed", 4 * scalar @opts);
      next MODULE;
    }
    if (is_skip($module)) { # !$have_IPC_Run is not really helpful here
      my $why = is_skip($module);
      $skip++;
      log_pass("skip", "$module $why", 0);

      skip("$module $why", 4 * scalar @opts);
      next MODULE;
    }
    $module = 'if(1) => "Sys::Hostname"' if $module eq 'if';

  TODO: {
      my $s = is_todo($module);
      local $TODO = $s if $s;
      $todo++ if $TODO;

      open F, ">", "mod.pl" or die;
      print F "use $module;\nprint 'ok';\n" or die;
      close F or die;

      my $module_passed = 1;
      my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
      foreach my $opt (@opts) {
        # my $stderr = $^O eq 'MSWin32' ? "" : ($log ? "2>>$log.err" : "2>/dev/null";
        $opt .= " $keep" if $keep;
        # XXX TODO ./a often hangs but perlcc not
        my @cmd = grep {!/^$/} $runperl,"-Mblib","blib/script/perlcc",$opt,"-r","mod.pl";
        my $cmd = "$runperl -Mblib blib/script/perlcc $opt -r";
        my ($result, $out, $err) = run_cmd(\@cmd, 120); # in secs
        ok(-e $binary_file && -s $binary_file > 20,
           "$module_count: use $module  generates non-zero binary")
          or $module_passed = 0;
        is($result, 0,  "$module_count: use $module $opt exits with 0")
          or $module_passed = 0;
	$err =~ s/^Using .+blib\n//m if $] < 5.007;
        like($out, qr/ok$/ms, "$module_count: use $module $opt gives expected 'ok' output")
          or $module_passed = 0;
        log_pass($module_passed ? "pass" : "fail", $module, $TODO);

        if ($module_passed) {
          $pass++;
        } else {
          diag "Failed: $cmd -e 'use $module; print \"ok\"'";
          $fail++;
        }

      TODO: {
          local $TODO = 'STDERR from compiler warnings in work' if $err;
          is($err, '', "$module_count: use $module  no error output compiling")
            && ($module_passed)
              or log_err($module, $out, $err)
            }
      }
      if ($do_test) {
        TODO: {
          local $TODO = 'all module tests';
          `$runperl -Mblib -It -MCPAN -Mmodules -e"CPAN::Shell->testcc("$module")"`;
        }
      }
      unlink ("mod.pl", 'a', 'a.out');
    }}
}

my $count = scalar @modules - $skip;
log_diag("$count / $module_count modules tested with B-C-${B::C::VERSION} - perl-$perlversion");
log_diag(sprintf("pass %3d / %3d (%s)", $pass, $count, percent($pass,$count)));
log_diag(sprintf("fail %3d / %3d (%s)", $fail, $count, percent($fail,$count)));
log_diag(sprintf("todo %3d / %3d (%s)", $todo, $fail, percent($todo,$fail)));
log_diag(sprintf("skip %3d / %3d (%s not installed)\n",
                 $skip, $module_count, percent($skip,$module_count)));

exit;

sub is_todo {
  my $module = shift or die;

  foreach (qw(ExtUtils::MakeMaker LWP Attribute::Handlers MooseX::Types)) {
    return 'generally' if $_ eq $module;
  }
  if ($] < 5.007) {
    # Can't locate object method "RV" via package "B::PV"
    # (perhaps you forgot to load "B::PV"?) at lib/B/C.pm line 422
    foreach(qw( ExtUtils::CBuilder Sub::Name)) {
      return '< 5.007' if $_ eq $module;
    }
  }
  if ($] < 5.010) {
    foreach(qw(B::Hooks::EndOfScope)) {
      return '< 5.010' if $_ eq $module;
    }
  }
  if ($] >= 5.007) {
    foreach(qw(File::Temp)) {
      return '>= 5.007' if $_ eq $module;
    }
  }
  if ($] >= 5.010) {
    foreach(qw(
		Test::Simple Module::Build Test::Exception
		Test::NoWarnings Test::Warn Test::Pod
	     )) {
      return '>= 5.10' if $_ eq $module;
    }
  }
  if ($] > 5.010) {
    foreach(qw(ExtUtils::Install Test::Harness Moose)) {
      return '> 5.010' if $_ eq $module;
    }
  }
  if ($] >= 5.013) {
    foreach(qw(Test
               Pod::Simple
               Getopt::Long
               Pod::Parser
               ExtUtils::MakeMaker
               Pod::Text
               Test
               Data::Dumper
               ExtUtils::CBuilder
               File::Path
               AppConfig
               DateTime::TimeZone
               Path::Class
               CGI
               YAML
              ))
    {
      return '>= 5.013' if $_ eq $module;
    }
  }
  if ($Config{useithreads}) {
    foreach(qw(
               File::Temp ExtUtils::Install
               Test::Tester Attribute::Handlers
               Test::Deep FCGI B::Hooks::EndOfScope Digest::SHA1
               namespace::clean DateTime::Locale DateTime
               Template::Stash
              )) {
      return 'with threads' if $_ eq $module;
    }
    if ($] >= 5.010 and $] < 5.012) {
      foreach(qw(
                 Class::Accessor Class::MOP
                )) {
        return '5.10 with threads' if $_ eq $module;
      }
    }
  } else {
    if ($] >= 5.010 and $] < 5.012) {
      foreach(qw(
                 IO ExtUtils::Install Test::Tester Test::Deep Path::Class
		 Scalar::Util
                )) {
        return '5.10 without threads' if $_ eq $module;
      }
    }
    if ($] >= 5.013) {
      foreach(qw(
                 DBI
                )) {
        return '5.13 without threads' if $_ eq $module;
      }
    }
  }
}

sub is_skip {
  my $module = shift or die;

  if ($] >= 5.011004) {
    foreach (qw(Test::Simple File::Temp Attribute::Handlers)) {
      return 'fails $] >= 5.011004' if $_ eq $module;
    }
    if ($Config{useithreads}) { # hangs and crashes threaded since 5.12
      foreach (qw( Moose Class::MOP)) {
	return 'hangs threaded, $] >= 5.011004' if $_ eq $module;
      }
    }
  }
}
