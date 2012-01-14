#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=90
# Magic Tie::Named::Capture <=> *main::+ main::*- and Errno vs !
use Test::More tests => 12;
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
  $todo = 'TODO %+ setting regdata magic crashes' if $name eq 'ccode90i_c';
  plctestok(1, $name, $script, $todo);
  ctestok(2, "C", $name, $script, @_);
  ctestok(3, "CC", $name, $script, @_);
  $runexe = qx($runperl -Mblib blib/script/perlcc --staticxs -r -o$name $name.pl);
 TODO: {
   local $TODO = '--staticxs Tie::Hash::NamedCapture' if $name eq 'ccode90i_c';
   is($runexe, 'ok', "--staticxs $name");
  }
}


test3('ccode90i_c', <<'EOF', '%+ includes Tie::Hash::NamedCapture');
my $s = 'test string';
$s =~ s/(?<first>test) (?<second>string)/\2 \1/g;
print q(o) if $s eq 'string test';
'test string' =~ /(?<first>\w+) (?<second>\w+)/;
print q(k) if $+{first} eq 'test';
EOF

test3('ccode90i_es', <<'EOF', '%! magic');
my %errs = %!; # t/op/magic.t Errno compiled in
print q(ok) if defined ${"!"}{ENOENT};
EOF

# this fails so far, %{"!"} is not detected at compile-time. requires -uErrno
test3('ccode90i_er', <<'EOF', 'TODO may require -uErrno');
my %errs = %{"!"}; # t/op/magic.t Errno to be loaded at run-time
print q(ok) if defined ${"!"}{ENOENT};
EOF
