package Ccode31i;my $regex = qr/\w+/;sub test {print ("word" =~ m/^$regex$/o a t "ok\n" : "not ok\n");} package main; &Ccode31i::test();
### RESULT:ok
