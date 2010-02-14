use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use 5.006;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

# generate lib/B/Asmdata.pm beforehand
system("$^X bytecode.pl");

WriteMakefile(
    NAME	 => "B::C",
    VERSION_FROM => "lib/B/C.pm",
    PL_FILES   => { 'script/perlcc.PL'    => 'script/perlcc' },
    EXE_FILES  => [qw(script/perlcc script/cc_harness script/assemble script/disassemble)],
    PREREQ_PM  => {'Opcodes'  => '0',
		   'IPC::Run' => '0',
		  #'B'        => '1.0901'
                  },
    'AUTHOR'   => 'Malcolm Beattie <mbeattie@sable.ox.ac.uk>, Reini Urban <perl-compiler@googlegroups.com>',
    'ABSTRACT' => 'Perl compiler',
    (($ExtUtils::MakeMaker::VERSION gt '6.31' and $ExtUtils::MakeMaker::VERSION lt '6.46') ?
       ('EXTRA_META'  => "recommends:\n" .
        "    B::Debug:    1.12\n"
       ) : ()),
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  => {"recommends" =>
                       {
                        "B::Debug" => "1.12",
                        "IPC::Run" => 0,
                       },
                       resources =>
                       {
                        license     => 'http://dev.perl.org/licenses/',
                        homepage    => 'http://perl-compiler.googlecode.com',
                        bugtracker  => 'http://code.google.com/p/perl-compiler/issues',
                        repository  => 'http://perl-compiler.googlecode.com/svn/',
                        MailingList => 'http://groups.google.com/group/perl-compiler',
                       },
                      }
    ) : ()),
    SIGN  => 1,
    clean => { FILES =>
               "bytecode[0-9]* ccode[0-9]* cccode[0-9]* ".
               "lib/B/Asmdata.pm script/perlcc ".
 	       "*.core *.stackdump a.out a.exe *.cee *.c *.asm *.dbg *.plc *.obj ".
               "*.concise *~ dll.base dll.exp mod.pl pcc* *.err *.bak"
             },
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
    return 0 if $] < 5.007 and $_[1] =~ /ByteLoader|Asmdata\.pm|Bytecode\.pm|Assembler\.pm/;
    return $_[1];
}


# XXX Fix ActivePerl for MSVC6
# The linker for cl 12.0.8804 has no -opt:ref,icf. Looks like a msvc8 linker syntax.
sub const_config {
    my $s = shift->SUPER::const_config(@_);
    if ($Config::Config{ccversion} eq '12.0.8804' and $Config::Config{cc} eq 'cl') {
	$s =~ s/ -opt:ref,icf//gm;
    }
    $s
}

sub post_constants {
    "\nLIBS = $Config::Config{libs}\n";
}

sub ccflags {
    my $ccflags = shift->SUPER::ccflags(@_);
    return $ccflags unless -d ".svn";
    # Recommended by http://www.network-theory.co.uk/docs/gccintro/gccintro_32.html
    # -ansi -pedantic -Wall -W -Wconversion -Wshadow -Wcast-qual -Wwrite-strings (-W => -WExtra)
    $ccflags .= " -ansi -pedantic -Wall -Wextra -Wconversion -Wshadow -Wcast-qual -Wwrite-strings" if $Config{cc} =~ /gcc/;
}

sub depend {
    my $headerpath = main::headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h sv.h);
    my $asmdata = File::Spec->catfile('lib', 'B', 'Asmdata.pm');
    my $byterun_c = File::Spec->catfile('ByteLoader', 'byterun.c');
    my $byterun_h = File::Spec->catfile('ByteLoader', 'byterun.h');
    my $result = "
C.c : C.xs Makefile

$asmdata : Makefile bytecode.pl @headers
	\$(PERL) bytecode.pl

$byterun_c : Makefile bytecode.pl @headers
	\$(PERL) bytecode.pl

$byterun_h : Makefile bytecode.pl @headers
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
