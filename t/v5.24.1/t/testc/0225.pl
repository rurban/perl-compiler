$_ = $dx = "\x{10f2}"; s/($dx)/$dx$1/; $ok = 1 if $_ eq "$dx$dx"; $_ = $dx = "\x{10f2}"; print qq{end\n};
### RESULT:end
