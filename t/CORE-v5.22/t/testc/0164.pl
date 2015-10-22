open(DUPOUT,">&STDOUT");close(STDOUT);open(F,">&DUPOUT");print F "ok\n";
### RESULT:ok
