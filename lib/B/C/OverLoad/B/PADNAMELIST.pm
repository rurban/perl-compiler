package B::PADNAMELIST;

use strict;

our @ISA = qw(B::AV);

# fixme: not sure it still needed: not triggered by the CORE test suite
sub save {
    return B::AV::save(@_);
}

sub flagspv {
    return "";
}

1;
