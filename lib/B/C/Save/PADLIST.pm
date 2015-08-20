package B::PADLIST;

use strict;

# fixme: not sure it still needed: not triggered by the CORE test suite
sub save {
    return B::AV::save(@_);
}

1;
