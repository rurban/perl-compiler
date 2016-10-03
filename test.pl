#!/bin/env perl

use JSON::PP ();

my $perl_hash_or_arrayref =  { foo => 1 };


print JSON::PP::encode_json( $perl_hash_or_arrayref);

print "\n\n";
