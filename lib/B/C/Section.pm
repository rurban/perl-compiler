package B::C::Section;
use strict;

# use warnings

use B::C::Config::Debug ();
my %sections;

# This isn't really a method. It's used to find another section if you don't know it.
sub get {
    my ( $class, $section ) = @_;
    return $sections{$section};
}

sub new {
    my ( $class, $section, $symtable, $default ) = @_;

    my $self = bless {
        'name'     => $section,
        'symtable' => $symtable,
        'default'  => $default,
        'values'   => [],
    }, $class;
    $sections{$section} = $self;

    # if sv add a dummy sv_arenaroot to support global destruction
    if ( $section eq 'sv' ) {
        $self->add("NULL, 0, SVTYPEMASK|0x01000000, {0}");    # SVf_FAKE
        $self->{'dbg'}->[0] = "PL_sv_arenaroot";
    }

    return $self;
}

sub add {
    my $self      = shift;
    my @list      = @_;
    my $add_stack = 'B::C::Save'->can('_caller_comment');
    if ( $list[-1] && ref $add_stack ) {
        $list[-1] .= qq{\n} . $add_stack->();
    }
    push( @{ $self->{'values'} }, @list );
    return;
}

sub remove {
    my $self = shift;
    pop @{ $self->{'values'} };
}

sub name {
    return shift->{'name'};
}

sub symtable {
    return shift->{'symtable'};
}

sub default {
    return shift->{'default'};
}

sub index {
    my $self = shift;
    return scalar( @{ $self->{'values'} } ) - 1;
}

sub typename {
    my $self     = shift;
    my $name     = $self->name;
    my $typename = uc($name);
    $typename = 'UNOP_AUX'  if $typename eq 'UNOPAUX';
    $typename = 'MyPADNAME' if $typename eq 'PADNAME';

    return $typename;
}

sub comment_common {
    my $self = shift;
    return $self->comment( B::C::opsect_common(), ', ', @_ );
}

sub comment {
    my $self = shift;

    my @comments = grep { defined $_ } @_;
    $self->{'comment'} = join( "", @comments ) if @comments;

    return $self->{'comment'};
}

# add debugging info - stringified flags on -DF
my $debug_flags;

sub debug {

    # disable the sub when unused
    if ( !defined $debug_flags ) {
        $debug_flags = B::C::Config::Debug::debug('flags') ? 1 : 0;
        if ( !$debug_flags ) {

            # Scoped no warnings without loading the module.
            local $^W;
            BEGIN { ${^WARNING_BITS} = 0; }
            *debug = sub { };

            return;
        }
    }

    # debug
    my ( $self, $op ) = @_;

    my $dbg = ref $op && $op->can('flagspv') ? $op->flagspv : undef;
    $self->{'dbg'}->[ $self->index ] = $dbg if $dbg;

    return;
}

sub output {
    my ( $self, $format ) = @_;
    my $sym     = $self->symtable;    # This should always be defined. see new
    my $default = $self->default;

    my $i = 0;
    my $dodbg = 1 if B::C::Config::Debug::debug('flags') and $self->{'dbg'};
    if ( $self->name eq 'sv' ) {      #fixup arenaroot refcnt
        my $len = scalar @{ $self->{'values'} };
        $self->{'values'}->[0] =~ s/^NULL, 0/NULL, $len/;
    }

    my $return_string = '';

    foreach ( @{ $self->{'values'} } ) {
        my $val = $_;                 # Copy so we don't overwrite on successive calls.
        my $dbg = "";
        my $ref = "";
        if ( $val =~ m/(s\\_[0-9a-f]+)/ ) {
            if ( !exists( $sym->{$1} ) and $1 ne 's\_0' ) {
                $ref = $1;
                $B::C::unresolved_count++;
                B::C::Config::Debug::verbose( "Warning: unresolved " . $self->name . " symbol $ref" );
            }
        }
        $val =~ s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
        if ( $dodbg and $self->{'dbg'}->[$i] ) {
            $dbg = " /* " . $self->{'dbg'}->[$i] . " " . $ref . " */";
        }

        {
            # Scoped no warnings without loading the module.
            local $^W;
            BEGIN { ${^WARNING_BITS} = 0; }
            $return_string .= sprintf( $format, $val, $self->name, $i, $ref, $dbg );
        }

        ++$i;
    }

    return $return_string;
}

1;
