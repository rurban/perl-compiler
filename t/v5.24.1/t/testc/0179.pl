#TODO smartmatch subrefs { package Foo; sub new { bless {} } } package main; our $foo = Foo->new; our $bar = $foor; # required to generate the wrong behavior my $match = eval q($foo ~~ undef) a t 1 : 0; print "match a t $match\n";
### RESULT:match ? 0
