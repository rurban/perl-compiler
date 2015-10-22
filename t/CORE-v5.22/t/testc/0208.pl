sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " } my $my =bless {}, MyKooh; sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" }our $our=bless {}, OurKooh;
### RESULT:RUN MyKooh DESTRUCT OurKooh
