package B::C::Debug::Walker;

use strict;
use B::C::Setup;
use B::C::Helpers::Symtable qw/objsym/;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw/walkoptree_debug/;
our @EXPORT    = @EXPORT_OK;

# call before each B::*OP::save call
#	when debug mode is enabled ( -Dwalk without -v )
sub walkoptree_debug {
    my $op = shift;

    # easy way to print some informations while walking the tree
    WARN( "Walking...", $op, objsym($op) );

    return;
}

1;
