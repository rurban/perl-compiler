open FOO, ">", "ccode3141.tmp"; print FOO "abc"; close FOO; open FOO, "<", "ccode3141.tmp"; { $/="b"; $in=<FOO>; if ($in eq "ab") { print "ok\n" } else { print qq(separator: "$/"\n\$/ is "$/"\nFAIL: "$in"\n)}}; unlink "ccode3141.tmp"
### RESULT:ok
