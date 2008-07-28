use ExtUtils::MakeMaker;
use Config;
use File::Spec;
#use 5.009005;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME	    => "B::C",
    VERSION_FROM    => "lib/B/C.pm",
	         # 'scripts/assemble','scripts/disassemble',
    PL_FILES => {'script/perlcc.PL'  => '$(INST_BIN)/perlcc' },
    PREREQ_PM 	    => {
	'B::Concise' => '0.66', # 0.74
	'B' => '1.0901',        # 1.17
    },
    ($] >= 5.005 ?
     ('AUTHOR' => 'Malcolm Beattie <mbeattie@sable.ox.ac.uk>',
      'ABSTRACT' => 'perl compiler') : ()),
    clean => { FILES => "bytecode[1-9]* cccode[1-9]* ccode[1-9]* *.core *.stackdump ".
	                "a.out *.cee *.c *.asm *.dbg *.plc *.concise *~"},
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
  # ignore temp testing files
  return 0 if $_[1] =~ /(bytecode.*\.pl|ccode\d+\..*|regen_lib\.pl|-588\.pod)$/;
  return $_[1];
}

sub post_constants {
    "\nLIBS = $Config::Config{libs}\n"
}

sub depend {
    my $headerpath = main::headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h sv.h);
    my $asmdata = File::Spec->catfile('lib', 'B', 'Asmdata.pm');
    my $byterun_c = File::Spec->catfile('ByteLoader', 'byterun.c');
    my $byterun_h = File::Spec->catfile('ByteLoader', 'byterun.h');
    my $perlcc_inst = File::Spec->catfile('$(INST_BIN)', 'perlcc');
    my $perlcc_exp = File::Spec->catfile('script', 'perlcc.PL');
    my $result = "
$perlcc_inst :: $perlcc_exp
	\$(CP) $perlcc_exp $perlcc_inst

C.c : C.xs Makefile

$asmdata : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl

$byterun_c : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl

$byterun_h : bytecode.pl @headers Makefile
	\$(PERL) bytecode.pl
";
    $result = "test :: subdirs-test\n\n" if $] > 5.009;
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
