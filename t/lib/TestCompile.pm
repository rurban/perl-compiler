package TestCompile;

use strict;
use warnings;

use Exporter ();

use Test::More;
use Test::Builder ();
use TAP::Harness  ();
use IO::Scalar;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/compile_script/;

use v5.14;

my %SIGNALS = ( qw( 11 SEGV 6 SIGABRT 1 SIGHUP 13 SIGPIPE), 0 => '' );

sub compile_script {
    my ( $file_to_test, $errors, $opts ) = @_;

    my $PERL = $^X;
    my $blib = ( grep { $_ =~ m{/blib/} } @INC ) ? '-Mblib' : '';

    # Generate the C code at $optimization level
    my $extra        = $opts->{extra}        // '';
    my $optimization = $opts->{optimization} // '';
    my $c_file       = $opts->{c_file}       // die;
    my $bin_file     = $opts->{bin_file}     // die,

      my $cmd = "$PERL $blib $extra -MO=-qq,C,$optimization,-o$c_file $file_to_test 2>&1";

    diag $cmd if $ENV{VERBOSE};
    my $BC_output = `$cmd`;
    note $BC_output if ($BC_output);

    unless ( $errors->check_todo( -e $c_file && !-z _, "$c_file is generated ($optimization)", 'BC' ) ) {
        unlink $c_file unless $ENV{BC_DEVELOPING};
        return 0, "Can't test further due to failure to create a c file.";
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
        return 0, "Can't test further due to failure to create a binary file.";
    }

    return 1 if $opts->{no_harness};    # bypass harness for testc for now

    # Parse through TAP::Harness [need to go to its own function]
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
    $parser->{out} = $out;
    $errors->check_todo( $parser, "Output parsed by TAP::Harness" ) or do {
        return 0, "Cannot parse TAP output";
    };

    my $signal = $res->{wait} % 256;
    my $sig_name = $SIGNALS{$signal} || '';

    unless ( $errors->check_todo( $signal == 0, "Exit signal is $signal $sig_name", 'SIG' ) ) {
        note $out if $out;
        return 0, "Test failures irrelevant if exits premature with $sig_name";
    }

    unless ( $errors->check_todo( $parser->{is_good_plan}, "Plan was valid", 'PLAN' ) ) {
        note $out if $out;
        return 0, "TAP parse is unpredictable when plan is invalid";
    }

    return $parser;
}

1;
