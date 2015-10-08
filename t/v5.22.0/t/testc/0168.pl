my $start_time = time; eval { local $SIG{ALRM} = sub { die "ALARM !\n" }; alarm 1; # perlfunc recommends against using sleep in combination with alarm. 1 while (time - $start_time < 3); }; alarm 0; print $@; print "ok\n" if $@ eq "ALARM !\n";
### RESULT:ALARM !
ok
