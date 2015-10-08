$SIG{__WARN__} = sub { die "warning: $_[0]" }; opendir(DIR, ".");closedir(DIR);print q(ok)
### RESULT:ok
