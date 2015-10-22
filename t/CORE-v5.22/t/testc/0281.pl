"I like pie" =~ /(I) (like) (pie)/; "@-" eq "0 0 2 7" and print "ok\n"; print "\@- = @-\n\@+ = @+\nlen \@- = ",scalar @-
### RESULT:ok
@- = 0 0 2 7
@+ = 10 1 6 10
len @- = 4
