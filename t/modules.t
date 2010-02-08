# -*- cperl -*-
# t/modules.t [-all] [t/mymodules]
# check if some common CPAN modules exist and
# can be compiled successfully. Only B::C is fatal,
# CC and Bytecode optional. Use -all for all three (optional), and
# -log for the reports (now default).
#
# The list in t/mymodules comes from two bigger projects.
# Recommended general lists are Task::Kensho and http://ali.as/top100/
# We are using top100 from the latter.
# We are NOT running the module testsuite yet, we can do that in another test
# to burn CPU for a few hours.
#
# Reports:
# for p in 5.6.2d-nt 5.8.9 5.10.1 5.11.4d-nt; do make -S clean; perl$p Makefile.PL; make; perl$p -Mblib t/modules.t -log; done
use strict;
use Test::More;

# try some simple XS module which exists in 5.6.2 and blead
# otherwise we'll get a bogus 40% failure rate

BEGIN {
  # check whether linking with xs works at all
  my $result = `$^X -Mblib blib/script/perlcc -e 'use Sys::Hostname;'`;
  unless (-e 'a' or -e 'a.out') {
    plan skip_all => "perlcc cannot link Sys::Hostname (XS module). Most likely wrong ldopts. Try -Bdynamic or -Bstatic.";
    exit;
  }
}

# Possible binary files.
my $binary_file = 'a';
$binary_file = 'a.out' if -e 'a.out';
unlink 'a', 'a.out';

my $opts_to_test = 1;
$opts_to_test = 3 if grep /-all/, @ARGV;

# Determine list of modules to action.
my %modules;
my @modules = get_module_list();
my $test_count = scalar @modules * $opts_to_test * 4;
# $test_count -= 4 * $opts_to_test * (scalar @modules - scalar(keys %modules));
plan tests => $test_count;

use Config;
use B::C;

eval { require IPC::Run; };
my $have_IPC_Run = defined $IPC::Run::VERSION;
log_diag("Warning: IPC::Run is not available. Error trapping will be limited")
  unless $have_IPC_Run;

my @opts = ("");				  # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV;  # all 3 compilers
my $log = 0;
my $perlversion;
$log = 1 if -d '.svn';
$log = 0 if @ARGV;
$log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
$perlversion = sprintf("%1.6f%s%s",
                       $],
                       ($DEBUGGING ? 'd' : ''),
                       ($Config{useithreads} ? '' : '-nt'));
if ($log) {
  $log = "log.modules-$perlversion";
  if (-e $log) {
    use File::Copy;
    copy $log, "$log.bak";
  }
  open(LOG, ">", "$log");
  close LOG;
}
log_diag("B::C::VERSION = $B::C::VERSION");
log_diag("perlversion = $perlversion");
log_diag("platform = $^O");
log_diag($Config{'useithreads'} ? "threaded perl" : "non-threaded perl");

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
    $module = 'if(1) => "Sys::Hostname"' if $module eq 'if';

  TODO: {
      local $TODO = "$module labeled to be skipped for this perl version"
        if is_todo($module);
      $todo++ if $TODO;

      open F, ">", "mod.pl" or die;
      print F "use $module;\nprint 'ok';\n" or die;
      close F or die;

      my $module_passed = 1;
      foreach my $opt (@opts) {
        # my $stderr = $^O eq 'MSWin32' ? "" : ($log ? "2>>$log.err" : "2>/dev/null";

        my $cmd = "$^X -Mblib blib/script/perlcc $opt -r";
        diag "$cmd -e 'use $module; print \"ok\"'";
        my ($result, $out, $err) = run_cmd("$cmd mod.pl");
        ok(-e $binary_file && -s $binary_file > 20,
           "$module_count: use $module generates non-zero binary") or $module_passed = 0;
        is($result, 0,  "$module_count: use $module $opt exits with 0") or $module_passed = 0;
        ok($out =~ /ok$/,  "$module_count: use $module $opt gives expected 'ok' output")
          or $module_passed = 0;
        log_pass($module_passed ? "pass" : "fail", $module, $TODO);

        if ($module_passed) {
          $pass++;
        } else {
          $fail++;
        }

      TODO: {
          local $TODO = 'STDERR from compiler warnings unavoidable';
          is($err, '', "$module_count: use $module no error output compiling")
            && ($module_passed)
              or log_err($module, $out, $err)
            }
      }
      unlink ("mod.pl", 'a', 'a.out');
    }}
}

#my $fail = $module_count - $pass - $todo - $skip;
my $count = scalar @modules - $skip;
log_diag("$count / $module_count modules tested with B-C-${B::C::VERSION} - perl-$perlversion");
log_diag(sprintf("pass %3d / %3d (%s)", $pass, $count, percent($pass,$count)));
log_diag(sprintf("fail %3d / %3d (%s)", $fail, $count, percent($fail,$count)));
log_diag(sprintf("todo %3d / %3d (%s)", $todo, $module_count, percent($todo,$module_count)));
log_diag(sprintf("skip %3d / %3d (%s not installed)\n",
                 $skip, $module_count, percent($skip,$module_count)));

exit;

sub percent {
  $_[1] ? sprintf("%0.1f%%", $_[0]*100/$_[1]) : '';
}

sub run_cmd {
  my ($cmd, $timeout) = @_;

  my ($result, $out, $err) = (0, '', '');
  if ( ! $have_IPC_Run ) {
    local $@;
    # No real way to trap STDERR?
    $cmd .= " 2>&1" if($^O !~ /^MSWin32|VMS/);
    $out = `$cmd`;
    $result = $?;
  }
  else {
    my $in;
    my @cmd = split /\s+/, $cmd;

    eval {
      my $h = IPC::Run::start(\@cmd, \$in, \$out, \$err);

      for (1..60) {
        if(!$h->pumpable) {
          last;
        }
        else {
          $h->pump_nb;
          diag "waiting $_\n" if $_ > 35;
          sleep 10;
        }
      }
      if($h->pumpable) {
        $h->kill_kill;
        $err .= "Timed out waiting for process exit";
      }
      $h->finish or die "cat returned $?";
      $result = $h->result(0);
    };
    $err .= "\$\@ = $@" if($@);
  }
  return ($result, $out, $err);
}

sub is_todo {
  my $module = shift or die;

  foreach (qw(Attribute::Handlers B::Hooks::EndOfScope YAML MooseX::Types)) {
    return 1 if $_ eq $module;
  }

  if ($] >= 5.010 && $] < 5.011004) {
    foreach(qw(File::Temp ExtUtils::Install Test::NoWarnings)) {
      return 1 if $_ eq $module;
    }
  }

  if ($Config{useithreads}) {
    foreach(qw(
               Pod::Parser File::Temp ExtUtils::Install
               LWP Test::Tester Attribute::Handlers
               Test::Deep DBI FCGI B::Hooks::EndOfScope Digest::SHA1
               namespace::clean DateTime::Locale DateTime
               Template::Stash
              )) {
      return 1 if $_ eq $module;
    }
  }
}

sub log_diag {
  my $message = shift;
  chomp $message;
  diag( $message );
  return unless $log;

  foreach ($log, "$log.err") {
    open(LOG, ">>", $_);
    $message =~ s/\n./\n# /xmsg;
    print LOG "# $message\n";
    close LOG;
  }
}

sub log_pass {
  my ($pass_msg, $module, $todo) = @_;
  return unless $log;

  if ($todo) {
    $todo = " #TODO $todo";
  } else {
    $todo = '';
  }

  open(LOG, ">>", "$log");
  print LOG "$pass_msg $module$todo\n";
  close LOG;
}

sub log_err {
  my ($module, $out, $err) = @_;
  return if(!$log);

  $_ =~ s/\n/\n# /xmsg foreach($out, $err); # Format for comments

  open(ERR, ">>", "$log.err");
  print ERR "Failed $module\n";
  print ERR "# No output\n" if(!$out && !$err);
  print ERR "# STDOUT:\n# $out\n" if($out && $out ne 'ok');
  print ERR "# STDERR:\n# $err\n" if($err);
  close ERR;
}

sub get_module_list {
  # Parse for command line modules and use this if seen.
  my @modules = grep {$_ !~ /^-(all|log|subset)$/} @ARGV; # Parse out -all var.
  my $module_list  = 't/top100';
  if (-e $modules[0]) {
    $module_list = $modules[0];
  }
  else {
    return @modules if @modules;
  }

  local $/;
  open F, "<", $module_list or die "$module_list not found";
  my $s = <F>;
  close F;
  @modules = grep {s/\s+//g;!/^#/} split /\n/, $s;

  diag "scanning installed modules";
  for my $m (@modules) {
    if (eval "require $m; 1;" || $m eq 'if' ) {
      $modules{$m} = 1;
    }
  }

  if (! -e '.svn' || grep /^-subset$/, @ARGV) {
    log_diag(".svn does not exist so only running a subset of tests");
    @modules = random_sublist(@modules);
  }

  @modules;
}

sub random_sublist {
  my @modules = @_;
  my %sublist;
  while (keys %sublist <= 10) {
    my $m = $modules[int(rand(scalar @modules))];
    next unless $modules{$m}; # Don't random test uninstalled module
    $sublist{$m} = 1;
  }
  return keys %sublist;
}
