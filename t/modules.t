# -*- cperl -*-
# t/modules.t - check if some common CPAN modules exist and
# can be compiled successfully. Only B::C is fatal,
# CC and Bytecode optional. Use -all for all three, and
# -log for the reports.
#
# The list in t/modules comes from two bigger projects.
# Recommended general lists are Task::Kensho and http://ali.as/top100/
#
# Reports:
# for p in 5.6.2d-nt 5.8.9 5.10.1 5.11.3d-nt; do make -S clean; perl$p Makefile.PL; make; perl$p -Mblib t/modules.t -log; done

BEGIN {
  unless (-d '.svn') {
    print "1..0 #skip author test\n";
    exit;
  }
}

my %TODO = map{$_=>1}
  qw(
     Attribute::Handlers B::Hooks::EndOfScope YAML MooseX::Types
    );

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
my @opts = (""); #, "-O", "-B"); # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV; # all 3 compilers
my $log = 1;
# $log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

printf "1..%d\n", scalar @modules * scalar @opts;

if ($log) {
  my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
  my $perlversion = sprintf("%1.6f%s%s",
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
	print   "ok $i  #     perlcc -r $opt use $m\n";
	if ($log) {
	  print LOG "pass $m",$opt ? " - $opt\n" : "\n";
	}
	$pass++;
      }
      else {
	if ($opt or $TODO{$m}) {
	  print "ok $i  #TODO perlcc -r $opt  no $m\n";
	  print LOG "fail $m - $opt\n" if $log;
	} else {
	  print "nok $i #     perlcc -r $opt  no $m\n";
	  print LOG "fail $m\n" if $log;
	  $fail++;
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
  "\n# $count modules tested with B-C-".$B::C::VERSION."\n"
  ."# pass $pass / $count ($pc)\n"
  ."# fail $fail / $count ($fc)\n"
  ."# skip $skip / ".scalar @modules." ($sc not installed)\n";
print $footer;
print LOG $footer;

END {
  unlink ("mod.pl", "a");
  close LOG if $log;
}
