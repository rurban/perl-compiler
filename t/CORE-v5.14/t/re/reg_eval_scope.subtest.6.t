  for my $x(1..3) {
   push @regexps = qr/(?{ print $x })a/;
  }
 "a" =~ $_ for @regexps;
 "ba" =~ /b$_/ for @regexps;
