#TODO re-eval no_modify, probably WONTFIX use re "eval"; our ( $x, $y, $z ) = 1..3; $x =~ qr/$x(?{ $y = $z++ })/; undef $@; print "ok\n"
### RESULT:ok
