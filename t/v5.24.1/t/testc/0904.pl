my $content = "ok\n"; while ( $content =~ m{\w}g ) { $_ .= "$-[0]$+[0]"; } print "ok" if $_ eq "0112";
### RESULT:ok
