#!/bin/env perl

use JSON::XS ();

my $perl_hash_or_arrayref =  { foo => 1 };


print JSON::XS::encode_json( $perl_hash_or_arrayref);

print "\n\n";
