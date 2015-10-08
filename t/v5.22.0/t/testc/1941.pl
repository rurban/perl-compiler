$0 = q{ccdave}; #print "pid: $$\n"; $s=`ps auxw | grep "$$" | grep "ccdave"|grep -v grep`; print q(ok) if $s =~ /ccdave/
### RESULT:ok
