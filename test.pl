#!./perl -w
BEGIN { $SIG{__WARN__} = sub { die @_ }; } 
print "ok\n";
