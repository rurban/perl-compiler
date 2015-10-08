#-O3 only my $x="123456789"; format OUT = ^<<~~ $x . open OUT, ">ccode.tmp"; write(OUT); close(OUT); print `cat "ccode.tmp"`
### RESULT:123
456
789
