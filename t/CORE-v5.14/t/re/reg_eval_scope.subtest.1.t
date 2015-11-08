 my $x = 7; my $a = 4; my $b = 5;
 print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })a/;
 print $x,$a,$b;
