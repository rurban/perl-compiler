eval q/use Net::DNS/; my $new = "IO::Socket::INET6"->can("new") or die "die at new"; my $inet = $new->("IO::Socket::INET6", LocalAddr => q/localhost/, Proto => "udp", LocalPort => undef); print q(ok) if ref($inet) eq "IO::Socket::INET6";
### RESULT:ok
