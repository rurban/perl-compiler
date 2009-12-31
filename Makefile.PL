use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use 5.006;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME	 => "B::C",
    VERSION_FROM => "lib/B/C.pm",
    PL_FILES   => { 'script/perlcc.PL'    => 'script/perlcc' },
    EXE_FILES  => [qw(script/perlcc script/cc_harness script/assemble script/disassemble)],
    #PREREQ_PM => {'B::Concise' => '0.66',
    #	           'B'          => '1.0901'},
    'AUTHOR'   => 'Malcolm Beattie <mbeattie@sable.ox.ac.uk>, Reini Urban <rurban@cpan.org>',
    'ABSTRACT' => 'Perl compiler',
    # ($ExtUtils::MakeMaker::VERSION gt '6.31' ?
    #    ('EXTRA_META'  => "recommends:\n" .
    #     "    B::Debug:    1.11\n"
    #    ) : ()),
    SIGN  => 1,
    clean => { FILES =>
               "bytecode[0-9]* ccode[0-9]* cccode[0-9]* ".
 	       "*.core *.stackdump a.out a.exe *.cee *.c *.asm *.dbg *.plc *.obj".
               "*.concise *~ dll.base dll.exp"},
);

sub headerpath {
    if ($core) {
	return File::Spec->catdir(File::Spec->updir,
				  File::Spec->updir);
    } else {
	return File::Spec->catdir($Config::Config{archlibexp}, "CORE");
    }
}

package MY;

sub libscan {
  # Ignore temp testing files
  return 0 if $_[1] =~ /^(.svn|jit.*|i386|.*\.orig|bytecode.*\.pl|c?ccode\d+\..*|regen_lib\.pl)$/;
  # Ignore Bytecode on 5.6 for now. The 5.6 CORE module produces better code (until fixed :)
  # Not even the Byteloader works for 5.6 assembled code. The Disassembler does not stop at ret.
  #return 0 if $] < 5.007 and $_[1] =~ /ByteLoader|Asmdata\.pm|Bytecode\.pm|Assembler\.pm/;
  return $_[1];
}

sub post_constants {
    "\nLIBS = $Config::Config{libs}\n"
}

sub ccflags {
  my $ccflags = shift->SUPER::ccflags(@_);
  return $ccflags unless -d ".svn";
  $ccflags .= " -ansi -Wall -Wextra -pedantic" if $Config{cc} =~ /gcc/;
}

sub depend {
    my $headerpath = main::headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h sv.h);
    my $asmdata = File::Spec->catfile('lib', 'B', 'Asmdata.pm');
    my $byterun_c = File::Spec->catfile('ByteLoader', 'byterun.c');
    my $byterun_h = File::Spec->catfile('ByteLoader', 'byterun.h');
    my $result = "
C.c : C.xs Makefile

$asmdata : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl

$byterun_c : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl

$byterun_h : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl
";
    $result .= "\ntest :: subdirs-test\n\n" if $] > 5.009;
    $result;
}

=pod

=for CORE only

sub postamble {
    my $headerpath = main::headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h);
    my $noecho = shift->{NOECHO};

"
B\$(OBJ_EXT) : defsubs.h

defsubs.h :: @headers defsubs_h.PL
	\$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) defsubs_h.PL defsubs.h $headerpath
"
}

sub processPL {
    my $text = shift->SUPER::processPL(@_);
    # Append our extra parameter
    $text =~ s/^\t.*defsubs_h\.PL.*/$& . ' ' . main::headerpath()/me;
    $text;
}

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
