sub f ($); sub f ($) { my $test = $_[0]; write; format STDOUT = ok @<<<<<<< $test . } f("");
### RESULT:ok
