package Foo; sub match { shift =~ m?xyz? a t 1 : 0; } sub match_reset { reset; } package Bar; sub match { shift =~ m?xyz? a t 1 : 0; } sub match_reset { reset; } package main; print "1..5\n"; print "ok 1\n" if Bar::match("xyz"); print "ok 2\n" unless Bar::match("xyz"); print "ok 3\n" if Foo::match("xyz"); print "ok 4\n" unless Foo::match("xyz"); Foo::match_reset(); print "ok 5\n" if Foo::match("xyz");
### RESULT:1..5
ok 1
ok 2
ok 3
ok 4
ok 5
