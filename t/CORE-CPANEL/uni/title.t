BEGIN {
    unshift @INC, 't/CORE-CPANEL/uni';
    require "case.pl";
}

casetest(0, # No extra tests run here,
	"Title", \%utf8::ToSpecTitle, sub { ucfirst $_[0] },
	 sub { my $a = ""; ucfirst ($_[0] . $a) });
