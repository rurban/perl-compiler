package B::PADNAMELIST;

use strict;
our @ISA = qw(B::AV);

use B::C::File qw/init padnamelistsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub add_to_section {
    my ( $self, $cv ) = @_;

    padnamelistsect()->comment("xpadnl_fill, xpadnl_alloc, xpadnl_max, xpadnl_max_named, xpadnl_refcnt");

    # TODO: max_named walk all names and look for non-empty names
    my $refcnt = $self->REFCNT + 1;    # XXX defer free to global destruction: 28
    my $fill   = $self->fill;
    my $maxnamed = $self->MAXNAMED;

    padnamelistsect->add("$fill, NULL, $fill, $maxnamed, $refcnt /* +1 */");

    my $padnamelist_index = padnamelistsect()->index;
    my $sym = savesym( $self, "&padnamelist_list[$padnamelist_index]" );
    push @B::C::static_free, $sym;

    return $sym;
}

sub add_to_init {
    my ( $self, $sym, $acc ) = @_;

    my $fill1 = $self->fill + 1;

    init()->no_split;
    init()->add( "{", "\tPADNAME **svp;" );
    init()->add("\tregister int gcount;") if $acc =~ qr{\bgcount\b};
    init()->add(
        "\tPADNAMELIST *padnl = $sym;",
        sprintf( "\tNewxz(svp, %d, PADNAME *);", $fill1 ),
        "\tPadnamelistARRAY(padnl) = svp;",
    );
    init()->add( substr( $acc, 0, -2 ) );
    init()->add("}");
    init()->split;

    return;
}

sub fill {
    my $self = shift;
    return $self->MAX;
}

sub cast_sv {
    return "(PADNAME*)";
}

1;
