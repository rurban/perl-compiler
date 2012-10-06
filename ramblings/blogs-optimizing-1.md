regex-dna - regex matching fast enough
======================================

Since my goal is to improve the compiler optimizer (staticly with B::CC, but also the perl compiler in op.c) I came to produce these interesting benchmarks.

I took the regex-dna example from *"The Computer Language Benchmarks Game"* at [shootout.alioth.debian.org](http://shootout.alioth.debian.org/)

    $ time perl t/regex-dna.pl <t/regexdna-input
    agggtaaa|tttaccct 0
    [cgt]gggtaaa|tttaccc[acg] 3
    a[act]ggtaaa|tttacc[agt]t 9
    ag[act]gtaaa|tttac[agt]ct 8
    agg[act]taaa|ttta[agt]cct 10
    aggg[acg]aaa|ttt[cgt]ccct 3
    agggt[cgt]aa|tt[acg]accct 4
    agggta[cgt]a|t[acg]taccct 3
    agggtaa[cgt]|[acg]ttaccct 5
    
    101745
    100000
    133640
    
    real	0m**0.130s**  /(varying from 0.125 to 0.132)/
    user	0m0.120s
    sys		0m0.008s

t/regexdna-input contains 100KB 1600 lines of DNA code, which is used to match
DNA 8-mers and substitute nucleotides for IUB codes.

    $ wc t/regexdna-input 
    1671   1680 101745 t/regexdna-input

Perl behaves pretty good in this [benchmark](http://shootout.alioth.debian.org/u64q/performance.php?test=regexdna),
it is actually the fastest scripting language.  But the compiler should
do better, and I had some ideas to try out for the optimizing
compiler. So I thought.

First the simple and stable B::C compiler with -O3:

    $ perlcc -O3 -o regex-dna-c -S t/regex-dna.pl
    $ time ./regex-dna-c <t/regexdna-input
    agggtaaa|tttaccct 0
    [cgt]gggtaaa|tttaccc[acg] 3
    a[act]ggtaaa|tttacc[agt]t 9
    ag[act]gtaaa|tttac[agt]ct 8
    agg[act]taaa|ttta[agt]cct 10
    aggg[acg]aaa|ttt[cgt]ccct 3
    agggt[cgt]aa|tt[acg]accct 4
    agggta[cgt]a|t[acg]taccct 3
    agggtaa[cgt]|[acg]ttaccct 5
    
    101745
    100000
    133640
    
    real	0m**0.285s**
    user	0m0.272s
    sys		0m0.004s

0.130s vs 0.285s compiled? What's going on? B::C promises faster startup-time and equal run-time.
With -S we keep the intermediate C source to study it.
Let's try B::CC, via -O. Here you don't need a -O3 as B::CC already contains all B::C -O3 optimizations

    $ perlcc -O -o regex-dna-cc t/regex-dna.pl
    $ time ./regex-dna-cc <t/regexdna-input
    ...
    real	0m**0.267s**
    user	0m0.256s
    sys		0m0.008s

Hmm? Let's see what's going on with **-v5**.

    $ perlcc -O3 -v5 -S -oregex-dna-c -v5 t/regex-dna.pl

    script/perlcc: Compiling t/regex-dna.pl
    script/perlcc: Writing C on regex-dna-c.c
    script/perlcc: Calling /usr/local/bin/perl5.14.2d-nt -Iblib/arch -Iblib/lib -MO=C,-O3,-Dsp,-v,-oregex-dna-c.c t/regex-dna.pl
    Starting compile
     Walking tree
     done main optree, walking symtable for extras
     Prescan 0 packages for unused subs in main::
     %skip_package: B::Stackobj B::Section B::FAKEOP B::C B::C::Section::SUPER B::C::Flags
     B::Asmdata O DB B::CC Term::ReadLine B::Shadow B::C::Section B::Bblock B::Pseudoreg
     B::C::InitSection B::C::InitSection::SUPER
     descend_marked_unused: 
    ...
    %INC and @INC:
     Delete unsaved packages from %INC, so run-time require will pull them in:
     Deleting IO::Handle from %INC
     Deleting XSLoader from %INC
     Deleting B::C::Flags from %INC
     Deleting B::Asmdata from %INC
     Deleting Tie::Hash::NamedCapture from %INC
     Deleting B::C from %INC
     Deleting SelectSaver from %INC
     Deleting IO::Seekable from %INC
     Deleting base from %INC
     Deleting Config from %INC
     Deleting B from %INC
     Deleting Fcntl from %INC
     Deleting IO from %INC
     Deleting Symbol from %INC
     Deleting O from %INC
     Deleting Carp from %INC
     Deleting mro from %INC
     Deleting File::Spec::Unix from %INC
     Deleting FileHandle from %INC
     Deleting Exporter::Heavy from %INC
     Deleting strict from %INC
     Deleting Exporter from %INC
     Deleting vars from %INC
     Deleting Errno from %INC
     Deleting File::Spec from %INC
     Deleting IO::File from %INC
     Deleting DynaLoader from %INC
     %include_package: warnings warnings::register
     %INC: warnings.pm warnings/register.pm
     amagic_generation = 1
     Writing output
     Total number of OPs processed: 323
     NULLOP count: 8

%include_package contains: **warnings warnings::register**. These two cost a lot of time. 
Carp is also a nice example of code bloat for the static compiler.

Let's try without:

    $ perlcc -O3 -Uwarnings -Uwarnings::register -S -oregex-dna-c1  t/regex-dna.pl
    $ wc regex-dna-c.c
    2293  16084 128953 regex-dna-c.c
    $ wc regex-dna-c1.c
    1201  7488 57236 regex-dna-c1.c

128953 down to 57236 bytes. Double size with warnings. So lot of startup-time overhead.

    $ perlcc -O -O2 -Uwarnings -Uwarnings::register -S -oregex-dna-cc1 t/regex-dna.pl

    $ time ./regex-dna-c1 <t/regexdna-input
    ...
    real	0m**0.284s**
    user	0m0.271s
    sys		0m0.004s

    $ time ./regex-dna-cc1 <t/regexdna-input
    ...
    real	0m**0.266s**
    user	0m0.255s
    sys		0m0.008s

Not much gain by stripping warnings, since the main part is run-time, startup-time is usually 
0.010 (uncompiled) to 0.001 (compiled).

Wait, what perl is perlcc calling at all? Hopefully the same as perl. Nope. As it turns out 
perlcc was compiled debugging, and comparing debugging perls with non-debugging explains double run-time. You see it with -v in the output above /usr/local/bin/perl5.14.2d-nt, which is my naming [perlall-derived](http://search.cpan.org/dist/App-perlall/) convention for debugging non-threaded.

Recompiling the compiler with normal perl, and re-testing:

    $ perl -S perlcc -O3 -Uwarnings -Uwarnings::register -S -oregex-dna-c1  t/regex-dna.pl
    $ perl -S perlcc -O -O2 -Uwarnings -Uwarnings::register -S -oregex-dna-cc1  t/regex-dna.pl

    $ time ./regex-dna-c1 <t/regexdna-input
    ...
    real	0m0.127s
    user	0m0.124s
    sys		0m0.000s

    $ time ./regex-dna-cc1 <t/regexdna-input
    ...
    real	0m0.121s
    user	0m0.120s
    sys		0m0.008s

0.130s vs 0.127s (compiled) vs 0.121s (optimizing compiled) makes now sense. But not much room to improve here, as the regex engine already has a pretty good DFA (not the fastest as re::Engine::RE2 would be faster) but is not optimizable by the optimizing compiler.

Better optimize numbers. Tomorrow. I want to improve *stack smashing* in B::CC.
Getting rid of copying intermediate C values from the C stack and back to the perl heap.

See the [arithmetic part 2](http://blogs.perl.org/users/rurban/2012/10/optimizing-compiler-benchmarks-part-2.html)