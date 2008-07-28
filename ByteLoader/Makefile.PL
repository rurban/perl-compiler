use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'ByteLoader',
    VERSION_FROM	=> 'ByteLoader.pm',
    XSPROTOARG		=> '-noprototypes',
    OBJECT		=> 'byterun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',
);

sub MY::depend {
  my $up = File::Spec->updir;
  my $bytecode_pl = File::Spec->catdir( '..', 'bytecode.pl' );
  "
byterun.c : $bytecode_pl
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

byterun.h : $bytecode_pl
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

ByteLoader\$(OBJ_EXT) : byterun.h byterun.c bytecode.h

"
}
