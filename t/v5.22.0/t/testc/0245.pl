sub foo { my ( $a, $b ) = @_; print "a: ".ord($a)." ; b: ".ord($b)." [ from foo ]\n"; } print "a: ". ord(lc("\x{1E9E}"))." ; "; print "b: ". ord("\x{df}")."\n"; foo(lc("\x{1E9E}"), "\x{df}");
### RESULT:a: 223 ; b: 223
a: 223 ; b: 223 [ from foo ]
