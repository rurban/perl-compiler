package B::PADLIST;

use strict;
our @ISA = qw(B::AV);

use B::C::File qw/init padlistsect/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub add_to_section {
    my ( $self, $cv ) = @_;

    padlistsect()->comment("xpadl_max, xpadl_alloc, xpadl_outid");
    padlistsect()->add( $self->fill() . ", NULL, 0, 0" );    # Perl_pad_new(0)

    my $padlist_index = padlistsect()->index;

    # could save sym to the object to reuse it in add_to_init
    my $sym = savesym( $self, "&padlist_list[$padlist_index]" );

    if (    $cv
        and $cv->OUTSIDE
        and ref( $cv->OUTSIDE ) ne 'B::SPECIAL'
        and $cv->OUTSIDE->PADLIST ) {
        my $outid = $cv->OUTSIDE->PADLIST->save();
        init()->add("($sym)->xpadl_outid = (PADNAMELIST*)$outid;") if $outid;
    }

    return $sym;
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
