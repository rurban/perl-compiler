#!perl

print "1..2\n";

# one level hash
my %a; $a{b} = qq{ok 1\n}; 
print $a{b};

# multi levels hash
my %foo; $foo{b}{c}{d}{e}{f} = qq{ok 2\n}; 
print $foo{b}{c}{d}{e}{f};
