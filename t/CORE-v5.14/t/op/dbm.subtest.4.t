delete $::{"AnyDBM_File::"}; $filename = 'tmp42342A';
@INC = ();
dbmopen(%LT, $filename, 0666);
1 while unlink $filename;
1 while unlink glob "$filename.*";
die "Failed to fail!";
