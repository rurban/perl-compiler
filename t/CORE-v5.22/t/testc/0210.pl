$a = 123; package xyz; sub xsub {bless [];} $x1 = 1; $x2 = 2; $s = join(":", sort(keys %xyz::)); package abc; my $foo; print $xyz::s
### RESULT:s:x1:x2:xsub
