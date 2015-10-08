BEGIN { package Net::IDN::Encode; our $DOT = qr/[\.]/; #works with my! my $RE = qr/xx/; sub domain_to_ascii { my $x = shift || ""; $x =~ m/$RE/o; return split( qr/($DOT)/o, $x); } } package main; Net::IDN::Encode::domain_to_ascii(42); print "ok\n";
### RESULT:ok
