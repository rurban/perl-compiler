package Pickup; use UNIVERSAL qw( can ); if (can( "Pickup", "can" ) != \&UNIVERSAL::can) { print "not " } print "ok\n";
### RESULT:ok
