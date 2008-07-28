#! perl
# Fake a PE/COFF header, forcing Windows to load and interpret a perl script.

open IN, (my $name = shift) or die "Syntax: pl2exe file.pl\n";

$name =~ s/\.pl$//;
$name .= '.exe';
open (OUT, ">$name") or die "can\'t write to $name: $!\n";
binmode OUT;  # because we want to be in control

print OUT "MZ(<<'EXE_STUFF') # -*-Perl-*-\015\012";
print OUT "Here comes offset 60 .....\015\012";

# The DWORD at offset 60 holds the offset of the IMAGE_NT_HEADERS struct.
# This stuff is in winnt.h.
print OUT pack ("L", 64);

my $code_size = 512;	# actually the size of the entire
			# code section, which in this case contains
			# data as well; rounded up to a multiple of 512

# Construct the IMAGE_NT_HEADERS structure.
my $headers = "PE\0\0";		# Portable Executable signature
$headers .= pack ('SSLLLSS',	# the IMAGE_FILE_HEADER substructure
		  0x14c,	# for Intel I386
		  1,		# number of sections
		  874806772,	# time-date stamp (whatever)
		  0,0,		# uniteresting fields
		  224,		# size of the IMAGE_OPTIONAL_HEADER
		  0x010f	# random flags: 0xa18e(?) for a DLL
		  );
$headers .= pack ('SCCL9S6L4SSL6',	# IMAGE_OPTIONAL_HEADERS substruct
		  0x010b,	# 0x0107 would be a ROM image
		  1,0,		# linker version maj.min (I guess that's us)
		  $code_size,
		  0,0,		# size of initialized/un- data
		  0x1000,	# RVA of entry point
		  		# (the RVA is the address when loaded,
		  		# relative to the image base)
		  0x1000,	# RVA of start of code section
		  0,		# RVA of data section, if there were one
		  0x400000,	# image base
		  0x1000,	# section alignment
		  512,		# file alignment
		  4, 0,		# OS version maj.min
		  0, 0,		# user-defined fields (whatever)
		  4, 0,		# subsystem version (???)
		  0,		# reserved zero
		  0x2000,	# size of image
		  512,		# size of headers
		  0,		# checksum; ignored
		  3,		# 3=console app; 2=GUI app
		  0,		# obsolete field
		  0x1000,	# size of stack reserve
		  0x1000,	# size of stack commit
		  0x100000,	# size of heap reserve
		  0,		# size of heap commit
		  0,		# another obsolete field
		  16		# the number or RVA/size pairs to follow
		  );
$headers .= pack ('L32',	# 16 (RVA,size) pairs locating certain
		  		# important image structures; the ones
		  		# we don't have are left zero
		  0,0,
		  0x1100, 195,	# import directory
		  0,0,0,0,0,0,
		  0x10f8, 8,	# relocation table (empty, but needed)
		  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		  );
print OUT $headers;

# We need to describe our one section.
my $section_header = pack ('a8L8',
			   '.perl',	# section name
			   464,		# raw data size
			   0x1000,	# section begin RVA
			   512,		# rounded-up data size
			   512,		# offset in file
			   0,0,0,	# whatever
			   0xe0000060,	# flags
			   );
print OUT $section_header;

print OUT "\015\012\015\012";
print OUT "-------------that was the IMAGE_NT_HEADERS struct-------------";
print OUT "\015\012------------------------\015\012";
print OUT "--------Now comes the code (at offset 512, if you please)-----";
print OUT "\015\012\015\012";

# Next comes the code.
# It performs fixups, prepends "perl -x " to the command line,
# launches perl, and returns perl's exit status.

print OUT pack ("H*", "b8cc114000833dcc1140000074168b1085d27d06");
print OUT pack ("H*", "01500483c004ff0283c00483380075eaa1481140");
print OUT pack ("H*", "00ffd089c389c731c0b9f7fffffffcf2ae89f829");
print OUT pack ("H*", "d883e1fc01ccbec311400089e7b908000000f3a4");
print OUT pack ("H*", "89de89c1f3a489e383ec7cb91b00000089e731c0");
print OUT pack ("H*", "f3ab895c2404c74424284400000089e083c02889");
print OUT pack ("H*", "44242083c04489442424a140114000ffd021c075");
print OUT pack ("H*", "046a64eb258b4424446aff50a14c114000ffd021");
print OUT pack ("H*", "c074046a65eb0f8b4424446a665450a150114000");
print OUT pack ("H*", "ffd0a144114000ffd0");

print OUT "\015\012\015\012";
print OUT "-------here's the data, at file offset 760: -------";
print OUT "\015\012\015\012";

# Print out a dummy relocation table.
# The code is not relocatable--it must be loaded at 0x400000.
# But to allow programs to load it with LoadLibrary() and access
# its resources, the file must contain this table.
print OUT pack ('LL', 0x1000,8);

# The import table.  Contains RVAs, names, and a dollop of nulls.
# (we import 5 functions from KERNEL32.DLL)
print OUT pack ('L5', 0x1128, 0,0, 0x1158, 0x1140);
print OUT pack ('L5', 0,0,0,0,0);
print OUT pack ('L6', 0x1166, 0x1178, 0x1186, 0x1198, 0x11ae, 0);
# Not sure if we really need to do this twice, but why argue:
print OUT pack ('L6', 0x1166, 0x1178, 0x1186, 0x1198, 0x11ae, 0);
# Gee it would be nice if C<pack> knew how to align things...
print OUT "KERNEL32.DLL\0\0";
print OUT "\0\0CreateProcessA\0\0";
print OUT "\0\0ExitProcess\0";
print OUT "\0\0GetCommandLineA\0";
print OUT "\0\0WaitForSingleObject\0";
print OUT "\0\0GetExitCodeProcess\0";

# Our initialized data:
print OUT "perl -x \0";
# align 4
print OUT pack ('L*', 0);

# Let Perl know we're done.  We no longer care about CRLF.
print OUT "\nEXE_STUFF\nif 0;\n\n";

$_ = <IN>;
unless ($_ =~ /^\#!.*perl/ ) {
    print OUT "#!perl\n";
}
print OUT $_, <IN>;
close IN;
close OUT;
chmod 0755, $name;
