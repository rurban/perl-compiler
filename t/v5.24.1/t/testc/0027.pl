use Fcntl ();my $a=Fcntl::O_CREAT(); print "ok" if ( $a >= 64 && &Fcntl::O_CREAT >= 64 );
### RESULT:ok
