my %errs = %!; # t/op/magic.t Errno compiled in print q(ok) if defined ${"!"}{ENOENT};
### RESULT:ok
