# Memory savings with -fcow

B::C has now better support for copy-on-write (COW) strings with about 6%
memory savings for 5.20 and 5.22.

The perl5.18 implementation for COW strings is totally broken as it
uses the COW REFCNT field within the string. You cannot ever come to a
true successful copy-on-write COW scheme with this. You cannot put the
string into the .rodata segment as with `static const char* pv =
"foo";` it needs to be outlined as `static char* pv =
"foo\000\001";`. The byte behind the NUL delimiter is used as REFCNT
byte, which prohibits its use in multi-threading or embedded
scenarios. In cperl I was working on moving this counter to an extra
field, but the 2 authors made it impossible to write it in a
maintainable way. I could easily seperate the refcnt flag but I
couldn't make it COW yet. Tried it three times already, and I'm used
to fix bad code.

But even if the COW implementation in the libperl run-time is broken
by design it still can be put into good use to store more strings
statically than expected.  The problem was that since 5.18 and with
this COW feature binaries needed 20% more memory, as I couldn't save
the strings statically anymore and had to allocate them dynamically.

In the first attempt I save some kilobytes memory by removing the
`IsCOW` flag and store more strings statically.

But now I do the opposite. I set the `IsCOW` flags on much more
strings since 5.20 and -O2, store it not as `const char*` to be able
up update the cow refcnt, and rely in the automatic `cow` and `uncow`
functions in the runtime to move this static buffer to the heap when
being written to, and don't need to rely on `LEN=0` anymore, which
indicates a normal static string.

With a typical example of a medium sized module, `Net::DNS::Resolver`,
64bit not threaded, the memory usage is now as follows:

5.22:

    pcc -O0 -S -e'use Net::DNS::Resolver; my $res = Net::DNS::Resolver->new;
      $res->send("www.google.com"); print `ps -p $$ -O rss,vsz`'
    pcc -O3 -S -e'use Net::DNS::Resolver; my $res = Net::DNS::Resolver->new;
      $res->send("www.google.com"); print `ps -p $$ -O rss,vsz`'

                   rss
    without -fcow: 12832
    with -fcow   : 12112
    cperl        : 12532

6% percent memory win for 5.22. Even better than with cperl.

The current distribution of .rodata, .data and dynamic heap strings with this example
is as follows:

                     .rodata  .data  heap
    -fno-cow (-O0):  305      1945   1435
    -fcow (-O3):     110      2225   1024
    cperl -O3:       107      2112   1001

Thus with -O3 we traded 40% less dynamic strings for 3x less .ro
strings, but 14% more static strings. With cperl the improvements are
no so dramatic, as cperl already has much more static optimizations already.
