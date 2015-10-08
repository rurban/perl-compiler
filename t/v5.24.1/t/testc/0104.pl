@a=(1..4);while($a=shift@a){print $a;}continue{$a=~/2/ and reset q(a);}
### RESULT:12
