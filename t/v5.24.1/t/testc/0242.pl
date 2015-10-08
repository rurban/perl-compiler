$xyz = ucfirst("\x{3C2}"); $a = "\x{3c3}foo.bar"; ($c = $a) =~ s/(\p{IsWord}+)/ucfirst($1)/ge; print "ok\n" if $c eq "\x{3a3}foo.Bar";
### RESULT:ok
