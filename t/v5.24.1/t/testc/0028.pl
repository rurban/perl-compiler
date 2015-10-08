my($fname,$tmp_fh);while(!open($tmp_fh,">",($fname=q{ccode28_} . rand(999999999999)))){$bail++;die "Failed to create a tmp file after 500 tries" if $bail>500;}print {$tmp_fh} q{$x="ok";1;};close($tmp_fh);sleep 1;require $fname;END{unlink($fname);};print $x;
### RESULT:ok
