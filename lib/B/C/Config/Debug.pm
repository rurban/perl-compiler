package B::C::Config::Debug;

use strict;

my %debug_map = (
    'O' => 'op',
    'A' => 'av',
    'H' => 'hv',
    'C' => 'cv',
    'M' => 'mg',
    'R' => 'rx',
    'G' => 'gv',
    'S' => 'sv',
    'P' => 'pv',
    'W' => 'walk',
    'c' => 'cops',
    's' => 'sub',
    'p' => 'pkg',
    'u' => 'unused',
);

# list all possible level of debugging
my %debug;

sub init {
    %debug = map { $_ => 0 } values %debug_map;
    %debug = (
        %debug,
        flags   => 0,
        runtime => 0,
    );
    return;
}
init();    # initialize

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

    return unless defined $debug_map{$cmdline_flag};
    enable_debug_level( $debug_map{$cmdline_flag} );
    return 1;
}

sub enable_debug_level {
    my $level = shift or die;

    $debug{$level}++;

    return;
}

my $verbose = 0;
sub enable_verbose { $verbose++ }

sub verbose {
    return $verbose unless $verbose;
    display_message(@_);
    return $verbose;
}

# can be improved
sub WARN { return display_message( "[WARN]", @_ ) }
sub INFO { return enable_verbose( "[INFO]", @_ ) }
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

    die "Unknown debug level $level" unless $level && defined $debug{$level};

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
