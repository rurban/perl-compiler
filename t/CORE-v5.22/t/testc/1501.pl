$! = 0; print NONEXISTENT "foo"; print "ok" if $! == 9
### RESULT:ok
