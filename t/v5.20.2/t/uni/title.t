BEGIN {
    chdir 't' if -d 't';
    unshift @INC,  qw(../lib uni .);
    require "case.pl";
}

casetest(0, # No extra tests run here,
	"Titlecase_Mapping", sub { ucfirst $_[0] },
	 sub { my $a = ""; ucfirst ($_[0] . $a) });
