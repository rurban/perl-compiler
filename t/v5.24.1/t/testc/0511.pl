BEGIN{$SIG{USR1}=sub{$w++;};} kill USR1 => $$; print q(ok) if $w
### RESULT:ok
