package dummy; my $invoked_as_script = !caller(); __PACKAGE__->script(@ARGV) if $invoked_as_script; sub script {my($package,@args)=@_;print "ok"}
### RESULT:ok
