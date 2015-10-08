open FOO, ">", "ccode314.tmp"; print FOO "abc"; close FOO; open FOO, "<", "ccode314.tmp"; { local $/="b"; $in=<FOO>; if ($in eq "ab") { print "ok\n" } else { print qq(separator: "$/"\n\$/ is "$/"\nFAIL: "$in"\n)}}; unlink "ccode314.tmp"
### RESULT:ok
