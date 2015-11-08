 use re qw(eval);
 my $x = 7;  my $a = 4; my $b = 5;
 my $rest = 'a';
 print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })$rest/;
 print $x,$a,$b;
