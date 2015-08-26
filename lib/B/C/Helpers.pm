package B::C::Helpers;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/svop_name padop_name mark_package do_labels/;

# wip to be moved
*do_labels    = \&B::C::do_labels;
*mark_package = \&B::C::mark_package;
*padop_name   = \&B::C::padop_name;
*svop_name    = \&B::C::svop_name;

# B/C/Helpers/Sym
