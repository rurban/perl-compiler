#WONTFIX re-eval lex/global mixup $_ = q{aaa}; my @res; pos = 1; s/\Ga(?{push @res, $_, $`})/xx/g; print "ok\n" if "$_ @res" eq "axxxx aaa a aaa aa"; print "$_ @res\n"
### RESULT:ok
axxxx aaa a aaa aa
