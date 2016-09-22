package B::C::Helpers;

use Exporter ();
use B::C::Config;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/svop_name padop_name mark_package do_labels read_utf8_string get_cv_string is_constant strlen_flags curcv set_curcv is_using_mro cow_strlen_flags is_shared_hek/;

# wip to be moved
*do_labels    = \&B::C::do_labels;
*mark_package = \&B::C::mark_package;
*padop_name   = \&B::C::padop_name;
*svop_name    = \&B::C::svop_name;

# B/C/Helpers/Sym

use B qw/cstring/;

sub is_constant {
    my $s = shift;
    return 1 if $s =~ /^(&sv_list|\-?[0-9]+|Nullsv)/;    # not gv_list, hek
    return 0;
}

sub is_shared_hek {
    my $sv = shift;
    return 0 unless $sv && $$sv;

    my $flags = $sv->FLAGS;
    return ( ( $flags & 0x09000000 ) == 0x09000000 ) || B::C::IsCOW_hek($sv);
}

# lazy helper for backward compatibility only (we can probably avoid to use it)
sub strlen_flags {
    my $str = shift;

    my ( $is_utf8, $cur ) = read_utf8_string($str);
    my $cstr = cstring($str);

    return ( $cstr, $cur, $is_utf8 ? 'SVf_UTF8' : '0' );
}

# lazy helper for backward compatibility only (we can probably avoid to use it)
sub cow_strlen_flags {
    my $str = shift;

    my ( $is_utf8, $cur ) = read_utf8_string($str);

    # TODO: we would like to use this but in some cases, the c string is corrupted
    # instead of
    #   cowpv7[] = "$c\000\377";
    # we had
    #   cowpv7[] = "$c\000\303\277";

    my $cstr = cstring($str);
    my $end  = q{\000\377};
    $cstr =~ s{"$}{$end"};

    return ( $cstr, $cur, $cur + 2, $is_utf8 ? 'SVf_UTF8' : '0' );    # NOTE: The actual Cstring length will be 2 bytes longer than $cur
}

# maybe move to B::C::Helpers::Str ?
sub read_utf8_string {
    my ($name) = @_;

    my $cur;

    #my $is_utf8 = $utf_len != $str_len ? 1 : 0;
    my $is_utf8 = utf8::is_utf8($name);
    if ($is_utf8) {
        my $copy = $name;
        $cur = utf8::upgrade($copy);
    }
    else {
        #$cur = length( pack "a*", $name );
        $cur = length($name);
    }

    return ( $is_utf8, $cur );
}

# previously known as:
# get_cv() returns a CV*
sub get_cv_string {
    my ( $name, $flags ) = @_;
    warn 'undefined flags' unless defined $flags;
    $name = "" if $name eq "__ANON__";
    my $cname = cstring($name);

    my ( $is_utf8, $length ) = read_utf8_string($name);

    $flags = '' unless defined $flags;
    $flags .= "|SVf_UTF8" if $is_utf8;
    $flags =~ s/^\|//;

    if ( $flags =~ qr{^0?$} ) {
        return qq/get_cv($cname, 0)/;
    }
    else {
        return qq/get_cvn_flags($cname, $length, $flags)/;
    }
}

{
    my $curcv;

    sub curcv { return $curcv }
    sub set_curcv($) { $curcv = shift }
}

sub _load_mro {
    eval q/require mro; 1/ or die;
    no warnings 'redefine';
    *_load_mro = sub { };
}

sub is_using_mro {
    return keys %{mro::} > 10 ? 1 : 0;
}

1;
