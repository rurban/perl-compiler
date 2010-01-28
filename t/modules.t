# -*- cperl -*-
# t/modules.t - check if some common CPAN modules exist and
#               can be compiled successfully. Only B::C is fatal,
#               CC and Bytecode optional.

my @modules;
my @opts;
BEGIN {
  @modules =
    qw (
	Getopt::Long Params::Validate Path::Class Perl::Critic Test::Kwalitee

	IO DBI PPI Sub::Exporter Benchmark Moose
	CGI CGI::FormBuilder CGI::Session CGI::Application
	DBIx::Class Pod::Usage

	Template::Toolkit HTML::Mason HTML::Template
	Text::Template Any::Template Template::Alloy

	Pod::Escapes Pod::Simple Test::Pod Devel::Symdump Pod::Coverage
	Test::Pod::Coverage
	Compress::Raw::Bzip2 IO::Compress::Bzip2 Compress::Bzip2
        IO::String
        File::Temp Archive::Zip
	Math::BigInt::FastCalc
	Term::ReadKey Term::ReadLine::Perl Term::ReadLine::Gnu
        XML::NamespaceSupport XML::SAX XML::LibXML::Common XML::LibXML
	XML::Parser
	Proc::ProcessTable
	YAML Config::Tiny File::Copy::Recursive IPC::Run3 Probe::Perl
    	Tee IO::CaptureOutput File::pushd File::HomeDir
	Digest::SHA
	Module::Signature
        URI HTML::Tagset HTML::Parser LWP
	CPAN
	Net::IP Net::DNS Test::Reporter CPAN::Reporter
        Text::Glob Number::Compare File::Find::Rule Data::Compare CPAN::Checksums
	File::Remove File::chmod
        Params::Util Test::Script CPAN::Checksums CPAN::Inject
	Net::Telnet
	Module::ScanDeps PAR::Dist
	Socket6 IO::Socket::INET6
	B::Generate PadWalker Alias
      );
  @opts = (""); #, "-O", "-B"); # only B::C
  # @opts = ("", "-O", "-B");   # all backends
  print "1..", scalar @modules * scalar @opts, "\n";
}

my $i = 1;
for my $m (@modules) {
  unless (eval "require $m;") {
    for (1 .. @opts) {
      print "ok $i #skip no $m\n"; $i++;
    }
  }
  else {
    open F, ">", "mod.pl";
    print F "use $m;\nprint \"ok\";";
    close F;

    for my $opt (@opts) {
      if (`$^X -Mblib blib/script/perlcc $opt -r mod.pl` eq "ok") {
	print   "ok $i  #     perlcc -r $opt use $m\n";
      } else {
	if ($opt) {
	  print "ok $i  # TODO perlcc -r $opt no $m\n";
	} else {
	  print "nok $i #      perlcc -r $opt no $m\n";
	}
      }
      $i++;
    }

    unlink "mod.pl";
  }
}

END { unlink "mod.pl"; }
