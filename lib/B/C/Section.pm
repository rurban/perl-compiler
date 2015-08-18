package B::C::Section;
use strict;

use B ();
use B::Flags;

use base 'B::Section';

sub new {
    my $class = shift;
    my $o     = $class->SUPER::new(@_);
    push @$o, { values => [] };

    # if sv add a dummy sv_arenaroot to support global destruction
    if ( $_[0] eq 'sv' ) {
        $o->add("0, 0, SVTYPEMASK|0x01000000, {0}");    # SVf_FAKE
        $o->[-1]{dbg}->[0] = "PL_sv_arenaroot";
    }
    return $o;
}

sub add {
    my $section = shift;
    push( @{ $section->[-1]{values} }, @_ );
}

sub remove {
    my $section = shift;
    pop @{ $section->[-1]{values} };
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

    my $dbg = $op->flagspv;
    $section->[-1]{dbg}->[ $section->index ] = $dbg if $dbg;
}

sub output {
    my ( $section, $fh, $format ) = @_;
    my $sym = $section->symtable || {};
    my $default = $section->default;
    return if $B::C::check;
    my $i = 0;
    my $dodbg = 1 if $B::C::debug{flags} and $section->[-1]{dbg};
    if ( $section->name eq 'sv' ) {    #fixup arenaroot refcnt
        my $len = scalar @{ $section->[-1]{values} };
        $section->[-1]{values}->[0] =~ s/^0, 0/0, $len/;
    }
    foreach ( @{ $section->[-1]{values} } ) {
        my $dbg = "";
        my $ref = "";
        if (m/(s\\_[0-9a-f]+)/) {
            if ( !exists( $sym->{$1} ) and $1 ne 's\_0' ) {
                $ref = $1;
                $B::C::unresolved_count++;
                if ($B::C::verbose) {
                    my $caller = caller(1);
                    warn "Warning: unresolved " . $section->name . " symbol $ref\n"
                      if $caller eq 'B::C';
                }
            }
        }
        s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
        if ( $dodbg and $section->[-1]{dbg}->[$i] ) {
            $dbg = " /* " . $section->[-1]{dbg}->[$i] . " " . $ref . " */";
        }
        printf $fh $format, $_, $section->name, $i, $ref, $dbg;
        ++$i;
    }
}

1;
