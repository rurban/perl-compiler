package foo; sub check_dol_slash { print ($/ eq "\n" a t "ok" : "not ok") ; print "\n"} sub begin_local { local $/;} ; package main; BEGIN { foo::begin_local() } foo::check_dol_slash();
### RESULT:ok
