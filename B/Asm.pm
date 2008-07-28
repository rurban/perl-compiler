#      Asm.pm
#
#      Copyright (c) 2008 Reini Urban
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.

package B::Asm;

# Use a two-pass compilation
# first walk the ops and mark type and jmp and register optimizations,
# second assemble the code from the perl ops with stack handling or our optimized ops.

1;

__END__

=head1 NAME

B::Asm - Assemble Perl native code, cpu dependant

=head1 SYNOPSIS

	use B::Asm qw(newasm endasm assemble);
	use B::Asm qw(assemble_fh);
	assemble_fh($fh, \&printsub);	# assemble everything in $fh

=head1 DESCRIPTION

Use high-level Perl to write and run readable assembler code for all perl
opcodes and possible optimizations. In contrast to the L<B::Jit> backend, which
uses the GNU lightning backend and a lot of low-level C macros.

  create the code - aka compile
  save the code   - as PLJC .plc - easy,
                    or as executable in PE/COFF or Elf, aka link - hard.
		    See my L<C::Dynalib> pl2exe or Audreys L<Win32::Exe> for
		    writing PE/COFF and see libjit or GNU binutils for dumping ELF.
  run the code    - setup sighandlers, load the code from a file (just for .plc)
                    and jump into the entry point. no JIT'ing.

Since the name B::Assembler is given away to the Bytecode assembler, B::Asm is
the native code assembler.

See also L<B::Jit>.

=head1 COMPILER

Use a two-pass compilation.

First walk the ops and mark type and jmp and register optimizations,
second assemble the code from the perl ops with stack handling or
our optimized ops.

=head1 LINKER

Either dump to a .plc file with ByteLoader interpretation - easy.

Or dump directly as executable in PE/COFF or Elf, aka link - hard.
See my L<C::Dynalib> pl2exe or Audreys L<Win32::Exe> for
writing PE/COFF and see libjit or GNU binutils for dumping ELF.

=head1 RUN

Only needed for .plc files.

Same as B::Jit, using F<jitrun.c>. Filter the .plc code from the DATA handle,
setup he sighandlers and jump into the PLJC code.

=head1 AUTHORS

Reini Urban <rurban@cpan.org>

=cut
