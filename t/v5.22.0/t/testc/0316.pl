package Diamond_A; sub foo {}; package Diamond_B; use base "Diamond_A"; package Diamond_C; use base "Diamond_A"; package Diamond_D; use base ("Diamond_B", "Diamond_C"); use mro "c3"; package main; my $order = mro::get_linear_isa("Diamond_D"); print $order->[3] eq "Diamond_A" a t "ok" : "not ok"; print "\n"
### RESULT:ok
