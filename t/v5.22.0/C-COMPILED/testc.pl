#!perl

use strict;
use warnings;

use IO::Scalar;
use Cwd;
use File::Basename;
use Fcntl qw(:flock SEEK_END);
use Test::More;
use FindBin;
use open ':std', ':encoding(utf8)';

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

# The relative path our symlinks will point to.
my $base_dir = dirname($path);

chdir "$FindBin::Bin/.." or die $!;

my ( $file_in_error, $type, $description ) = ('');
open( my $errors_fh, '<', $known_errors_file ) or die;
lock($errors_fh);
while ( my $line = <$errors_fh> ) {
    chomp $line;
    ( $file_in_error, $type, $description ) = split( ' ', $line, 3 );
    last if ( $file_in_error && $file_in_error eq $file_to_test );
}
unlock($errors_fh);
close($errors_fh);

my $current_t_file = $file_to_test;

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

    $todo_description = $failure_profiles->{$type} . " - " . $description;
}
else {
    $todo_description = $description = $type = '';
}

# Skip this test all together if $type is SKIP or COMPAT
if ( $type eq 'COMPAT' || $type eq 'SKIP' ) {
    plan skip_all => $todo_description;
}

my $first_error = 1;

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

my $check = qx{$PERL -I$FindBin::Bin/../../.. -c '$perl_file' 2>&1};
check_todo( $check =~ qr/syntax OK/, "$PERL -c $perl_file", "CHECK" );

$ENV{HARNESS_NOTTY} = 1;

my %SIGNALS = qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE);
$SIGNALS{0} = '';

foreach my $optimization (@optimizations) {
  TODO: SKIP: {
        local $TODO;

        # Generate the C code at $optimization level
        my $cmd = "$PERL $blib -I$FindBin::Bin/../../.. -MO=-qq,C,$optimization,-o$c_file $perl_file 2>&1";

        diag $cmd if $ENV{VERBOSE};
        my $BC_output = `$cmd`;
        note $BC_output if ($BC_output);
        check_todo( -e $c_file && !-z _, "$c_file is generated ($optimization)", 'BC' );

        if ( -z $c_file ) {
            unlink $c_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a c file.", 9 );
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
        check_todo( -x $bin_file, "$bin_file is compiled and ready to run.", 'GCC' );

        if ( !-x $bin_file ) {
            unlink $c_file, $bin_file unless $ENV{BC_DEVELOPING};
            skip( "Can't test further due to failure to create a binary file.", 8 );
        }

        # Parse through TAP::Harness
        my $out = `$bin_file 2>&1`;
        check_todo( $out eq $want, "Output is: $want", 'TESTS' );

        my $signal    = $? % 256;
        my $exit_code = $? >> 8;
        my $sig_name  = $SIGNALS{$signal} || '';

        check_todo( $signal == 0, "Exit signal is $signal $sig_name", 'SIG' );
        if ( $type eq 'SIG' ) {
            note $out if ($out);
            skip( "Test failures irrelevant if exits premature with $sig_name", 6 );
        }

        is( $exit_code, 0, "Exit code is 0" );
    }
}

if ( $ENV{UPDATE_ERRORS} ) {
    note "Force updating known_errors.txt";
    update_known_errors( force => 1 );
}

exit;

my $previous_todo;

sub check_todo {
    my ( $v, $msg, $want_type ) = @_;

    # is it the expected error
    my $todo = $type eq $want_type ? $todo_description : undef;
    my $known_error = $previous_todo;
    $previous_todo ||= $todo;
    $todo          ||= $previous_todo;

    if ( !$todo ) {
        if ( !$v ) {
            if ($first_error) {
                $first_error = 0;
                note "Adding $current_t_file $want_type error to known_errors.txt file";
                update_known_errors( test => $current_t_file, add => [qq{$current_t_file\t$want_type\t$msg}] );
            }
        }

        # we want the test to succeed
        return ok( $v, $msg );
    }
    else {
        #return subtest "TODO - $msg" => sub {
        if ( $v && !$known_error ) {
            fail "TODO test is now passing, auto adjust known_errors.txt file";
            $TODO = $todo;

            # removing test from file
            diag "Removing test $current_t_file from known_errors.txt";
            update_known_errors( test => $current_t_file ) if $first_error;
        }
        else {
            $TODO = $todo;
            ok($v);
        }
    }
}

sub update_known_errors {
    my %opts = @_;

    # tests can be run in parallel
    open( my $fh, '+<', qq{$FindBin::Bin/../$known_errors_file} ) or die("Can't open $known_errors_file");
    lock($fh);
    my @all_known_errors = <$fh>;
    my @new_errors       = @all_known_errors;
    @new_errors = grep { $_ !~ qr{^$opts{test}\s} } @all_known_errors if $opts{test};
    my $need_update;
    $need_update = 1 if scalar @new_errors < scalar @all_known_errors;

    if ( $opts{add} && ref $opts{add} eq 'ARRAY' ) {
        push @new_errors, @{ $opts{add} };
        $need_update = 1;
    }

    if ( $need_update || $opts{force} ) {

        # do the sort
        my @header;
        my @body;
        my $in_header = 1;
        foreach my $line (@new_errors) {
            if ( $in_header = 1 && ( $line =~ qr{^\s*#} || $line =~ qr{^\s*$} ) ) {
                push @header, $line;
            }
            else {
                $in_header = 0;
                push @body, $line;
            }
        }

        @body = sort { lc($a) cmp lc($b) } @body;

        my @body_format;
        my $max_tfile_len = 0;
        my $previous_tfile;
        foreach my $line (@body) {
            my ( $tfile, $type, $txt ) = split( /\s+/, $line, 3 );

            # remove duplicates (only the first one matters)
            next if $previous_tfile && $previous_tfile eq $tfile;
            $previous_tfile = $tfile;
            push @body_format, [ $tfile, $type, $txt ];
            my $len = length $tfile;
            $max_tfile_len = $len if $len > $max_tfile_len;
        }
        $max_tfile_len += 2;

        seek( $fh, 0, 0 );
        map { chomp($_); print {$fh} $_ . "\n" } @header, map { sprintf( "%-" . $max_tfile_len . "s%-10s%s", @$_ ) } @body_format;
        truncate( $fh, tell($fh) );
    }

    unlock($fh);
    close($fh);

    return;
}

sub lock {
    my ($fh) = @_;
    flock( $fh, LOCK_EX ) or die "Cannot lock mailbox - $!\n";

    # and, in case someone appended while we were waiting...
    seek( $fh, 0, SEEK_END ) or die "Cannot seek - $!\n";
}

sub unlock {
    my ($fh) = @_;
    flock( $fh, LOCK_UN ) or die "Cannot unlock mailbox - $!\n";
}

