#!./perl

print "1..2\n";

$x = 'AbelCaincatdogx';
$reused = 'AbelCaincatdogx';

print "ok - 1\n" if $x eq $reused;
print "ok - 2\n" if f($x, $reused );

sub f {
  my ($a, $reused ) = @_; # renaming the variable here solves the issue...
  return eval "\$a eq \$reused";
}

