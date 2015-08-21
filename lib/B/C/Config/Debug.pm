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
my %debug = map { $_ => 0 } values %debug_map;
%debug = (
    %debug,
    flags   => 0,
    runtime => 0,
);

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

=pod
=item debug( $level, @msg )
 always return the current status for the level
 when call with one single arg print the string
	 			more than one, use sprintf
=cut

sub debug {
    my ( $level, @msg ) = @_;

    die "Unknown debug level $level" unless $level && defined $debug{$level};

    my $cnt = @msg;
    if ( $debug{$level} && scalar @msg ) {
        my $warn;
        if ( $cnt == 1 ) {
            $warn = $msg[0];
        }
        else {
            my $str = shift @msg;
            $warn = sprintf( $str, @msg );
        }
        $warn = '' unless defined $warn;
        chomp $warn;                # just safety to avoid double \n
        warn "[$level] $warn\n";    # can be improved to a better loggin system
    }

    return $debug{$level};
}

1;
