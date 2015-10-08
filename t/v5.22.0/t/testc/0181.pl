sub End::DESTROY { $_[0]->() }; my $inx = "OOOO"; $SIG{__WARN__} = sub { print$_[0] . "\n" }; { $@ = "XXXX"; my $e = bless( sub { die $inx }, "End") } print q(ok)
### RESULT:ok
