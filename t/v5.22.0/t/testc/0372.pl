use utf8; require mro; my $f_gen = mro::get_pkg_gen(ᕘ); undef %ᕘ::; mro::get_pkg_gen(ᕘ); delete $::{"ᕘ::"}; print "ok";
### RESULT:ok
