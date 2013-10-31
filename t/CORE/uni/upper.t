BEGIN {
    chdir 't/CORE' if -d 't';
    unshift @INC, qw(../lib uni .);
#     @INC = qw(../lib uni .);
    require "case.pl";
}

casetest(0, "Upper", \%utf8::ToSpecUpper, sub { uc $_[0] },
	 sub { my $a = ""; uc ($_[0] . $a) });
