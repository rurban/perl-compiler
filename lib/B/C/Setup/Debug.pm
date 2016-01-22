package B::C::Setup::Debug;

use strict;

my %debug_map = (
    'A' => 'av',
    'c' => 'cops',
    'C' => 'cv',
    'f' => 'file',
    'G' => 'gv',
    'g' => 'signals',
    'H' => 'hv',
    'M' => 'mg',
    'O' => 'op',
    'p' => 'pkg',
    'P' => 'pv',
    'R' => 'rx',
    's' => 'sub',
    'S' => 'sv',
    'u' => 'unused',
    'v' => 'verbose',    # special case to consider verbose as a debug level
    'W' => 'walk',
);

my %reverse_map = reverse %debug_map;

# list all possible level of debugging
my %debug;

sub init {
    %debug = map { $_ => 0 } sort values %debug_map, sort keys %debug_map;
    %debug = (
        %debug,
        flags   => 0,
        runtime => 0,
    );

    binmode( STDERR, ":utf8" );    # Binmode of STDOUT and STDERR are not preserved for the perl compiler

    return;
}
init();                            # initialize

my %saved;

sub save {
    my %copy = %debug;
    return \%copy;
}

sub restore {
    my $cfg = shift;
    die unless ref $cfg;
    %debug = %$cfg;
    return;
}

# you can then enable them
# $debug{sv} = 1;

sub enable_debug_level {
    my $l = shift or die;

    if ( defined $debug_map{$l} ) {
        INFO("Enabling debug level: '$debug_map{$l}'");
        _enable_debug_level( $debug_map{$l} );
        _enable_debug_level($l);
        return 1;
    }
    if ( defined $reverse_map{$l} ) {
        INFO("Enabling debug level: '$l'");
        _enable_debug_level($l);
        _enable_debug_level( $reverse_map{$l} );
        return 1;
    }

    return;
}

sub _enable_debug_level {
    my $level = shift or die;
    $debug{$level}++;
    return;
}

sub enable_all {
    enable_verbose() unless verbose();
    foreach my $level ( sort keys %debug ) {
        next if $debug{$level};
        enable_debug_level($level);
    }
    return;
}

sub enable_verbose {
    enable_debug_level('verbose');
}

sub verbose {
    return $debug{'v'} unless $debug{'v'};
    return $debug{'v'} unless scalar @_;
    display_message( '[verbose]', @_ );
    return $debug{'v'};
}

# can be improved
sub WARN { return verbose() && display_message( "[WARNING]", @_ ) }
sub INFO { return verbose() && display_message( "[INFO]", @_ ) }
sub FATAL { die display_message( "[FATAL]", @_ ) }

sub display_message {
    return unless scalar @_;
    my $txt = join( " ", map { defined $_ ? $_ : 'undef' } @_ );

    # just safety to avoid double \n
    chomp $txt;
    print STDERR "$txt\n";

    return;
}

=pod
=item debug( $level, @msg )
 always return the current status for the level
 when call with one single arg print the string
	 			more than one, use sprintf
=cut

sub debug {
    my ( $level, @msg ) = @_;

    my @levels = ref $level eq 'ARRAY' ? @$level : $level;

    if ( !scalar @levels || grep { !defined $debug{$_} } @levels ) {
        my $error_msg = "One or more unknown debug level in " . ( join( ', ', sort @levels ) );
        eval q/require Carp; 1/ or die $error_msg;
        Carp::croak($error_msg);
    }

    my $debug_on = grep { $debug{$_} } @levels;

    if ( $debug_on && scalar @msg ) {
        @msg = map { defined $_ ? $_ : 'undef' } @msg;
        my $header = '[level=' . join( ',', sort @levels ) . '] ';
        my $cnt = @msg;
        my $warn;
        if ( $cnt == 1 ) {
            $warn = $msg[0];
        }
        else {
            my $str = shift @msg;
            eval {
                $warn = sprintf( $str, @msg );
                1;
            } or do {
                my $error = $@;

                # track the error source when possible
                eval q/require Carp; 1/ or die $error;
                Carp::croak( "Error: $error", $header, "STR:'$str' ; ", join( ', ', @msg ) );
            };

        }
        $warn = '' unless defined $warn;
        display_message("$header$warn");
    }

    return $debug_on;
}

1;
