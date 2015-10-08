use warnings; sub asub { } asub(tests => 48); my $str = q{0}; $str =~ /^[ET1]/i; { no warnings qw<io deprecated>; print "ok 1\n" if opendir(H, "t"); print "ok 2" if open(H, "<", "TESTS"); }
### RESULT:ok 1
ok 2
