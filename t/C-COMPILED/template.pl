#!perl

use strict;
use warnings;

use TAP::Harness ();
use IO::Scalar;

use Test::More;

#my @optimizations = ( '-O2,-fno-fold', '-O1' );
my @optimizations = $ENV{BC_OPT} ? split(/\s+/,$ENV{BC_OPT}) : ('-O0','-O3');
my $todo       = '';

# Setup file_to_test to be the file we actually want to test.
my $file_to_test = $0;
if ( $file_to_test =~ s{==(.*)\.t$}{.t} ) {
    my $options = $1;
    $todo = "B::C Fails to generate c code. Issues: $1"         if ( $options =~ /BC-([\d-]+)/ );
    $todo = "gcc cannot compile generated c code. Issues: $1"   if ( $options =~ /GCC-([\d-]+)/ );
    $todo = "Compiled binary exits with signal. Issues: $1"     if ( $options =~ /SIG-([\d-]+)/ );
    $todo = "Test crashes before completion. Issues: $1"        if ( $options =~ /BADPLAN-([\d-]+)/ );
    $todo = "Fails tests when compiled with perlcc. Issues: $1" if ( $options =~ /BADTEST-([\d-]+)/ );
    $todo = "Tests out of sequence. Issues: $1"                 if ( $options =~ /SEQ-([\d-]+)/ );
    $todo = "TODO test unexpectedly passing. Issues: $1"        if ( $options =~ /TODO-([\d-]+)/ );
}

$file_to_test =~ s{--}{/}g;
$file_to_test =~ s{C-COMPILED/}{};    # Strip the BINARY dir off to look for this test elsewhere.

if ( $] < 5.014 && $file_to_test =~ m{^t/CORE/} ) {
    plan skip_all => "Perl CORE tests only supported since 5.14 right now.";
}
else {
    plan tests => 3 + 10 * scalar @optimizations;
}

ok( !-z $file_to_test, "$file_to_test exists" );

open( my $fh, '<', $file_to_test ) or die("Can't open $file_to_test");
my $taint = <$fh>;
close $fh;
$taint = ( ( $taint =~ m/\s\-T/ ) ? '-T' : '' );
pass( $taint ? "Taint mode!" : "Not in taint mode" );

( my $c_file   = $file_to_test ) =~ s/\.t$/.c/;
( my $bin_file = $file_to_test ) =~ s/\.t$/.bin/;
unlink $bin_file, $c_file;

my $PERL = $^X =~ m/\s/ ? qq{"$^X"} : $^X;

my $check = `$PERL -c $taint '$file_to_test' 2>&1`;
like( $check, qr/syntax OK/, "$PERL -c $taint $file_to_test" );

$ENV{HARNESS_NOTTY} = 1;

my %SIGNALS = qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE);
$SIGNALS{0} = '';

foreach my $optimization (@optimizations) {
TODO: {
  SKIP: {
        local $TODO = $todo if ( $todo =~ /B::C Fails to generate c code/ );
        local $ENV{BC_OPT} = $optimization;

        my $b = $optimization; # protect against parallel test name clashes
        #$b =~ s/-(D.*|f.*|v),//g;
        #$b =~ s/-/_/g;
        #$b =~ s/[, ]//g;
        #$b =~ s/_O0$//;
        #$b = lc($b);
        $b = ''; # need to check $0 diagnostics
        ( $c_file   = $file_to_test ) =~ s/\.t$/$b.c/;
        $b = '.bin'; # need to check $0 diagnostics
        ( $bin_file = $file_to_test ) =~ s/\.t$/$b/;
        unlink $bin_file, $c_file;

        # Generate the C code at $optimization level
        my $cmd = "$PERL $taint -Iblib/arch -Iblib/lib -MO=-qq,C,$optimization,-o$c_file $file_to_test 2>&1";

        diag $cmd if $ENV{TEST_VERBOSE};
        my $BC_output = `$cmd`;
        note $BC_output if ($BC_output);
        ok( !-z $c_file, "$c_file is generated ($optimization)" );

        if ( -z $c_file ) {
            unlink $c_file;
            skip( "Can't test further due to failure to create a c file.", 9 );
        }

        # gcc the c code.
        local $TODO = $todo if ( $todo =~ /gcc cannot compile generated c code/ );

        $cmd = "$PERL -Iblib/arch -Iblib/lib script/cc_harness -q $c_file -o $bin_file 2>&1";
        diag $cmd if $ENV{TEST_VERBOSE};
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
        if ( $todo =~ /Compiled binary exits with signal/ ) {
            local $TODO = "Tests don't pass at the moment - $todo";
            my $sig_name = $SIGNALS{$signal};
            ok( $signal == 0, "Exit signal is $signal ($sig_name)" );
            note $out if ($out);
            skip( "Test failures irrelevant if exits premature with $sig_name", 6 );
        }
        else {
            ok( $signal == 0, "Exit signal is $signal" );
        }

        if ( $todo =~ m/Test crashes before completion/ ) {
            local $TODO = $todo;
            ok( $parser->{is_good_plan}, "Plan was valid" );
            note $out;
            skip( "TAP parse is unpredictable when plan is invalid", 5 );
        }
        else {
            ok( $parser->{is_good_plan}, "Plan was valid" );
        }

        ok( $parser->{exit} == 0, "Exit code is $parser->{exit}" );

        local $TODO = "Tests don't pass at the moment - $todo"
          if ( $todo =~ /Fails tests when compiled with perlcc/ );
        ok( !scalar @{ $parser->{failed} }, "Test results:" );
        print "    $_\n" foreach ( split( "\n", $out ) );

        if (!ok( !scalar @{ $parser->{failed} }, "No test failures $optimization" )) {
          note( "Failed $optimization tests: " . join( ", ", @{ $parser->{failed} } ) );
          $ENV{BC_DEVELOPING} = 1; # keep temp files
        }

        skip( "Don't care about test sequence if tests are failing", 2 )
          if ( $todo =~ /Fails tests when compiled with perlcc/ );

        local $TODO = $todo if ( $todo =~ m/Tests out of sequence/ );
        if (!ok( !scalar @{ $parser->{parse_errors} }, "Tests are in sequence" )) {
          note explain $parser->{parse_errors};
          $ENV{BC_DEVELOPING} = 1; # keep temp files
        }

        local $TODO = "tests unexpectedly passing" if scalar @{ $parser->{todo_passed} };
        if (!ok( !scalar @{ $parser->{todo_passed} }, "No TODO tests passed $optimization" )) {
          note( "TODO Passed: " . join( ", ", @{ $parser->{todo_passed} } ) );
          $ENV{BC_DEVELOPING} = 1; # keep temp files
        }
        $TODO = '';
    }
  }
  unlink $bin_file, $c_file unless $ENV{BC_DEVELOPING};
}
