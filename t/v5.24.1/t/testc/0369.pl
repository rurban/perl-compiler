use EV; use Coro; use Coro::Timer; my @a; push @a, async { while() { warn $c++; Coro::Timer::sleep 1; }; }; push @a, async { while() { warn $d++; Coro::Timer::sleep 0.5; }; }; schedule; print q(ok)
### RESULT:ok
