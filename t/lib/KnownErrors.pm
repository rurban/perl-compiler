package KnownErrors;

use strict;
use warnings;

use open ':std', ':encoding(utf8)';
use Exporter ();
use Test::More;
use Test::Builder ();
use FindBin;
use Fcntl qw(:flock SEEK_END);

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/check_todo/;

my $previous_todo;

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
    'CHECK'  => "Uncompile version passses perl -c",
    'EXIT'   => "Exit != 0",
};

sub new {
    my ( $class, %opts ) = @_;

    my $known_errors_file = "known_errors.txt";

    $opts{error_file} ||= qq{$FindBin::Bin/../$known_errors_file};
    die "file_to_test is required" unless $opts{file_to_test};

    return bless { %opts, first_error => 1, test => Test::Builder->new };
}

sub test {
    return $_[0]->{test};
}

sub get_current_error_type {
    my ($self) = @_;

    return $self->{type} || '' if exists $self->{type};

    my ( $file_in_error, $type, $description ) = ('', '');
    my $file_to_test = $self->{file_to_test} or die;

    open( my $errors_fh, '<', $self->{error_file} ) or die;
    lock($errors_fh);
    while ( my $line = <$errors_fh> ) {
        chomp $line;
        ( $file_in_error, $type, $description ) = split( ' ', $line, 3 );
        if ( $file_in_error && $file_in_error eq $file_to_test ) {
            $type                      or die("$file_to_test found in known_errors_file but no 'type' was found on the line.");
            $failure_profiles->{$type} or die("Failure profile '$type' is unknown for test $file_to_test");
            $description               or die("$file_to_test found in known_errors_file but no 'description' was found on the line.");
            $self->{description}      = $description;
            $self->{todo_description} = $failure_profiles->{$type} . " - " . $description;
            last;
        }
    }
    unlock($errors_fh);
    close($errors_fh);

    return $self->{type} = $type;
}

sub check_todo {
    my ( $self, $v, $msg, $want_type ) = @_;

    --$self->{to_skip} if exists $self->{to_skip};
    $want_type ||= '';

    my $current_t_file = $self->{file_to_test} or die;

    # is it the expected error
    my $todo = $self->get_current_error_type() eq $want_type ? $self->{todo_description} : undef;
    my $known_error = $previous_todo;
    $previous_todo ||= $todo;
    $todo          ||= $previous_todo;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( !$todo ) {
        if ( !$v ) {
            if ( $self->{first_error} ) {
                $self->{first_error} = 0;
                note "Adding $current_t_file $want_type error to known_errors.txt file";
                $self->update_known_errors( test => $current_t_file, add => [qq{$current_t_file\t$want_type\t$msg}] );
            }
        }

        # we want the test to succeed
        return ok( $v, $msg );
    }
    else {
        #return subtest "TODO - $msg" => sub {
        if ( $v && !$known_error ) {
            fail "TODO test is now passing, auto adjust known_errors.txt file";
            $self->test->todo_start($todo);

            # removing test from file
            diag "Removing test $current_t_file from known_errors.txt";
            $self->update_known_errors( test => $current_t_file ) if $self->{first_error};
            return 0;
        }
        else {
            $self->test->todo_start($todo);
            return ok( $v, $msg );
        }
    }
}

sub update_known_errors {
    my ( $self, %opts ) = @_;

    # disable updates when running travis (not sure if FS support flock)
    return if $ENV{TRAVIS} && $ENV{CI};

    # tests can be run in parallel
    open( my $fh, '+<', $self->{error_file} ) or die( "Can't open " . $self->{error_file} . ": $!" );
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
            push @body_format, [ $tfile || '', $type || '', $txt || '' ];
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
    flock( $fh, LOCK_EX ) or die "Cannot lock file - $!\n";

    # and, in case someone appended while we were waiting...
    seek( $fh, 0, SEEK_END ) or die "Cannot seek - $!\n";
}

sub unlock {
    my ($fh) = @_;
    flock( $fh, LOCK_UN ) or die "Cannot unlock file - $!\n";
}

1;
