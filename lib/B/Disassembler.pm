#      Disassembler.pm
#
#      Copyright (c) 1996 Malcolm Beattie
#      Copyright (c) 2008 Reini Urban
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.

$B::Disassembler::VERSION = '1.05_03';

package B::Disassembler::BytecodeStream;

use FileHandle;
use Carp;
use Config qw(%Config);
use B qw(cstring cast_I32);
@ISA = qw(FileHandle);

sub readn {
  my ( $fh, $len ) = @_;
  my $data;
  read( $fh, $data, $len );
  croak "reached EOF while reading $len bytes" unless length($data) == $len;
  return $data;
}

sub GET_U8 {
  my $fh = shift;
  my $c  = $fh->getc;
  croak "reached EOF while reading U8" unless defined($c);
  return ord($c);
}

sub GET_U16 {
  my $fh  = shift;
  my $str = $fh->readn(2);
  croak "reached EOF while reading U16" unless length($str) == 2;

  # Todo: check byteorder
  return unpack( "S", $str );
}

sub GET_NV {
  my $fh = shift;
  my ( $str, $c );
  while ( defined( $c = $fh->getc ) && $c ne "\0" ) {
    $str .= $c;
  }
  croak "reached EOF while reading double" unless defined($c);
  return $str;
}

sub GET_U32 {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading U32" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_I32 {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading I32" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "l", $str );
}

sub GET_objindex {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading objindex" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_opindex {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading opindex" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_svindex {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading svindex" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_pvindex {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading pvindex" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_hekindex {
  my $fh  = shift;
  my $str = $fh->readn(4);
  croak "reached EOF while reading hekindex" unless length($str) == 4;

  # Todo: check byteorder
  return unpack( "L", $str );
}

sub GET_strconst {
  my $fh = shift;
  my ( $str, $c );
  $str = '';
  while ( defined( $c = $fh->getc ) && $c ne "\0" ) {
    $str .= $c;
  }
  croak "reached EOF while reading strconst" unless defined($c);
  return cstring($str);
}

sub GET_pvcontents { }

sub GET_PV {
  my $fh = shift;
  my $str;
  my $len = $fh->GET_U32;
  if ($len) {
    read( $fh, $str, $len );
    croak "reached EOF while reading PV" unless length($str) == $len;
    return cstring($str);
  }
  else {
    return '""';
  }
}

sub GET_comment_t {
  my $fh = shift;
  my ( $str, $c );
  while ( defined( $c = $fh->getc ) && $c ne "\n" ) {
    $str .= $c;
  }
  croak "reached EOF while reading comment" unless defined($c);
  return cstring($str);
}

sub GET_double {
  my $fh = shift;
  my ( $str, $c );
  while ( defined( $c = $fh->getc ) && $c ne "\0" ) {
    $str .= $c;
  }
  croak "reached EOF while reading double" unless defined($c);
  return $str;
}

sub GET_none { }

sub GET_op_tr_array {
  my $fh  = shift;
  my $len = unpack "S", $fh->readn(2);
  my @ary = unpack "S*", $fh->readn( $len * 2 );
  return join( ",", $len, @ary );
}

sub GET_IV64 {
  my $fh  = shift;
  my $str = $fh->readn(8);
  croak "reached EOF while reading I32" unless length($str) == 8;

  # Todo: check byteorder
  return sprintf "0x%09llx", unpack( "q", $str );
}

sub GET_IV {

  # Check the header settings, not the current settings.
  $B::Disassembler::ivsize == 4 ? &GET_I32 : &GET_IV64;

  #$Config{ivsize} == 4 ? &GET_I32 : &GET_IV64;
}

sub GET_PADOFFSET {

  # Check the header settings, not the current settings.
  $B::Disassembler::ptrsize == 8 ? &GET_IV64 : &GET_U32;

  # $Config{ptrsize} == 8 ? &GET_IV64 : &GET_U32;
}

sub GET_long {

  # FIXME: this should check the header settings, not the current settings.
  # B::Disassembler::ivsize ?
  $Config{longsize} == 8 ? &GET_IV64 : &GET_U32;
}

package B::Disassembler;
use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(disassemble_fh get_header print_insn print_insn_bare @opname);
use Carp;
use strict;
use B::Asmdata qw(%insn_data @insn_name);
use Opcode qw(opset_to_ops full_opset);
use Config qw(%Config);

my $opix;
our @opname = opset_to_ops(full_opset);
our (
  $magic,   $archname, $blversion, $ivsize,
  $ptrsize, $longsize, $byteorder, $archflag
);

sub dis_header($) {
  my ($fh) = @_;
  $magic = $fh->GET_U32();
  warn("bad magic") if $magic != 0x43424c50;
  $archname  = $fh->GET_strconst();
  $blversion = $fh->GET_strconst();
  $ivsize    = $fh->GET_U32();
  $ptrsize   = $fh->GET_U32();
  if ( $blversion ge '"0.06_03"' ) {
    $longsize = $fh->GET_U32();
  }
  else {
    $longsize = $Config{longsize};
  }
  $byteorder = $fh->GET_strconst();
  if ( $blversion ge '"0.06_05"' ) {
    $archflag = $fh->GET_U16();
  }
  else {
    $archflag = -1;
  }
}

sub get_header() {
  if (wantarray) {
    return (
      $magic,   $archname,  $blversion, $ivsize,
      $ptrsize, $byteorder, $longsize,  $archflag
    );
  }
  else {
    return {
      magic     => $magic,
      archname  => $archname,
      blversion => $blversion,
      ivsize    => $ivsize,
      ptrsize   => $ptrsize,
      byteorder => $byteorder,
      longsize  => $longsize,
      archflag  => $archflag
    };
  }
}

sub print_insn {
  my ( $insn, $arg, $comment ) = @_;
  undef $comment unless $comment;
  if ( defined($arg) ) {
    if ( $insn eq 'newopx' or $insn eq 'ldop' ) {    # threaded or unthreaded
      my $type = $arg >> 7;
      my $size = $arg - ( $type << 7 );
      $arg .= sprintf( " \t# size:%d, type:%d %s", $size, $type ) if $comment;
      printf "\n# [%s %d]\n", $opname[$type], $opix++ if $comment;
    }
    elsif ( !$comment ) {
      ;
    }
    elsif ( $insn eq 'newsvx' ) {

      # TODO which type? SV, AV or GV. check arg
      $arg .= "\t# " . $comment if $comment ne '1';
      printf "\n# [%s]\n", 'SV';
    }
    elsif ( $insn eq 'gv_stashpvx' ) {
      $arg .= "\t# " . $comment if $comment ne '1';
      printf "\n# [%s]\n", "STASH";
    }
    elsif ( $insn eq 'ldsv' ) {

      # TODO which type? SV, AV or GV. check arg
      $arg .= "\t# " . $comment if $comment ne '1';
      printf "\n# -%s-\n", 'SV';
    }
    elsif ( $insn eq 'gv_fetchpvx' ) {
      $arg .= "\t# " . $comment if $comment ne '1';
      printf "\n# [%s]\n", 'prototype';
    }
    else {
      $arg .= "\t# " . $comment if $comment ne '1';
    }
    printf "%s %s\n", $insn, $arg;
  }
  else {
    $insn .= "\t# " . $comment if $comment ne '1';
    print $insn, "\n";
  }
}

sub print_insn_bare {
  my ( $insn, $arg ) = @_;
  if ( defined($arg) ) {
    printf "%s %s\n", $insn, $arg;
  }
  else {
    print $insn, "\n";
  }
}

sub disassemble_fh {
  my $fh      = shift;
  my $out     = shift;
  my $verbose = shift;
  my ( $c, $getmeth, $insn, $arg );
  $opix = 1;
  bless $fh, "B::Disassembler::BytecodeStream";
  dis_header($fh);
  if ($verbose) {
    printf "#magic     0x%x\n", $magic; #0x43424c50
    printf "#archname  %s\n", $archname;
    printf "#blversion %s\n", $blversion;
    printf "#ivsize    %d\n", $ivsize;
    printf "#ptrsize   %d\n", $ptrsize;
    printf "#byteorder %s\n", $byteorder;
    printf "#longsize  %d\n", $longsize;
    printf "#archflag  %d\n\n", $archflag;
  }
  while ( defined( $c = $fh->getc ) ) {
    $c    = ord($c);
    $insn = $insn_name[$c];
    if ( !defined($insn) || $insn eq "unused" ) {
      my $pos = $fh->tell - 1;
      die "Illegal instruction code $c at stream offset $pos\n";
    }
    $getmeth = $insn_data{$insn}->[2];
    $arg     = $fh->$getmeth();
    if ( defined($arg) ) {
      &$out( $insn, $arg, $verbose );
    }
    else {
      &$out( $insn, undef, $verbose );
    }
  }
}

1;

__END__

=head1 NAME

B::Disassembler - Disassemble Perl bytecode

=head1 SYNOPSIS

	use Disassembler qw(print_insn);
        my $fh = new FileHandle "<$ARGV[0]";
	disassemble_fh($fh, \&print_insn);

=head1 DESCRIPTION

disassemble_fh takes an filehandle with bytecode and a printer function.
The printer function gets three arguments: insn, arg (optional) and the comment.

Two default printer functions are provided:
  print_insn print_insn_bare

See F<lib/B/Disassembler.pm> and F<scripts/disassemble>.

=head1 disassemble_fh (filehandle, printer_coderef, [ verbose ])

disassemble_fh takes an filehandle with bytecode and a printer coderef.

Two default printer functions are provided:

  print_insn 
  print_insn_bare

=head1 print_insn

Callback function for disassemble_fh, which gets three arguments from the disassembler.
insn (a string), arg (a string or number or undef) and the comment (an optional string).

This supports the new behaviour in F<scripts/disassemble>.
It prints each insn and optional argument with some additional comments,
which looks similar to B::Assembler with option -S (commented source).

=head1 print_insn_bare

This is the same as the old behaviour of scripts/disassemble.
It prints each insn and optional argument without any comments. Line per line.

=head1 get_header

Returns the .plc header as array of
  ( $magic, $archname, $blversion, $ivsize, $ptrsize, $byteorder, $longsize, $archflag )
in ARRAY context, or in SCALAR context the array from above as named hash.

$magic is always "PLBC"

$archname is the archname string and is in the ByteLoader up to 0.06
checked strictly. Starting with ByteLoader 0.06_05 platform
compatibility is implemented by checking the $archflag, and doing
byteorder swapping for same length longsize, and adjusting the ivsize
and ptrsize.

$blversion is the matching ByteLoader version as string.
Up to ByteLoader 0.06 this version must have matched exactly, since 0.07
earlier ByteLoader versions are also accepted in the ByteLoader.

$ivsize matches $Config{ivsize} of the assembling perl. A number, 4 or 8 only supported.

$ptrsize matches $Config{ptrsize} of the assembling perl. A number, 4 or 8 only supported.

$longsize is $Config{longsize} of the assembling perl. A number, 4 or 8.

$byteorder is a string of "0x12345678" on big-endian or "0x56781234" (?)
on little-endian machines. The beginning "0x" is stripped for compatibility
with intermediate ByteLoader versions, i.e. 5.8.

$archflag is a bitmask of opcode platform-dependencies.
Currently used is only bit 1 for USE_ITHREADS.

=head1 AUTHORS

Malcolm Beattie, C<mbeattie@sable.ox.ac.uk>.
Reini Urban <rurban@cpan.org> since 2008.

=cut
