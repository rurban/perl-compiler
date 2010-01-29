# -*- cperl -*-
# t/modules.t - check if some common CPAN modules exist and
#               can be compiled successfully. Only B::C is fatal,
#               CC and Bytecode optional.

use Config;

my @modules;
{
  local $/;
  #Bundle::DBD::mysql
  #Bundle::Interchange
  #Bundle::LWP
  open F, "<", "t/modules" or die "t/modules not found";
  my $s = <F>;
  close F;
  @modules = grep {!/^#/} split /\n/, $s;
}
my @opts = (""); #, "-O", "-B"); # only B::C
@opts = ("", "-O", "-B") if grep /-all/, @ARGV; # all 3 compilers
my $log;
$log = 1 if grep /-log/, @ARGV or $ENV{TEST_LOG};

printf "1..%d\n", scalar @modules * scalar @opts;

if ($log) {
  my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
  my $perlversion = sprintf("%1.6f%s%s",
			    $],
			    ($DEBUGGING ? 'd' : ''),
			    ($Config{useithreads} ? '' : '-nt'));
  $log = "log.modules-$perlversion";
  open LOG, ">", $log or die "Cannot write to $log";
  eval {require B::C;};
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
      print   "ok $i  #            skip no $m\n"; $i++;
      print LOG "skip $m\n" if $log;
      $skip++;
    }
  } else {
    open F, ">", "mod.pl";
    print F "use $m;\nprint \"ok\";";
    close F;
    for my $opt (@opts) {
      my $stderr = $^O eq 'MSWin32' ? "" : "2>$log.err";
      if (`$^X -Mblib blib/script/perlcc $opt -r mod.pl $stderr` eq "ok") {
	print   "ok $i  #     perlcc -r $opt use $m\n";
	if ($log) {
	  print LOG "pass $m",$opt ? " - $opt\n" : "\n";
	}
	$pass++;
      }
      else {
	if ($opt) {
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

my $count = scalar @modules - $skip;
print "\n# $count modules tested with B-C-",$B::C::VERSION,"\n";
print "# pass $pass ($pass/$count)\n";
print "# fail $fail ($fail/$count)\n";
print "# skip $skip (not installed)\n";

END {
  unlink "mod.pl";
  print LOG "\n# $count modules tested with B-C-",$B::C::VERSION,"\n";
  print LOG "# pass $pass ($pass/$count)\n";
  print LOG "# fail $fail ($fail/$count)\n";
  print LOG "# skip $skip\n";
  close LOG if $log;
}
