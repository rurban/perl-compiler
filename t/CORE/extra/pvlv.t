#!./perl

print "1..3\n";

# from https://rt.perl.org/Public/Bug/Display.html?id=77500
# put a glob in a PVLV by passing a nonexistent hash element to a subroutine and then assigning a glob to it

my %hash;
sub {
    for (shift) { $_ = *foo; }
  }
  ->( $hash{any_key} );

print qq/ok 1\n/;

$hash{test} = 'bar';
sub {
    for (shift) { $_ = *foo; }
  }
  ->( $hash{'test'} );

print ref \&bar == 'CODE' ? qq/ok 2\n/ : qq/not ok 2\n/;

my $s = q/abcd/;
my $x = \substr( $s, 1, 2 );

#use Devel::Peek; Dump $x;
print ref $x == 'LVALUE' ? qq/ok 3\n/ : qq/not ok 3\n/;
