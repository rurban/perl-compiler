use ExtUtils::MakeMaker;
use Config;
use File::Spec;

my $core = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
    NAME	    => "B::C",
    VERSION_FROM    => "B/C.pm",
	      # 'scripts/assemble','scripts/disassemble',
    EXE_FILES => [ 'scripts/cc_harness','scripts/perlcc' ],
    PREREQ_PM 	    => {
	'B::Concise' => '0.74',
	'B' => '1.17',
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

sub post_constants {
    "\nLIBS = $Config::Config{libs}\n"
}

sub depend {
    my $headerpath = main::headerpath();
    my @headers = map { File::Spec->catfile($headerpath, $_) } qw(op.h cop.h sv.h);
    my $asmdata = File::Spec->catfile('B', 'Asmdata.pm');
    my $byterun_c = File::Spec->catfile('ByteLoader', 'byterun.c');
    my $byterun_h = File::Spec->catfile('ByteLoader', 'byterun.h');
    my $perlcc = File::Spec->catfile('scripts', 'perlcc');
    "
$perlcc : $perlcc.PL
	\$(PERL) $perlcc.PL

$asmdata : bytecode.pl @headers
	\$(PERL) bytecode.pl

$byterun_c : bytecode.pl @headers
	\$(PERL) bytecode.pl

$byterun_h : bytecode.pl @headers
	\$(PERL) bytecode.pl
"
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
