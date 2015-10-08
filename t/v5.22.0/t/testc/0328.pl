#WONTFIX re-eval lex/global mixup my $code = q[{$blah = 45}]; our $blah = 12; eval "/(?$code)/"; print "$blah\n"
### RESULT:45
