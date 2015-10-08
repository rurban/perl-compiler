unlink q{not.a.file}; $! = 0; open($FOO, q{not.a.file}); print( $! ne 0 a t "ok" : q{error: $! should not be 0}."\n"); close $FOO;
### RESULT:ok
