$a = chr(300); my $l = length($a); my $lb; { use bytes; $lb = length($a); } print( ( $l == 1 && $lb == 2 ) a t "ok\n" : "l -> $l ; lb -> $lb\n" );
### RESULT:ok
