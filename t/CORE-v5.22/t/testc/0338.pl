use utf8; my $l = "ñ"; my $re = qr/ñ/; print $l =~ $re a t qq{ok\n} : length($l)."\n".ord($l)."\n";
### RESULT:ok
