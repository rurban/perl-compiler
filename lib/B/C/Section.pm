package B::C::Section;
use strict;

use B ();
use B::Flags;

my %sections;

# This isn't really a method. It's used to find another section if you don't know it.
sub get {
    my ( $class, $section ) = @_;
    return $sections{$section};
}

sub new {
    my ( $class, $section, $symtable, $default ) = @_;

    my $obj = bless [ -1, $section, $symtable, $default, { values => [] } ], $class;
    $sections{$section} = $obj;

    # if sv add a dummy sv_arenaroot to support global destruction
    if ( $section eq 'sv' ) {
        $obj->add("0, 0, SVTYPEMASK|0x01000000, {0}");    # SVf_FAKE
        $obj->[-1]{dbg}->[0] = "PL_sv_arenaroot";
    }

    return $obj;
}

sub add {
    my $section = shift;
    push( @{ $section->[-1]{values} }, @_ );
}

sub remove {
    my $section = shift;
    pop @{ $section->[-1]{values} };
}

sub name {
    my $section = shift;
    return $section->[1];
}

sub symtable {
    my $section = shift;
    return $section->[2];
}

sub default {
    my $section = shift;
    return $section->[3];
}

sub index {
    my $section = shift;
    return scalar( @{ $section->[-1]{values} } ) - 1;
}

sub typename {
    my $section  = shift;
    my $name     = $section->name;
    my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);

    # $typename = 'const '.$typename if $name !~ /^(cop_|sv_)/;
    return $typename;
}

sub comment_common {
    my $self = shift;
    return $self->comment( B::C::opsect_common(), ', ', @_ );
}

sub comment {
    my $section = shift;

    my @comments = grep { defined $_ } @_;
    $section->[-1]{comment} = join( "", @comments ) if @comments;

    return $section->[-1]{comment};
}

# add debugging info - stringified flags on -DF
sub debug {
    return if !$B::C::debug{'flags'};

    my $section = shift;
    my $op      = shift;

    my $dbg = ref $op ? $op->flagspv : undef;
    $section->[-1]{dbg}->[ $section->index ] = $dbg if $dbg;
}

sub output {
    my ( $section, $fh, $format ) = @_;
    my $sym     = $section->symtable;    # This should always be defined. see new
    my $default = $section->default;

    my $i = 0;
    my $dodbg = 1 if $B::C::debug{flags} and $section->[-1]{dbg};
    if ( $section->name eq 'sv' ) {      #fixup arenaroot refcnt
        my $len = scalar @{ $section->[-1]{values} };
        $section->[-1]{values}->[0] =~ s/^0, 0/0, $len/;
    }
    foreach ( @{ $section->[-1]{values} } ) {
        my $val = $_;                    # Copy so we don't overwrite on successive calls.
        my $dbg = "";
        my $ref = "";
        if ( $val =~ m/(s\\_[0-9a-f]+)/ ) {
            if ( !exists( $sym->{$1} ) and $1 ne 's\_0' ) {
                $ref = $1;
                $B::C::unresolved_count++;
                if ($B::C::verbose) {
                    warn "Warning: unresolved " . $section->name . " symbol $ref\n";
                }
            }
        }
        $val =~ s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
        if ( $dodbg and $section->[-1]{dbg}->[$i] ) {
            $dbg = " /* " . $section->[-1]{dbg}->[$i] . " " . $ref . " */";
        }
        printf $fh $format, $val, $section->name, $i, $ref, $dbg;
        ++$i;
    }
}

1;
