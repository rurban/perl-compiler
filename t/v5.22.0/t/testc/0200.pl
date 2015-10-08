%u=("\x{123}"=>"fo"); print "ok" if $u{"\x{123}"} eq "fo"
### RESULT:ok
