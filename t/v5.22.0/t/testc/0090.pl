my $s = q(test string); $s =~ s/(?<first>test) (?<second>string)/\2 \1/g; print q(o) if $s eq q(string test); q(test string) =~ /(?<first>\w+) (?<second>\w+)/; print q(k) if $+{first} eq q(test);
### RESULT:ok
