#TODO Wide character warnings missing (bytes layer ignored) use warnings q{utf8}; my $w; local $SIG{__WARN__} = sub { $w = $_[0] }; my $c = chr(300); open F, ">", "a"; binmode(F, ":bytes:"); print F $c,"\n"; close F; print $w
### RESULT:ok
