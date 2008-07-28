use ExtUtils::MakeMaker;
my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME		=> 'ByteLoader',
    VERSION_FROM	=> 'ByteLoader.pm',
    XSPROTOARG		=> '-noprototypes',
    OBJECT		=> 'byterun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',
);
#    OBJECT		=> 'byterun$(OBJ_EXT) jitrun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',

sub MY::depend {
  my $up = File::Spec->updir;
  my ($bytecode_pl, $jitcompiler_pl);
  if ($core) {
    $bytecode_pl = File::Spec->catdir( 'ByteLoader', 'bytecode.pl' );
    $jitcompiler_pl = File::Spec->catdir( 'ByteLoader', 'jitcompiler.pl' );
  } else {
    $bytecode_pl = File::Spec->catdir( '..', 'bytecode.pl' );
    $jitcompiler_pl = File::Spec->catdir( '..', 'jitcompiler.pl' );
  }
  return "
byterun.c : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

byterun.h : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

jitrun.c : $jitcompiler_pl Makefile
	cd $up && \$(PERL) jitcompiler.pl && cd ByteLoader

jitrun.h : $jitcompiler_pl Makefile
	cd $up && \$(PERL) jitcompiler.pl && cd ByteLoader

ByteLoader.c: byterun.h jitrun.h Makefile

ByteLoader\$(OBJ_EXT) : byterun.h byterun.c jitrun.c bytecode.h Makefile

"
}
