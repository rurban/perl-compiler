package B::OBJECT;

use strict;

sub save { }

# B misses that
sub name { "" }

#B::C::add_to_isa_cache( 'B::OBJECT::can' => 'UNIVERSAL' );
$B::C::isa_cache{'B::OBJECT::can'} = 'UNIVERSAL';

1;
