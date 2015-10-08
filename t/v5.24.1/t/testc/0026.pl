sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}
### RESULT:26
