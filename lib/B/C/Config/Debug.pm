package B::C::Config::Debug;

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
    'W' => 'walk',
);

my %reverse_map = reverse %debug_map;

# list all possible level of debugging
my %debug;

sub init {
    %debug = map { $_ => 0 } values %debug_map;
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

sub enable_debug_with_map {
    my $cmdline_flag = shift or die;

    if ( defined $debug_map{$cmdline_flag} ) {
        enable_debug_level( $debug_map{$cmdline_flag} );
        return 1;
    }
    if ( defined $reverse_map{$cmdline_flag} ) {
        enable_debug_level($cmdline_flag);
        return 1;
    }

    return;
}

sub enable_debug_level {
    my $level = shift or die;

    INFO("Enabling debug level: '$level'");
    $debug{$level}++;

    return;
}

sub enable_all {
    enable_verbose() unless verbose();
    foreach my $level ( keys %debug ) {
        next if $debug{$level};
        enable_debug_level($level);
    }
    return;
}

my $verbose = 0;
sub enable_verbose { $verbose++ }

sub verbose {
    return $verbose unless $verbose;
    return $verbose unless scalar @_;
    display_message( '[verbose]', @_ );
    return $verbose;
}

# can be improved
sub WARN { return display_message( "[WARNING]", @_ ) }
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

    if ( !$level || !defined $debug{$level} ) {
        eval q/require Carp; 1/ or die "Unknown debug level $level";
        Carp::croak("Unknown debug level $level");
    }

    if ( $debug{$level} && scalar @msg ) {
        @msg = map { defined $_ ? $_ : 'undef' } @msg;
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
                Carp::croak( "Error: $error", "[level=$level] ", "STR:'$str' ; ", join( ', ', @msg ) );
            };

        }
        $warn = '' unless defined $warn;
        display_message("[$level] $warn");
    }

    return $debug{$level};
}

1;
