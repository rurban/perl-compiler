package FINALE; { $ref3 = bless ["ok - package destruction"]; my $ref2 = bless ["ok - lexical destruction\n"]; local $ref1 = bless ["ok - dynamic destruction\n"]; 1; } DESTROY { print $_[0][0]; }
### RESULT:ok - dynamic destruction
ok - lexical destruction
ok - package destruction
