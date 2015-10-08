package foo;use Moose; has "x" => (isa => "Int", is => "rw", required => 1); has "y" => (isa => "Int", is => "rw", required => 1); sub clear { my $self = shift; $self->x(0); $self->y(0); } __PACKAGE__->meta->make_immutable; package main; my $f = foo->new( x => 5, y => 6); print $f->x . "\n";
### RESULT:5
