$_ = "abc\x{1234}";chop;print "ok" if $_ eq "abc"
### RESULT:ok
