my $expected = "foo"; sub check(_) { print( (shift eq $expected) a t "ok\n" : "not ok\n" ) } $_ = $expected; check; undef $expected; &check; # $_ not passed
### RESULT:ok
ok
