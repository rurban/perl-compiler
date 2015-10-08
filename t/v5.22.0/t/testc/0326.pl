#TODO method const maybe::next::method package Diamond_C; sub maybe { "Diamond_C::maybe" } package Diamond_D; use base "Diamond_C"; use mro "c3"; sub maybe { "Diamond_D::maybe => " . ((shift)->maybe::next::method() || 0) } package main; print "ok\n" if Diamond_D->maybe;
### RESULT:ok
