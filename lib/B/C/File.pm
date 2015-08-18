package B::C::File;

use Exporter ();

use B::C::Section     ();
use B::C::InitSection ();

our @ISA = qw(Exporter);

my $self;

our %symtable;

sub code_section_names {
    return qw{
      decl init0 free sym hek binop condop cop padop listop logop
      op pmop pvop svop unop sv xpv xpvav xpvhv xpvcv xpviv xpvuv
      xpvnv xpvmg xpvlv xrv xpvbm xpvio padlist loop
    };
}

sub init_section_names { return qw /init init2/ }

sub op_sections {
    return qw { binop condop cop padop loop listop logop  op pmop pvop svop unop };
}

BEGIN {
    our @EXPORT_OK = map { ( $_, "${_}sect" ) } code_section_names();
    push @EXPORT_OK, init_section_names();
}

sub new {
    $self and die("Re-initialized???");
    $self = bless {};

    foreach my $section_name ( code_section_names() ) {
        $self->{$section_name} = B::C::Section->new( $section_name, \%symtable, 0 );
    }

    foreach my $section_name ( init_section_names() ) {
        $self->{$section_name} = B::C::InitSection->new( $section_name, \%symtable, 0 );
    }
}

sub get_sect {
    my $section = shift;
    return $self->{$section};
}

sub AUTOLOAD {
    my $sect = $AUTOLOAD;
    $sect =~ s/.*:://;

    $sect =~ s/sect$//;    # Strip sect off the call so we can just access the key.

    return $self->{$sect}; # If it doesn't exist, it'll just be undef so why check?
}

1;
