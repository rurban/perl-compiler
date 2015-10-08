package my;sub recurse{my $i=shift;recurse(++$i)unless $i>5000;print"ok";exit};package main;my::recurse(1)
### RESULT:ok
