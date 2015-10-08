sub f{shift==2}sub test{while(1){last if f(2);}while(1){last if f(2);}} print q(ok)
### RESULT:ok
