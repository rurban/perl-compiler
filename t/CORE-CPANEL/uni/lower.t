BEGIN {
    require "t/CORE-CPANEL/uni/case.pl";
}

casetest(0, # No extra tests run here,
	"Lower", \%utf8::ToSpecLower,
	 sub { lc $_[0] }, sub { my $a = ""; lc ($_[0] . $a) },
	 sub { lcfirst $_[0] }, sub { my $a = ""; lcfirst ($_[0] . $a) });
