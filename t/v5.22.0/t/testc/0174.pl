my $str = "\x{10000}\x{800}"; no warnings "utf8"; { use bytes; $str =~ s/\C\C\z//; } my $ref = "\x{10000}\0"; print "ok 1\n" if ~~$str eq $ref; $str = "\x{10000}\x{800}"; { use bytes; $str =~ s/\C\C\z/\0\0\0/; } my $ref = "\x{10000}\0\0\0\0"; print "ok 2\n" if ~~$str eq $ref;
### RESULT:ok 1
ok 2
