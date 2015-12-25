package B::C::Setup;

use strict;

use B::C::Config         ();
use B::C::Setup::Debug ();

use Exporter ();
our @ISA = qw(Exporter);

# alias
*debug           = \&B::C::Setup::Debug::debug;
*debug_all       = \&B::C::Setup::Debug::enable_all;
*verbose         = \&B::C::Setup::Debug::verbose;
*display_message = \&B::C::Setup::Debug::display_message;

*WARN  = \&B::C::Setup::Debug::WARN;
*INFO  = \&B::C::Setup::Debug::INFO;
*FATAL = \&B::C::Setup::Debug::FATAL;

# usually 0x400000, but can be as low as 0x10000
# http://docs.embarcadero.com/products/rad_studio/delphiAndcpp2009/HelpUpdate2/EN/html/devcommon/compdirsimagebaseaddress_xml.html
# called mapped_base on linux (usually 0xa38000)
sub LOWEST_IMAGEBASE() { 0x10000 }

sub _autoload_map {
    my $map = {
        USE_ITHREADS     => $B::C::Config::Config{useithreads},
        USE_MULTIPLICITY => $B::C::Config::Config{usemultiplicity},

        # Thanks to Mattia Barbon for the C99 tip to init any union members
        C99 => $B::C::Config::Config{d_c99_variadic_macros},    # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962

        MAD => $B::C::Config::Config{mad},
    };
    $map->{HAVE_DLFCN_DLOPEN} = $B::C::Config::Config{i_dlfcn} && $B::C::Config::Config{d_dlopen};

    # debugging variables
    $map->{'DEBUGGING'}             = ( $B::C::Config::Config{ccflags} =~ m/-DDEBUGGING/ );
    $map->{'DEBUG_LEAKING_SCALARS'} = $B::C::Config::Config{ccflags} =~ m/-DDEBUG_LEAKING_SCALARS/;

    return $map;
}

my $_autoload;

BEGIN {
    $_autoload = _autoload_map();
    our @EXPORT_OK = sort keys %$_autoload;
    push @EXPORT_OK, qw/debug debug_all display_message verbose WARN INFO FATAL LOWEST_IMAGEBASE/;
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
