my %errs = %{"!"}; # t/op/magic.t Errno to be loaded at run-time print q(ok) if defined ${"!"}{ENOENT};
### RESULT:ok
