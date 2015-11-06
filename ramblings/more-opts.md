pp_dlload as op (core)

    Implement DynaLoader in C
    One should not call perl to load a shared library.    

    Implement a sane XSLoader API using that.
    http://blogs.perl.org/users/rurban/2011/10/the-two-worst-perl-apis.html

-fcarp-as-warn (core)
    
    Replace the 4 Carp calls with ops, which do die/warn and display
    the backtrace as op.  Carp autoloads XS Carp::Heavy, and one
    usecase is Carp in Dynaloader failing code.  It also has too much
    dependencies

-fno-warnings (B::C, B::CC)

    Production perl wants to choose no run-time warnings overhead.
    fix current B::CC -fno-warnings -Uwarnings

    nop warnings calls. some modules use warnif and fail with the
    current -fno-warnings.  E.g. Find::File

compile-time utf8 folding tables
   
    do not defer swash_init to run-time. mark the ops (lc,uc,fc,match)
    as utf8 or ascii or undecided.  implement the folding tables as
    shared objects, created at build-time (as Encode does)

implement exists symbol as op (lexical or global)

   symbols should not be created when asking if a symbol exists.

implement last out of grep/map

tail recursion

implement the taint flag bit for HEKs

implement the run-time part for oplines

    search for the upper cop in case of warnings/errors for the filename
