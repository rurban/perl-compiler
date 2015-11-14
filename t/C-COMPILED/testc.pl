#!perl

use strict;
use warnings;
use open ':std', ':encoding(utf8)';

use IO::Scalar;
use Cwd;
use File::Basename;
use Test::More;

if ( $0 =~ m{/testc\.pl$} ) {
  plan q{skip_all} => "This program is not designed to be called directly";
  exit;
}

my @optimizations = $ENV{'BC_TEST_OPTIMIZATIONS'} || ('-O3', '-O0');
$optimizations[0] .= ',-v'        if $ENV{VERBOSE};
$optimizations[0] .= ',-fwalkall' if $ENV{BC_WALK};

# Setup file_to_test to be the file we actually want to test.
my ( $file_to_test, $path ) = fileparse($0);
my ( $before, $after ) = split( 'C-COMPILED/', $path );
my $short_path = $path;
$short_path =~ s{^.*C-COMPILED/+}{};
$file_to_test = $short_path . $file_to_test;

# The relative path our symlinks will point to.
my $base_dir = dirname($path);

my $current_t_file   = $file_to_test;
my $to_skip = 0;

plan tests => scalar @optimizations;

# need to run CORE test suite in C-COMPILED
$file_to_test =~ m/0*(\d+?)\.t/ or
  die("$file_to_test cannot be recognized as a testc test!");
my $testc_test = $1;
my $test_code = `t/testc.sh -X $testc_test 2>/dev/null`;

### RESULT:133
$test_code =~ s/### RESULT:(.+)$//ms;
my $want = $1;

( my $perl_file = $file_to_test ) =~ s/xtestc-(.*)\.t$/ccode-xt$1.pl/;
( my $c_file    = $file_to_test ) =~ s/xtestc-(.*)\.t$/ccode-xt$1.c/;
( my $bin_file  = $file_to_test ) =~ s/xtestc-(.*)\.t$/ccode-xt$1.bin/;

END { unlink $bin_file, $c_file, $perl_file unless $ENV{BC_DEVEL}; }

open( my $fh, '>', $perl_file ) or die "Can't write $perl_file";
print {$fh} $test_code;
close $fh;

my $PERL = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $blib = ( grep { m{blib/} } @INC ) ? '-Iblib/arch -Iblib/lib' : '';

SKIP: {

  my $check = qx{$PERL -c '$perl_file' 2>&1};
  unless ( $check =~ qr/syntax OK/ ) {
    skip( "Cannot compile with perl -c", 5 );
    exit;
  }

  $ENV{HARNESS_NOTTY} = 1;

  my %SIGNALS = qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE);
  $SIGNALS{0} = '';

  foreach my $optimization (@optimizations) {
  TODO: SKIP: {
    local $TODO;

    # lazy way to count and keep the skip counter up to date
    $to_skip = 5;

    # Generate the C code at $optimization level
    my $cmd = "$PERL $blib -MO=-qq,C,$optimization,-o$c_file $perl_file 2>&1";

    diag $cmd if $ENV{VERBOSE};
    my $BC_output = `$cmd`;
    note $BC_output if ($BC_output);
    unless ( -e $c_file && !-z _) {
      unlink $c_file unless $ENV{BC_DEVEL};
      skip( "Can't test further due to failure to create a c file.", $to_skip );
    }

    # gcc the c code.
    my $harness_opts = '';
    $harness_opts = '-Wall' if $ENV{VERBOSE} && $ENV{WARNINGS};
    $harness_opts .= $ENV{VERBOSE} ? '' : ' -q';
    $cmd = "$PERL $blib script/cc_harness $harness_opts $c_file -o $bin_file 2>&1";
    diag $cmd if $ENV{VERBOSE};
    my $compile_output = qx{$cmd};
    note $compile_output if ($compile_output);

    # Validate compiles
    unless ( -x $bin_file ) {
      unlink $c_file, $bin_file unless $ENV{BC_DEVEL};
      skip( "Can't test further due to failure to create a binary file.", 
            $to_skip );
    }

    # Parse through TAP::Harness
    my $out     = qx{./$bin_file 2>&1} || "";
    my $signal    = $? % 256;
    my $exit_code = $? >> 8;
    chomp $want;
    chomp $out;

    if (!is($out, $want, $file_to_test)) {
      $out = `$PERL $perl_file 2>&1`;
      chomp $out;
      diag "pure perl fails also" if $out ne $want;
    }

    my $sig_name  = $SIGNALS{$signal} || '';
    unless ( $signal == 0 ) {
      note $out if ($out);
      skip( "Test failures irrelevant if exits premature with $sig_name", 
            $to_skip );
    }}
  }
}
exit;
