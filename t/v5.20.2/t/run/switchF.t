#!./perl -anFx+

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    *ARGV = *DATA;
    plan(tests => 2);
}
my $index = $F[-1];
chomp $index;
is($index, $., "line $.");

__DATA__
okx1
okx3xx2
