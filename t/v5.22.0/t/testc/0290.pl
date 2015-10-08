sub f;print "ok" if exists &f && not defined &f;
### RESULT:ok
