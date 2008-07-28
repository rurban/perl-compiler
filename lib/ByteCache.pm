package ByteCache;

require 5.006;
use strict;
use warnings;
our $VERSION = '0.04';

BEGIN {
  use Config ();
  use File::Spec::Functions ();
  unshift @INC,
    File::Spec::Functions::catdir($Config::Config{sitearch},"byte"),
    \&ByteCache::bytecacher;

  use File::Path ();
  use File::Basename ();

  my $caching = 1 unless $^P; # unless debugging

  sub bytecacher {
     # Woah, don't fall into that trap again
     return undef if $_[1] eq "ByteLoader.pm" or $_[1] eq "XSLoader.pm";
     return undef unless $caching;

     my ($current, $output, $curdir);
     if (-e $INC{$_[1]}) {
       $current = $INC{$_[1]};
       $curdir = File::Basename::dirname($current);
     } else {
       for (@INC) {
	 if (-e ($current = File::Spec::Functions::catfile($_,$_[1]))) {
	   $curdir = File::Basename::dirname($current);
	 }
       }
     }
     return undef unless $current;

     # If curdir is writable, use current.pmc as supported by the core
     if (-w $curdir) {
       $output = $current . "c";
     }
     else {
       $output=File::Spec::Functions::catfile($Config::Config{sitearch},"byte",$_[1]);
       my $outputdir = File::Basename::dirname($output);
       unless (-d $outputdir or File::Path::mkpath($outputdir)) {
	 warn "Can't create $outputdir, not byte caching.\n";
	 return undef;
       }
     }
     # Bytecompile, store and return filehandle.
     warn "# Compiling $_[1]\n";
     if (system($^X, "-MO=-qq,Bytecode,-H,-o$output", $current) < 0) {
       warn "Couldn't call the Bytecode compiler.\n";
       $caching = 0;
     }
     if (-e $output) {
       open(FH, $output);
       binmode FH;
       return *FH;
     }
   }
}

1;

=head1 NAME

ByteCache - byte-compile modules when needed

=head1 SYNOPSIS

     use ByteCache;
     use Other::Module;

=head1 DESCRIPTION

This module causes any modules loaded after it to be loaded in bytecode
compiled format. If a bytecode compiled version of the module does not
currently exist, ByteCache will call the compiler to create one and
then save it away.

=head1 WARNING

This module is dependent on the compiler suite, and is therefore B<very>
experimental. Your results may vary. Do not use in production systems.

=head1 AUTHOR

Simon Cozens, C<simon@brecon.co.uk>

=head1 SEE ALSO

L<perl>, L<perlcc>, L<ByteLoader>
