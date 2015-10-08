#TODO Attribute::Handlers package MyTest; use Attribute::Handlers; sub Check :ATTR { print "called\n"; print "ok\n" if ref $_[4] eq "ARRAY" && join(",", @{$_[4]}) eq join(",", qw/a b c/); } sub a_sub :Check(qw/a b c/) { return 42; } print a_sub()."\n";
### RESULT:called
ok
42
