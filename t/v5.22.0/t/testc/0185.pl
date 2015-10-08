my $a=pack("U",0xFF);use bytes;print "not " unless $a eq "\xc3\xbf" && bytes::length($a) == 2; print "ok\n";
### RESULT:ok
