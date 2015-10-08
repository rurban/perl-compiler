use vars qw($glook $smek $foof); $glook = 3; $smek = 4; $foof = "halt and cool down"; my $rv = \*smek; *glook = $rv; my $pv = ""; $pv = \*smek; *foof = $pv; print "ok\n";
### RESULT:ok
