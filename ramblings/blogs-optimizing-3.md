nbody - Unrolling AELEM loops to AELEMFAST
------------------------------------------

In the [first
part](http://blogs.perl.org/users/rurban/2012/09/optimizing-compiler-benchmarks-part-1.html)
I showed some problems and possibilities of the B::C compiler and
B::CC optimizing compiler with an regexp example which was very bad to
optimize.

In the [second
part](http://blogs.perl.org/users/rurban/2012/10/optimizing-compiler-benchmarks-part-2.html)
I got 2 times faster run-times with the B::CC compiler with the
[nbody](http://shootout.alioth.debian.org/u32/performance.php?test=nbody) benchmark, which does a lot of arithmetic.

Two open problems were detected: slow function calls, and slow array accesses.

At first I inlined the function call which is called the most, `sub advance`
which was called N times, N being 5000, 50.000 or 50.000.000.

    for (1..$n) {
        advance(0.01);
    }

The runtime with N=50.000.000 went from 22m13.754s down to 21m48.015s,
25s less. This is not what I wanted.
php and jruby are at 12 min and 9m. So it is not slow functions calls,
it is slow array access.
Inspecting the opcodes shows that a lot of AELEM ops are used, for
reading and writing arrays.

AELEM checks for lvalue invocation and several more flags, which do
exist at compile-time and there exists a fast version already
AELEMFAST, but this only operates on literal constant indices, already
known at compile-time. The index is stored at compile-time in the
op->private flag then.

So instead of

    for (my $j = $i + 1; $j < $last + 1; $j++) {
      # inner-loop $j..4
      $dx = $xs[$i] - $xs[$j];
      $dy = $ys[$i] - $ys[$j];
      $dz = $zs[$i] - $zs[$j];
      ...

One could generate a macro-like string which just evals the array indices and generate from this
string the final function.

Array accesses: `$a[const]` are optimized to AELEMFAST, `$a[$lexical]` not.
So unroll the loop in macro-like fashion.

    $energy = '
    sub energy
    {
      my $e = 0.0;
      my ($dx, $dy, $dz, $distance);';
      for my $i (0 .. $last) {
    $energy .= "
    # outer-loop $i..4
        \$e += 0.5 * \$mass[$i] *
              (\$vxs[$i] * \$vxs[$i] + \$vys[$i] * \$vys[$i] + \$vzs[$i] * \$vzs[$i]);
    ";
      for (my $j = $i + 1; $j < $last + 1; $j++) {
    $energy .= "
        # inner-loop $j..4
        \$dx = \$xs[$i] - \$xs[$j];
        \$dy = \$ys[$i] - \$ys[$j];
        \$dz = \$zs[$i] - \$zs[$j];
        \$distance = sqrt(\$dx * \$dx + \$dy * \$dy + \$dz * \$dz);
        \$e -= (\$mass[$i] * \$mass[$j]) / \$distance;";
        }
      }
    $energy .= '
      return $e;
    }';
    eval $energy; die if $@;

Every `$i` and `$j` got expanded into a literal, 0 .. 4.

I did this loop unrolling for the three functions, and the results
were impressive. It is a nice little macro trick which you could use
for normal uncompiled perl code also.  With compiled code the
loop-unrolling should happen automatically.

Full code here: [nbody.perl-2.perl](https://github.com/rurban/shootout/commit/62b216756320e8c224eef2c933326924ab73c18a)

Original:

    $ perlcc --time -r -O -S -O1 --Wb=-fno-destruct,-Uwarnings,-UB,-UCarp ../shootout/bench/nbody/nbody.perl 50000
    script/perlcc: c time: 0.380353
    script/perlcc: cc time: 0.967525
    -0.169075164
    -0.169078071
    script/perlcc: r time: 2.214327

Unrolled:

    $ perlcc --time -r -O -S -O1 --Wb=-fno-destruct,-Uwarnings,-UB,-UCarp ../shootout/bench/nbody/nbody.perl-2.perl 50000
    script/perlcc: c time: 0.448817
    script/perlcc: cc time: 2.167499
    -0.169075164
    -0.169078071
    script/perlcc: r time: 1.341283

Another **2x times faster!**

For comparison the same effect uncompiled:

    $ time perl ../shootout/bench/nbody/nbody.perl 50000
    -0.169075164
    -0.169078071

    real	0m3.650s
    user	0m3.644s
    sys	0m0.000s

Unrolled:

    $ time perl ../shootout/bench/nbody/nbody.perl-2.perl 50000
    -0.169075164
    -0.169078071

    real	0m2.399s
    user	0m2.388s
    sys	0m0.004s

So we went from **3.6s** down to **2.4s** and compiled to **1.3s**.

With N=50,000,000 we got **14m12.653s** uncompiled and **7m11.3597s**
compiled. Close to jruby, even if the array accesses still goes
through the `av_fetch` function, magic is checked and undefined indices
are autovivified.


Generalization
--------------

The above macro-code code looks pretty unreadable, similar to lisp
macros, with its mix of quoted and unquoted variables.  The compiler
needs to detect unrollable loop code which will lead to more
constants and AELEMFAST ops. And we better define a helper function
for easier generation of such unrolled loops.

    # unquote local vars
    sub qv {
      my ($s, $env) = @_;
      # expand our local loop vars
      $s =~ s/(\$\w+?)\b/exists($env->{$1})?$env->{$1}:$1/sge;
      $s
    }

    $energy = '
    sub energy
    {
      my $e = 0.0;
      my ($dx, $dy, $dz, $distance);';
      for my $i (0 .. $last) {
        my $env = {'$i'=>$i,'$last'=>$last};
        $energy .= qv('
        # outer-loop $i..4
        $e += 0.5 * $mass[$i] *
              ($vxs[$i] * $vxs[$i] + $vys[$i] * $vys[$i] + $vzs[$i] * $vzs[$i]);', $env);
        for (my $j = $i + 1; $j < $last + 1; $j++) {
          $env->{'$j'} = $j;
          $energy .= qv('
          # inner-loop $j..4
          $dx = $xs[$i] - $xs[$j];
          $dy = $ys[$i] - $ys[$j];
          $dz = $zs[$i] - $zs[$j];
          $distance = sqrt($dx * $dx + $dy * $dy + $dz * $dz);
          $e -= ($mass[$i] * $mass[$j]) / $distance;', $env);
        }
      }
      $energy .= '
      return $e;
    }';
    eval $energy; die if $@;

This looks now much better and leads in a BEGIN block to only neglectible
run-time penalty.
Full code here: [nbody.perl-2a.perl](https://github.com/rurban/shootout/commit/c35bb85ed84941157eb01b7ca844d3b4472e0df3)

I also tried a generic `unroll_loop()` function, but it was a bit too
unstable finding the end of the loop blocks on the source level, and
`qv()` looked good enough. The compiler can use the optree to find the
optimization.


Types and autovivification
--------------------------

A naive optimization would check the index ranges beforehand, and access
the array values directly. Something the type optimizer for arrays would
do.

    my (num @xs[4],  num @ys[4],  num @zs[4]);
    my (num @vxs[4], num @vys[4], num @vzs[4]);
    my num @mass[4];

And instead of `$xs[0] * $xs[1]` which compiles to
AELEMFASTs, currently inlined by B::CC to:

    { AV* av = MUTABLE_AV(PL_curpad[6]);
      SV** const svp = av_fetch(av, 0, 0);
      SV *sv = (svp ? *svp : &PL_sv_undef);
      if (SvRMAGICAL(av) && SvGMAGICAL(sv)) mg_get(sv);
      PUSHs(sv);
    }
    { AV* av = MUTABLE_AV(PL_curpad[6]);
      SV** const svp = av_fetch(av, 1, 0);
      SV *sv = (svp ? *svp : &PL_sv_undef);
      if (SvRMAGICAL(av) && SvGMAGICAL(sv)) mg_get(sv);
      PUSHs(sv);
    }
    rnv0 = POPn; lnv0 = POPn;       /* multiply */
    d30_tmp = lnv0 * rnv0;

It should compile to:

    d30_tmp = (double)AvARRAY(PL_curpad[6])[0] *
              (double)AvARRAY(PL_curpad[6])[1];

With the size declaration you can omit the `av_fetch()` call and undef
check ("autovivification"), with the type `num` you do not need to get
to the `SvNV` of the array element, the value is stored directly, and
the type also guarantees that there is no magic to be checked.  So
`AvARRAY(PL_curpad[6])[0]` would return a double.

And the stack handling (PUSH, PUSH, POP, POP) can also be optimized
away, since the ops are inlined already.  That would get us close to
an optimizing compiler as with Haskell, Lua, PyPy or LISP. Not close
to Go or Java, as their languages are stricter.

I tried a simple B::CC AELEMFAST optimization together with "no autovivification"
which does not yet eliminate superfluous PUSH/POP pairs but could be applied
for typed arrays and leads to another 2x times win.

2.80s down to 1.67s on a slower PC with N=50,000.

Compiled to *(perlcc /2a)*:

    PUSHs(AvARRAY(PL_curpad[6])[0]));
    PUSHs(AvARRAY(PL_curpad[6])[1]));
    rnv0 = POPn; lnv0 = POPn;       /* multiply */
    d30_tmp = rnv0 * lnv0;

Without superfluous PUSH/POP pairs I suspect another 2x times win. But this
is not implemented yet. With typed arrays maybe another 50% win, and we don't
need the no autovivification overhead.

It should look like *(perlcc /2b)*:

    rnv0 = SvNV(AvARRAY(PL_curpad[6])[0]);
    lnv0 = SvNV(AvARRAY(PL_curpad[6])[1]);
    d30_tmp = rnv0 * lnv0;          /* multiply */

I'm just implementing the check for the 'no autovivification' pragma and
the stack optimizations.

Summary
-------

[u64q nbody](http://shootout.alioth.debian.org/u64q/performance.php?test=nbody)

Original numbers with N=50,000,000:

    * Fortran       14.09s
    * C             20.72s
    * Go            32.11s
    * SBCL          42.75s
    * Javascript V8 44.78s - 82.49s
    * JRuby       8m
    * PHP        11m
    * Python 3   16m
    * Perl       23m
    * Ruby 1.9   26m

My numbers with N=50,000,000:

    * Perl       22m14s
    * Perl 1     21m48s         (inline sub advance, no ENTERSUB/LEAVESUB)
    * perlcc      9m52s
    * Perl 2    14m13s          (unrolled loop + AELEM => AELEMFAST)
    * perlcc 2   7m11s
    * perlcc 2a  4m52s          (no autovivification, 4.5x faster)
    * perlcc 2b  ? (~2m30)      (no autovivification + stack opt)
    * perlcc 2c  ? (~1m25s)     (typed arrays + stack opt)

