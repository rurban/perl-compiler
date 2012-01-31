use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use 5.006;
use Carp;

WriteMakefile(
    'NAME'	 => "B::Stash",
    'VERSION_FROM' => "Stash.pm",
    'AUTHOR'   => 'Reini Urban <perl-compiler@googlegroups.com>',
    'ABSTRACT' => 'Perl compiler',
    'LICENSE'  => 'perl',
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
      ('META_MERGE'  =>
       {
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
);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
