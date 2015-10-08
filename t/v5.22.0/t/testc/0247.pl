# WontFix no warnings; $[ = 1; $big = "N\xabN\xab"; print qq{ok\n} if rindex($big, "N", 3) == 3
### RESULT:ok
