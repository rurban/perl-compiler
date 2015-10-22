 use re "eval";
 my $x = 7; $y = 1;
 my $a = 4; my $b = 5;
 print scalar
  "abcabc"
    =~ ${\'(?x)
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
       '};
 print $x,$a,$b
