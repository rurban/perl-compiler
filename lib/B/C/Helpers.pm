package B::C::Helpers;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/svop_name padop_name mark_package do_labels read_utf8_string/;

# wip to be moved
*do_labels    = \&B::C::do_labels;
*mark_package = \&B::C::mark_package;
*padop_name   = \&B::C::padop_name;
*svop_name    = \&B::C::svop_name;

# B/C/Helpers/Sym

sub read_utf8_string {
    my ($name) = @_;

    my $copy    = $name;
    my $utf_len = utf8::upgrade($copy);
    my $str_len = length($name);

    my $is_utf8 = $utf_len != $str_len ? 1 : 0;

    return ( $is_utf8, $utf_len );
}
