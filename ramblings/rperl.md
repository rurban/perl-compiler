B::C[C] and rperl

With rperl we have now a second serious perl compiler project, which has distinctive advantages 
over B::C and B::CC, but also several disadvantages.

Basically we need to define compilation blocks of rperl (restricted perl) - 
typed and compile-time optimizable syntax - and combine it with unoptimizable dynamic perl5 syntax, 
to be able to run ordinary perl5 code. Partially optimized.

B::C can compile dynamic perl5 syntax to C code and simply run the unoptimized optree through libperl.
B::CC does control-flow optimizations, esp. on stack variables but has no type integration yet, and 
will never be able to run 100% of perl5 code. perl5 is a too dynamic language to be properly
compilable as you would expect, but perl5 has support to parse and store types, just nobody is using it yet. And p5p does not support optimizations based on the type information, it rather blocks those attempts. So we need seperate compilation to C (reini), C++ (will) or LLVM (goccy).
perlcc, the frontend, cannot compile yet .pm packages to single shared libraries and link it together,
to be able to use different copile-time optimizations, and reduce compile and link times.
rperl can compile restricted typed syntax, using C++ libraries to operate on typed data and source-level type
information. This is a much better approach then with B::CC which optimizes only on int and num lexical variables. rperl can also treat efficiently typed and no-magic arrayrefs, hashrefs and function arguments and return types. Because it has control over the parser and compiler, which B::CC has not.

The problem is that rperl cannot use the perl AST, the B optree, because it is too tightly bound to the 
mostly undocumented internal ops and data, which is hard to work with properly from outside perl5. So rperl uses the PPI AST, 
interestingly called DOCTREE, does the type optimization and translation to C++ on this doctree via Inline::C++ which is btw. called Inline::CPP, not CXX and has nothing to do with the C preprocessor.

If you look at rperl/docs/rperl_grammar.txt you'll see the parsed boundaries with which another compiler
can interact with rperl. Basically we could use seperate compilation units (module files or programs) or single 
blocks with rperl syntax, and maybe as advanced problems subroutines, but then you need to pass the type
information of the arguments and return values back and forth. This is done via standard XS typemaps.

perlcc or maybe a script called buildcc should be usable as frontend to link seperate compilation units as compiled libraries (shared or static)
together and the different compilers should be able to detect each other and pass the work back and forth.
It needs to be seperate because they use different parsers and different compilers, but agree on the same
types and the typed calling convention. This calling convention should be specified on the C/C++ level, and for the user it
would be nice if the perl-level types also agree. The basis for these types would be perl6 types because these
are the only ones in existance today.
B::C can do int and num and accepts str.
rperl requires also object and void, and can already do aggregate types, like arrayrefs and hashrefs of those types.
perl6 adds bool, some more numbers and intermediate and meta object types, which we dont need yet.
What needs to be added are sized array declarations to be able to omit run-time bounds checks, but this should be trivial.

rperl already offers compile-time or run-time type-checks and compile-time type optimizations.

How to interface?

Inline is not easy to interface with, notoriously hard to debug, and has several unmaintained bugs and omissions.
But it's the best and most transparent way, and the only way to mix perl and rperl code on the source level.
The biggest bug is the notorious "namespace hack", i.e. the stashes for the generated functions and data are missing.
Also argument passing has some serious limitations. Will is using a really crazy hack right now in rperl to push
arrayrefs and hashref arguments properly onto the stack, the inline stack macros are too simple, they only work for
trivial examples. Inline::CPP does not properly support passing plain arrays and hashes to and from perl5 code, so now rperl uses just scalar types, esp. arrayrefs and hashrefs.
We will need to look into lifting those limitations.

Methods

Methods and subroutines need to be seperated at compile-time for rperl/Inline:CPP. In the old days there was a :method attribute idea, which is not compile-time accessible, only at run-time. And there were Devel::Declare based hacks to support class and method keywords, but they never made it into core. Nowadays Devel::Declare is not needed anymore, but there is still no flag to denote methods-only or OO semantics as in perl6 to enable OO compile-time optimizations, such as method dispatch and method inlining. use oo :closed :immutable. We cannot even declare yet read-only hashes or @ISA arrays properly, as they still clash with restricted hashes and COW. So they need to be implemented seperately, as done in rperl.
In rperl method types are done via special type names, to denote the return type and if it's a method or normal subroutine.
