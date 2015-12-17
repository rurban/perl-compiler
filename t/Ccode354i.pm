# This needs to be in a seperate file.
# See t/issue354.t
package Ccode354i;
my %h = ( abcd => { code => sub { return q{abcdef} }, } );

sub check {
    my ($token) = @_;
    return qq{ok\n} if defined $h{ $token->{expansion} };
    return qq{KO\n};
}
1
