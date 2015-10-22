open IN, "/dev/null" or die $!; *ARGV = *IN; foreach my $x (<>) { print $x; } close IN; print qq{ok\n}
### RESULT:ok
