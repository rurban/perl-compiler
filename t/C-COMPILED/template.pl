#!perl

use strict;
use warnings;

use TAP::Harness ();
use IO::Scalar;
use Cwd;
use File::Basename;

use Test::More;

if ( $0 =~ m{/template\.pl$} ) {
    plan q{skip_all} => "This program is not designed to be called directly";
    exit;
}

my @optimizations = $ENV{'BC_TEST_OPTIMIZATIONS'} || '-O3,-fno-fold';
$optimizations[0] .= ',-v'     if ( $ENV{VERBOSE} );
$optimizations[0] .= ',-Dwalk' if ( $ENV{BC_WALK} );

# Setup file_to_test to be the file we actually want to test.
my ( $file_to_test, $path ) = fileparse($0);

# The file that tracks acceptable failures in the compiled unit tests.
my $known_errors_file = "$path/known_errors.txt";

# The relative path our symlinks will point to.
my $base_dir = dirname($path);

# convert double dashes into a directory slash.
$file_to_test =~ s{--}{/}g;

my ( $file_in_error, $type, $description ) = ('');
open( my $errors_fh, '<', $known_errors_file ) or die;
while ( my $line = <$errors_fh> ) {
    chomp $line;
    ( $file_in_error, $type, $description ) = split( ' ', $line, 3 );
    last if ( $file_in_error && $file_in_error eq $file_to_test );
}

my $failure_profiles = {
    'BC'     => "B::C Fails to generate c code",
    'GCC'    => "gcc cannot compile generated c code",
    'SIG'    => "Tests don't pass at the moment - Compiled binary exits with signal",
    'PLAN'   => "Tests don't pass at the moment - Crashes before completion",
    'TESTS'  => "Tests don't pass at the moment",
    'SEQ'    => "Tests out of sequence",
    'TODO'   => "TODO test unexpectedly passing",
    'COMPAT' => "Test isn't useful for B::C",
    'SKIP'   => "TODO test is skipped (broken?)",
};

my $todo_description;
if ( $file_in_error eq $file_to_test ) {

    # The line must have had a valid description and type.
    $type        or die("$file_to_test found in $known_errors_file but no 'type' was found on the line.");
    $description or die("$file_to_test found in $known_errors_file but no 'description' was found on the line.");

    # Must be a known failure profile
    $failure_profiles->{$type} or die("Failure profile '$type' is unknown for test $file_to_test");

    $todo_description = $failure_profiles->{$type} . " - ". $description;
}
else {
    $todo_description = $description = $type = '';
}

# Skip this test all together if $type is SKIP or COMPAT
if ( $type eq 'COMPAT' || $type eq 'SKIP' ) {
    plan skip_all => $todo_description;
}

$file_to_test = "t/$file_to_test";    # Append t/ to make the relative path correct relative to pwd.

plan tests => 3 + 10 * scalar @optimizations;

ok( !-z $file_to_test, "$file_to_test exists" );

open( my $fh, '<', $file_to_test ) or die("Can't open $file_to_test");
my $taint = <$fh>;
close $fh;
$taint = ( ( $taint =~ m/\s\-T/ ) ? '-T' : '' );
pass( $taint ? "Taint mode!" : "Not in taint mode" );

( my $c_file   = $file_to_test ) =~ s/\.t$/.c/;
( my $bin_file = $file_to_test ) =~ s/\.t$/.bin/;
unlink $bin_file, $c_file;

my $PERL = $^X;

my $check = `$PERL -c $taint '$file_to_test' 2>&1`;
like( $check, qr/syntax OK/, "$PERL -c $taint $file_to_test" );

$ENV{HARNESS_NOTTY} = 1;

my %SIGNALS = qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE);
$SIGNALS{0} = '';

foreach my $optimization (@optimizations) {
  TODO: SKIP: {
        local $TODO = $todo_description if ( $type eq 'BC' );

        # Generate the C code at $optimization level
        my $cmd = "$PERL $taint -MO=-qq,C,$optimization,-o$c_file $file_to_test 2>&1";

        diag $cmd if $ENV{VERBOSE};
        my $BC_output = `$cmd`;
        note $BC_output if ($BC_output);
        ok( -e $c_file && !-z _, "$c_file is generated ($optimization)" );

        if ( -z $c_file ) {
            unlink $c_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a c file.", 9 );
        }

        # gcc the c code.
        local $TODO = $todo_description if ( $type eq 'GCC' );

        $cmd = "$PERL script/cc_harness -q $c_file -o $bin_file 2>&1";
        diag $cmd if $ENV{VERBOSE};
        my $compile_output = `$cmd`;
        note $compile_output if ($compile_output);

        # Validate compiles
        ok( -x $bin_file, "$bin_file is compiled and ready to run." );

        if ( !-x $bin_file ) {
            unlink $c_file, $bin_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a binary file.", 8 );
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
        ok( $parser, "Output parsed by TAP::Harness" );

        my $signal = $res->{wait} % 256;
        if ( $type eq 'SIG' ) {
            local $TODO = $todo_description;
            my $sig_name = $SIGNALS{$signal};
            ok( $signal == 0, "Exit signal is $signal ($sig_name)" );
            note $out if ($out);
            skip( "Test failures irrelevant if exits premature with $sig_name", 6 );
        }
        else {
            ok( $signal == 0, "Exit signal is $signal" );
        }

        if ( $type eq 'PLAN' ) {
            local $TODO = $todo_description;
            ok( $parser->{is_good_plan}, "Plan was valid" );
            note $out;
            skip( "TAP parse is unpredictable when plan is invalid", 5 );
        }
        else {
            ok( $parser->{is_good_plan}, "Plan was valid" );
        }

        ok( $parser->{exit} == 0, "Exit code is $parser->{exit}" );

        local $TODO = $todo_description if ( $type eq 'TESTS' );
        ok( !scalar @{ $parser->{failed} }, "Test results:" );
        print "    $_\n" foreach ( split( "\n", $out ) );

        ok( !scalar @{ $parser->{failed} }, "No test failures" )
          or note( "Failed tests: " . join( ", ", @{ $parser->{failed} } ) );

        skip( "Don't care about test sequence if tests are failing", 2 ) if ( $type =~ m/^(PLAN|TESTS)$/ );

        local $TODO = $todo_description if ( $type eq 'SEQ' );
        ok( !scalar @{ $parser->{parse_errors} }, "Tests are in sequence" )
          or note explain $parser->{parse_errors};

        local $TODO = $todo_description if ( $type eq 'TODO' );
        ok( !scalar @{ $parser->{todo_passed} }, "No TODO tests passed" )
          or note( "TODO Passed: " . join( ", ", @{ $parser->{todo_passed} } ) );
    }
}
unlink $bin_file, $c_file unless $ENV{BC_DEVELOPING};
