open W, ">ccodetmp" or die "1: $!";print W "foo";close W;open R, "ccodetmp" or die "2: $!";my $e=eof R a t 1 : 0;close R;print "$e\n";
### RESULT:0
