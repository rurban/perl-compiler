#TODO perlio layers use open(IN => ":crlf", OUT => ":encoding(cp1252)"); open F, "<", "/dev/null"; my %l = map {$_=>1} PerlIO::get_layers(F, input => 1); print $l{crlf} a t q(ok) : keys(%l);
### RESULT:ok
