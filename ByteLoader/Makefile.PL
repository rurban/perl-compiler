use ExtUtils::MakeMaker;
my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME		=> 'ByteLoader',
    VERSION_FROM	=> 'ByteLoader.pm',
    XSPROTOARG		=> '-noprototypes',
    OBJECT		=> 'byterun$(OBJ_EXT) ByteLoader$(OBJ_EXT)',
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
byterun.c : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

byterun.h : $bytecode_pl Makefile
	cd $up && \$(PERL) bytecode.pl && cd ByteLoader

ByteLoader.c: byterun.h Makefile

ByteLoader\$(OBJ_EXT) : byterun.h byterun.c bytecode.h Makefile

"
}
