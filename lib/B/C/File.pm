package B::C::File;

=head1 NAME

B::C::File - Responsible for rendering the C file from a provided stash and locally tracked sections for use with perlcc

=head1 SYNOPSIS

    # In B::C
    use B::C::File ();
    B::C::File::new(); # Singleton.
    ...
    B::C::File::write( 'file.c' ) # C File to generate.

=head1 DESCRIPTION

B<B::C::File> B::C::File is B::C's view. It uses Template Toolkit to render the C file using a passed in stash,
combined with B::C::Section objects which it initializes and tree walkers update as they go.

=cut

use strict;
use warnings;

use Exporter ();

use B::C::Config;
use B::C::Helpers::Symtable qw(get_symtable_ref);
use B::C::Section     ();
use B::C::InitSection ();

use B qw(cstring comppadlist);

our @ISA = qw(Exporter);

# singleton
my $self;

sub code_section_names {
    return qw{const decl init0 free sym hek}, struct_names(), op_sections();
}

sub struct_names {
    return qw( xpv xpvav xpvhv xpvcv padlist padname padnamelist
      xpviv xpvuv xpvnv xpvmg xpvlv xrv xpvbm xpvio sv sharedhe);
}

sub init_section_names { return qw /init init1 init2/ }

sub op_sections {
    return qw { binop condop cop padop loop listop logop op pmop pvop svop unop unopaux methop};
}

BEGIN {
    our @EXPORT_OK = map { ( $_, "${_}sect" ) } code_section_names();
    push @EXPORT_OK, init_section_names();

}

sub re_initialize {
    my $outfile = $self->{'c_file_name'};
    $self = undef;
    return new($outfile);
}

sub new {
    $self and die("Re-initialized???");

    my $outfile = shift;
    debug( 'file' => "Write to c file: '$outfile'" );
    $self = bless { 'c_file_name' => $outfile };

    foreach my $section_name ( code_section_names() ) {
        $self->{$section_name} = B::C::Section->new( $section_name, get_symtable_ref(), 0 );
    }

    foreach my $section_name ( init_section_names() ) {
        $self->{$section_name} = B::C::InitSection->new( $section_name, get_symtable_ref(), 0 );
    }
}

sub get_sect {
    my $section = shift;
    return $self->{$section};
}

# Devel::NYTProf gives bad data when AUTOLOAD is in place. Just the same, we have no evidence that run times change when you replace it.
# But in the interests of accurate data, you can replace the output of the below one liner and remove AUTOLOAD so you can get a useful
# NYTProf report back.
# perl -MB::C::File -E'foreach my $s ("", "sect") { foreach my $sect (B::C::File::code_section_names(), B::C::File::init_section_names()) {print "sub $sect$s { return \$self->{'\''$sect'\''} }\n"}; print "\n"}'

sub DESTROY { }    # Because we're doing autoload.

our $AUTOLOAD;     # Avoids warnings.

sub AUTOLOAD {
    my $sect = $AUTOLOAD;
    $sect =~ s/.*:://;

    $sect =~ s/sect$//;    # Strip sect off the call so we can just access the key.

    exists $self->{$sect} or die("Tried to call undefined subroutine '$sect'");
    return $self->{$sect};
}

my $cfh;
my %static_ext;

sub write {
    my $c_file_stash = shift or die;
    my $template_name_short = shift || 'base.c.tt2';

    # Controls the rendering order of the sections.
    $c_file_stash->{section_list} = [
        struct_names(),
        op_sections()
    ];

    foreach my $section ( code_section_names(), init_section_names() ) {
        $c_file_stash->{'section'}->{$section} = $self->{$section};
    }

    $self->{'verbose'} = $c_file_stash->{'verbose'};    # So verbose() will work. TODO: Remove me when all verbose() are gone.

    my $template_dir;
    {
        # Scoped no warnings without loading the module.
        local $^W;
        BEGIN { ${^WARNING_BITS} = 0; }
        $template_dir = $B::C::savINC{'B/C.pm'};
    }
    $template_dir =~ s{\.pm$}{};
    $template_dir .= "/Templates";
    my $template_file = "$template_dir/$template_name_short";
    -e $template_file or die("Can't find or read $template_file for generating B::C C code.");

    # op/magic-27839.t sets SIG{WARN} in a begin block and then never releases it.
    eval q{local $SIG{__WARN__} = 'IGNORE'; require Config; require Exporter::Heavy; require Template};
    $INC{'Template.pm'} or die("Can't load Template Toolkit at run time to render the C file.");

    # some useful options (see below for full list)
    my $config = {
        INCLUDE_PATH => $template_dir,
        INTERPOLATE  => 0,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # Don't cleanup whitespace
        EVAL_PERL    => 1,               # evaluate Perl code blocks
    };

    if ( verbose() ) {
        WARN $c_file_stash->{'compile_stats'};
        WARN "NULLOP count: $c_file_stash->{nullop_count}";
    }

    # Used to be buried in output_main_rest();
    my @possible_static_free_errors = grep { $_ !~ m/^(cop_list|&sv_list|sv_list|&padname_list|&padnamelist_list)|^ptr_undef$/ } @{ $c_file_stash->{'static_free'} };
    if (@possible_static_free_errors) {
        WARN("unknown $_ found in \@static_free") foreach @possible_static_free_errors;
    }

    # Used to be buried in output_main_rest();
    if ( verbose() ) {
        foreach my $stashname ( sort keys %static_ext ) {
            verbose("bootstrapping static $stashname added to xs_init");
        }
    }

    # create Template object
    my $template = Template->new($config);

    open( my $fh, '>:utf8', $self->{'c_file_name'} ) or die;

    # process input template, substituting variables
    $template->process( $template_name_short, $c_file_stash, $fh ) or die $template->error();

}

1;
