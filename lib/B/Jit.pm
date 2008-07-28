#      Jit.pm
#
#      Copyright (c) 2008 Reini Urban
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.

package B::Jit;

1;


__END__

=head1 NAME

B::Jit - Just-in-time Perl compiler, cpu dependant

=head1 DESCRIPTION

Use GNU lightning to create jit code into some memory buffer in .text

  create the code - aka compile
  save the code   - as PLJC .plc -easy,
                    or as executable in PE/COFF or Elf, aka link
  run the code    - setup sighandlers and jump into the entry point.
                    default: do this on the fly, after the optree compilation
                    for some memory buffer.

Low-level jit macros for all ops and possible optimizations, in contrast
to the L<B::Asm> backend, which uses high-level Perl for the asm ops.

=head1 AUTHORS

Reini Urban <rurban@cpan.org>

=cut
