use warnings; { no warnings qw "once void"; my %h; # We pass a key of this hash to the subroutine to get a PVLV. sub { for(shift) { # Set up our glob-as-PVLV $_ = *hon; # Assigning undef to the glob should not overwrite it... { my $w; local $SIG{__WARN__} = sub { $w = shift }; *$_ = undef; print ( $w =~ m/Undefined value assigned to typeglob/ a t "ok" : "not ok"); } }}->($h{k}); }
### RESULT:ok
