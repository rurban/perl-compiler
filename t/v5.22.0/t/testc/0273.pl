package Foo; use overload; sub import { overload::constant "integer" => sub { return shift }}; package main; BEGIN { $INC{"Foo.pm"} = "/lib/Foo.pm" }; use Foo; my $result = eval "5+6"; print "$result\n"
### RESULT:11
