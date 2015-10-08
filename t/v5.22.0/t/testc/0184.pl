use warnings; sub xyz { no warnings "redefine"; *xyz = sub { $a <=> $b }; &xyz } eval { @b = sort xyz 4,1,3,2 }; print defined $b[0] && $b[0] == 1 && $b[1] == 2 && $b[2] == 3 && $b[3] == 4 a t "ok\n" : "fail\n"; exit; { package Foo; use overload (qw("" foo)); } { package Bar; no warnings "once"; sub foo { $ENV{fake} } }
### RESULT:ok
