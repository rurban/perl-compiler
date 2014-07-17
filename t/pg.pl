#! perl
use strict;
$ENV{DBI_TRACE} = 127 unless exists $ENV{DBI_TRACE};
use DBI;
# faster if compiled in, but does not work
#use DBD::Pg;

my $user = $ENV{USER} || 'postgres';
my ($db, $port) = ($user, 5432);
my $dbh = DBI->connect("dbi:Pg:dbname=$db;port=$port", $user, '', 
                      {
                        'RaiseError' => 1,
                        'PrintError' => 1
                      }
  ) && print "ok\n";
