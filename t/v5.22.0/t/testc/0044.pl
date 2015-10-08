use Scalar::Util "weaken";my $re1=qr/foo/;my $re2=$re1;weaken($re2);print "ok" if $re3=qr/$re1/;
### RESULT:ok
