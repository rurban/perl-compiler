package Top;sub top{q(ok)};package Next;our @ISA=qw(Top);package main;print Next->top();
### RESULT:ok
