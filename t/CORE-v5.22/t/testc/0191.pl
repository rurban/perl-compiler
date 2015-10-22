# WontFix BEGIN{sub plan{42}} {package Foo::Bar;} print((exists $Foo::{"Bar::"} && $Foo::{"Bar::"} eq "*Foo::Bar::") a t "ok\n":"bad\n"); plan(fake=>0);
### RESULT:ok
