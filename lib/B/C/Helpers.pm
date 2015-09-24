package B::C::Helpers;

use Exporter ();
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/svop_name padop_name mark_package do_labels read_utf8_string get_cv_string/;

# wip to be moved
*do_labels    = \&B::C::do_labels;
*mark_package = \&B::C::mark_package;
*padop_name   = \&B::C::padop_name;
*svop_name    = \&B::C::svop_name;

# B/C/Helpers/Sym

use B qw/cstring/;

# maybe move to B::C::Helpers::Str ?
sub read_utf8_string {
    my ($name) = @_;

    my $copy    = $name;
    my $utf_len = utf8::upgrade($copy);
    my $str_len = length($name);

    my $is_utf8 = $utf_len != $str_len ? 1 : 0;

    return ( $is_utf8, $utf_len );
}

sub get_cv_string {
    my ( $name, $flags ) = @_;
    my $cname = cstring($name);

    my ( $is_utf8, $length ) = read_utf8_string($name);

    $flags = '' unless defined $flags;
    $flags .= "|SVf_UTF8" if $is_utf8;
    $flags =~ s/^\|//;

    if ( defined $flags && $flags ) {
        return qq/get_cvn_flags($cname, $length, $flags)/;
    }
    else {
        return qq/get_cv($cname, 0)/;
    }
}

1;
