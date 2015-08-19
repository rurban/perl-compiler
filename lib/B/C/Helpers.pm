package B::C::Helpers;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/objsym savesym svop_name padop_name mark_package do_labels save_rv/;

# wip to be moved
*do_labels    = \&B::C::do_labels;
*mark_package = \&B::C::mark_package;
*objsym       = \&B::C::objsym;
*padop_name   = \&B::C::padop_name;
*save_rv      = \&B::C::save_rv;
*savesym      = \&B::C::savesym;
*svop_name    = \&B::C::svop_name;

