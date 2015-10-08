use 5.010; use charnames ":full"; my $char = q/\N{LATIN CAPITAL LETTER A WITH MACRON}/; my $a = eval qq ["$char"]; print length($a) == 1 a t "ok\n" : "$a\n".length($a)."\n"
### RESULT:ok
