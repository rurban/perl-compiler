#!perl

use strict;
use warnings;

use TAP::Harness ();
use IO::Scalar;
use Cwd;
use File::Basename;
use Test::More;

BEGIN {
    use FindBin;
    unshift @INC, $FindBin::Bin . "/../../../lib";
}

# Used by runperl to find perlcc
$ENV{'PROVE_BASEDIR'} = getcwd;

use KnownErrors qw/check_todo/;

if ( $0 =~ m{/template\.pl$} ) {
    plan q{skip_all} => "This program is not designed to be called directly";
    exit;
}

my @optimizations = $ENV{'BC_TEST_OPTIMIZATIONS'} || '-O3,-fno-fold';
$optimizations[0] .= ',-v'     if ( $ENV{VERBOSE} );
$optimizations[0] .= ',-Dwalk' if ( $ENV{BC_WALK} );

# Setup file_to_test to be the file we actually want to test.
my ( $file_to_test, $path ) = fileparse($0);
my ( $before, $after ) = split( 'C-COMPILED/', $path );
my $short_path = $path;
$short_path =~ s{^.*C-COMPILED/+}{};
$file_to_test = $short_path . $file_to_test;

# The file that tracks acceptable failures in the compiled unit tests.
my $known_errors_file = "known_errors.txt";

my $errors = KnownErrors->new( file_to_test => $file_to_test );

# The relative path our symlinks will point to.
my $base_dir = dirname($path);

chdir "$FindBin::Bin/../" or die $!;

my $current_t_file   = $file_to_test;
my $todo_description = '';

my $type = $errors->get_current_error_type();
$todo_description = $errors->{todo_description} if $type;

# Skip this test all together if $type is SKIP or COMPAT
if ( $type eq 'COMPAT' || $type eq 'SKIP' ) {
    plan skip_all => $todo_description;
}

# need to run CORE test suite in t
chdir "$FindBin::Bin/../../t" or die "Cannot chdir to t directory: $!";

plan tests => 3 + 9 * scalar @optimizations;

ok( !-z $file_to_test, "$file_to_test exists" );
open( my $fh, '<', $file_to_test ) or die("Can't open $file_to_test");
my $taint = <$fh>;
close $fh;
$taint = ( ( $taint =~ m/\s\-w?T/ ) ? '-T' : '' );
pass( $taint ? "Taint mode!" : "Not in taint mode" );

( my $c_file   = $file_to_test ) =~ s/\.t$/.c/;
( my $bin_file = $file_to_test ) =~ s/\.t$/.bin/;
unlink $bin_file, $c_file;

my $PERL = $^X;
my $blib = ( grep { $_ =~ m{/blib/} } @INC ) ? '-Mblib' : '';

my $check = `$PERL -c $taint '$file_to_test' 2>&1`;
like( $check, qr/syntax OK/, "$PERL -c $taint $file_to_test" );

$ENV{HARNESS_NOTTY} = 1;

my %SIGNALS = qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE);
$SIGNALS{0} = '';

foreach my $optimization (@optimizations) {
  TODO: SKIP: {
        local $TODO;

        $errors->{to_skip} = 9;

        # Generate the C code at $optimization level
        my $cmd = "$PERL $blib $taint -MO=-qq,C,$optimization,-o$c_file $file_to_test 2>&1";

        diag $cmd if $ENV{VERBOSE};
        my $BC_output = `$cmd`;
        note $BC_output if ($BC_output);

        unless ( $errors->check_todo( -e $c_file && !-z _, "$c_file is generated ($optimization)", 'BC' ) ) {
            unlink $c_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a c file.", $errors->{to_skip} );
        }

        # gcc the c code.
        my $harness_opts = '';
        $harness_opts = '-Wall' if $ENV{VERBOSE} && $ENV{WARNINGS};
        $harness_opts .= $ENV{VERBOSE} ? '' : ' -q';
        $cmd = "$PERL $FindBin::Bin/../../../../script/cc_harness $harness_opts $c_file -o $bin_file 2>&1";
        diag $cmd if $ENV{VERBOSE};
        my $compile_output = `$cmd`;
        note $compile_output if ($compile_output);

        # Validate compiles
        unless ( $errors->check_todo( -x $bin_file, "$bin_file is compiled and ready to run.", 'GCC' ) ) {
            unlink $c_file, $bin_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a binary file.", $errors->{to_skip} );
        }

        # Parse through TAP::Harness
        my $out    = '';
        my $out_fh = new IO::Scalar \$out;

        my %args = (
            verbosity => 1,
            lib       => [],
            merge     => 1,
            stdout    => $out_fh,
        );
        my $harness = TAP::Harness->new( \%args );
        my $res     = $harness->runtests($bin_file);
        close $out_fh;

        my $parser = $res->{parser_for}->{$bin_file};
        $errors->check_todo( $parser, "Output parsed by TAP::Harness" ) or do {
            skip "Cannot parse TAP output", $errors->{to_skip};
        };

        my $signal = $res->{wait} % 256;
        my $sig_name = $SIGNALS{$signal} || '';

        unless ( $errors->check_todo( $signal == 0, "Exit signal is $signal $sig_name", 'SIG' ) ) {
            note $out if $out;
            skip( "Test failures irrelevant if exits premature with $sig_name", $errors->{to_skip} );
        }

        unless ( $errors->check_todo( $parser->{is_good_plan}, "Plan was valid", 'PLAN' ) ) {
            note $out if $out;
            skip( "TAP parse is unpredictable when plan is invalid", $errors->{to_skip} );
        }

        my $tests_ok = $errors->check_todo( $parser->{exit} == 0, "Exit code is $parser->{exit}", "EXIT" );
        $tests_ok = $errors->check_todo( !scalar @{ $parser->{failed} }, "Test results:", 'TESTS' ) && $tests_ok;
        print "    $_\n" foreach ( split( "\n", $out ) );

        unless ($tests_ok) {
            note( "Failed tests: " . join( ", ", @{ $parser->{failed} } ) );
            skip "tests are failing", $errors->{to_skip};
        }

        $errors->check_todo( !scalar @{ $parser->{parse_errors} }, "Tests are in sequence", 'SEQ' )
          or do {
            note explain $parser->{parse_errors};
            skip "tests are not in sequence", $errors->{to_skip};
          };

        $errors->check_todo( !scalar @{ $parser->{todo_passed} }, "No TODO tests passed", 'TODO' )
          or note( "TODO Passed: " . join( ", ", @{ $parser->{todo_passed} } ) );
    }
}
unlink $bin_file, $c_file unless $ENV{BC_DEVELOPING};

exit;
