nbody - unboxed inlined arithmetic 2x faster
=============================================

In the [first part](http://blogs.perl.org/users/rurban/2012/09/optimizing-compiler-benchmarks-part-1.html) I showed some problems and possibilities of the B::C compiler and B::CC optimizing compiler with an example which was very bad to optimize, and promised for the next day an improvement with "stack smashing", avoiding copy overhead between the compiler stacks and global perl data.

The next days I went to Austin to meet with the [perl11.org](http://perl11.org/) group, which has as one of the goals an optimizing compiler for perl5, and to replace all three main parts of perl: the parser, the compiler/optimizer and the vm (the runtime) at will. You can do most of it already, esp. replace the runloop, but the 3 parts are too intermingled and undocumented.

So I discussed the "stack smashing" problem with Will and my idea on the solution.

1. The "stack smashing" problem
-------------------------------

B::CC keeps two internal stacks to be able to optimize arithmetic and boolean operations on numbers, int IV and double NV.

The first stack, called "stack", keeps the perl operand stack, the arguments for each push/pop runtime pp\_* function.
The perl AST, called optree, is a bit disfunctional, as it not able to generate optimized variants on the operand types. So e.g there are integer optimized versions, used with "use integer", e.g. an i\_add variant for the add operator, which are used if both operands are known to be integers or integer constants at compile-time. There are no variants for strict NV, and most importantly, there are no variants for degenerated arguments, arguments with magic. Because you can add magic at run-time, which the compiler (op.c) does not know about (*which is super lame*), all argument types need to be checked at run-time, and you always have to go the slow general path.

This B::CC stack, implemented in B::Stackobj keeps track of the types during the lifetime and can optimize and pessimize the used type of each stack variable. It can esp. optimize on bool, int and double, needs to exchange values on stringification and pessimizes on magic, esp. tie (a variable) and overload (an op).
There is no nice picture in [illguts](http://search.cpan.org/dist/illguts/) describing operand stacks.

The second stack holds lexicals. For all perl lexical variables the same is done, the B::Stackobj::Padsv lexical stack mimics every function's PADLIST. Contrary to the stack, the access to this list is optimized by the compiler (op.c) already at compile-time in the PL_curpad array, since it defines lexicals variables which are fully known at compile-time. So each op knows the exact index into the padlist, stored in the fields "targ" or "padix". Pad types are dynamic as on the stack, but there is an additional list, the comppadnames, which holds optional type information, essentially a pointer to packagename for each typed variable. It is just unused yet.
See illguts for a [picture](http://cpansearch.perl.org/src/RURBAN/illguts-0.42/index.html#stack).

B::Stackobj::Padsv can use the perl type information for the packages int and double, but not yet for number and bool or CTypes nor Moose types. So `my int $i` already specifies an optimized integer, as an IV during the scope of `use integer`.

Specifying types via perl attributes, like `my $i :int;` would be nice also, but is technically impossible, since there is no compile-time method for attributes to be checked; only at run-time.

`B::CC` keeps a list of good ops (pp\_ functions), where the type or at least the number of arguments or return types is known at compile time. The same information is also available in the [Opcodes](http://search.cpan.org/dist/Opcodes/) module on CPAN.
Defined are op lists like, no\_stack, skip\_stack,  skip\_lexicals, skip\_invalidate, need\_curcop and for various other predefined op types needed for other optimizers or the Jit module. Does it branch, i.e. will it always return op->next or not?
Does it need to call PERL\_ASYNC\_CHECK?

On all unknown ops or ops which need to access lexicals, the current internal B::Stackobj::Padsv lexical stack values need to refreshed, written back from the internal compiler stack to the actual values on the heap, which is `PL_curpad[ix].` (sub write\_back\_lexicals). The same must be done for all stack variables which need to accessed by the next op (sub write\_back\_stack). Just not for ops, which do not access stack variables.

So there is a lot of theoretical copying - "stack smashing" - going on.
But B::CC is cleverly keeping track of the stack areas which need to be written back, so in practice only the really needed values are handled.
In practice only numeric and boolean optimizations operate on private c variables on the C stack, rather than on referenced heap values, either on the perl stack or in the curpad. Simple sort callbacks also.
So only on unboxed numbers we need to copy the values back and force, before and after, as B::CC inlines most of these ops.

2. Benchmarks
-------------

I'll take a benchmark in which Perl is very slow compared to other scripting
languages, and which does a lot of arithmetic. Because I expect the
B::CC type optimizer to kick in, unboxing all the numbers, and inling
most of the arithmetic.

[nbody](http://shootout.alioth.debian.org/u32/performance.php?test=nbody)
performs a simple N-body simulation of the Jovian planets.
Perl is currently by far the slowest scripting language for nbody,
26 min compared to 9-18 min for ruby, php or python with n=50,000,000.

perl = perl5.14.2-nt (non-threaded, -Os -msse4.2 -march=corei7)

    $ time perl ../shootout/bench/nbody/nbody.perl 50000

    -0.169075164
    -0.169057007

     real	0m1.305s
     user	0m1.300s
     sys	0m0.000s

Compiled:

    $ perlcc --time -r -O -S -O1 --Wb=-fno-destruct,-Uwarnings,-UB,-UCarp,-DOscpSqlm,-v \
                  ../shootout/bench/nbody/nbody.perl 50000

    script/perlcc: c time: 0.171225
    script/perlcc: cc time: 0.984996
    -0.169075214
    -0.169078108
    script/perlcc: r time: 0.600024

So we get a **2x times faster run-time**, with a little bit of different results and a lot of interesting command line options.

**--time** prints the B::CC time as 'c time', the gcc and ld time as 'cc time', and the run-time as 'r time'. 0.625202s vs. 1.305s in pure perl. Even gcc plus ld with -OS is faster than perl. And B::CC's optimizer is also real fast here in this simple example.

**-r** runs the compiled program with the rest of the perlcc arguments

**-O** compiles with B::CC, not with the non-optimizing B::C

**-S** keeps the C source, to be able to inspect the generated optimized C code.

**-O1** adds some minor B::CC optimizations. -O2 is pretty unstable yet, and B::CC proper (-O0) already adds all B::C -O3 optimizations.

**--Wb** defines further B::CC options

**-fno-destruct** is a B::C option to skip optree destruction at the very end. It does thread, IO and object destruction in proper order, and of course does object destruction during run-time, but we do not care of memory leaks with normal executables. Process termination does it better and faster than perl. Even daemons are safe to be compiled with -fno-destruct, just not shared libraries.

-U defines packages to be **unused**. warnings, B, Carp are notorious compiler packages, which are innocently being pulled in, even if you do not use or call them.

B is used by the compiler itself, and since the B maintainer does a terrible job helping the B compiler modules, we have to manually force B get out of our way. warnings and Carp are also magically pulled in by some dependent core modules and cause a lot of startup and memory overhead. These 3 packages are easily skipped with simple programs or benchmarks, in the real world you have to live with multi-megabyte compiled programs. This reflects the reality of the memory perl uses during run-time.

E.g. without -U the numbers are:

    cc pp_main
     cc pp_sub_offset_momentum
     cc pp_sub_energy
     cc pp_sub_advance
     Prescan 1 packages for unused subs in main::
     Saving unused subs in main::
     old unused: 1, new: 1
     no %SIG in BEGIN block
     save context:
     cc pp_sub_warnings__register_categories
     cc pp_sub_warnings___mkMask
     Total number of OPs processed: 193
     NULLOP count: 0
     bootstrapping DynaLoader added to xs_init
     no dl_init for B, not marked
     my_perl_destruct (-fcog)
    script/perlcc: c time: 0.192175
    script/perlcc: cc time: 1.3049
    -0.169075214
    -0.169078108
    script/perlcc: r time: 0.642252

**-DOscpSqlm** are some debugging options, which add interesting information into the generated C code. B::CC adds debugging output as comments into the C code, to be able to inspect the optimizer result, B::C prints debugging output to STDOUT.

Let's have a look into the [code](http://shootout.alioth.debian.org/u32/program.php?test=nbody&lang=perl&id=1).

`cat ../shootout/bench/nbody/nbody.perl`


    # The Computer Language Shootout
    # http://shootout.alioth.debian.org/
    #
    # contributed by Christoph Bauer
    # converted into Perl by Márton Papp
    # fixed and cleaned up by Danny Sauer
    # optimized by Jesse Millikan

    use constant PI            => 3.141592653589793;
    use constant SOLAR_MASS    => (4 * PI * PI);
    use constant DAYS_PER_YEAR => 365.24;

    #  Globals for arrays... Oh well.
    #  Almost every iteration is a range, so I keep the last index rather than a count.
    my (@xs, @ys, @zs, @vxs, @vys, @vzs, @mass, $last);

    sub advance($)
    {
      my ($dt) = @_;
      my ($mm, $mm2, $j, $dx, $dy, $dz, $distance, $mag);

      #  This is faster in the outer loop...
      for (0..$last) {
      #  But not in the inner loop. Strange.
        for ($j = $_ + 1; $j < $last + 1; $j++) {
          $dx = $xs[$_] - $xs[$j];
          $dy = $ys[$_] - $ys[$j];
          $dz = $zs[$_] - $zs[$j];
          $distance = sqrt($dx * $dx + $dy * $dy + $dz * $dz);
          $mag = $dt / ($distance * $distance * $distance);
          $mm = $mass[$_] * $mag;
          $mm2 = $mass[$j] * $mag;
          $vxs[$_] -= $dx * $mm2;
          $vxs[$j] += $dx * $mm;
          $vys[$_] -= $dy * $mm2;
          $vys[$j] += $dy * $mm;
          $vzs[$_] -= $dz * $mm2;
          $vzs[$j] += $dz * $mm;
        }

        # We're done with planet $_ at this point
        # This could be done in a seperate loop, but it's slower
        $xs[$_] += $dt * $vxs[$_];
        $ys[$_] += $dt * $vys[$_];
        $zs[$_] += $dt * $vzs[$_];
      }
    }

    sub energy
    {
      my ($e, $i, $dx, $dy, $dz, $distance);

      $e = 0.0;
      for $i (0..$last) {
        $e += 0.5 * $mass[$i] *
              ($vxs[$i] * $vxs[$i] + $vys[$i] * $vys[$i] + $vzs[$i] * $vzs[$i]);
        for ($i + 1..$last) {
          $dx = $xs[$i] - $xs[$_];
          $dy = $ys[$i] - $ys[$_];
          $dz = $zs[$i] - $zs[$_];
          $distance = sqrt($dx * $dx + $dy * $dy + $dz * $dz);
          $e -= ($mass[$i] * $mass[$_]) / $distance;
        }
      }
      return $e;
    }

    sub offset_momentum
    {
      my ($px, $py, $pz) = (0.0, 0.0, 0.0);

      for (0..$last) {
        $px += $vxs[$_] * $mass[$_];
        $py += $vys[$_] * $mass[$_];
        $pz += $vzs[$_] * $mass[$_];
      }
      $vxs[0] = - $px / SOLAR_MASS;
      $vys[0] = - $py / SOLAR_MASS;
      $vzs[0] = - $pz / SOLAR_MASS;
    }

    # @ns = ( sun, jupiter, saturn, uranus, neptune )
    @xs = (0, 4.84143144246472090e+00, 8.34336671824457987e+00, 1.28943695621391310e+01, 1.53796971148509165e+01);
    @ys = (0, -1.16032004402742839e+00, 4.12479856412430479e+00, -1.51111514016986312e+01, -2.59193146099879641e+01);
    @zs = (0, -1.03622044471123109e-01, -4.03523417114321381e-01, -2.23307578892655734e-01, 1.79258772950371181e-01);
    @vxs = map {$_ * DAYS_PER_YEAR}
      (0, 1.66007664274403694e-03, -2.76742510726862411e-03, 2.96460137564761618e-03, 2.68067772490389322e-03);
    @vys = map {$_ * DAYS_PER_YEAR}
      (0, 7.69901118419740425e-03, 4.99852801234917238e-03, 2.37847173959480950e-03, 1.62824170038242295e-03);
    @vzs = map {$_ * DAYS_PER_YEAR}
      (0, -6.90460016972063023e-05, 2.30417297573763929e-05, -2.96589568540237556e-05, -9.51592254519715870e-05);
    @mass = map {$_ * SOLAR_MASS}
      (1, 9.54791938424326609e-04, 2.85885980666130812e-04, 4.36624404335156298e-05, 5.15138902046611451e-05);

    $last = @xs - 1;

    offset_momentum();
    printf ("%.9f\n", energy());

    my $n = $ARGV[0];

    # This does not, in fact, consume N*4 bytes of memory
    for (1..$n){
      advance(0.01);
    }

    printf ("%.9f\n", energy());


A lot of arithmetic, only three functions, advance is called 50,000 times, the others only once.

The generated C code for some inlined arithmetic looks like:

`$ grep -A50 pp_sub_energy nbody.perl.c`


    static
    CCPP(pp_sub_energy)
    {
        double rnv0, lnv0, d1_e, d2_i, d3_dx, d4_dy, d5_dz, d6_distance, d11_tmp, d13_tmp,
               d15_tmp, d16_tmp, d18_tmp, d19_tmp, d20_tmp, d22_tmp, d31_tmp, d32_tmp, d33_tmp,
               d34_tmp, d35_tmp, d37_tmp, d38_tmp;
    	SV *sv, *src, *dst, *left, *right;
    	PERL_CONTEXT *cx;
    	MAGIC *mg;
    	I32 oldsave, gimme;
    	dSP;
    	/* init_pp: pp_sub_energy */
    	/* load_pad: 39 names, 39 values */
    	/* PL_curpad[1] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[1] iv=i1_e nv=d1_e */
    	/* PL_curpad[2] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[2] iv=i2_i nv=d2_i */
    	/* PL_curpad[3] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[3] iv=i3_dx nv=d3_dx */
    	/* PL_curpad[4] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[4] iv=i4_dy nv=d4_dy */
    	/* PL_curpad[5] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[5] iv=i5_dz nv=d5_dz */
    	/* PL_curpad[6] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[6] iv=i6_distance nv=d6_distance */
    	/* PL_curpad[7] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[7] iv=i7_last nv=d7_last */
    	/* PL_curpad[8] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[8] iv=i8_tmp nv=d8_tmp */
    	/* PL_curpad[9] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[9] iv=i9_tmp nv=d9_tmp */
    	/* PL_curpad[10] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[10] iv=i10_tmp nv=d10_tmp */
    	/* PL_curpad[11] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[11] iv=i11_tmp nv=d11_tmp */
    	/* PL_curpad[12] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[12] iv=i12_tmp nv=d12_tmp */
    	/* PL_curpad[13] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[13] iv=i13_tmp nv=d13_tmp */
    	/* PL_curpad[14] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[14] iv=i14_tmp nv=d14_tmp */
    	/* PL_curpad[15] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[15] iv=i15_tmp nv=d15_tmp */
    	/* PL_curpad[16] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[16] iv=i16_tmp nv=d16_tmp */
    	/* PL_curpad[17] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[17] iv=i17_tmp nv=d17_tmp */
    	/* PL_curpad[18] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[18] iv=i18_tmp nv=d18_tmp */
    	/* PL_curpad[19] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[19] iv=i19_tmp nv=d19_tmp */
    	/* PL_curpad[20] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[20] iv=i20_tmp nv=d20_tmp */
    	/* PL_curpad[21] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[21] iv=i21_tmp nv=d21_tmp */
    	/* PL_curpad[22] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[22] iv=i22_tmp nv=d22_tmp */
    	/* PL_curpad[23] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[23] iv=i23_tmp nv=d23_tmp */
    	/* PL_curpad[24] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[24] iv=i24_tmp nv=d24_tmp */
    	/* PL_curpad[25] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[25] iv=i25_tmp nv=d25_tmp */
    	/* PL_curpad[26] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[26] iv=i26_tmp nv=d26_tmp */
    	/* PL_curpad[27] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[27] iv=i27_tmp nv=d27_tmp */
    	/* PL_curpad[28] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[28] iv=i28_tmp nv=d28_tmp */
    	/* PL_curpad[29] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[29] iv=i29_tmp nv=d29_tmp */
    	/* PL_curpad[30] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[30] iv=i30_tmp nv=d30_tmp */
    	/* PL_curpad[31] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[31] iv=i31_tmp nv=d31_tmp */
    	/* PL_curpad[32] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[32] iv=i32_tmp nv=d32_tmp */
    	/* PL_curpad[33] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[33] iv=i33_tmp nv=d33_tmp */
    	/* PL_curpad[34] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[34] iv=i34_tmp nv=d34_tmp */
    	/* PL_curpad[35] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[35] iv=i35_tmp nv=d35_tmp */
    	/* PL_curpad[36] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[36] iv=i36_tmp nv=d36_tmp */
    	/* PL_curpad[37] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[37] iv=i37_tmp nv=d37_tmp */
    	/* PL_curpad[38] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[38] iv=i38_tmp nv=d38_tmp */
    	/* PL_curpad[39] = Padsv type=T_UNKNOWN flags=VALID_SV|REGISTER|TEMPORARY sv=PL_curpad[39] iv=i39_tmp nv=d39_tmp */
      lab_1fd4ba0:	/* nextstate */
    	/* stack =  */
    	/* COP (0x1fd4ba0) nextstate [0] */
    	/* ../shootout/bench/nbody/nbody.perl:51 */
    	TAINT_NOT;
    	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
    	FREETMPS;
    	/* write_back_stack() 0 called from B::CC::compile_bblock */
      lab_1fd4a10:	/* pushmark */
    	/* stack =  */
    	/* OP (0x1fd4a10) pushmark [0] */
    	/* write_back_stack() 0 called from B::CC::pp_pushmark */
    	PUSHMARK(sp);
    	/* stack =  */
    	/* OP (0x1fd4960) padsv [1] */
    	SAVECLEARSV(PL_curpad[1]);
    	/* stack = PL_curpad[1] */
    	/* OP (0x1fd49c0) padsv [2] */
    	SAVECLEARSV(PL_curpad[2]);
    	/* stack = PL_curpad[1] PL_curpad[2] */
    	/* OP (0x1fd4a40) padsv [3] */
    	SAVECLEARSV(PL_curpad[3]);
    	/* stack = PL_curpad[1] PL_curpad[2] PL_curpad[3] */
    	/* OP (0x1fd4a90) padsv [4] */
    	SAVECLEARSV(PL_curpad[4]);
    	/* stack = PL_curpad[1] PL_curpad[2] PL_curpad[3] PL_curpad[4] */
    	/* OP (0x1fd4990) padsv [5] */
    	SAVECLEARSV(PL_curpad[5]);
    	/* stack = PL_curpad[1] PL_curpad[2] PL_curpad[3] PL_curpad[4] PL_curpad[5] */
    	/* OP (0x1fd4930) padsv [6] */
    	SAVECLEARSV(PL_curpad[6]);
    	/* stack = PL_curpad[1] PL_curpad[2] PL_curpad[3] PL_curpad[4] PL_curpad[5] PL_curpad[6] */
    	/* LISTOP (0x1e99820) list [0] */
    	/* list */
    	/* write_back_stack() 6 called from B::CC::pp_list */
    	EXTEND(sp, 6);
    	PUSHs((SV*)PL_curpad[1]);
    	PUSHs((SV*)PL_curpad[2]);
    	PUSHs((SV*)PL_curpad[3]);
    	PUSHs((SV*)PL_curpad[4]);
    	PUSHs((SV*)PL_curpad[5]);
    	PUSHs((SV*)PL_curpad[6]);
    	PP_LIST(1);
    	/* write_back_stack() 0 called from B::CC::compile_bblock */
        ...

No interesting code, but you get the idea that the compiler keeps track of all
the used lexicals and stack variables and was able to optimize some types of most of the
numeric lexicals.

    sub energy
    {
      my ($e, $i, $dx, $dy, $dz, $distance);
    ...

E.g.
`PL_curpad[1] = Padsv type=T_UNKNOWN flags=VALID_SV sv=PL_curpad[1] iv=i1_e nv=d1_e`

`PL_curpad[1]` the first lexical, which is named `i1_e` for the IV value and $e in the perl code.

`type=T_UNKNOWN` means that there was no strict type information inferred. `T_DOUBLE` would have been
better as `$e` is only used as NV and returns the resulting energy. A declaration of `my double $e;`
would have done that.

`flags=VALID_SV` is also not optimal, `|REGISTER|TEMPORARY` would be better. `iv=i1_e nv=d1_e`
are the two theoretical dual vars during the life-time in this local function. But only the
NV `d1_e` is used. The IV part `i1_e` is never used and not declared.

Let's continue to some interesting parts:

    lab_1fffd30:	/* nextstate */
	/* ../shootout/bench/nbody/nbody.perl:61 */
	TAINT_NOT;
	sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
	FREETMPS;
	/* stack =  */
	/* OP (0x1fd5260) padsv [3] */
	/* stack = PL_curpad[3] */
	/* OP (0x1fd5290) padsv [3] */
	/* stack = PL_curpad[3] PL_curpad[3] */
	/* BINOP (0x1fd51c0) multiply [31] */
	d3_dx = SvNV(PL_curpad[3]);
	rnv0 = d3_dx; lnv0 = d3_dx;	/* multiply */
	d31_tmp = lnv0 * rnv0;
	/* stack = d31_tmp */
	/* OP (0x1fffaf0) padsv [4] */
	/* stack = d31_tmp PL_curpad[4] */
	/* OP (0x1fffb20) padsv [4] */
	/* stack = d31_tmp PL_curpad[4] PL_curpad[4] */
	/* BINOP (0x1fffb50) multiply [32] */
	d4_dy = SvNV(PL_curpad[4]);
	rnv0 = d4_dy; lnv0 = d4_dy;	/* multiply */
	d32_tmp = lnv0 * rnv0;
	/* stack = d31_tmp d32_tmp */
	/* BINOP (0x1fffb90) add [33] */
	rnv0 = d32_tmp; lnv0 = d31_tmp;	/* add */
	d33_tmp = lnv0 + rnv0;
	/* stack = d33_tmp */
	/* OP (0x1fffbd0) padsv [5] */
	/* stack = d33_tmp d5_dz */
	/* OP (0x1fffc00) padsv [5] */
	/* stack = d33_tmp d5_dz d5_dz */
	/* BINOP (0x1fffc30) multiply [34] */
	rnv0 = d5_dz; lnv0 = d5_dz;	/* multiply */
	d34_tmp = lnv0 * rnv0;
	/* stack = d33_tmp d34_tmp */
	/* BINOP (0x1fffc70) add [35] */
	rnv0 = d34_tmp; lnv0 = d33_tmp;	/* add */
	d35_tmp = lnv0 + rnv0;
	/* stack = d35_tmp */
	/* UNOP (0x1fffcb0) sqrt [6] */
	/* write_back_lexicals(0) called from B::CC::default_pp */
	sv_setnv(PL_curpad[5], d5_dz);
	sv_setnv(PL_curpad[31], d31_tmp);
	sv_setnv(PL_curpad[32], d32_tmp);
	sv_setnv(PL_curpad[33], d33_tmp);
	sv_setnv(PL_curpad[34], d34_tmp);
	sv_setnv(PL_curpad[35], d35_tmp);
	/* write_back_stack() 1 called from B::CC::default_pp */
	EXTEND(sp, 1);
	PUSHs((SV*)PL_curpad[35]);
	PL_op = (OP*)&unop_list[31];
	DOOP(PL_ppaddr[OP_SQRT]);
	/* invalidate_lexicals(0) called from B::CC::default_pp */
	/* stack =  */

This is part of:

      $distance = sqrt($dx * $dx + $dy * $dy + $dz * $dz);

We see the `OP_SQRT` as last part, not inlined, and all the simple
`+` and `*` being unboxed and inlined via tempory variables.
What I called stack smashing is `write_back_lexicals` writing back
the nv values of `PL_curpad[5]` and `PL_curpad[31-35]`,
and `write_back_stack()` `PL_curpad[35]` as argument for SQRT.

My idea was to calculate directly on the `SvNVX(PL_curpad[*])` values,
but on second thought I believe copying the values to temporaries,
basically in local stack locations or even in registers is faster
than doing ptr references to them. Initialising and writing them back
seems to be okay and not exaggerated.

So arithmetic optimizations are already pretty good, sqrt could be
inlined also, since perl has no bignum promotion, so the big remaining
problems are consting, function calls, method calls and stabilize
B::CC.

To compare real numbers, *50_000_000* is the argument used at alioth, leading to 26m.
My PC is a bit faster, needing 22m13s.

    $ time perl5.14.2-nt ../shootout/bench/nbody/nbody.perl 50000
    -0.169075164
    -0.169096567

    real	**0m13.132s**
    user	0m13.109s
    sys	        0m0.000s

Compiled:

    perlcc --time -r -O -S -O1 --Wb=-fno-destruct,-Uwarnings,-UB,-UCarp \
           ../shootout/bench/nbody/nbody.perl 50000

    script/perlcc: c time: 0.158228
    script/perlcc: cc time: 0.98483
    -0.169075214
    -0.169096616
    script/perlcc: r time: **5.992293**

Comparable times with N=50,000,000:

    perlcc --time -r -O -S -O1 --Wb=-fno-destruct,-Uwarnings,-UB,-UCarp \
           ../shootout/bench/nbody/nbody.perl 50000000

    script/perlcc: c time: 0.19311
    script/perlcc: cc time: 0.962425
    -0.169075214
    -0.169096616
    script/perlcc: r time: **591.965999**

Reference value, uncompiled:

    time perl5.14.2-nt ../shootout/bench/nbody/nbody.perl 50000000
    -0.169075164
    -0.169059907

    real        22m13.754s
    user        22m8.155s
    sys         0m1.156s

591.965999s = **9m51.966s** vs 22m13.754s

So we bypassed python 3 (18m), php (12min) and ruby 1.9 (23m), but not jruby (9m).
jruby uses 585,948KB memory though, and at least php has a better algo.

Function calls and more optimisations are inspected in part 3, hopefully with
the [binarytrees](http://shootout.alioth.debian.org/u32/performance.php?test=binarytrees)
benchmark.  I will also analyse the calls to the `sub analyse` loop
here, as `sub analyse` can be easily optimized automatically. This
function does not throw exceptions, has a prototype defining one
argument, has no return value and ignores return values, and does not
define any locals. It even can be automatically inlined.

    for (1..$n) {
        advance(0.01);
    }

The uncompiled, inlined version for `sub analyse` needs 21m48.015s, 25s less.
Compiled and inlined manually: 612.395542s (10m12s), a bit slower than not inlined.
So the biggest performance hit is the unoptimized slow AELEM op, which accesses
array elements. With an immediate AELEM the run-time should be 8-10x faster,
such as the AELEMFAST op, which is already inlined. I'm going for LVAL optimizations
in AELEM.
Typed arrays would also help a lot here.


Increasing precision
--------------------

The casual reader might have noticed that the compiler result would
not pass the shootout precision tests as it produced an invalid
result.

Wanted: +-1e-8 with arg 1000

    -0.169075164
    -0.169087605

Have: with arg 1000

    -0.169075214
    -0.169087656

That's not even close, it's a 6 digit precision. The perl afficionado
might remember the Config settings `nvgformat` to print out NV, and
`d_longdbl` to define if `long double` is defined.

`long double` is however not used as NV, and worst `%g` is used as
printf format for NV, not `%.16g` as it should be done to keep double
precision. `%g` is just a pretty result to the casual reader, but not
suitable to keep precision, e.g. for Data::Dumper, YAML, JSON,
or the B::C or perlito compilers.

So I changed the NV format to %.16g with commit [3fc61aa](https://github.com/rurban/perl-compiler/commit/3fc61aa69af24d438a2983a15996362207443f43)
and the precision went up, passing the nbody shootout test with argument 1000.

New result with arg 1000

    -0.169075164
    -0.169087605

Exactly the same. Also for other n cmdline arguments.

See [part 3](http://blogs.perl.org/users/rurban/2012/10/optimizing-compiler-benchmarks-part-3.html) which finds more optimizations, being 2x times faster on top of this.