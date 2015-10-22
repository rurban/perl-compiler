my $a = "\x{100}\x{101}Aa"; print "ok\n" if "\U$a" eq "\x{100}\x{100}AA"; my $b = "\U\x{149}cD"; # no pb without that line
### RESULT:ok
