package B::C::InitSection;
use strict;

# avoid use vars
@B::C::InitSection::ISA = qw(B::C::Section);

sub new {
    my $class     = shift;
    my $max_lines = 10000;                    #pop;
    my $section   = $class->SUPER::new(@_);

    $section->[-1]{evals}     = [];
    $section->[-1]{initav}    = [];
    $section->[-1]{chunks}    = [];
    $section->[-1]{nosplit}   = 0;
    $section->[-1]{current}   = [];
    $section->[-1]{count}     = 0;
    $section->[-1]{max_lines} = $max_lines;

    return $section;
}

sub split {
    my $section = shift;
    $section->[-1]{nosplit}--
      if $section->[-1]{nosplit} > 0;
}

sub no_split {
    shift->[-1]{nosplit}++;
}

sub inc_count {
    my $section = shift;

    $section->[-1]{count} += $_[0];

    # this is cheating
    $section->add();
}

sub add {
    my $section = shift->[-1];
    my $current = $section->{current};
    my $nosplit = $section->{nosplit};

    push @$current, @_;
    $section->{count} += scalar(@_);
    if ( !$nosplit && $section->{count} >= $section->{max_lines} ) {
        push @{ $section->{chunks} }, $current;
        $section->{current} = [];
        $section->{count}   = 0;
    }
}

sub add_eval {
    my $section = shift;
    my @strings = @_;

    foreach my $i (@strings) {
        $i =~ s/\"/\\\"/g;
    }
    push @{ $section->[-1]{evals} }, @strings;
}

sub pre_destruct {
    my $section = shift;
    push @{ $section->[-1]{pre_destruct} }, @_;
}

sub add_initav {
    my $section = shift;
    push @{ $section->[-1]{initav} }, @_;
}

sub output {
    my ( $section, $fh, $format, $init_name ) = @_;
    my $sym = $section->symtable || {};
    my $default = $section->default;
    return if $B::C::check;
    push @{ $section->[-1]{chunks} }, $section->[-1]{current};

    my $name = "aaaa";
    foreach my $i ( @{ $section->[-1]{chunks} } ) {

        # dTARG and dSP unused -nt
        print $fh <<"EOT";
static int ${init_name}_${name}(pTHX)
{
EOT
        foreach my $i ( @{ $section->[-1]{initav} } ) {
            print $fh "\t", $i, "\n";
        }
        foreach my $j (@$i) {
            $j =~ s{(s\\_[0-9a-f]+)}
                   { exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
            print $fh "\t$j\n";
        }
        print $fh "\treturn 0;\n}\n";

        $section->SUPER::add("${init_name}_${name}(aTHX);");
        ++$name;
    }

    # We need to output evals after dl_init.
    foreach my $s ( @{ $section->[-1]{evals} } ) {
        ${B::C::eval_pvs} .= "    eval_pv(\"$s\",1);\n";
    }

    print $fh <<"EOT";
static int ${init_name}(pTHX)
{
EOT
    if ( $section->name eq 'init' ) {
        print $fh "\tperl_init0(aTHX);\n";
    }
    $section->SUPER::output( $fh, $format );
    print $fh "\treturn 0;\n}\n";
}

1;
