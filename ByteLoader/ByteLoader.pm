package ByteLoader;

use XSLoader ();

our $VERSION = '0.06_02';
# XSLoader problem:
# ByteLoader version 0.0601 required--this is only version 0.06_01 at ./bytecode2.plc line 2.
# on use ByteLoader $ByteLoader::VERSION;
# Fixed with use ByteLoader '$ByteLoader::VERSION';

if ($] < 5.009 and $VERSION eq '0.06_02') {
  XSLoader::load 'ByteLoader'; # fake the old backwards compatible version
} else {
  XSLoader::load 'ByteLoader', $VERSION;
}

1;
__END__

=head1 NAME

ByteLoader - load byte compiled perl code

=head1 SYNOPSIS

  use ByteLoader 0.07;
  <byte code>

  perl -MByteLoader bytecode_file

  perl -MO=Bytecode,-H,-ofile.plc file.pl
  ./file.plc

=head1 DESCRIPTION

This module is used to load byte compiled perl code as produced by
C<perl -MO=Bytecode=...>. It uses the source filter mechanism to read
the byte code and insert it into the compiled code at the appropriate point.

=head1 AUTHOR

Tom Hughes <tom@compton.nu> based on the ideas of Tim Bunce and others.
Many changes by Enache Adrian <enache@rdslink.ro> 2003 a.d.
and Reini Urban <rurban@cpan.org> 2008.

=head1 SEE ALSO

perl(1).

=cut
