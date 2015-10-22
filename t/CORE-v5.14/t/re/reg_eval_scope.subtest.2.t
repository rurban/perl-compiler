 for my $x("a".."c") {
  $y = 1;
  print scalar
   "abcabc" =~
       /
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
       /x;
  print "$x ";
 }
