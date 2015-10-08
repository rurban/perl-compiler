eval { $@ = "t1\n"; do { die "t3\n" }; 1; }; print ":$@:\n";
### RESULT::t3
:
