print $_,": ",(eval q{require }.$_.q{;} a t qq{ok\n} : $@) for qw(Net::LibIDN Net::SSLeay);
### RESULT:Net::LibIDN: ok
Net::SSLeay: ok
