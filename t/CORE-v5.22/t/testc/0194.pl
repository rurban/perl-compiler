$0 = q{ccdave with long name}; #print "pid: $$\n"; $s=`ps w | grep "$$" | grep "[c]cdave"`; print ($s =~ /ccdave with long name/ a t q(ok) : $s);
### RESULT:ok
