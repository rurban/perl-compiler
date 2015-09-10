#!perl -w

use strict;
use warnings;

use Test::More;

use B qw/svref_2object/;
use B::C::OverLoad::B::IV ();
use B::C::OverLoad::B::UV ();
use B::C::OverLoad::B::RV ();
use B::C::File qw/svsect xpvivsect/;
use B::C::Helpers::Symtable qw/getsym/;

my $simple_int = 8675309;

my $iv = svref_2object( \$simple_int );

isa_ok( $iv, 'B::IV', '$simple_int' );
B::C::File::new('doesnt matter');

my $got = B::IV::save( $iv, '$main::simple_int' );
like( svsect()->{'values'}->[1],    qr{^\&xpviv_list\[0\], 1}, "it's listed in svsect and has 1 reference" );
like( xpvivsect()->{'values'}->[0], qr/\{$simple_int\}$/,      "its value is listed in xpvivsect" );

clear_all();

my $second_ref = \$simple_int;
$got = B::IV::save( $iv, '$main::simple_int' );
like( svsect()->{'values'}->[1], qr{^\&xpviv_list\[0\], 2}, "it's listed in svsect and has 2 references once we refer to it from elsewhere" );

clear_all();

my $rv_save_called;
{
    no warnings 'redefine';
    *B::RV::save = sub { $rv_save_called++ };
}

my $rv = svref_2object( \$second_ref );
isa_ok( $rv, 'B::IV', 'A ref to the int variable' );
$got = B::IV::save( $rv, '$main::second_ref' );
is( $rv_save_called, 1, "B::RV::save is called when a B::IV is a reference actually" );

clear_all();

my $uv_save_called;
{
    no warnings 'redefine';
    *B::UV::save = sub { $uv_save_called++ };
}

my $unsigned_int = 0 + sprintf( '%u', -1 );
my $uv = svref_2object( \$unsigned_int );
$got = B::IV::save( $uv, '$main::unsigned_int' );
is( $uv_save_called, 1, "B::UV::save is called on an unsigned integer" );

done_testing();
exit;

sub clear_all {
    B::C::Helpers::Symtable::clearsym();
    B::C::File::re_initialize();
}
