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

BEGIN {
  # try some simple XS module which exists in 5.6.2 and blead
  # otherwise we'll get a bogus 40% failure rate
  my $result = `$^X -Mblib blib/script/perlcc -e 'use Sys::Hostname;'`;
  # check whether linking with xs works at all
  unless (-e 'a' or -e 'a.out') {
    print "1..0 #skip perlcc cannot link Sys::Hostname. Most likely wrong ldopts from your Config.\n";
    exit;
  }
  unlink ("a", "a.out");
}

use Config;
use strict;

eval { require IPC::Run; };
my $have_IPC_Run = defined $IPC::Run::VERSION;

sub run_cmd {
    my ($cmd, $timeout) = @_;
    my ($out, $result, $in, $err);

    if ( ! $have_IPC_Run ) {
	local $@;
	$out = `$cmd`;
	$result = !$?;
    } else {
	my $in;
	my @cmd = split /\s+/, $cmd;
	if ($timeout) {
	    $result = IPC::Run::run(\@cmd, \$in, \$out, \$err,
				    IPC::Run::timeout($timeout));
	} else {
	    $result = IPC::Run::run(\@cmd, \$in, \$out, \$err);
	}
    }
    return ($result, $out, $err);
}

my %TODO = map{$_=>1}
  qw(Attribute::Handlers B::Hooks::EndOfScope YAML MooseX::Types);
if ($] >= 5.010) {
  $TODO{$_} = 1
    for qw( File::Temp ExtUtils::Install Test::NoWarnings);
  $TODO{$_} = 0
    for qw( B::Hooks::EndOfScope YAML MooseX::Types );
  if ($Config{useithreads}) {
    $TODO{$_} = 1
      for qw(
             Test::Harness Pod::Simple IO Getopt::Long Pod::Parser
             ExtUtils::MakeMaker Pod::Text File::Temp ExtUtils::Install
             ExtUtils::CBuilder Module::Build Digest::MD5 URI HTML::Parser LWP
             Storable Test::Tester Attribute::Handlers Test::NoWarnings
             Filter::Util::Call Try::Tiny Class::MOP Moose Test::Deep Carp::Clan
             Module::Pluggable DBI FCGI Tree::DAG_Node Path::Class Test::Warn
             Encode CGI B::Hooks::EndOfScope Test::Pod Digest::SHA1
             namespace::clean XML::SAX DateTime::Locale DateTime AppConfig
             Template::Stash
            );
  }
  if ($] >= 5.011004) {
    $TODO{'Test::NoWarnings'} = 0;
  }
}

my $log = 1;
my @modules;
{
  local $/;
  my $test = (@ARGV and $ARGV[0]) ? $ARGV[0] : "t/top100";
  if (-e $test) {
    open F, "<", $test or die "$test not found";
    my $s = <F>;
    close F;
    @modules = grep {!/^#/} split /\n/, $s;
    unless (-d ".svn") {  # non-author: just pick 10 randomly
      my @temp;
      for (0..9) {
        push @temp, ($modules[rand(scalar @modules)]);
      }
      @modules = @temp;
      undef $log;
    }
  }
  else {
    undef $log;
    @modules = ($test);
  }
}
my @opts = ("");				  # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV;  # all 3 compilers
my $perlversion;
# $log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

printf "1..%d\n", scalar @modules * scalar @opts;
print "# basic perlcc check looks good - perlcc could link successfully.\n";

if ($log) {
  my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
  $perlversion = sprintf("%1.6f%s%s",
			 $],
			 ($DEBUGGING ? 'd' : ''),
			 ($Config{useithreads} ? '' : '-nt'));
  $log = "log.modules-$perlversion";
  if (-e $log) {
    use File::Copy;
    copy $log, "$log.bak";
  }
  open ERR, ">", "$log.err";
  open LOG, ">", $log or die "Cannot write to $log";
  eval { require B::C; };
  print LOG "# B::C::VERSION = ",$B::C::VERSION,"\n";
  print LOG "# perlversion = $perlversion\n";
  print LOG "# platform = $^O\n";
  print LOG "# ithreads = ",$Config{useithreads}?"yes":"no","\n";
  close LOG;
  open LOG, ">>", $log;
}

my $i = 1;
my ($skip, $pass, $fail);
for my $m (@modules) {
  local($\, $,);   # guard against -l and other things that screw with
                   # print
  unless (eval "require $m;") {
    for (1 .. @opts) {
      print   "ok $i  #skip             no $m\n"; $i++;
      print LOG "skip $m\n" if $log;
      $skip++;
    }
  }
  else {
    open F, ">", "mod.pl";
    print F "use $m;\nprint \"ok\";";
    close F;
    for my $opt (@opts) {
      print ERR "$m - $opt\n" if $log;
      # my $stderr = $^O eq 'MSWin32' ? "" : ($log ? "2>>$log.err" : "2>/dev/null";
      my ($result, $out, $err) = run_cmd("$^X -Mblib blib/script/perlcc $opt -r mod.pl");
      if ($result and $out eq "ok") {
	print   "ok $i      #",$TODO{$m}?"TODO":""," perlcc -r $opt use $m\n";
	if ($log) {
	  print LOG "pass $m",$opt ? " - $opt\n" : "\n";
	}
	$pass++;
      }
      else {
	print ERR "$err\n" if $log and $have_IPC_Run;
	$fail++;
	if ($opt or $TODO{$m}) {
	  print "ok $i  #TODO perlcc -r $opt  no $m\n";
	  print LOG "fail $m",$opt?" - $opt":"","\n" if $log;
	}
        else {
	  print "not ok $i  # perlcc -r $opt  no $m\n";
	  print "# ", join "\n#", split/\n/, $err if $err;
	  print "\n" if $err;
	  print LOG "fail $m\n" if $log;
	}
      }
      $i++;
    }
    unlink ("mod.pl", "a");
  }
}

sub percent {
  sprintf("%0.1f%%", $_[0]*100/$_[1]);
}
my $count = scalar @modules - $skip;
my $pc = percent($pass,$count);
my $fc = percent($fail,$count);
my $sc = percent($skip,scalar @modules);
my $footer =
  "\n# $count modules tested with B-C-".$B::C::VERSION." - perl-$perlversion\n"
  .sprintf("# pass %3d / %3d (%s)\n", $pass, $count, $pc)
  .sprintf("# fail %3d / %3d (%s)\n", $fail, $count, $fc )
  .sprintf("# skip %3d / %3d (%s not installed)\n", $skip, scalar @modules, $sc);
print $footer;
print LOG $footer;

END {
  unlink ("mod.pl", "a", "a.out");
  close LOG if $log;
  close ERR if $log;
}
