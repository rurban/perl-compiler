# issue59 use strict; use warnings; use IO::Socket; my $remote = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "perl.org", PeerPort => "80" ); print $remote "GET / HTTP/1.0" . "\r\n\r\n"; my $result = <$remote>; $result =~ m|HTTP/1.1 200 OK| a t print "ok" : print $result; close $remote;
### RESULT:ok
