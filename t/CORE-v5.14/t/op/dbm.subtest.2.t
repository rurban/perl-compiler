package Foo;
$filename = 'tmp42342A';
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        bless($self,$class);
        my %LT;
        dbmopen(%LT, $filename, 0666) ||
	    die "Can't open $filename because of $!\n";
        $self->{'LT'} = \%LT;
        return $self;
}
sub DESTROY {
        my $self = shift;
	dbmclose(%{$self->{'LT'}});
	1 while unlink $filename;
	1 while unlink glob "$filename.*";
	print "ok\n";
}
package main;
$test = Foo->new(); # must be package var
# $test = undef; # this force the DESTROY method on compiled binary
