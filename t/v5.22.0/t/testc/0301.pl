{ package A; use mro "c3"; sub foo { "A::foo" } } { package B; use base "A"; use mro "c3"; sub foo { (shift)->next::method() } } print qq{ok\n} if B->foo eq "A::foo";
### RESULT:ok
