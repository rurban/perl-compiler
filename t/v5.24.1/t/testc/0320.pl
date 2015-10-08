#TODO No warnings reading in invalid utf8 stream (utf8 layer ignored) use warnings "utf8"; local $SIG{__WARN__} = sub { $@ = shift }; open F, ">", "a"; binmode F; my ($chrE4, $chrF6) = (chr(0xE4), chr(0xF6)); print F "foo", $chrE4, "\n"; print F "foo", $chrF6, "\n"; close F; open F, "<:utf8", "a"; undef $@; my $line = <F>; print q(ok) if $@ =~ /utf8 "\xE4" does not map to Unicode/;
### RESULT:ok
