#TODO stash-magic delete renames to ANON my @c; sub foo { @c = caller(0); print $c[3] } my $fooref = delete $::{foo}; $fooref -> ();
### RESULT:main::__ANON__
