BEGIN {
    chdir 't/CORE' if -d 't';
    unshift @INC, qw(../lib uni .);
#     @INC = qw(../lib uni .);
    require "case.pl";
}

casetest(0, # No extra tests run here,
         "Title", \%utf8::ToSpecTitle, sub { ucfirst $_[0] },
	 sub { my $a = ""; ucfirst ($_[0] . $a) });
