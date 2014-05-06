#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=305
# wrong compile-time Encode::XS &ascii_encoding
# fix in perl_init2_aaaa:
#  #include <dlfcn.h>
#  void *handle = dlopen(sv_list[5032].sv_u.svu_pv, RTLD_NOW|RTLD_NOLOAD); // <pathto/Encode.so>
#  void *ascii_encoding = dlsym(handle, "ascii_encoding");
#  SvIV_set(&sv_list[1], PTR2IV(ascii_encoding));  PVMG->iv

use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}
use Test::More tests => 2;
my $cmt = '#305 compile-time Encode::XS encodings';
my $script = 'use constant ASCII => eval { require Encode; Encode::find_encoding("ASCII"); } || 0;
print ASCII->encode("www.google.com")';
my $exp = "www.google.com";
ctest(1, $exp, 'C,-O3', 'ccode305i', $script, 'TODO C '.$cmt);

$script = 'INIT{ sub ASCII { eval { require Encode; Encode::find_encoding("ASCII"); } || 0; }}
print ASCII->encode("www.google.com")';
ctest(2, $exp, 'C,-O3', 'ccode305i', $script, 'C run-time init');

