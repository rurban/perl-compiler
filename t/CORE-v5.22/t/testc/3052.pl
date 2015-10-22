use Net::DNS::Resolver; my $res = Net::DNS::Resolver->new; $res->send("www.google.com"), print q(ok)
### RESULT:ok
