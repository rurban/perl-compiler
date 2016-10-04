package B::PADLIST;

use strict;
our @ISA = qw(B::AV);

use B::C::File qw/init padlistsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub add_to_section {    # id+outid as U32 (PL_padlist_generation++)
    my ( $self, $cv ) = @_;

    my $fill = $self->fill;

    padlistsect()->comment("xpadl_max, xpadl_alloc, xpadl_id, xpadl_outid");
    my ( $id, $outid ) = ( $self->ID, $self->OUTID );
    padlistsect()->add("$fill, {NULL}, $id, $outid");
    my $padlist_index = padlistsect()->index;

    return savesym( $self, "&padlist_list[$padlist_index]" );
}

sub add_to_init {
    my ( $self, $sym, $acc ) = @_;

    my $fill1 = $self->fill + 1;

    init()->no_split;
    init()->add( "{", "\tPAD **svp;" );
    init()->add("\tregister int gcount;") if $acc =~ qr{\bgcount\b};    # only if gcount is used
    init()->add(
        "\tPADLIST *padl = $sym;",
        sprintf( "\tNewxz(svp, %d, PAD *);", $fill1 ),
        "\tPadlistARRAY(padl) = svp;",
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
    return "(PAD*)";
}

1;
