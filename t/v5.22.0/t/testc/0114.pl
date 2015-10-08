sub f1{0}sub f2{my $x;if(f1()){}if($x){}else{[$x]}}my @a=f2();print "ok";
### RESULT:ok
