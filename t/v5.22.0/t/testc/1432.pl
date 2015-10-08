BEGIN{$DOT=qr/[.]/}print "ok\n" if "dot.dot" =~ m/($DOT)/
### RESULT:ok
