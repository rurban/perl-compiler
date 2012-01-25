#
# t/test.pl - from CORE

use Test::More;

sub _where {
    my @caller = caller($Level);
    return "at $caller[1] line $caller[2]";
}

# runperl - Runs a separate perl interpreter.
# Arguments :
#   switches => [ command-line switches ]
#   nolib    => 1 # don't use -I../lib (included by default)
#   prog     => one-liner (avoid quotes)
#   progs    => [ multi-liner (avoid quotes) ]
#   progfile => perl script
#   stdin    => string to feed the stdin
#   stderr   => redirect stderr to stdout
#   args     => [ command-line arguments to the perl program ]
#   verbose  => print the command line

my $is_mswin    = $^O eq 'MSWin32';
my $is_netware  = $^O eq 'NetWare';
my $is_macos    = $^O eq 'MacOS';
my $is_vms      = $^O eq 'VMS';
my $is_cygwin   = $^O eq 'cygwin';

sub _quote_args {
    my ($runperl, $args) = @_;

    foreach (@$args) {
	# In VMS protect with doublequotes because otherwise
	# DCL will lowercase -- unless already doublequoted.
        $_ = q(").$_.q(") if $is_vms && !/^\"/ && length($_) > 0;
	$$runperl .= ' ' . $_;
    }
}

sub _create_runperl { # Create the string to qx in runperl().
    my %args = @_;
    my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
    #- this allows, for example, to set PERL_RUNPERL_DEBUG=/usr/bin/valgrind
    if ($ENV{PERL_RUNPERL_DEBUG}) {
	$runperl = "$ENV{PERL_RUNPERL_DEBUG} $runperl";
    }
    unless ($args{nolib}) {
	if ($is_macos) {
	    $runperl .= ' -I::lib';
	    # Use UNIX style error messages instead of MPW style.
	    $runperl .= ' -MMac::err=unix' if $args{stderr};
	}
	else {
	    $runperl .= ' "-I../lib"'; # doublequotes because of VMS
	}
    }
    if ($args{switches}) {
	local $Level = 2;
	die "test.pl:runperl(): 'switches' must be an ARRAYREF " . _where()
	    unless ref $args{switches} eq "ARRAY";
	_quote_args(\$runperl, $args{switches});
    }
    if (defined $args{prog}) {
	die "test.pl:runperl(): both 'prog' and 'progs' cannot be used " . _where()
	    if defined $args{progs};
        $args{progs} = [$args{prog}]
    }
    if (defined $args{progs}) {
	die "test.pl:runperl(): 'progs' must be an ARRAYREF " . _where()
	    unless ref $args{progs} eq "ARRAY";
        foreach my $prog (@{$args{progs}}) {
            if ($is_mswin || $is_netware || $is_vms) {
                $runperl .= qq ( -e "$prog" );
            }
            else {
                $runperl .= qq ( -e '$prog' );
            }
        }
    } elsif (defined $args{progfile}) {
	$runperl .= qq( "$args{progfile}");
    } else {
	# You probaby didn't want to be sucking in from the upstream stdin
	die "test.pl:runperl(): none of prog, progs, progfile, args, "
	    . " switches or stdin specified"
	    unless defined $args{args} or defined $args{switches}
		or defined $args{stdin};
    }
    if (defined $args{stdin}) {
	# so we don't try to put literal newlines and crs onto the
	# command line.
	$args{stdin} =~ s/\n/\\n/g;
	$args{stdin} =~ s/\r/\\r/g;

	if ($is_mswin || $is_netware || $is_vms) {
	    $runperl = qq{$^X -e "print qq(} .
		$args{stdin} . q{)" | } . $runperl;
	}
	elsif ($is_macos) {
	    # MacOS can only do two processes under MPW at once;
	    # the test itself is one; we can't do two more, so
	    # write to temp file
	    my $stdin = qq{$^X -e 'print qq(} . $args{stdin} . qq{)' > teststdin; };
	    if ($args{verbose}) {
		my $stdindisplay = $stdin;
		$stdindisplay =~ s/\n/\n\#/g;
		print STDERR "# $stdindisplay\n";
	    }
	    `$stdin`;
	    $runperl .= q{ < teststdin };
	}
	else {
	    $runperl = qq{$^X -e 'print qq(} .
		$args{stdin} . q{)' | } . $runperl;
	}
    }
    if (defined $args{args}) {
	_quote_args(\$runperl, $args{args});
    }
    $runperl .= ' 2>&1'          if  $args{stderr} && !$is_mswin && !$is_macos;
    $runperl .= " \xB3 Dev:Null" if !$args{stderr} && $is_macos;
    if ($args{verbose}) {
	my $runperldisplay = $runperl;
	$runperldisplay =~ s/\n/\n\#/g;
	print STDERR "# $runperldisplay\n";
    }
    return $runperl;
}

sub runperl {
    die "test.pl:runperl() does not take a hashref"
	if ref $_[0] and ref $_[0] eq 'HASH';
    my $runperl = &_create_runperl;
    # ${^TAINT} is invalid in perl5.00505
    my $tainted;
    eval '$tainted = ${^TAINT};' if $] >= 5.006;
    my %args = @_;
    exists $args{switches} && grep m/^-T$/, @{$args{switches}} and $tainted = $tainted + 1;

    if ($tainted) {
	# We will assume that if you're running under -T, you really mean to
	# run a fresh perl, so we'll brute force launder everything for you
	my $sep;

	eval "require Config; Config->import";
	if ($@) {
	    warn "test.pl had problems loading Config: $@";
	    $sep = ':';
	} else {
	    $sep = $Config{path_sep};
	}

	my @keys = grep {exists $ENV{$_}} qw(CDPATH IFS ENV BASH_ENV);
	local @ENV{@keys} = ();
	# Untaint, plus take out . and empty string:
	local $ENV{'DCL$PATH'} = $1 if $is_vms && ($ENV{'DCL$PATH'} =~ /(.*)/s);
	$ENV{PATH} =~ /(.*)/s;
	local $ENV{PATH} =
	    join $sep, grep { $_ ne "" and $_ ne "." and -d $_ and
		($is_mswin or $is_vms or !(stat && (stat _)[2]&0022)) }
		    split quotemeta ($sep), $1;
	$ENV{PATH} .= "$sep/bin" if $is_cygwin;  # Must have /bin under Cygwin

	$runperl =~ /(.*)/s;
	$runperl = $1;

        my ($err,$result,$stderr) = run_cmd($runperl, $args{timeout});
	$result =~ s/\n\n/\n/ if $is_vms; # XXX pipes sometimes double these
	return $result;
    } else {
        my ($err,$result,$stderr) = run_cmd($runperl, $args{timeout});
	$result =~ s/\n\n/\n/ if $is_vms; # XXX pipes sometimes double these
	return $result;
    }
}

*run_perl = \&runperl; # Nice alias.

sub DIE {
    print STDERR "# @_\n";
    exit 1;
}

# A somewhat safer version of the sometimes wrong $^X.
my $Perl;
sub which_perl {
    unless (defined $Perl) {
	$Perl = $^X;

	# VMS should have 'perl' aliased properly
	return $Perl if $^O eq 'VMS';

	my $exe;
	eval "require Config; Config->import";
	if ($@) {
	    warn "test.pl had problems loading Config: $@";
	    $exe = '';
	} else {
	    $exe = $Config{exe_ext};
	}
       $exe = '' unless defined $exe;

	# This doesn't absolutize the path: beware of future chdirs().
	# We could do File::Spec->abs2rel() but that does getcwd()s,
	# which is a bit heavyweight to do here.

	if ($Perl =~ /^perl\Q$exe\E$/i) {
	    my $perl = "perl$exe";
	    eval "require File::Spec";
	    if ($@) {
		warn "test.pl had problems loading File::Spec: $@";
		$Perl = "./$perl";
	    } else {
		$Perl = File::Spec->catfile(File::Spec->curdir(), $perl);
	    }
	}

	# Build up the name of the executable file from the name of
	# the command.

	if ($Perl !~ /\Q$exe\E$/i) {
	    $Perl .= $exe;
	}

	warn "which_perl: cannot find $Perl from $^X" unless -f $Perl;

	# For subcommands to use.
	$ENV{PERLEXE} = $Perl;
    }
    return $Perl;
}

sub unlink_all {
    foreach my $file (@_) {
        1 while unlink $file;
        print STDERR "# Couldn't unlink '$file': $!\n" if -f $file;
    }
}

my $tmpfile = "misctmp000";
1 while -f ++$tmpfile;
END { unlink_all $tmpfile }

#
# _fresh_perl
#
# The $resolve must be a subref that tests the first argument
# for success, or returns the definition of success (e.g. the
# expected scalar) if given no arguments.
#

sub _fresh_perl {
    my($prog, $resolve, $runperl_args, $name) = @_;

    $runperl_args ||= {};
    $runperl_args->{progfile} = $tmpfile;
    $runperl_args->{stderr} = 1;

    open TEST, ">$tmpfile" or die "Cannot open $tmpfile: $!";

    # VMS adjustments
    if( $^O eq 'VMS' ) {
        $prog =~ s#/dev/null#NL:#;

        # VMS file locking
        $prog =~ s{if \(-e _ and -f _ and -r _\)}
                  {if (-e _ and -f _)}
    }

    print TEST $prog;
    close TEST or die "Cannot close $tmpfile: $!";

    my $results = runperl(%$runperl_args);
    my $status = $?;

    # Clean up the results into something a bit more predictable.
    $results =~ s/\n+$//;
    $results =~ s/at\s+misctmp\d+\s+line/at - line/g;
    $results =~ s/of\s+misctmp\d+\s+aborted/of - aborted/g;

    # bison says 'parse error' instead of 'syntax error',
    # various yaccs may or may not capitalize 'syntax'.
    $results =~ s/^(syntax|parse) error/syntax error/mig;

    if ($^O eq 'VMS') {
        # some tests will trigger VMS messages that won't be expected
        $results =~ s/\n?%[A-Z]+-[SIWEF]-[A-Z]+,.*//;

        # pipes double these sometimes
        $results =~ s/\n\n/\n/g;
    }

    my $pass = $resolve->($results);
    unless ($pass) {
        diag "# PROG: \n$prog\n";
        diag "# EXPECTED:\n", $resolve->(), "\n";
        diag "# GOT:\n$results\n";
        diag "# STATUS: $status\n";
    }

    # Use the first line of the program as a name if none was given
    unless( $name ) {
        ($first_line, $name) = $prog =~ /^((.{1,50}).*)/;
        $name .= '...' if length $first_line > length $name;
    }

    ok($pass, "fresh_perl - $name");
}

#
# fresh_perl_is
#
# Combination of run_perl() and is().
#

sub fresh_perl_is {
    my($prog, $expected, $runperl_args, $name) = @_;
    local $Level = 2;
    _fresh_perl($prog,
		sub { @_ ? $_[0] eq $expected : $expected },
		$runperl_args, $name);
}

#
# fresh_perl_like
#
# Combination of run_perl() and like().
#

sub fresh_perl_like {
    my($prog, $expected, $runperl_args, $name) = @_;
    local $Level = 2;
    _fresh_perl($prog,
		sub { @_ ?
			  $_[0] =~ (ref $expected ? $expected : /$expected/) :
		          $expected },
		$runperl_args, $name);
}

# now my new B::C functions

sub run_cmd {
    my ($cmd, $timeout) = @_;

    my ($result, $out, $err) = (0, '', '');
    if ( ! defined $IPC::Run::VERSION ) {
	local $@;
	if (ref($cmd) eq 'ARRAY') {
            $cmd = join " ", @$cmd;
        }
	# No real way to trap STDERR?
        $cmd .= " 2>&1" if ($^O !~ /^MSWin32|VMS/);
	$out = `$cmd`;
	$result = $?;
    }
    else {
	my $in;
        # XXX TODO this fails with spaces in path. pass and check ARRAYREF then
	my @cmd = ref($cmd) eq 'ARRAY' ? @$cmd : split /\s+/, $cmd;

	eval {
            # XXX TODO hanging or stacktrace'd children are not killed on cygwin
	    my $h = IPC::Run::start(\@cmd, \$in, \$out, \$err);
	    if ($timeout) {
		my $secs10 = $timeout/10;
		for (1..$secs10) {
		    if(!$h->pumpable) {
			last;
		    }
		    else {
			$h->pump_nb;
			diag sprintf("waiting %d[s]",$_*10) if $_ > 30;
			sleep 10;
		    }
		}
		if($h->pumpable) {
		    $h->kill_kill;
		    $err .= "Timed out waiting for process exit";
		}
	    }
	    $h->finish or die "cmd returned $?";
	    $result = $h->result(0);
	};
	$err .= "\$\@ = $@" if($@);
    }
    return ($result, $out, $err);
}

sub tests {
    my $in = shift || "t/TESTS";
    $in = "TESTS" unless -f $in;
    undef $/;
    open TEST, "< $in" or die "Cannot open $in";
    my @tests = split /\n####+.*##\n/, <TEST>;
    close TEST;
    delete $tests[$#tests] unless $tests[$#tests];
    @tests;
}

sub run_cc_test {
    my ($cnt, $backend, $script, $expect, $keep_c, $keep_c_fail, $todo) = @_;
    my ($opt, $got);
    local($\, $,);   # guard against -l and other things that screw with
                     # print
    $expect =~ s/\n$//;
    my ($out,$result,$stderr) = ('');
    my $fnbackend = lc($backend); #C,-O2
    ($fnbackend,$opt) = $fnbackend =~ /^(cc?)(,-o.)?/;
#    if ($cnt == 28 and $backend eq 'C,-O3') {
#	print "ok $cnt # skip $backend SIGSEGV or hangs\n";
#	return 0;
#    }
#    if ($todo and $cnt =~ /^(103)$/ and $] eq '5.010001') {
#	print "ok $cnt # skip $backend hangs\n";
#	return 0;
#    }
    $opt =~ s/,-/_/ if $opt;
    $opt = '' unless $opt;
    use Config;
    require B::C::Flags;
    my $test = $fnbackend."code".$cnt.".pl";
    my $cfile = $fnbackend."code".$cnt.$opt.".c";
    my @obj = ($fnbackend."code".$cnt.$opt.".obj",
               $fnbackend."code".$cnt.$opt.".ilk",
               $fnbackend."code".$cnt.$opt.".pdb")
      if $Config{cc} =~ /^cl/i; # MSVC uses a lot of intermediate files
    my $exe = $fnbackend."code".$cnt.$opt.$Config{exe_ext};
    unlink ($test, $cfile, $exe, @obj);
    open T, ">$test"; print T $script; close T;
    my $Mblib = $] >= 5.009005 ? "-Mblib" : ""; # test also the CORE B in older perls
    unless ($Mblib) {           # check for -Mblib from the testsuite
        if (grep { m{blib(/|\\)arch$} } @INC) {
            $Mblib = "-Iblib/arch -Iblib/lib";  # forced -Mblib via cmdline without
            					# printing to stderr
            $backend = "-qq,$backend,-q" if (!$ENV{TEST_VERBOSE} and $] > 5.007);
        }
    } else {
        $backend = "-qq,$backend,-q" if (!$ENV{TEST_VERBOSE} and $] > 5.007);
    }
    $backend .= ",-fno-warnings" if $] >= 5.013005;
    $backend .= ",-fno-fold" if $] >= 5.013009;
    $got = run_perl(switches => [ "$Mblib -MO=$backend,-o${cfile}" ],
                    verbose  => $ENV{TEST_VERBOSE}, # for debugging
                    nolib    => $ENV{PERL_CORE} ? 0 : 1, # include ../lib only in CORE
                    stderr   => 1, # to capture the "ccode.pl syntax ok"
		    timeout  => 120,
                    progfile => $test);
    if (! $? and -s $cfile) {
	use ExtUtils::Embed ();
	my $command = ExtUtils::Embed::ccopts;
	$command .= " -DHAVE_INDEPENDENT_COMALLOC "
	  if $B::C::Flags::have_independent_comalloc;
	$command .= " -o $exe $cfile ".$B::C::Flags::extra_cflags . " ";
	my $coredir = $ENV{PERL_SRC} || "$Config{installarchlib}/CORE";
	my $libdir  = "$Config{prefix}/lib";
	if ( -e "$coredir/$Config{libperl}" and $Config{libperl} !~ /\.(dll|so)$/ ) {
	    $command .= ExtUtils::Embed::ldopts('-std');
	} elsif ( $Config{useshrplib} and -e "$libdir/$Config{libperl}" ) {
	    # debian: /usr/lib/libperl.so.5.10.1 and broken ExtUtils::Embed::ldopts
	    my $linkargs = ExtUtils::Embed::ldopts('-std');
	    $linkargs =~ s|-lperl |$libdir/$Config{libperl} |;
            $linkargs =~ s/-fstack-protector//
              if $command =~ /-fstack-protector/ and $linkargs =~ /-fstack-protector/;
	    $command .= $linkargs;
	} else {
	    my $linkargs = ExtUtils::Embed::ldopts('-std');
            # cygwin gcc-4.3 crashes with -fstack-protector 2x
            $linkargs =~ s/-fstack-protector//
              if $command =~ /-fstack-protector/ and $linkargs =~ /-fstack-protector/;
	    $command .= $linkargs;
	    $command .= " -lperl" if $command !~ /(-lperl|CORE\/libperl5)/ and $^O ne 'MSWin32';
	}
	$command .= $B::C::Flags::extra_libs;
        my $NULL = $^O eq 'MSWin32' ? '' : '2>/dev/null';
	if ($^O eq 'MSWin32' and $Config{ccversion} eq '12.0.8804' and $Config{cc} eq 'cl') {
	    $command =~ s/ -opt:ref,icf//;
	}
        my $cmdline = "$Config{cc} $command $NULL";
	diag ($cmdline) if $ENV{TEST_VERBOSE} and $ENV{TEST_VERBOSE} == 2;
        run_cmd($cmdline, 20);
        unless (-e $exe) {
            print "not ok $cnt $todo failed $cmdline\n";
            print STDERR "# ",system("$Config{cc} $command"), "\n";
            #unlink ($test, $cfile, $exe, @obj) unless $keep_c_fail;
            return 0;
        }
        $exe = "./".$exe unless $^O eq 'MSWin32';
	# system("/bin/bash -c ulimit -d 1000000") if -e "/bin/bash";
        ($result,$out,$stderr) = run_cmd($exe, 5);
        if (defined($out) and !$result) {
            if ($out =~ /^$expect$/) {
                print "ok $cnt", $todo eq '#' ? "\n" : " $todo\n";
                unlink ($test, $cfile, $exe, @obj) unless $keep_c;
                return 1;
            } else {
                # cc test failed, double check uncompiled
                $got = run_perl(verbose  => $ENV{TEST_VERBOSE}, # for debugging
                                nolib    => $ENV{PERL_CORE} ? 0 : 1, # include ../lib only in CORE
                                stderr   => 1, # to capture the "ccode.pl syntax ok"
                                timeout  => 10,
                                progfile => $test);
                if (! $? and $got =~ /^$expect$/) {
                    print "not ok $cnt $todo wanted: \"$expect\", got: \"$out\"\n";
                } else {
                    print "ok $cnt # skip also fails uncompiled\n";
                    return 1;
                }
                unlink ($test, $cfile, $exe, @obj) unless $keep_c_fail;
                return 0;
            }
        } else {
            $out = '';
        }
    }
    print "not ok $cnt $todo wanted: \"$expect\", \$\? = $?, got: \"$out\"\n";
    if ($stderr) {
	$stderr =~ s/\n./\n# /xmsg;
	print "# $stderr\n";
    }
    unlink ($test, $cfile, $exe, @obj) unless $keep_c_fail;
    return 0;
}

sub prepare_c_tests {
    BEGIN {
        use Config;
        if ($^O eq 'VMS') {
            print "1..0 # skip - B::C doesn't work on VMS\n";
            exit 0;
        }
        if (($Config{'extensions'} !~ /\bB\b/) ) {
            print "1..0 # Skip -- Perl configured without B module\n";
            exit 0;
        }
        # with 5.10 and 5.8.9 PERL_COPY_ON_WRITE was renamed to PERL_OLD_COPY_ON_WRITE
        if ($Config{ccflags} =~ /-DPERL_OLD_COPY_ON_WRITE/) {
            print "1..0 # skip - no OLD COW for now\n";
            exit 0;
        }
    }
}

sub run_c_tests {
    my $backend = $_[0];
    my @todo = @{$_[1]};
    my @skip = @{$_[2]};

    use Config;
    my $AUTHOR      = -d ".svn" or -d ".git";
    my $keep_c      = 0;	  # set it to keep the pl, c and exe files
    my $keep_c_fail = 1;          # keep on failures

    my %todo = map { $_ => 1 } @todo;
    my %skip = map { $_ => 1 } @skip;
    my @tests = tests();

    # add some CC specific tests after 100
    # perl -lne "/^\s*sub pp_(\w+)/ && print \$1" lib/B/CC.pm > ccpp
    # for p in `cat ccpp`; do echo -n "$p "; grep -m1 " $p[(\[ ]" *.concise; done
    #
    # grep -A1 "coverage: ny" lib/B/CC.pm|grep sub
    # pp_stub pp_cond_expr pp_dbstate pp_reset pp_stringify pp_ncmp pp_preinc
    # pp_formline pp_enterwrite pp_leavewrite pp_entergiven pp_leavegiven
    # pp_dofile pp_grepstart pp_mapstart pp_grepwhile pp_mapwhile
    if ($backend =~ /^CC/) {
        local $/;
        my $cctests = <<'CCTESTS';
my ($r_i,$i_i,$d_d)=(0,2,3.0); $r_i=$i_i*$i_i; $r_i*=$d_d; print $r_i;
>>>>
12
######### 101 - CC types and arith ###############
if ($x eq "2"){}else{print "ok"}
>>>>
ok
######### 102 - CC cond_expr,stub,scope ############
require B; my $x=1e1; my $s="$x"; print ref B::svref_2object(\$s)
>>>>
B::PV
######### 103 - CC stringify srefgen ############
@a=(1..4);while($a=shift@a){print $a;}continue{$a=~/2/ and reset q(a);}
>>>>
12
######### 104 CC reset ###############################
use blib;use B::CC;my int $r;my $i:int=2;our double $d=3.0; $r=$i*$i; $r*=$d; print $r;
>>>>
12
######### 105 CC attrs ###############################
CCTESTS

        my $i = 100;
        for (split /\n####+.*##\n/, $cctests) {
            next unless $_;
            $tests[$i] = $_;
            $i++;
        }
    }

    print "1..".(scalar @tests)."\n";

    my $cnt = 1;
    for (@tests) {
        my $todo = $todo{$cnt} ? "#TODO" : "#";
        # skip empty CC holes to have the same test indices in STATUS and t/testcc.sh
        unless ($_) {
            print sprintf("ok %d # skip hole for CC\n", $cnt);
            $cnt++;
            next;
        }
        # only once. skip subsequent tests 29 on MSVC. 7:30min!
        if ($cnt == 29 and $Config{cc} =~ /^cl/i and $backend ne 'C') {
            $todo{$cnt} = $skip{$cnt} = 1;
        }
        if ($todo{$cnt} and $skip{$cnt} and
            # those are currently blocking the system
            # do not even run them at home if TODO+SKIP
            (!$AUTHOR
             or ($cnt==15 and $backend eq 'C,-O1')   # hanging
             or ($cnt==103 and $backend eq 'CC,-O2') # hanging
            ))
        {
            print sprintf("ok %d # skip\n", $cnt);
        } else {
            my ($script, $expect) = split />>>+\n/;
	    die "Invalid empty t/TESTS" if !$script or $expect eq '';
            run_cc_test($cnt, $backend.($cnt == 46 ? ',-fstash' : ''),
			$script, $expect, $keep_c, $keep_c_fail, $todo);
        }
        $cnt++;
    }
}

sub plctestok {
    my ($num, $base, $script, $todo) =  @_;
    plctest($num,'^ok', $base, $script, $todo);
}

sub plctest {
    my ($num, $expected, $base, $script, $todo) =  @_;

    my $name = $base."_$num";
    unlink($name, "$name.plc", "$name.pl", "$name.exe");
    open F, ">", "$base.pl";
    print F $script;
    close F;

    my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
    my $b = $] > 5.008 ? "-qq,Bytecode" : "Bytecode";
    system "$runperl -Iblib/arch -Iblib/lib -MO=$b,-o$name.plc $base.pl";
    unless (-e "$name.plc") {
        print "not ok $num #B::Bytecode failed\n";
        exit;
    }
    my $out = qx($runperl -Mblib -MByteLoader $name.plc);
    chomp $out;
    my $ok = $out =~ /$expected/;
    if ($todo and $todo =~ /TODO/) {
	$todo =~ s/TODO //;
      TODO: {
	    local $TODO = $todo;
	    ok($ok);
	}
    } else {
	ok($ok, "Bytecode $base".($todo ? " $todo" : ''));
    }
    if ($ok) {
        unlink("$name.plc", "$base.pl");
    }
}

sub ctestok {
    my ($num, $backend, $base, $script, $todo) =  @_;
    my $qr = '^ok'; # how lame
    ctest($num, $qr, $backend, $base, $script, $todo);
}

sub ctest {
    my ($num, $expected, $backend, $base, $script, $todo) =  @_;
    my $name = $base."_$num";
    unlink($name, "$name.c", "$name.pl", "$name.exe");
    open F, ">", "$name.pl";
    print F $script;
    close F;

    my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
    my $b = $] > 5.008 ? "-qq,$backend" : "$backend";
    $b .= q(,-fno-fold,-fno-warnings) if $] >= 5.013005;
    system "$runperl -Iblib/arch -Iblib/lib -MO=$b,-o$name.c $name.pl";
    unless (-e "$name.c") {
        print "not ok $num #B::$backend failed\n";
        exit;
    }
    system "$runperl -Iblib/arch -Iblib/lib blib/script/cc_harness -q -o $name $name.c";
    my $exe = $name.$Config{exe_ext};
    unless (-e $exe) {
	if ($todo and $todo =~ /TODO/) {
	    $todo =~ s/TODO //;
          TODO: {
                local $TODO = $todo;
                ok(undef, "failed to compile");
            }
        } else {
            ok(undef, "failed to compile $todo");
        }
        return;
    }
    $exe = "./".$exe unless $^O eq 'MSWin32';
    ($result,$out,$stderr) = run_cmd($exe, 5);
    my $ok;
    if (defined($out) and !$result) {
        chomp $out;
        $ok = $out =~ /$expected/;
        unless ($ok) { #crosscheck uncompiled
            my $out1 = `$runperl $name.pl`;
            unless ($out1 =~ /$expected/) {
                ok(1, "skip also fails uncompiled $todo");
                return;
            }
        }
	if ($todo and $todo =~ /TODO/) {
	    $todo =~ s/TODO //;
          TODO: {
                local $TODO = $todo;
                ok ($out =~ /$expected/);
            }
        } else {
            ok ($out =~ /$expected/, $todo);
        }
    } else {
	if ($todo and $todo =~ /TODO/) {
	    $todo =~ s/TODO //;
          TODO: {
                local $TODO = $todo;
                ok (undef);
            }
	} else {
	    #crosscheck uncompiled
	    my $out1 = `$runperl $name.pl`;
            unless ($out1 =~ /$expected/) {
                ok(1, "skip also fails uncompiled");
                return;
            }
	    ok (undef, $todo);
	}
    }
    unlink("$name.pl");
    if ($ok) {
        unlink($name, "$name.c", "$name.exe");
    }
}

sub ccompileok {
    my ($num, $backend, $base, $script, $todo) =  @_;
    my $name = $base."_$num";
    unlink($name, "$name.c", "$name.pl", "$name.exe");
    open F, ">", "$name.pl";
    print F $script;
    close F;

    my $runperl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
    my $b = $] > 5.008 ? "-qq,$backend" : "$backend";
    system "$runperl -Iblib/arch -Iblib/lib -MO=$b,-o$name.c $name.pl";
    unless (-e "$name.c") {
        print "not ok 1 #B::$backend failed\n";
        exit;
    }
    system "$runperl -Iblib/arch -Iblib/lib blib/script/cc_harness -q -o $name $name.c";
    my $ok = -e $name or -e "$name.exe";
    if ($todo and $todo =~ /TODO/) {
      TODO: {
	    $todo =~ s/TODO //;
            local $TODO = $todo;
            ok($ok);
        }
    } else {
        ok($ok, $todo);
    }
    unlink("$name.pl");
    if ($ok) {
        unlink($name, "$name.c", "$name.exe");
    }
}

sub todo_tests_default {
    my $what = shift;
    my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
    my $ITHREADS  = ($Config{useithreads});

    my @todo  = ();
    # split->pushre->pmreplroot as int. bug in B walker
    # push @todo, (7)   if $] > 5.008 and $] < 5.008008; # and $ITHREADS;
    push @todo, (15)  if $] < 5.007;
    if ($what =~ /^c(|_o[1-4])$/) {
        push @todo, (50)    if $] >= 5.010 and $] < 5.012 and $what =~ /c_o[4]/;
        push @todo, (21)    if $] >= 5.012 and $] < 5.014;
        push @todo, (15)    if $] > 5.010 and $ITHREADS;

	# @ISA issue 64
        push @todo, (10,12,19,25,42,43,50)  if $what eq 'c_o4';
        #push @todo, (48)    if $what eq 'c_o4' and $] < 5.010;
        # push @todo, (50) if $] > 5.013  and $what eq 'c' and !$ITHREADS;
	# issue 78 error at DynaLoader (require Carp + invalid version)
        #push @todo, (29,44,45) if $] > 5.015 and $what =~ /c_o[34]/;
	# DynaLoader::dl_load_file()
        push @todo, (15,27,29,41..45,49) if $] > 5.015 and $what eq 'c_o4';
    } elsif ($what =~ /^cc/) {
	# 8,11,14..16,18..19 fail on 5.00505 + 5.6, old core failures (max 20)
	# on cygwin 29 passes
	#15,21,27,30,41-45,50,103,105
	push @todo, (21,30,46,50,103,105);
	push @todo, (3,7,15,41,44,45) if $] > 5.008 and $] <= 5.008005;
	push @todo, (15)    if $] < 5.008008 or $] >= 5.010;
	push @todo, (14)    if $] >= 5.012;

	#push @todo, (44)    if $ITHREADS or $] < 5.012;
        #push @todo, (44)   if !$ITHREADS and $] >= 5.012;
	push @todo, (104,105) if $] < 5.007; # leaveloop, no cxstack
	push @todo, (10,16) if $what eq 'cc_o2';
	#push @todo, (103)   if $] > 5.007 and $] < 5.009 and $what eq 'cc_o1';
	# only tested 5.8.4 and .5
	push @todo, (29)    if $] < 5.008006 or ($] > 5.013 and $] < 5.015);
	#push @todo, (11,27) if $] < 5.009;
	push @todo, (14)    if $] >= 5.010 and $^O !~ /MSWin32|cygwin/i;
	# solaris also. I suspected nvx<=>cop_seq_*
	push @todo, (12)    if $^O eq 'MSWin32' and $Config{cc} =~ /^cl/i;
	#push @todo, (3,4,27,42,43) if $] >= 5.011004 and $ITHREADS;
	push @todo, (26)    if $what =~ /^cc_o[12]/;
	push @todo, (27)    if $] <= 5.008008;
	push @todo, (25)    if $] >= 5.011004 and $DEBUGGING and $ITHREADS;
	push @todo, (3,4)   if $] >= 5.011004 and $ITHREADS;
	#push @todo, (103)   if $] >= 5.012 and $ITHREADS;
	#push @todo, (49)    if $] >= 5.013009 and $] < 5.015 and !$ITHREADS; # fixed with r1142
	push @todo, (49)    if $] >= 5.013009 and !$ITHREADS; #not
    }
    #push @todo, (12)   if $] >= 5.015007 and $ITHREADS;
    push @todo, (48)   if $] > 5.007 and $] < 5.009 and $^O =~ /MSWin32|cygwin/i;
    #push @todo, (25)   if $] eq "5.010001" and !$DEBUGGING and $ITHREADS;
    #push @todo, (25)   if $] >= 5.010 and $] < 5.012 and !$ITHREADS;
    #push @todo, (32)  if $] >= 5.011003;
    return @todo;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab shiftwidth=4:
