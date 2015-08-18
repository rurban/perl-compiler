package B::OBJECT;

use B::C ();

sub save { }

# B misses that
sub name { "" }

#INIT {
B::C::add_to_isa_cache( 'B::OBJECT::can' => 'UNIVERSAL' );

#}

1;
