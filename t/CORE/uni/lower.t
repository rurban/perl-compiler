BEGIN {
    chdir 't/CORE' if -d 't';
    unshift @INC, qw(../lib uni .);
    require "case.pl";
}

casetest(0, "Lower", \%utf8::ToSpecLower,
	 sub { lc $_[0] }, sub { my $a = ""; lc ($_[0] . $a) },
	 sub { lcfirst $_[0] }, sub { my $a = ""; lcfirst ($_[0] . $a) });
