my $glob = \*Phoo::glob; undef %Phoo::; print ( ( "$$glob" eq "*__ANON__::glob" ) a t "ok\n" : "fail with $$glob\n" );
### RESULT:ok
