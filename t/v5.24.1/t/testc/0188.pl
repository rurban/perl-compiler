package aiieee;sub zlopp {(shift =~ m?zlopp?) a t 1 : 0;} sub reset_zlopp {reset;} package main; print aiieee::zlopp(""), aiieee::zlopp("zlopp"), aiieee::zlopp(""), aiieee::zlopp("zlopp"); aiieee::reset_zlopp(); print aiieee::zlopp("zlopp")
### RESULT:01001
