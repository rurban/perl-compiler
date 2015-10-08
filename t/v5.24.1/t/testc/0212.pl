$blurfl = 123; { package abc; $blurfl = 5; } $abc = join(":", sort(keys %abc::)); package abc; print "variable: $blurfl\n"; print "eval: ". eval q/"$blurfl\n"/; package main; sub ok { 1 }
### RESULT:variable: 5
eval: 5
