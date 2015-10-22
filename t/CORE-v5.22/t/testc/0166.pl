my $ok = 1; foreach my $chr (60, 200, 600, 6000, 60000) { my ($key, $value) = (chr ($chr) . "\x{ABCD}", "$chr\x{ABCD}"); chop($key, $value); my %utf8c = ( $key => $value ); my $tempval = sprintf q($utf8c{"\x{%x}"}), $chr; my $ev = eval $tempval; $ok = 0 if !$ev or $ev ne $value; } print "ok" if $ok
### RESULT:ok
