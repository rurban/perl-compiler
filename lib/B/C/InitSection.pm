package B::C::InitSection;
use strict;
use warnings;

# avoid use vars
use parent 'B::C::Section';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{'evals'}     = [];
    $self->{'initav'}    = [];
    $self->{'chunks'}    = [];
    $self->{'nosplit'}   = 0;
    $self->{'current'}   = [];
    $self->{'count'}     = 0;
    $self->{'max_lines'} = 10000;

    return $self;
}

sub split {
    my $self = shift;
    $self->{'nosplit'}--
      if $self->{'nosplit'} > 0;
}

sub no_split {
    shift->{'nosplit'}++;
}

sub inc_count {
    my $self = shift;

    $self->{'count'} += $_[0];

    # this is cheating
    $self->add();
}

sub add {
    my $self    = shift;
    my $current = $self->{'current'};
    my $nosplit = $self->{'nosplit'};

    push @$current, @_;
    $self->{'count'} += scalar(@_);
    if ( !$nosplit && $self->{'count'} >= $self->{'max_lines'} ) {
        push @{ $self->{'chunks'} }, $current;
        $self->{'current'} = [];
        $self->{'count'}   = 0;
    }
}

sub add_eval {
    my $self    = shift;
    my @strings = @_;

    foreach my $i (@strings) {
        $i =~ s/\"/\\\"/g;
    }
    push @{ $self->{'evals'} }, @strings;
}

sub pre_destruct {
    my $self = shift;
    push @{ $self->{'pre_destruct'} }, @_;
}

sub add_initav {
    my $self = shift;
    push @{ $self->{'initav'} }, @_;
}

sub output {
    my ( $self, $format, $init_name ) = @_;
    my $sym = $self->symtable || {};
    my $default = $self->default;

    push @{ $self->{'chunks'} }, $self->{'current'};

    my $return_string = '';

    my $name = "aaaa";
    foreach my $i ( @{ $self->{'chunks'} } ) {

        # dTARG and dSP unused -nt
        $return_string .= "static int ${init_name}_${name}(pTHX)\n{\n";

        foreach my $i ( @{ $self->{'initav'} } ) {
            $return_string .= "    $i\n";
        }
        foreach my $j (@$i) {
            $j =~ s{(s\\_[0-9a-f]+)}
                   { exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
            $return_string .= "    $j\n";
        }
        $return_string .= "    return 0;\n}\n";

        $self->SUPER::add("${init_name}_${name}(aTHX);");
        ++$name;
    }

    # We need to output evals after dl_init.
    foreach my $s ( @{ $self->{'evals'} } ) {
        ${B::C::eval_pvs} .= "    eval_pv(\"$s\",1);\n";
    }

    $return_string .= "static int ${init_name}(pTHX)\n{\n";

    if ( $self->name eq 'init' ) {
        $return_string .= "    perl_init0(aTHX);\n";
    }
    $return_string .= $self->SUPER::output($format);
    $return_string .= "    return 0;\n}\n";
}

1;
