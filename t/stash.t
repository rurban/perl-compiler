#! /usr/bin/env perl

BEGIN {
    if ($ENV{PERL_CORE}){
	chdir('t') if -d 't';
	if ($^O eq 'MacOS') {
	    @INC = qw(: ::lib ::macos:lib);
	} else {
	    @INC = '.';
	    push @INC, '../lib';
	}
    } else {
	unshift @INC, 't';
    }
    use Config;
    if (($Config{'extensions'} !~ /\bB\b/) ){
        print "1..0 # Skip -- Perl configured without B module\n";
        exit 0;
    }
    if ($] < 5.007 ){
        print "1..0 # Skip -- stash tests disabled for 5.6\n";
        exit 0;
    }
    if ($^O eq 'MSWin32' and $Config{cc} =~ /^cl/i) {
        print "1..0 # Skip -- stash tests skipped on MSVC for now\n";
        exit 0;
    }
}

$|  = 1;
use warnings;
use strict;
use Config;

print "1..1\n";

my $test = 1;

sub ok { print "ok $test\n"; $test++ }


my $got;
my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

my $path = join " ", map { qq["-I$_"] } @INC;
$path = '"-I../lib" "-Iperl_root:[lib]"' if $Is_VMS;   # gets too long otherwise
my $redir = $Is_MacOS ? "" : "2>&1";
my $cover = $ENV{HARNESS_PERL_SWITCHES} || "";

chomp($got = `$^X $path "-MB::Stash" $cover "-Mwarnings" -e1`);

$got =~ s/-u//g;

print "# got = $got\n";

my @got = map { s/^\S+ //; $_ }
              sort { $a cmp $b }
                   map { lc($_) . " " . $_ }
                       split /,/, $got;

print "# (after sorting)\n";
print "# got = @got\n";

@got = grep { ! /^(PerlIO|open)(?:::\w+)?$/ } @got;

print "# (after perlio censorings)\n";
print "# got = @got\n";

@got = grep { ! /^Win32$/                     } @got  if $^O eq 'MSWin32';
@got = grep { ! /^NetWare$/                   } @got  if $^O eq 'NetWare';
@got = grep { ! /^(Cwd|File|File::Copy|OS2)$/ } @got  if $^O eq 'os2';
@got = grep { ! /^(Win32|Win32CORE|Cwd|Cygwin)$/} @got if $^O eq 'cygwin';
@got = grep { ! /^(Devel::Cover)$/            } @got  if $cover =~ /-MDevel::Cover/;

if ($Is_VMS) {
    @got = grep { ! /^File(?:::Copy)?$/    } @got;
    @got = grep { ! /^VMS(?:::Filespec)?$/ } @got;
    @got = grep { ! /^vmsish$/             } @got;
     # Socket is optional/compiler version dependent
    @got = grep { ! /^Socket$/             } @got;
}

print "# (after platform censorings)\n";
print "# got = @got\n";

$got = "@got";

my $expected = "attributes Carp Carp::Heavy DB Internals main Regexp utf8 version warnings";
if ($] < 5.009) {
    $expected =~ s/version //;
    $expected =~ s/DB /DB Exporter Exporter::Heavy /;
}
if ($] >= 5.010) {
    $expected = "attributes Carp Carp::Heavy DB Internals main mro re Regexp Tie Tie::Hash Tie::Hash::NamedCapture utf8 version warnings";
}
if ($] >= 5.012) {
    $expected = "Carp DB Exporter Internals IO::File IO::Seekable main mro re Regexp Tie Tie::Hash Tie::Hash::NamedCapture utf8 version warnings";
}
if ($] >= 5.011001 and $] < 5.012) {
    $expected .= " XS::APItest::KeywordRPN";
}
if ($] >= 5.013005) {
    $expected = "Carp DB Exporter Internals IO::File IO::Seekable main mro re Regexp utf8 version warnings";
}

{
    no strict 'vars';
    use vars '$OS2::is_aout';
}

if ((($Config{static_ext} eq ' ') 
     || ($Config{static_ext} eq '')
     || ($Config{static_ext} eq 'Win23CORE' and $^O eq 'cygwin'))
    && !($^O eq 'os2' and $OS2::is_aout)
   ) {
    print "# got [$got]\n# vs.\n# expected [$expected]\nnot " if $got ne $expected;
    ok;
} else {
    print "ok $test # skipped: one or more static extensions\n"; $test++;
}

