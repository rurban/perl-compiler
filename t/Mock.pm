package
  Mock; # do not index
use strict;
BEGIN {
  unshift @INC, 't';
}

=head1 NAME

Mock - lengthy compiler tests

=head1 DESCRIPTION

Replay results from stored log files to test the result of the
current TODO status.

Currently perl compiler tests are stored in two formats:

1. log.test-$arch-$perlversion

2. log.modules-$perlversion

When running the Mock tests the actual tests are not executed,
instead the results from log file are used instead. A typical
pelr-compiler testrun lasts several hours, with Mock
several seconds.

=head1 SYNOPSIS

  perlall="5.6.2 5.8.9 5.10.1 5.12.1 5.13.4"
  # actual tests
  for p in perl$perlall; do
    perl$p Makefile.PL && make && \
      make test TEST_VERBOSE=1 2>&1 > log.test-`uname -a`-$p
  done
  # fixup TODO's
  # check tests
  for p in perl$perlall; do
    perl$p t/mock t/*.t
  done

=cut

require "test.pl";
use Test::More;
use Config;
use Cwd;
use Exporter;
our @ISA     = qw(Exporter);
our @EXPORT = qw();

# log.test or log.modules
# check only the latest version, and match revision and perlversion
sub find_test_report () {
  my $arch = shift || `uname -a`;
  #log.test-
}

sub find_modules_report {
}

sub parse_report {
}

sub result ($) {
  my $parse = shift;
}

# 1, "C", "require LWP::UserAgent;\nprint q(ok);", "ok",0,1,"#TODO issue 27"
sub run_cc_test {
}
# 1, "CC", "ccode37i", $script, $todo
sub ctestok {
}
# 1, "CC", "ccode36i", $script, $todo
sub ccompileok() {
}

sub mock_harness {
  my ($log, $t) = @_;
  my $rpt = parse_report($log);
}
