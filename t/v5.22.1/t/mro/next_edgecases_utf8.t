#!/usr/bin/perl

use strict;
use warnings;

BEGIN { chdir 't' if -d 't'; require q(./test.pl); 
    set_up_inc('../lib', 'lib');
}

use utf8;
binmode STDOUT, ":utf8"; binmode STDERR, ":utf8";

plan(tests => 12);

{

    {
        package ᕘ;
        use strict;
        use warnings;
        use mro 'c3';
        sub new { bless {}, $_[0] }
        sub ƚ { 'ᕘ::ƚ' }
    }

    # call the submethod in the direct instance

    my $foo = ᕘ->new();
    object_ok($foo, 'ᕘ');

    can_ok($foo, 'ƚ');
    is($foo->ƚ(), 'ᕘ::ƚ', '... got the right return value');    

    # fail calling it from a subclass

    {
        package Baɾ;
        use strict;
        use warnings;
        use mro 'c3';
        our @ISA = ('ᕘ');
    }  
    
    my $bar = Baɾ->new();
    object_ok($bar, 'Baɾ');
    object_ok($bar, 'ᕘ');    
    
    # test it working with with Sub::Name
    SKIP: {    
        skip q{Test doesn't pass uncompiled}, 3;
        eval 'use Sub::Name';
        skip("Sub::Name is required for this test", 3) if $@;        

        my $m = sub { (shift)->next::method() };
        Sub::Name::subname('Baɾ::ƚ', $m);
        {
            no strict 'refs';
            *{'Baɾ::ƚ'} = $m;
        }

        can_ok($bar, 'ƚ');
        my $value = eval { $bar->ƚ() };
        ok(!$@, '... calling ƚ() succeeded') || diag $@;
        is($value, 'ᕘ::ƚ', '... got the right return value too');
    }
    
    # test it failing without Sub::Name
    {
        package બʑ;
        use strict;
        use warnings;
        use mro 'c3';
        our @ISA = ('ᕘ');
    }      
    
    my $baz = બʑ->new();
    object_ok($baz, 'બʑ');
    object_ok($baz, 'ᕘ');    
    
    {
        my $m = sub { (shift)->next::method() };
        {
            no strict 'refs';
            *{'બʑ::ƚ'} = $m;
        }

        eval { $baz->ƚ() };
        ok($@, '... calling ƚ() with next::method failed') || diag $@;
    }

    # Test with non-existing class (used to segfault)
    {
        package Qűx;
        use mro;
        sub fਓ { No::Such::Class->next::can }
    }

    eval { Qűx->fਓ() };
    is($@, '', "->next::can on non-existing package name");

}
