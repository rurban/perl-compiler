sub AUTOLOAD { print 1 } &{"a"}()
### RESULT:1
