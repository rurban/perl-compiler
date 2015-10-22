my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h
### RESULT:ba
