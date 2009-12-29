# -*- cperl -*-
# t/testcore.t - run the core testsuite with the compilers, C, CC or ByteCode
#
# Copy your matching CORE t dirs into t/CORE.
# For now we test qw(base comp lib op run)
# Then fixup the @INC setters.
#   perl -pi -e 's/^(\s*\@INC = )/# $1/' t/CORE/*/*.t

use Cwd;
use File::Copy;

BEGIN {
  unless (-d "t/CORE") {
    print "1..0 #skip t/CORE missing\n";
    exit 0;
  }
}

sub vcmd {
  my $cmd = join "", @_;
  print "#",$cmd,"\n";
  `$cmd`;
}

my $dir = getcwd();
`ln -sf $^X t/perl`;
for my $t (@ARGV ? @ARGV : <t/CORE/*/*.t>) {

  chdir $dir;
  unlink ("a", "a.c", "t/a.c");
  # perlcc 2.06 should now work also: omit unneeded B::Stash -u<> and fixed linking
  # see t/c_argv.t
  vcmd "$^X -Mblib -MO=-qq,C,-oa.c $t";
  # core often does BEGIN { chdir "t" }
  chdir $dir;
  move ("t/a.c", "a.c") if -e "t/a.c";
  vcmd "$^X -Mblib script/cc_harness -q a.c -o a" if -e "a.c";
  `prove --exec ./a` if -e "a";

  chdir $dir;
  unlink ("aa", "aa.c", "t/aa.c");
  vcmd "$^X -Mblib -MO=-qq,CC,-oaa.c $t";
  chdir $dir;
  move ("t/aa.c", "aa.c") if -e "t/aa.c";
  vcmd "$^X -Mblib script/cc_harness -q aa.c -o aa" if -e "aa.c";
  `prove --exec ./aa` if -e "aa";

  chdir $dir;
  unlink ("b.plc", "t/b.plc", "b.result");
  vcmd "$^X -Mblib -MO=-qq,Bytecode,-ob.plc $t";
  chdir $dir;
  move ("t/b.plc", "b.plc") if -e "t/b.plc";
  vcmd "$^X -Mblib -MByteLoader b.plc > b.result" if -e "b.plc";
  `prove --exec cat b.result` if -s "b.result";

}

END {
  unlink ("a", "a.c", "t/a.c", "aa.c", "aa", "b.plc", "b.result");
}
