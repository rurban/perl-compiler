use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use 5.006;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

# generate lib/B/Asmdata.pm beforehand
system("$^X bytecode.pl");

my ($use_declare_independent_comalloc, $extra_cflags, $extra_libs) = (0, "", "");
my $have_independent_comalloc = &check_independent_comalloc;
{
    my ($e_c) = grep { /-extra-cflags[= ](.+)/ } @ARGV;
    my ($e_l) = grep { /-extra-libs[= ](.+)/ } @ARGV;
    $extra_cflags .= " $e_c" if $e_c;
    $extra_libs .= " $e_l" if $e_l;
}
# cygwin still has the old gdb-6 debugger which does not understand dwarf4 features from gcc-4.5
#if ($Config{gccversion} =~ /^4\.[56]\./) {
#    my $gdb_ver = `gdb --version`;
#    if ($gdb_ver =~ /gdb 6\./) {
#        print "Adding extra_cflags=-gstrict-dwarf for gcc-4.5 for a gdb-6 debugger which does not understand dwarf4 features\n";
#        $extra_cflags .= " -gstrict-dwarf";
#    }
#}
sub write_b_c_flags {
    mkdir "lib/B/C" unless -d "lib/B/C";
    open PH, ">", "lib/B/C/Flags.pm";
    print PH "# written by B::C Makefile.PL. \$extra_{cflags,libs} need a leading space if used.\n";
    print PH "package B::C::Flags;\n\n";
    print PH "# -fav-init optimization\n";
    print PH "\$have_independent_comalloc = $have_independent_comalloc;\n";
    print PH "\$use_declare_independent_comalloc = $use_declare_independent_comalloc;\n\n";
    print PH "# use extra compiler flags, after ccopts, resp. ldopts\n";
    print PH "\$extra_cflags = \"$extra_cflags\";\n";
    print PH "\$extra_libs = \"$extra_libs\";\n";
    print PH "\n1;\n";
    close PH;
    chmod (0644, "lib/B/C/Flags.pm");
}
write_b_c_flags;

WriteMakefile(
    NAME	 => "B::C",
    VERSION_FROM => "lib/B/C.pm",
    PL_FILES   => { 'script/perlcc.PL'    => 'script/perlcc' },
    EXE_FILES  => [qw(script/perlcc script/cc_harness script/assemble script/disassemble)],
    PREREQ_PM  => {'Opcodes'  => '0',
		   'IPC::Run' => '0',
		   'B::Flags' => '0.04',
		   'Time::HiRes' => '0',
                   #'B'        => '1.0901'
                  },
    'AUTHOR'   => 'Malcolm Beattie (retired), '
	      .   'Reini Urban <perl-compiler@googlegroups.com>',
    'ABSTRACT' => 'Perl compiler',
    (($ExtUtils::MakeMaker::VERSION gt '6.31' and $ExtUtils::MakeMaker::VERSION lt '6.46') ?
       ('EXTRA_META'  => "recommends:\n" .
        "    B::Debug:  1.16\n".
        "    Opcodes:   0.9\n".
        "    IPC::Run:  0\n",
       ) : ()),
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  => {"recommends" =>
                       {
                        "B::Debug" => '1.16',
                        "Opcodes"  => '0.9',
                        "IPC::Run" => 0,
                       },
                       resources =>
                       {
                        license     => 'http://dev.perl.org/licenses/',
                        homepage    => 'http://www.perl-compiler.org',
                        bugtracker  => 'http://code.google.com/p/perl-compiler/issues',
                        repository  => 'http://perl-compiler.googlecode.com/',
                        MailingList => 'http://groups.google.com/group/perl-compiler',
                       },
                      }
    ) : ()),
    SIGN  => 1,
    clean => { FILES =>
               "bytecode[0-9]* ".
               "lib/B/Asmdata.pm script/perlcc ccode* cccode* Ccode* ".
 	       "*.core *.stackdump a.out a.exe *.cee *.c *.asm *.dbg *.plc *.obj ".
               "*.concise *~ dll.base dll.exp mod.pl pcc* *.bak"
             },
);

# EUMM has a problem. If a subproject has a XS but main not,
# main needs the dynamic+dynamic_lib target. So we create an unused dummy target.
# MSWin32 is quite strict, so we need a full XS, other targets do not care.
# touch C.c is enough there.
# XXX Some old 5.6. tests (which exactly?) still fail on regex, so we better keep
# the old xs and just do not use bootstrap it.
if (0) {
    open my $c, ">", "C.c";
    if ($^O =~ /MSWin32|AIX/) {
        print $c <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
extern "C"
#endif
XS(B__C);
XS(B__C) { 1; }
EOF
    } else {
        print $c "/* dummy */\n";
    }
    close $c;
}

sub headerpath {
    if ($core) {
	return File::Spec->catdir(File::Spec->updir,
				  File::Spec->updir);
    } else {
	return File::Spec->catdir($Config::Config{archlibexp}, "CORE");
    }
}

# Check for Doug Lea's dlmalloc version, or ptmalloc2 included in glibc
# or an extra ptmalloc3.
# This improves -fav-init startup speed dramatically (18% tested).
# ptmalloc3 needs #include <malloc-2.8.3.h>, but we don't want to clash
# with an existing malloc.h from perl.h, so we declare it by ourselves.
sub try_compile {
    my $testc = shift;
    my $libs = shift;
    unless (open PROG, ">", "test.c") {
	print ("Can't write test.c\n");
	return 0;
    }
    print PROG $testc;
    close PROG;
    @candidate = ();
    $devnull = $^O eq 'MSWin32' ? "> NUL" : ">/dev/null 2>&1";
    my $cmd = "$Config{cc} $Config{ccflags} test.c";
    push @candidate, "$cmd -o test$Config{EXE_EXT} $libs $devnull";
    push @candidate, "$cmd -otest$Config{EXE_EXT} $libs $devnull";
    while (my $cmd1 = shift (@candidate)) {
	system ($cmd1);
	unlink "test.c", "test$Config{EXE_EXT}";
	$? == 0 && return 1;
    }
    return 0;
}

sub check_independent_comalloc {
    my $testc = "
#include <stdlib.h>
#include <malloc.h>
int main() {
    void* chunks[3];
    size_t sizes[3] = {3,25,4};
    if (independent_comalloc( 3, sizes, chunks ) == 0) { exit(1); };
    return 0;
}
";
    try_compile($testc) and return 1;

    my @extra_libs = ("-lptmalloc3", "-lptmalloc", "-ldlmalloc", "-lnedmalloc");
    for my $lib (@extra_libs) {
        $lib =~ s/^-l(.+)$/lib$1.lib/ if $^O eq 'MSWin32';
        if (try_compile($testc, $lib)) {
            $extra_libs = " $lib";
            return 1;
        }
    }

    my $testc =~ s/#include <malloc.h>/void** dlindependent_comalloc(size_t, size_t*, void**);/;
    for my $lib (@extra_libs) {
        $lib =~ s/^-l(.+)$/lib$1.lib/ if $^O eq 'MSWin32';
        if (try_compile($testc, $lib)) {
            $extra_libs = " $lib";
            $use_declare_independent_comalloc = 1;
            return 1;
        }
    }

    return 0;
}

package MY;

sub libscan {
    # Ignore temp testing files
    return 0 if $_[1] =~ /^(.svn|jit.*|i386|.*\.orig|bytecode.*\.pl|c?ccode.*|regen_lib\.pl)$/;
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
    my $libs = "\nLIBS = $Config::Config{libs}";
    $libs .= " -lptmalloc3" if $use_ptmalloc3;
    #XXX PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc
    return "$libs\n";
}

sub ccflags {
    my $ccflags = shift->SUPER::ccflags(@_);
    $ccflags .= " -DHAVE_INDEPENDENT_COMALLOC" if $have_independent_comalloc;
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

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
