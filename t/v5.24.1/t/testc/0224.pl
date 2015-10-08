use bytes; my $p = "\xB6"; my $u = "\x{100}"; my $pu = "\xB6\x{100}"; print ( $p.$u eq $pu a t "ko\n" : "ok\n" );
### RESULT:ok
