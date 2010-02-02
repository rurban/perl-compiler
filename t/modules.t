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
  unless (-d '.svn') {
    print "1..0 #skip author test (16min)\n";
    exit;
  }
}

my %TODO = map{$_=>1}
  qw(Attribute::Handlers B::Hooks::EndOfScope YAML MooseX::Types);
if ($] >= 5.010) {
  $TODO{$_} = 1
    for qw( File::Temp ExtUtils::Install Test::NoWarnings);
  $TODO{$_} = 0
    for qw( B::Hooks::EndOfScope YAML MooseX::Types );
}
if ($] >= 5.011004) {
  $TODO{Test::NoWarnings} = 0;
}

use Config;
my @modules;
{
  local $/;
  my $test = (@ARGV and -e $ARGV[0]) ? $ARGV[0] : "t/top100";
  open F, "<", $test or die "$test not found";
  my $s = <F>;
  close F;
  @modules = grep {!/^#/} split /\n/, $s;
}
my @opts = ("");				  # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV;  # all 3 compilers
my $log = 1;
my $perlversion;
# $log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

printf "1..%d\n", scalar @modules * scalar @opts;

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
  open LOG, ">", "$log.err";
  close LOG;
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
  } else {
    open F, ">", "mod.pl";
    print F "use $m;\nprint \"ok\";";
    close F;
    for my $opt (@opts) {
      `echo "$m - $opt" >>$log.err` if $^O ne 'MSWin32';
      my $stderr = $^O eq 'MSWin32' ? "" : ($log ? "2>>$log.err" : "2>/dev/null");
      if (`$^X -Mblib blib/script/perlcc $opt -r mod.pl $stderr` eq "ok") {
	print   "ok $i      #",$TODO{$m}?"TODO":""," perlcc -r $opt use $m\n";
	if ($log) {
	  print LOG "pass $m",$opt ? " - $opt\n" : "\n";
	}
	$pass++;
      }
      else {
	$fail++;
	if ($opt or $TODO{$m}) {
	  print "ok $i  #TODO perlcc -r $opt  no $m\n";
	  print LOG "fail $m - $opt\n" if $log;
	} else {
	  print "not ok $i  # perlcc -r $opt  no $m\n";
	  print LOG "fail $m\n" if $log;
	}
      }
      $i++;
    }
    unlink "mod.pl";
  }
}

sub percent {
  sprintf("%0.1f%%", $_[0]*100/$_[1]);
}
my $count = scalar @modules - $skip;
my $pc = percent($pass,$count);
my $fc = percent($fail,$count);
my $sc = percent($skip,$count);
my $footer =
  "\n# $count modules tested with B-C-".$B::C::VERSION." - perl-$perlversion\n"
  .sprintf("# pass %3d / %3d (%s)\n", $pass, $count, $pc)
  .sprintf("# fail %3d / %3d (%s)\n", $fail, $count, $fc )
  .sprintf("# skip %3d / %3d (%s not installed)\n", $skip, scalar @modules, $sc);
print $footer;
print LOG $footer;

END {
  unlink ("mod.pl", "a");
  close LOG if $log;
}
