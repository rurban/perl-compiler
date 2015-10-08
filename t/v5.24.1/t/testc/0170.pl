eval "sub xyz (\$) : bad ;"; print "~~~~\n$@~~~~\n"
### RESULT:~~~~
Invalid CODE attribute: bad at (eval 1) line 1.
BEGIN failed--compilation aborted at (eval 1) line 1.
~~~~
