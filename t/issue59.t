#! /usr/bin/env perl
# http://code.google.com/p/perl-compiler/issues/detail?id=59
# Problems compiling scripts that use IO::Socket
use Test::More tests => 3;
use strict;
BEGIN {
  unshift @INC, 't';
  require "test.pl";
}

my $name = "ccode59i";
my $script = <<'EOF';
use strict;
use warnings;
use IO::Socket;
my $remote = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "perl.org", PeerPort => "80" );
print $remote "GET / HTTP/1.0" . "\r\n\r\n";
my $result = <$remote>;
$result =~ m|HTTP/1.1 200 OK| ? print "ok" : print $result;
close $remote;
EOF

open F, ">", "$name.pl";
print F $script;
close F;

my $expected = "ok";
my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $q = $] < 5.008001 ? "" : "-qq,";
system($runperl,'-Mblib',"-MO=${q}Bytecode,-o$name.plc","$name.pl");
my $result = qx($runperl -Mblib -MByteLoader $name.plc);
is($result, $expected, 'Bytecode connect to http://perl.org:80');

TODO: {
  local $TODO = "cannot connect to http://perl.org:80" if $result ne $expected;
  ctestok(2, "C", $name, $script);
  ctestok(3, "CC", $name, $script, "CC fails");
}

END {
  unlink($name, $name, "$name.pl", "$name.plc")
    if $result eq $expected;
}
