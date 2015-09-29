#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
plan(tests => 3);

{ # perl #116190
  fresh_perl_is('print qq!@F!', '1 2',
		{
		 stdin => "1:2",
		 switches => [ '-n', '-F:' ],
		}, "passing -F implies -a");
  fresh_perl_is('print qq!@F!', '1 2',
		{
		 stdin => "1:2",
		 switches => [ '-F:' ],
		}, "passing -F implies -an");
  fresh_perl_is('print join q!,!, @F', '1,2',
		{
		 stdin => "1 2",
		 switches => [ '-a' ],
		}, "passing -a implies -n");
}
