use Test;
BEGIN { $^W = 1; $| = 1; plan tests => 9; }

use strict;
use B::Asm::i386;

my ($cpu);

$cpu = B::Asm::i386->new;

$cpu->eax(0x123);
ok($cpu->eax, 0x123);

$cpu->ah(0x87);
ok($cpu->eax, 0x8723);

#   0:   b8 01 02 03 04          mov    $0x4030201,%eax
$cpu->do(pack("H*", "b801020304"));
ok($cpu->eax, 0x04030201);

#   0:   89 c3                   mov    %eax,%ebx
#   2:   31 c0                   xor    %eax,%eax
#   4:   90                      nop
#   5:   90                      nop
#   6:   a3 00 00 00 00          mov    %eax,0x0
$cpu->do(pack("H*", "89c331c09090a300000000"));
ok($cpu->eax, 0);
ok($cpu->ebx, 0x04030201);
ok($cpu->sig eq 'SEGV');
ok($cpu->died_where, 6);

#   0:   6a 00                   push   $0x0
#   2:   c3                      ret
$cpu->do(pack("H*", "6a00c3"));
ok($cpu->sig eq 'SEGV');
ok(not defined $cpu->died_where);
