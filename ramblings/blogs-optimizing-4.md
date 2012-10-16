nbody - More optimizations
--------------------------

In the [first part](http://blogs.perl.org/users/rurban/2012/09/optimizing-compiler-benchmarks-part-1.html)
I showed some problems and possibilities of the B::C compiler and
B::CC optimizing compiler with an regexp example which was very bad to
optimize.

In the [second part](http://blogs.perl.org/users/rurban/2012/10/optimizing-compiler-benchmarks-part-2.html)
I got 2 times faster run-times with the B::CC compiler with the
[nbody](http://shootout.alioth.debian.org/u32/performance.php?test=nbody) benchmark, which does a lot of arithmetic.

In the [third part](http://blogs.perl.org/users/rurban/2012/10/optimizing-compiler-benchmarks-part-3.html)
I got 4.5 times faster run-times with perl-level AELEMFAST optimizations, and discussed optimising array accesses
via no autovivification or types.

Optimising array accesses showed the need for autovivification detection in B::CC and better stack
handling for more ops and datatypes, esp. aelem and helem. 

But first let's study more easier goals to accomplish. If we look at
the generated C source for a simple arithmetic function, like
`pp_sub_offset_momentum` we immediately detect more possibilities.

    static
    CCPP(pp_sub_offset_momentum)
    {
    	SV *sv, *src, *dst, *left, *right;
    	NV rnv0, lnv0, d1_px, d2_py, d3_pz, d4_mass, d7_tmp, d10_tmp, d13_tmp, d15_tmp, d17_tmp, d19_tmp, d21_tmp, d23_tmp, d25_tmp, d27_tmp, d29_tmp, d31_tmp, d33_tmp, d35_tmp, d37_tmp, d40_tmp, d42_tmp, d44_tmp;
    	PERL_CONTEXT *cx;
    	MAGIC *mg;
    	I32 oldsave, gimme;
    	dSP;
      lab_2a41220:
    	TAINT_NOT;                 /* only needed once */
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* only needed once */
    	FREETMPS;                  /* only needed once */
    	SAVECLEARSV(PL_curpad[1]); /* not needed at all */
    	d1_px = 0.00;
      lab_2a41370:
    	TAINT_NOT;                 /* only needed once */
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* unneeded */
    	FREETMPS;                  /* only needed once */
    	SAVECLEARSV(PL_curpad[2]); /* not needed at all */
    	d2_py = 0.00;
      lab_2a50a00:
    	TAINT_NOT;                 /* only needed once */
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* unneeded */
    	FREETMPS;                  /* only needed once */
    	SAVECLEARSV(PL_curpad[3]); /* not needed at all */
    	d3_pz = 0.00;
      lab_2a50b30:
    	TAINT_NOT;                 /* only needed once */
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* unneeded */
    	FREETMPS;                  /* only needed once */
    	SAVECLEARSV(PL_curpad[4]); /* not needed at all */
      lab_2a50cc0:
    	TAINT_NOT;                 /* only needed once */
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* unneeded */
    	FREETMPS;                  /* only needed once */
    	PUSHs(AvARRAY(MUTABLE_AV(PL_curpad[5]))[0]);	/* no autovivification */
    	sv = POPs;
    	MAYBE_TAINT_SASSIGN_SRC(sv);    /* not needed */
    	SvSetMagicSV(PL_curpad[4], sv); /* i.e. PL_curpad[4] = sv; */
        ...

We can study the expanded macros with:

    cc_harness -DOPT -E -O2 -onbody.perl-2.perl-1.i nbody.perl-2.perl.c

`TAINT_NOT` does `(PL_tainted = (0))`. It is needed only once, because nobody
changes `PL_tainted`. We can also ignore taint checks generally by setting `-fomit_taint`.

    perl -MO=Concise,offset_momentum nbody.perl-2a.perl

    main::offset_momentum:
    42 <1> leavesub[1 ref] K/REFC,1 ->(end)
    -     <@> lineseq KP ->42
    1        <;> nextstate(main 141 (eval 5):4) v ->2
    4        <2> sassign vKS/2 ->5
    2           <$> const(NV 0) s ->3
    3           <0> padsv[$px:141,145] sRM*/LVINTRO ->4
    ...

`sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;` is the 2nd part of the inlined code for 
`nextstate` and resets the stack pointer. As we keep track of the stack by ourselves we can
omit most of these resets in nextstate.

`FREETMPS` is also part of `nextstate`, and calling it after each basic
block is optimized by -O1, and -O2 would free the temps after each
loop.  If FREETMPS is needed at all, i.e. if locals are used in the
function at all, is not checked yet.

`SAVECLEARSV(PL_curpad[1-4])` is part of `padsv /LVINTRO`, but here unneeded, since
it is in the context of sassign. So the value of the lexical does not need to be cleared
before it is set. And btw. the setter of the lexical is already optimized to a temporary.

`MAYBE_TAINT_SASSIGN_SRC(sv)` is part of `sassign` and can be omitted with `-fomit_taint`,
and since we are at `TAINT_NOT` we can leave it out.

`SvSetMagicSV(PL_curpad[4], sv)` is also part of the optimized `sassign` op, just not
yet optimized enough, since sv cannot have any magic. A type declaration for the `padsv`
would have used the faster equivalent `SvNV(PL_curpad[4]) = SvNV(sv);` put on the stack.

We can easily test this out by NOP'ing these code sections and see the costs.

With **4m53.073s**, without **4m23.265s**. 30 seconds or ~10% faster. This is now in the typical
range of p5p micro-optimizations and not considered high-priority for now.

Let's rather check out more stack optimizations.

I added a new [B::Stackobj::Aelem](https://github.com/rurban/perl-compiler/commit/edda0c5ca8cd8fd072e425977dd3a1f80d34857c) object to B::Stackobj to track aelemfast accesses
to array indices, and do the PUSH/POP optimizations on them.

The generated code now looks like:

      lab_116f270:
    	TAINT_NOT;
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
    	FREETMPS;
    	rnv0 = d9_mag; lnv0 = SvNV(AvARRAY((AV*)PL_curpad[25])[1]);	/* multiply */
    	d3_mm2 = lnv0 * rnv0;
      lab_116be90:
    	TAINT_NOT;
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
    	FREETMPS;
    	d5_dx = SvNV(PL_curpad[5]);
    	rnv0 = d3_mm2; lnv0 = d5_dx;	/* multiply */
    	d29_tmp = lnv0 * rnv0;
    	SvNVX(AvARRAY((AV*)PL_curpad[28])[0]) = SvNVX(AvARRAY((AV*)PL_curpad[28])[0]) - d29_tmp;

Lvalue assignments need SvNVX, right-value can keep SvNV.
The multiply op for `PL_curpad[28])[0]` has the OPf_MOD flag since the first arg is modified.
nextstate with TAINT, FREETMPS and sp reset is still not optimized.

Performance went from **4m53.073s** to **3m58.249s**, 55s or 18.7% faster. Much better than
with the nextstate optimizations. 30s less on top of this would be **3m30s**, still slower
than Erlang, Racket or C#. And my goal was 2m30s.

But there's still a lot to optimize (loop unrolling, aelem, helem, ...) and adding the [no autovivification check](https://github.com/rurban/perl-compiler/commit/cc90753d69000453856f4746fd885e058c30ff4b) was also costly. 
Several dependant packages were added to the generated code, like autovivification, Tie::Hash::NamedCapture, mro,
Fcntl, IO, Exporter, Cwd, File::Spec, Config, FileHandle, IO::Handle,
IO::Seekable, IO::File, Symbol, Exporter::Heavy, ...
But you don't see this cost in the binary size, and neither in the run-time.


I also tested the [fannkuchredux](http://shootout.alioth.debian.org/u32/benchmark.php?test=fannkuchredux&lang=all) benchmark, which was created for 
a bad [LISP compiler](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.35.5124) in 1994, also with array accessors.

Uncompiled with N=10 I got 16.093s, compiled 9.1222s, almost 2x times
faster (1.75x).  And this code has the same aelem problem as nbody, so
a loop unrolling to aelemfast and better direct accessors with
no-autovivification would lead to a ~4x times faster run-time.

nextstate optimisations
-----------------------

nextstate and its COP brother dbstate are mainly used to store the line
number of the current op for debugging.
I wrote an [oplines patch](https://github.com/rurban/perl/commits/oplines)
already to move the line info to all OPs, which reduced the need for
90% nextstate ops, which would overcome the problem we are facing here:

    PL_op = &curcop_list[0];                 /* set file and line number */
    TAINT_NOT;                                       /* only needed once */
    sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp; /* rarely needed */
    FREETMPS;                           /* rarely needed, only with TMPs */

oplines is not yet usable because it only reduces the number of nextstate ops,
but I haven't written the needed change to warnings and error handling which
would be needed to search for the current cop with warn or die, to be able to
display the file name together with the line number.

A different strategy would be to create simplier state COPs, without TAINT check,
without stack reset and without FREETMPS.
Like `state, state_t, state_s, state_f, state_ts, state_sf, state_tsf == nextstate`.


*TBC...*
