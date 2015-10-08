$a = "a\xFF\x{100}"; eval {$b = crypt($a, "cd")}; print $@;
### RESULT:Wide character in crypt at ccode167.pl line 2.
