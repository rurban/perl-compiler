#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=90
# Magic Tie::Named::Capture <=> *main::+ main::*- and Errno vs !
use Test::More tests => 9;
use strict;
BEGIN {
  die "1..0 # Tie::Named::Capture requires Perl v5.10\n" if $] < 5.010;
  unshift @INC, 't';
  require "test.pl";
}

sub save {
  my $name = shift;
  my $script = join("\n",@_);
  open my $s, ">$name.pl";
  print $s $script;
  close $s;
}

sub test3 {
  my $name = shift;
  my $script = shift;
  save($name, $script);
  my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
  system($runperl,'-Mblib',"-MO=Bytecode,-o$name.plc","$name.pl");
  my $runexe = qx($runperl -Mblib -MByteLoader $name.plc);
 TODO: {
   local $TODO = '%+ setting regdata magic crashes' if $name eq 'ccode90i_c';
   is($runexe, 'ok', "Bytecode $name");
  }
  ctestok(2, "C", $name, $script, @_);
  ctestok(3, "CC", $name, $script, @_);
  #unlink("$name.plc", "$name.pl");
  #unlink("$name_2.c", "$name_2");
  #unlink("$name_3.c", "$name_3");
}


test3('ccode90i_c', <<'EOF');
my $s = 'test string';
$s =~ s/(?<first>test) (?<second>string)/\2 \1/g;
print q(o) if $s eq 'string test';
'test string' =~ /(?<first>\w+) (?<second>\w+)/;
print q(k) if $+{first} eq 'test';
EOF

test3('ccode90i_es', <<'EOF');
my %errs = %!; # t/op/magic.t Errno compiled in
print q(ok) if defined ${"!"}{ENOENT};
EOF

# this fails so far, %{"!"} is not detected at compile-time. requires -uErrno
test3('ccode90i_er', <<'EOF', 'requires -uErrno');
my %errs = %{"!"}; # t/op/magic.t Errno to be loaded at run-time
print q(ok) if defined ${"!"}{ENOENT};
EOF
