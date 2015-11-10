#!perl

use strict;
use warnings;
use open ':std', ':encoding(utf8)';

use IO::Scalar;
use Cwd;
use File::Basename;
use Test::More;

BEGIN {
    use FindBin;
    unshift @INC, $FindBin::Bin . "/../../../lib";
}

die "Please use perl 5.22" unless $^V =~ qr{^v5.22};

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

chdir "$FindBin::Bin/.." or die $!;

my $current_t_file   = $file_to_test;
my $todo_description = '';

my $type = $errors->get_current_error_type();
$todo_description = $errors->{todo_description} if $type;

# Skip this test all together if $type is SKIP or COMPAT
if ( $type eq 'COMPAT' || $type eq 'SKIP' ) {
    plan skip_all => $todo_description;
}

my $working_dir = $FindBin::Bin;

plan tests => 1 + 5 * scalar @optimizations;

# need to run CORE test suite in C-COMPILED
$file_to_test =~ m/0*(\d+?)\.t/ or die("$file_to_test cannot be recognized as a testc test!");
my $testc_test = $1;

my $test_code = `$working_dir/../../../testc.sh -X $testc_test 2>/dev/null`;

### RESULT:133
$test_code =~ s/### RESULT:(.+)$//ms;
my $want = $1;

( my $perl_file = $file_to_test ) =~ s/\.t$/.pl/;
( my $c_file    = $file_to_test ) =~ s/\.t$/.c/;
( my $bin_file  = $file_to_test ) =~ s/\.t$/.bin/;

eval q{ END { unlink $bin_file, $c_file, $perl_file unless $ENV{BC_DEVELOPING} }};
unlink $bin_file, $c_file, $perl_file;

open( my $fh, '>', $perl_file ) or die "Can't write $perl_file";
print {$fh} $test_code;
close $fh;

my $PERL = $^X;
my $blib = ( grep { $_ =~ m{/blib/} } @INC ) ? '-Mblib' : '';

SKIP: {

    my $check = qx{$PERL -I$FindBin::Bin/../../.. -c '$perl_file' 2>&1};
    unless ( $errors->check_todo( $check =~ qr/syntax OK/, "$PERL -c $perl_file", "CHECK" ) ) {
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
            $errors->{to_skip} = 5;

            # Generate the C code at $optimization level
            my $cmd = "$PERL $blib -I$FindBin::Bin/../../.. -MO=-qq,C,$optimization,-o$c_file $perl_file 2>&1";

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
            my $compile_output = qx{$cmd};
            note $compile_output if ($compile_output);

            # Validate compiles
            unless ( $errors->check_todo( -x $bin_file, "$bin_file is compiled and ready to run.", 'GCC' ) ) {
                unlink $c_file, $bin_file unless $ENV{BC_DEVELOPING};
                skip( "Can't test further due to failure to create a binary file.", $errors->{to_skip} );
            }

            # Parse through TAP::Harness
            my $out     = qx{$bin_file 2>&1};
            my $str_out = $out;
            $str_out =~ s{\n}{\\n}g;
            $str_out =~ s{[^A-Za-z0-9\s\\:=,;\.\(\)]}{ }g;
            $str_out =~ s{\s+}{ }g;
            if ( length($str_out) > 30 ) {
                $str_out = substr( $str_out, 0, 30 );
                $str_out =~ s{[^\s]+$}{};
                $str_out .= '...';
            }

            # limitation... for now
            chomp $want;
            chomp $out;

            #chomp $out if $want eq 'ok';
            unless ( $errors->check_todo( $out eq $want, qq{Output is: "$str_out"}, 'TESTS' ) ) {
                skip( "TESTS failure", $errors->{to_skip} );
            }

            my $signal    = $? % 256;
            my $exit_code = $? >> 8;
            my $sig_name  = $SIGNALS{$signal} || '';

            unless ( $errors->check_todo( $signal == 0, "Exit signal is $signal $sig_name", 'SIG' ) ) {
                note $out if ($out);
                skip( "Test failures irrelevant if exits premature with $sig_name", $errors->{to_skip} );
            }

            $errors->check_todo( $exit_code == 0, "Exit code is 0", 'EXIT' );
        }
    }

}
exit;
