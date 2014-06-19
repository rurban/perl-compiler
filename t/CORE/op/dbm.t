#!./perl

BEGIN {
    unshift @INC, 't/CORE/lib';
    require 't/CORE/test.pl';
}

eval q{ require AnyDBM_File }; # not all places have dbm* functions
skip_all("No dbm functions") if $@;

plan tests => 4;

# This is [20020104.007] "coredump on dbmclose"

my $filename = tempfile();

my $prog = <<'EOC';
package Foo;
$filename = '@@@@';
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        bless($self,$class);
        my %LT;
        dbmopen(%LT, $filename, 0666) ||
	    die "Can't open $filename because of $!\n";
        $self->{'LT'} = \%LT;
        return $self;
}
sub DESTROY {
        my $self = shift;
	dbmclose(%{$self->{'LT'}});
	1 while unlink $filename;
	1 while unlink glob "$filename.*";
	print "ok\n";
}
package main;
$test = Foo->new(); # must be package var
# $test = undef; # this force the DESTROY method on compiled binary
EOC

$prog =~ s/\@\@\@\@/$filename/;

fresh_perl_is("require AnyDBM_File;\n$prog", 'ok', {}, 'explicit require');
# perlcc issue 208 - https://code.google.com/p/perl-compiler/issues/detail?id=208
fresh_perl_is($prog, 'ok', {}, 'implicit require');

$prog = <<'EOC';
$filename = '@@@@';
@INC = ();
dbmopen(%LT, $filename, 0666);
1 while unlink $filename;
1 while unlink glob "$filename.*";
die "Failed to fail!";
EOC

$prog =~ s/\@\@\@\@/$filename/;

# perlcc wontfix issue 226 - https://code.google.com/p/perl-compiler/issues/detail?id=226
# dbmopen is resolved at compile-time (require "AnyDBM_File.pm"), not run-time
# So this dbmopen error - can("TIEHASH") - does not trigger.
SKIP: {
  if (is_perlcc_compiled()) { # test if runnning compiled
    skip "wontfix issue 226 in perlcc";
  } else {
    fresh_perl_like($prog, qr/No dbm on this machine/, {},
                    'implicit require fails');
  }
}
fresh_perl_like('delete $::{"AnyDBM_File::"}; ' . $prog,
		qr/No dbm on this machine/, {},
		'implicit require and no stash fails');
