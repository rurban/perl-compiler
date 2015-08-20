package B::C::Helpers::Symtable;

use strict;

use Exporter ();

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(get_symtable_ref savesym objsym getsym dump_symtable delsym);

my %SYMTABLE;

sub get_symtable_ref {
    return \%SYMTABLE;
}

{
    my $warn_undefined_syms;

    sub enable_warnings {
        $warn_undefined_syms = 1;
    }

    sub use_warnings {
        return $warn_undefined_syms;
    }
}

# todo move all the sym to helper
sub savesym {
    my ( $obj, $value ) = @_;
    no strict 'refs';
    my $sym = sprintf( "s\\_%x", $$obj );
    $SYMTABLE{$sym} = $value;
    return $value;
}

sub objsym {
    my $obj = shift;
    no strict 'refs';
    return $SYMTABLE{ sprintf( "s\\_%x", $$obj ) };
}

sub getsym {
    my $sym = shift;
    my $value;

    return 0 if $sym eq "sym_0";    # special case
    $value = $SYMTABLE{$sym};
    if ( defined($value) ) {
        return $value;
    }
    else {
        warn "warning: undefined symbol $sym\n" if use_warnings();
        return "UNUSED";
    }
}

sub delsym {
    my ($obj) = @_;
    my $sym = sprintf( "s\\_%x", $$obj );

    # fixme move the variable here with accessor
    delete $SYMTABLE{$sym};
}

sub dump_symtable {

    # For debugging
    my ( $sym, $val );
    warn "----Symbol table:\n";

    for $sym ( sort keys %SYMTABLE ) {
        $val = $SYMTABLE{$sym};
        warn "$sym => $val\n";
    }
    warn "---End of symbol table\n";
}

1;
