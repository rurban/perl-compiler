package B::C::Config;

use strict;
use Config;

use B::C::Config::Debug ();

use Exporter ();
our @ISA = qw(Exporter);

# alias
*debug           = \&B::C::Config::Debug::debug;
*verbose         = \&B::C::Config::Debug::verbose;
*display_message = \&B::C::Config::Debug::display_message;

*WARN = \&B::C::Config::Debug::WARN;

sub _autoload_map {
    my $map = {
        USE_ITHREADS     => $Config{useithreads},
        USE_MULTIPLICITY => $Config{usemultiplicity},

        # Thanks to Mattia Barbon for the C99 tip to init any union members
        C99 => $Config{d_c99_variadic_macros},    # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962

        MAD => $Config{mad},

    };

    $map->{HAVE_DLFCN_DLOPEN} = $Config{i_dlfcn} && $Config{d_dlopen};

    # debugging variables
    $map->{'DEBUGGING'}             = ( $Config{ccflags} =~ m/-DDEBUGGING/ );
    $map->{'DEBUG_LEAKING_SCALARS'} = $Config{ccflags} =~ m/-DDEBUG_LEAKING_SCALARS/;

    return $map;
}

my $_autoload;

BEGIN {
    $_autoload = _autoload_map();
    our @EXPORT_OK = keys %$_autoload;
    push @EXPORT_OK, qw/debug display_message verbose WARN INFO FATAL/;
    our @EXPORT = @EXPORT_OK;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $ask_for = $AUTOLOAD;
    $ask_for =~ s/.*:://;

    $ask_for =~ s/sect$//;    # Strip sect off the call so we can just access the key.

    exists $_autoload->{$ask_for} or die("Tried to call undefined subroutine '$ask_for'");
    return $_autoload->{$ask_for};
}

1;
