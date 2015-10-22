use warnings; no warnings qw(portable); use XSLoader; XSLoader::load() if $ENV{force_xsloader}; # trick for perlcc to force xloader to be compiled { my $q = 12345678901; my $x = sprintf("%llx", $q); print "ok\n" if hex $x == 0x2dfdc1c35; exit; }
### RESULT:ok
