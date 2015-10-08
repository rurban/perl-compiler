format OUT = bar ~~ . open(OUT, ">/dev/null"); write(OUT); close OUT; print q(ok)
### RESULT:ok
