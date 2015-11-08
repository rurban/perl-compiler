#!./perl -w

BEGIN {
    require q(t/CORE/test.pl);
    undef &Regexp::DESTROY;
}

skip_all "perlcc re-eval doesnt call Regexp::DESTROY #328" if is_perlcc_compiled;
plan tests => 2;

my $destroyed;
{
    sub Regexp::DESTROY { $destroyed++ }
}

{
    my $rx = qr//;
}

is( $destroyed, 1, "destroyed regexp" );

undef $destroyed;

{
    my $var = bless {}, "Foo";
    my $rx = qr/(?{ $var })/;
}

is( $destroyed, 1, "destroyed regexp with closure capture" );

