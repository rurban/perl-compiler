use ExtUtils::MakeMaker;
use Config;
my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;
my $ccflags   = $Config{ccflags};
my $lddlflags = $Config{lddlflags};
if ($^O eq 'cygwin'
    and $Config{gccversion} eq '4.3.4 20090804 (release) 1') # possible bug
{
    $ccflags   =~ s/ -fstack-protector//;
    $lddlflags =~ s/ -fstack-protector//;
}

WriteMakefile(
    NAME		=> 'ByteLoader',
    VERSION_FROM	=> 'ByteLoader.pm',
    XSPROTOARG		=> '-noprototypes',
    OBJECT		=> 'byterun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',
    LDDLFLAGS           => $lddlflags,
    CCFLAGS             => $ccflags,
    clean => { FILES =>
               "byterun.* *.core *.stackdump a.out *.c *.o *~"},

);

sub MY::depend {
  my $up = File::Spec->updir;
  my ($bytecode_pl);
  if ($core) {
    $bytecode_pl = File::Spec->catdir( 'ByteLoader', 'bytecode.pl' );
  } else {
    $bytecode_pl = File::Spec->catdir( '..', 'bytecode.pl' );
  }
  return "
\$(INST_LIB)/ByteLoader.pm : ByteLoader.pm
	\$(NOECHO) \$(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', '\''$(PM_FILTER)'\'')' -- \
	  ByteLoader.pm \$(INST_LIB)/ByteLoader.pm

byterun.c : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

byterun.h : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

ByteLoader.c: byterun.h Makefile

ByteLoader\$(OBJ_EXT) : byterun.h byterun.c bytecode.h Makefile

"
}
