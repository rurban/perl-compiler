package B::Asm::i386;

use Carp ();
use constant REG_NAMES => qw( edi esi ebp esp ebx edx ecx eax eflags );
use constant REG_PACK => "VVVVVVVVV";
use constant ETC_NAMES => qw( start_esp esp signal start_eip sig_eip );
use constant ETC_PACK => "VVpVV";
use constant FLAGS => ([cf=>0], [pf=>2], [af=>4], [zf=>6],
		       [sf=>7], [tf=>8], [if=>9], [df=>10],
		       [of=>11], [nt=>14], [rf=>16], [vm=>17], [ac=>18],
		       [vif=>19], [vip=>20], [id=>21]);

use strict;
use vars qw( $VERSION $in $out $jmp %nibs );

BEGIN {
    $VERSION = '0.01_01';
    {
	require DynaLoader;
	no strict;
	local @ISA = ('DynaLoader');
	__PACKAGE__->bootstrap ($VERSION);
    }
    if (not defined &_in) {
	Carp::croak ("This module requires an i386-compatible processor");
    }
}

INIT {
    $in = _in();
    $out = _out();
    $jmp = _jmp();
    @nibs{(REG_NAMES)} = (8) x REG_NAMES;
    delete $nibs{esp};

    no strict 'refs';

    foreach my $name (REG_NAMES) {
	next if $name eq 'esp';
	*$name = sub {
	    if (@_ == 1) {
		return $_[0]->{$name};
	    } elsif (@_ == 2) {
		return $_[0]->{$name} = $_[1];
	    } else {
		Carp::croak ("Usage: obj->$name *or* obj->$name(newval)");
	    }
	};
    }
    foreach (
	     [qw( eflags flags 0 16 )],
	     [qw( eax ax 0 16 )],
	     [qw( ecx cx 0 16 )],
	     [qw( edx dx 0 16 )],
	     [qw( ebx bx 0 16 )],
	     [qw( ebp bp 0 16 )],
	     [qw( esi si 0 16 )],
	     [qw( edi di 0 16 )],
	     [qw( eax ah 8 8 )],
	     [qw( ecx ch 8 8 )],
	     [qw( edx dh 8 8 )],
	     [qw( ebx bh 8 8 )],
	     [qw( eax al 0 8 )],
	     [qw( ecx cl 0 8 )],
	     [qw( edx dl 0 8 )],
	     [qw( ebx bl 0 8 )],
	     map { ['eflags', @$_[0,1], 1 ] } FLAGS,
	    )
    {
	# vec() is a pain to use here.
	my ($parent, $name, $offset, $bits) = @$_;
	my ($mask);

	$mask = (1 << $bits) - 1;
	$nibs{$name} = int (($bits + 3) / 4);
	*$name = sub {
	    if (@_ == 1) {
		return (($_[0]->{$parent} >> $offset) & $mask);
	    } elsif (@_ == 2) {
		($_[0]->{$parent} &= ~($mask << $offset))
		    |= ($_[1] << $offset);
		return $_[1];
	    } else {
		Carp::croak ("Usage: cpu->$name *or* cpu->$name(newval)");
	    }
	};
    }
}


#use strict;

sub new {
    my ($class, @args);
    ($class, @args) = @_;
    my ($self);

    if (ref($args[0]) eq 'HASH') {
	$self = shift @args;
	Carp::croak ("Usage: $class->new(HASHREF)");
    } else {
	$self = { @args };
    }
    for (REG_NAMES) { $self->{$_} ||= 0 }  # Cure undefinedness for -w
    return bless $self, $class;
}

sub do {
    my ($self, $bytes) = @_;

#warn "doing ".join (' ', map { sprintf "%.2x", ord } split //, $bytes)."\n";
    $self->{code_len} = length($bytes);
    _set_regs (pack ("V*", @$self{(REG_NAMES)}));
    _do ("$in$bytes$out$jmp");
    @$self{(REG_NAMES)} = unpack (REG_PACK, _regs());
    @$self{(ETC_NAMES)} = unpack (ETC_PACK, _etc());
    return $self;
}

sub sig { return $_[0]->{signal}; }
sub died_where {
    my ($self) = @_;
    my ($offs);

    $offs = $$self{sig_eip} - $$self{start_eip} - length($in);
    if ($offs >= 0 && $offs < $self->{code_len}) {
	return $offs;
    } else {
	return undef;
    }
}

sub dump_regs {
    my ($self) = @_;

    if ($$self{signal}) {
	printf "SIG$$self{signal}";
	if (defined $self->died_where) {
	    printf " at byte 0x%x", $self->died_where;
	} else {
	    print " (eip corrupt)";
	}
	print "\n";
    }
    print "Register dump\n------------------\n";
    foreach (REG_NAMES) {
	next if $_ eq 'esp';
	printf ("  %7s %.$nibs{$_}x\n", $_, $$self{$_});
    }
    foreach (FLAGS) {
	if ($$self{eflags} & (1 << $$_[1])) {
	    print uc(substr($$_[0],0,1));
	} else {
	    print "-";
	}
    }
    print "\n";
    if ($$self{esp} != $$self{start_esp}) {
	my $change = $$self{esp} - $$self{start_esp};

	if ($change <= 0x10 && $change >= -0x100000) {
	    print ("esp changed $change bytes.\n");
	} else {
	    print "esp apparently corrupt\n";
	}
    }
}

sub is_reg {
    return exists $nibs{$_[0]};
}

sub slurp_stdin {
    my ($self) = @_;
    my ($code, $line);

    $code = '';
    while (defined ($line = <STDIN>)) {
	$line =~ s/[#;].*//;
	$line =~ s/^[\s\w]*:\t(.*?)\s\s.*/$1/;
	while ($line =~ m/([0-9a-fA-F]{2})/g) {
	    $code .= pack ("H*", $1);
	}
    }
    return $code;
}

# for one-liners
sub run {
    my ($code, $cpu, $count, @argv);

    $code = '';
    $cpu = B::Asm::i386->new;
    $count = 0;

    if (@ARGV) {
	@argv = @ARGV;
	while (@argv) {
	    my $arg = shift @argv;

	    if ($arg =~ /^(?:[0-9a-fA-F]{2})*$/i) {
		$code .= pack ("H*", $arg);
		next;
	    }
	    if ($arg eq '-') {
		$code .= $cpu->slurp_stdin();
		next;
	    }
	    if ($arg =~ /^push=(.*)$/) {
		$code .= pack("CV", 0x68, $1);
		next;
	    }
	    if ($code ne '') {
		$cpu->do($code);
		$count += length ($code);
		$code = '';
	    }
	    if ($arg =~ /(.*?)=(.*)/) {
		my ($reg, $val) = ($1, $2);

		if (not is_reg($reg)) {
		    die "Invalid register name '$reg'";
		}
		$val =~ s/^0x([0-9a-fA-F]+)$/hex($val)/ie;
		if ($val !~ /^\d$/) {
		    if (is_reg($val)) {
			$val = $cpu->can($val)->($cpu);
		    } else {
			$val = eval $val;
		    }
		}
		$cpu->can($reg)->($cpu, $val);
		next;
	    }
	    if ($arg =~ /dump(?:_regs)?/) {
		$cpu->dump_regs;
		next;
	    }
	    if ($arg =~ /^-?(.*)$/ && is_reg($1)) {
		my ($reg) = ($1);

		@argv && printf ("at 0x%x ", $count);
		printf ("$reg: %.$nibs{$reg}x\n", $cpu->can($reg)->($cpu));
		next;
	    }
	    die "Invalid arg '$arg'";
	}
	if ($code ne '') {
	    $cpu->do($code);
	    $cpu->dump_regs;
	}
    } else {
	$cpu->do(slurp_stdin());
	$cpu->dump_regs;
    }
}

1;
