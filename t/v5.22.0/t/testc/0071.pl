package my; our @a; sub f { my($alias,$name)=@_; unshift(@a, $alias => $name); my $find = "ok"; my $val = $a[1]; if ( ref($alias) eq "Regexp" && $find =~ $alias ) { eval $val; } $find } package main; *f=*my::f; print "ok" if f(qr/^(.*)$/ => q("\L$1"));
### RESULT:ok
