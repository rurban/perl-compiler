@X::ISA = "Y"; sub Y::z {"Y::z"} print "ok\n" if X->z eq "Y::z"; delete $X::{z}; exit
### RESULT:ok
