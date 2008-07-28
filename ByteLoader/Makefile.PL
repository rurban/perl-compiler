use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'ByteLoader',
    VERSION_FROM	=> 'ByteLoader.pm',
    XSPROTOARG		=> '-noprototypes',
    OBJECT		=> 'byterun$(OBJ_EXT) jitrun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',
);

sub MY::depend {
  my $up = File::Spec->updir;
  my $bytecode_pl = File::Spec->catdir( '..', 'bytecode.pl' );
  my $jitcompiler_pl = File::Spec->catdir( '..', 'jitcompiler.pl' );
  "
byterun.c : $bytecode_pl
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

jitrun.c : $bytecode_pl $jitcompiler_pl
	cd $up && \$(PERL) jitcompiler.pl && cd ByteLoader

byterun.h : $bytecode_pl
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

ByteLoader\$(OBJ_EXT) : byterun.h byterun.c jitrun.c bytecode.h

"
}
