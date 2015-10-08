use Encode; my $x = "abc"; print "ok" if "abc" eq Encode::decode("UTF-8", $x);
### RESULT:ok
