my $i_i = 1; my $foo = sub { $i_i = shift if @_ }; print $i_i; print &$foo(3),$i_i;
### RESULT:133
