package B::C::Config;

use strict;

use B::C::Flags         ();
use B::C::Config::Debug ();

use Exporter ();
our @ISA = qw(Exporter);

# alias
*debug           = \&B::C::Config::Debug::debug;
*debug_all       = \&B::C::Config::Debug::enable_all;
*verbose         = \&B::C::Config::Debug::verbose;
*display_message = \&B::C::Config::Debug::display_message;

*WARN  = \&B::C::Config::Debug::WARN;
*INFO  = \&B::C::Config::Debug::INFO;
*FATAL = \&B::C::Config::Debug::FATAL;

# usually 0x400000, but can be as low as 0x10000
# http://docs.embarcadero.com/products/rad_studio/delphiAndcpp2009/HelpUpdate2/EN/html/devcommon/compdirsimagebaseaddress_xml.html
# called mapped_base on linux (usually 0xa38000)
sub LOWEST_IMAGEBASE() { 0x10000 }

sub _autoload_map {

    my $map = {
        USE_ITHREADS     => $B::C::Flags::Config{useithreads},
        USE_MULTIPLICITY => $B::C::Flags::Config{usemultiplicity},
        MAD => $B::C::Flags::Config{mad},
    };
    $map->{HAVE_DLFCN_DLOPEN} = $B::C::Flags::Config{i_dlfcn} && $B::C::Flags::Config{d_dlopen};

    # debugging variables
    $map->{'DEBUGGING'}             = ( $B::C::Flags::Config{ccflags} =~ m/-DDEBUGGING/ );
    $map->{'DEBUG_LEAKING_SCALARS'} = $B::C::Flags::Config{ccflags} =~ m/-DDEBUG_LEAKING_SCALARS/;

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

{
    # protection to check that C99 is always enabled
    $B::C::Flags::Config{d_c99_variadic_macros} or die "C99 should be enabled";

    # croak when C99 is used in our code
    sub C99 {
        die "Do not use C99: this should always be true";
    }
}


sub AUTOLOAD {
    my $ask_for = $AUTOLOAD;
    $ask_for =~ s/.*:://;

    $ask_for =~ s/sect$//;    # Strip sect off the call so we can just access the key.

    exists $_autoload->{$ask_for} or die("Tried to call undefined subroutine '$ask_for'");
    return $_autoload->{$ask_for};
}

1;
