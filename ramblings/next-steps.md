perlcc next steps
-----------------

cPanel uses now the new perl compiler B::C with -O3 and --staticxs
with 5.14.4 in production, and I'm outlining the next steps.

Our old compiler (with 5.6.2) needed 2:30 hours for each build,
produced ~100 binaries of about 30-50MB size. This sounds a lot but it
is not.  This is about the size a single perl scripts needs in memory,
but a single perl script has to find all the dependent files first,
load and parse it, and construct the stashes, the nested hashes of
namespaces. All this is not needed at all during run-time, hence
perlcc compiled binaries do not need it.

There are not many shared libraries used in such a compiled binary,
just libperl and the used XS shared libraries.

Starting such a single binary is very fast, it's just mapped into
memory at once, then the dynamic symbols need to be generated, as B::C
cannot yet generate them statically, and perl5 is not really helpful
in supporting static symbols, but all other data, strings and ops
(perl functions) are generated statically. Then the XS modules are
initialized (booted), then some pointers pointing into the XS
libraries need to updated, as the pointed to someother pointer at
compile-time and then the perl program is started.

perlcc -m
---------

The plan for the next year is to support generating shared modules per
perl package, perlcc -m compiles a package to a shared library,
buildcc generates the Makefile.depend dependencies for each binary,
and then you can use selectively more advanced optimizations per
package. I.e. B::CC or rperl optimized compilations, which should run
2-20x faster than the current B::C compiled packages.

B::CC is not stable enough yet, so you can only use it with some
modules, and it currently benefits greatly from type information, for
which upstream maintainers have no interest. With rperl it is even
more strict, as those modules are not even more strict, as in real
programming languages compared to our simple dynamic scripting
language, it explicitly disallows certain kinds of dynamic magic or
array autovivification, which slows down run-time so much as
benchmarked in my YAPC::EU 2013 talk.

So the plan is to compile to several optimized libraries seperately
and link them together later. For binaries which fork or which need to
be updated pretty often, shared libraries are preferred, for other
simple binaries static libraries are preferred as they are loaded much
faster.  Shared libraries can be updated much easier, and when you
fork a binary, its shared libraries are shared, there's no seperate
copy in memory. This is also one of the main reasons to change our
current perl5 unicode implementation from simple and slow perl data
structures, to compiled shared libraries, which are just mapped in
when needed and can be shared.

Data::Compile
-------------

But first some other steps are needed. Before we create shared
libraries for perl packages we want to compile only some read-only
datastructures, hashes mainly. The name of this module is
Data::Compile and will replace our current cdb databases for
localization data. cdb maps readonly strings to strings, but cannot
store other values than strings and is implemented only as b-tree.
Our localization data would be much easier to use with stored
coderefs, similar to pre-compiled html templates, which which is a mix
of strings and coderefs. By using certain parts of B::C it is trivial
to store data as shared library, which can be dynaloaded on
demand. Loading such a compiled datastructure of perl data is of
course much faster then loading a btree and accessing it at run-time
through some magic tie interface. B::C is very efficient in storing
perl data statically, and only some GV symbols need to be initialized
at boot-time.

`Data::Compile` will also replace the overly slow serializers, like
`Sereal`, `Cpanel::JSON::XS`, `Data::MessagePack` or `Storable`, which
have to convert binary data from and to perl data. `Data::Compile`
freezes perl data natively and just thaws it at instance. So loading
the CPAN Metadata file will go from 16 secs to 0.1ms, similar to
`CPAN::SQLite` and `cpanm` which does those queries at run-time to
some server will not be needed anymore. Updating such a compiled CPAN
Metadata file is estimated to need 2 secs, which needs about the same
time as updating CPAN with CPAN::SQLite. And CPAN::SQLite still has a
locking bug, which prevents multiple cpan sessions, so you are easier
of with cpanm.

In order to optimize loading of static data, readonly hashes, to
replace `cdb` or `sqlite` databases or serialized caches we need
another module first:

Perfect::Hash
-------------

Currently there's is only
[`gperf`](https://www.gnu.org/software/gperf/manual/gperf.html) to
create perfect hashes in C or C++, and then there is also the lesser
known bob jenkins
[`perfect`](http://burtleburtle.net/bob/hash/perfect.html) executable
to create perfect hashes (with some weird header files) and of course
the [cmph](http://cmph.sourceforge.net) library to create perfect
hashes of bigger dictionaries, google size.  No single database or
datra-structure can be faster to lookup then perfect hashes for
readonly data, the fastest single-host readonly databases are cdb and
mysql. And perfect hashes beat them by far. Ever wondered why Google
lookups are so fast?  Well, they distribute hashes across several
servers with so-called
[**consistent hashes**](https://news.ycombinator.com/item?id=8136408),
which map strings into buckets of `n` servers, and when they insert
and delete entries the remapping (copying to other buckets) is
minimized. But the real trick are minimal perfect hashes, which
minimize lookup times and storage sizes far beyond normal or sparse
hashes or b-trees.

So I created `phash` to replace `gperf` in the long term, by using
better algorithms to handle any data (`gperf` fails to work with
anagrams or weird keys), to create optimally fast C libraries or
optimally small C libraries for fast hash lookups, and even provide
backends to output perfect hashes for several popular programming
languages, like perl (XS), java, ruby, php or python.  As C library
you can only store strings as keys, and integers and strings as
values. With those other backends you can store all supported values.

Perfect hashes look differently on small 8-bit machines than on fast
x86_64 machines, for static libraries or for shared libraries with
`-fPIC`, for <1000 keys or for >1.000.000 keys, for keys with NUL
characters or not, for 7-bit keys only, for unicode keys, for
case-insensitive key lookup, and much more. Using a high-level
language to analyze the keys to generate a good perfect hash (in this
case perl) is much easier than fixing and enhancing gperf.

The other main problem is `icu` which is a collection of glorified but
moderately efficient hashmaps of unicode tables and the even worse
perl5 implementation of those unicode tables. Encode does it much
better by pre-compiling encoding tables into good shared libraries,
but unicode has much more tables than just encodings. `parrot`
currently uses icu with a new `gperf` generated workaround for missing
tables in icu (the not-existing whitespace class and missing
namealiases which were broken in icu 5.0), and `moarvm` came up with
it's own implementation of those tables to workaround icu
deficiencies.

So far I have re-implemented the best algorithms to create and use
perfect hashes in pure perl and optimized it with XS functions and I
am able to create good C code. I am still testing optimal hash
functions and strategies. I need only ~2 seconds to create a perfect
hash for 100.000 entries in pure perl, with C libraries this goes
down to 0.001 seconds, scaling linearily. The main problem is solved.
Compilation with a C compiler and -O3 of such hashes need another second.

E.g. these hashes can be used to replace the constant lookup in
ExtUtils::Constants. So I'll look soon into seperate my current ~10
different implementations of perfect hashes into one simple but good
enough pure-perl version, which will generate pure-c code, without the
need for any external library, and then seperate the others into
several packages with external dependencies, like zlib for a fast
hardware-assisted crc32 hash function (1 op per word), or libcmph and
the various output formatters.

Then Data::Compiled will use Perfect::Hash::XS to store the read-only
hashes. And then source code will change to use those hashes instead,
and then perlcc -m will be able to compile and link arbitrary perl
packages with various type annotations and various compilers, if B::C
-O0, -O3, B::CC -O0, -O2 or even rperl.

The next plan is then to create a type inferencer in C, but I'll wait
for this until p5p comes to a syntax decision how to annotate return
types of functions. If ever.
