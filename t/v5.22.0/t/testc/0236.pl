sub t { if ($_[0] == $_[1]) { print "ok\n"; } else { print "not ok - $_[0] == $_[1]\n"; } } t(-1.2, " -1.2");
### RESULT:ok
