#!/bin/bash
# t/testc.sh -c -Du,-q -B static 2>&1 |tee c.log|grep FAIL
# for p in 5.6.2 5.8.8-nt 5.8.9d 5.10.1d 5.10.1d-nt 5.11.2d 5.11.2d-nt; do make -s clean; echo perl$p; perl$p Makefile.PL; t/testc.sh -q -O0 31; done
# quiet c only: t/testc.sh -q -O0
# t/testcc.sh -DOscpSql,-v,-UB::Concise,-UIO::File,-UIO::Handle,-Uwarnings
function help {
  echo "t/testc.sh [OPTIONS] [1-$ntests]"
  echo " -D<debugflags>     for O=C or O=CC. Default: C,-DspmF,-v resp. CC,-DOscpSql,-v"
  echo " -O<0-4>            optimization level"
  echo " -f<opt>            special optimization"
  echo " -B<static|dynamic> pass to cc_harness"
  echo " -c                 continue on errors"
  echo " -k                 keep temp. files on PASS"
  echo " -E                 dump preprocessed source file with cc -E as _E.c"
  echo " -o                 orig. no -Mblib, use installed modules (5.6, 5.8)"
  echo " -a                 all. undo -Du. Unsilence scanning unused sub"
  echo " -A                 -DALLOW_PERL_OPTIONS"
  echo " -q                 quiet"
  echo " -h                 help"
  echo "Without arguments try all $ntests tests. Without Option -Ox try -O0 to -O3 optimizations."
}

# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
v518=`$PERL -e'print (($] < 5.018)?0:1)'`

function init {
BASE=`basename $0`
# if $] < 5.9 you may want to remove -Mblib for testing the core lib. -o
#Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
Mblib=${Mblib:--Iblib/arch -Iblib/lib} # B::C is now fully 5.6+5.8 backwards compatible
v513="`$PERL -e'print (($] < 5.013005) ? q() : q(-fno-fold,-fno-warnings,))'`"
# OCMD=${OCMD}${v513}
if [ -z "$Mblib" ]; then
    VERS="${VERS}_global"; 
    OCMD="$PERL $Mblib -MO=C,${v513}-Dcsp,"
    if [ $BASE = "testcc.sh" ]; then # DrOsplt 
        OCMD="$PERL $Mblib -MO=CC,${v513}-DOsplt,"
    fi
else
    OCMD="$PERL $Mblib -MO=C,${v513}-DspF,-v,"
    if [ $BASE = "testcc.sh" ]; then # DoOscprSql
        OCMD="$PERL $Mblib -MO=CC,${v513}-DOscpSql,-v,"
    fi
fi
CONT=
# 5.6: rather use -B static
#CCMD="$PERL script/cc_harness -g3"
# rest. -DALLOW_PERL_OPTIONS for -Dtlv
#CCMD="$PERL $Mblib script/cc_harness -g3 -DALLOW_PERL_OPTIONS"
CCMD="$PERL $Mblib script/cc_harness"
LCMD=
# On some perls I also had to add $archlib/DynaLoader/DynaLoader.a to libs in Config.pm
}

function vcmd {
    test -n "$QUIET" || echo $*
    $*
}

function pass {
    echo -e -n "\033[1;32mPASS \033[0;0m"
    echo $*
}
function fail {
    echo -e -n "\033[1;31mFAIL \033[0;0m"
    echo $*
}

function runopt {
    o=$1
    optim=$2
    OCMDO1="$(echo $OCMD|sed -e s/C,/C,-O$optim,/)"
    suff="_o${optim}"
    if [ "$optim" == "0" ]; then suff=""; fi
    rm ${o}${suff} ${o}${suff}.c 2> /dev/null
    if [ $optim -lt 5 ]; then CMD=$OCMDO1
    else CMD=$OCMD
    fi
    if [ "$o" = "ccode46" -o "$o" = "cccode46" ]; then
	CMD="$CMD-fstash,"
    fi
    if [ -z $qq ]; then
	vcmd ${CMD}-o${o}${suff}.c $o.pl 2>&1 | grep -v "$o.pl syntax OK"
    else
	vcmd ${CMD}-o${o}${suff}.c $o.pl
    fi
    test -z $CPP || vcmd $CCMD ${o}${suff}.c -c -E -o ${o}${suff}_E.c
    test -n "$QUIET" || echo ${CMD}-o${o}${suff}.c $o.pl
    vcmd $CCMD ${o}${suff}.c $LCMD -o ${o}${suff}
    test -x ${o}${suff} || (test -z $CONT && exit)
    if [ -z "$QUIET" ]; then echo "./${o}${suff}"
    else echo -n "./${o}${suff} "
    fi
    mem=$(ulimit -m 2>/dev/null)
    err=$?
    test -z $err && ulimit -S -m 50000
    res=$(./${o}${suff}) || fail "./${o}${suff}" "errcode $?"
    test -z $err && ulimit -S -m $mem
    if [ "X$res" = "X${result[$n]}" ]; then
	test "X$res" = "X${result[$n]}" && pass "./${o}${suff}" "=> '$res'"
        if [ -z $KEEP ]; then rm ${o}${suff}_E.c ${o}${suff}.c ${o}${suff} 2>/dev/null; fi
        true
    else
	fail "./${o}${suff}" "=> '$str' => '$res'. Expected: '${result[$n]}'"
        false
    fi
}

function ctest {
    n=$1
    str=$2
    if [ $BASE = "testcc.sh" ]; then 
      o="cccode$n"
    else
      o="ccode$n"
    fi
    if [ -z "$str" ]; then
        if [ "$n" = "08" ]; then n=8; fi 
        if [ "$n" = "09" ]; then n=9; fi
	echo "${tests[${n}]}" > ${o}.pl
        str="${tests[${n}]}"
    else
	echo "$str" > ${o}.pl
    fi
    if [ -z "$str" ]; then
      true
    else
      if [ $OPTIM -ge 0 ]; then
	runopt "$o" "$OPTIM"
      else # -1
	rm $o.c $o ${o}_o.c ${o}_o 2> /dev/null
	vcmd ${OCMD}-o$o.c $o.pl
        test -s $o.c || (echo "empty $o.c"; test -z $CONT && exit 2)
	test -z $CPP || vcmd $CCMD $o.c -c -E -o ${o}_E.c
        test -n "$QUIET" || echo ${OCMD}-o$o.c $o.pl
	vcmd $CCMD $o.c $LCMD -o $o
	test -x $o || (test -z $CONT && exit)
	if [ -z "$QUIET" ]; then echo "./$o"
	else echo -n "./$o "
        fi
	res=$(./$o) || (fail "./${o}${suff}" "'$?' = $?"; test -z $CONT && exit 1)
	if [ "X$res" = "X${result[$n]}" ]; then
	    pass "./$o" "'$str' => '$res'"
            if [ -z $KEEP ]; then rm ${o}_E.c ${o}.c ${o} 2>/dev/null; fi
	    if [ $BASE = "testcc.sh" ]; then
	      runopt $o 1 && \
	        runopt $o 2
            else
	      runopt $o 1 && \
	        runopt $o 2 && \
	        runopt $o 3 && \
	        runopt $o 4
            fi
	    true
	else
	    fail "./$o" "'$str' => '$res' Expected: '${result[$n]}'"
	    test -z $CONT && exit 3
	fi
      fi
    fi
}

ntests=300
declare -a tests[$ntests]
declare -a result[$ntests]
ncctests=23
declare -a cctests[$((100+$ncctests))]
declare -a ccresult[$((100+$ncctests))]
tests[1]='print "hi"'
result[1]='hi'
tests[2]='for (1,2,3) { print if /\d/ }'
result[2]='123'
tests[3]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_'
result[3]='zzz2y2y2'
tests[4]='$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_'
if [[ $v518 -gt 0 ]]; then
  result[4]='zzz2y2y2'
else
  result[4]='z2y2y2'
fi
tests[5]='print split /a/,"bananarama"'
result[5]='bnnrm'
tests[6]="{package P; sub x {print 'ya'} x}"
result[6]='ya'
tests[7]='@z = split /:/,"b:r:n:f:g"; print @z'
result[7]='brnfg'
tests[8]='sub AUTOLOAD { print 1 } &{"a"}()'
result[8]='1'
tests[9]='my $l_i = 3; $x = sub { print $l_i }; &$x'
result[9]='3'
tests[10]='my $i_i = 1; 
my $foo = sub {
  $i_i = shift if @_
}; print $i_i; 
print &$foo(3),$i_i;'
result[10]='133'
# index: do fbm_compile or not
tests[11]='$x="Cannot use"; print index $x, "Can"'
result[11]='0'
tests[12]='my $i_i=6; eval "print \$i_i\n"; print ""'
result[12]='6'
tests[13]='BEGIN { %h=(1=>2,3=>4) } print $h{3}'
result[13]='4'
tests[14]='open our $T,"a"; print "ok";'
result[14]='ok'
# __DATA__ handles still broken non-threaded 5.10
tests[15]='print <DATA>
__DATA__
a
b'
result[15]='a
b'
tests[16]='BEGIN{tie @a, __PACKAGE__;sub TIEARRAY {bless{}} sub FETCH{1}}; print $a[1]'
result[16]='1'
tests[17]='my $i_ir=3; print 1 .. $i_ir'
result[17]='123'
# custom key sort
tests[18]='my $h = { a=>3, b=>1 }; print sort {$h->{$a} <=> $h->{$b}} keys %$h'
result[18]='ba'
# fool the sort optimizer by my $p, pp_sort works ok on CC
tests[19]='print sort { my $p; $b <=> $a } 1,4,3'
result[19]='431'
# not repro: something like this is broken in original 5.6 (Net::DNS::ZoneFile::Fast)
# see new test 33
tests[20]='$a="abcd123";my $r=qr/\d/;print $a =~ $r;'
result[20]='1'
# broken on early alpha and 5.10: run-time labels.
tests[21]='sub skip_on_odd{next NUMBER if $_[0]% 2}NUMBER:for($i=0;$i<5;$i++){skip_on_odd($i);print $i;}'
result[21]='024'
# broken in original perl 5.6
tests[22]='my $fh; BEGIN { open($fh,"<","/dev/null"); } print "ok";';
result[22]='ok'
# broken in perl 5.8
tests[23]='package MyMod; our $VERSION = 1.3; print "ok";'
result[23]='ok'
# works in original perl 5.6, broken with latest B::C in 5.6, 5.8
tests[24]='sub level1{return(level2()?"fail":"ok")} sub level2{0} print level1();'
result[24]='ok'
# enforce custom ncmp sort and count it. fails as CC in all. How to enforce icmp?
# <=5.6 qsort needs two more passes here than >=5.8 merge_sort
# 5.12 got it backwards and added 4 more passes.
tests[25]='print sort { $i++; $b <=> $a } 1..4'
result[25]="4321"
# lvalue sub
tests[26]='sub a:lvalue{my $a=26; ${\(bless \$a)}}sub b:lvalue{${\shift}}; print ${a(b)}';
result[26]="26"
# xsub constants (constant folded). newlib: 0x200, glibc: 0x100
tests[27]='use Fcntl ();my $a=Fcntl::O_CREAT(); print "ok" if ( $a >= 64 && &Fcntl::O_CREAT >= 64 );'
result[27]='ok'
# require $fname
tests[28]='my($fname,$tmp_fh);while(!open($tmp_fh,">",($fname=q{ccode28_} . rand(999999999999)))){$bail++;die "Failed to create a tmp file after 500 tries" if $bail>500;}print {$tmp_fh} q{$x="ok";1;};close($tmp_fh);sleep 1;require $fname;END{unlink($fname);};print $x;'
result[28]='ok'
# special old IO handling
tests[29]='use IO;print "ok"'
result[29]='ok'
# run-time context of .., fails in CC
tests[30]='@a=(4,6,1,0,0,1);sub range{(shift @a)..(shift @a)}print range();while(@a){print scalar(range())}'
result[30]='456123E0'
# AUTOLOAD w/o goto xsub
tests[31]='package MockShell;sub AUTOLOAD{my $p=$AUTOLOAD;$p=~s/.*:://;print(join(" ",$p,@_),";");} package main; MockShell::date();MockShell::who("am","i");MockShell::ls("-l");'
result[31]='date;who am i;ls -l;'
# CC entertry/jmpenv_jump/leavetry
tests[32]='eval{print "1"};eval{die 1};print "2";'
result[32]='12'
# C qr test was broken in 5.6 -- needs to load an actual file to test. See test 20.
# used to error with Can't locate object method "save" via package "U??WVS?-" (perhaps you forgot to load "U??WVS?-"?) at /usr/lib/perl5/5.6.2/i686-linux/B/C.pm line 676.
# fails with new constant only. still not repro (r-magic probably)
tests[33]='BEGIN{unshift @INC,("t");} use qr_loaded_module; print "ok" if qr_loaded_module::qr_called_in_sub("name1")'
result[33]='ok'
# init of magic hashes. %ENV has e magic since a0714e2c perl.c
# (Steven Schubiger      2006-02-03 17:24:49 +0100 3967) i.e. 5.8.9 but not 5.8.8
tests[34]='my $x=$ENV{TMPDIR};print "ok"'
result[34]='ok'
# static method_named. fixed with 1.16
tests[35]='package dummy;my $i=0;sub meth{print $i++};package main;dummy->meth(1);my dummy $o = bless {},"dummy";$o->meth("const");my $meth="meth";$o->$meth("const");dummy->$meth("const");dummy::meth("dummy","const")'
result[35]='01234'
# HV self-ref
tests[36]='my ($rv, %hv); %hv = ( key => \$rv ); $rv = \%hv; print "ok";'
result[36]='ok'
# AV self-ref
tests[37]='my ($rv, @av); @av = ( \$rv ); $rv = \@av; print "ok";'
result[37]='ok'
# constant autoload loop crash test
tests[38]='for(1 .. 1024) { if (open(my $null_fh,"<","/dev/null")) { seek($null_fh,0,SEEK_SET); close($null_fh); $ok++; } }if ($ok == 1024) { print "ok"; }'
result[38]='ok'
# check re::is_regexp, and on 5.12 if being upgraded to SVt_REGEXP
# => Undefined subroutine &re::is_regexp with B-C-1.19, even with -ure
tests[39]='{$a=qr/x/;print($]<5.010?1:re::is_regexp($a))}'
result[39]='1'
# String with a null byte -- used to generate broken .c on 5.6.2 with static pvs
tests[40]='my $var="this string has a null \\000 byte in it";print "ok";'
result[40]='ok'
# Shared scalar, n magic. => Don't know how to handle magic of type \156.
usethreads=""
#usethreads="`$PERL -MConfig -e'print ($Config{useithreads} ? q(use threads;) : q())'`"
#usethreads='BEGIN{use Config; unless ($Config{useithreads}) {print "ok"; exit}} '
#;threads->create(sub{$s="ok"})->join;
# not yet testing n, only P
tests[41]=$usethreads'use threads::shared;{my $s="ok";share($s);print $s}'
result[41]='ok'
# Shared aggregate, P magic
tests[42]=$usethreads'use threads::shared;my %h : shared; print "ok"'
result[42]='ok'
# Aggregate element, n + p magic
tests[43]=$usethreads'use threads::shared;my @a : shared; $a[0]="ok"; print $a[0]'
result[43]='ok'
# perl #72922 (5.11.4 fails with magic_killbackrefs)
tests[44]='use Scalar::Util "weaken";my $re1=qr/foo/;my $re2=$re1;weaken($re2);print "ok" if $re3=qr/$re1/;'
result[44]='ok'
# test dynamic loading
tests[45]='use Data::Dumper ();Data::Dumper::Dumpxs({});print "ok";'
result[45]='ok'
# issue 79: Exporter:: stash missing in main::
#tests[46]='use Exporter; if (exists $main::{"Exporter::"}) { print "ok"; }'
tests[46]='use Exporter; print "ok" if %main::Exporter::'
#tests[46]='use Exporter; print "ok" if scalar(keys(%main::Exporter::)) > 2'
result[46]='ok'
# non-tied av->MAGICAL
tests[47]='@ISA=(q(ok));print $ISA[0];'
result[47]='ok'
# END block del_backref with bytecode only
tests[48]='my $s=q{ok};END{print $s}'
result[48]='ok'
# even this failed until r1000 (AvFILL 3 of END)
#tests[48]='print q{ok};END{}'
#result[48]='ok'
# no-fold
tests[49]='print q(ok) if "test" =~ /es/i;'
result[49]='ok'
# @ISA issue 64
tests[50]='package Top;sub top{q(ok)};package Next;our @ISA=qw(Top);package main;print Next->top();'
result[50]='ok'
# XXX TODO sigwarn $w = B::NULL without -v
tests[51]='$SIG{__WARN__}=sub{print "ok"};warn 1;'
result[51]='ok'
# check if general signals work
tests[511]='BEGIN{$SIG{USR1}=sub{$w++;};} kill USR1 => $$; print q(ok) if $w';
result[511]='ok'
#-------------
# issue27
tests[527]='require LWP::UserAgent;print q(ok);'
result[527]='ok'
#issue 24
tests[224]='dbmopen(%H,q(f),0644);print q(ok);'
result[224]='ok'
tests[68]='package A;
sub test {
  use Data::Dumper ();
  /^(.*?)\d+$/;
  "Some::Package"->new();
}
print "ok"'
result[68]='ok'
# issue71
tests[71]='
package my;
our @a;
sub f { 
  my($alias,$name)=@_;
  unshift(@a, $alias => $name);
  my $find = "ok"; 
  my $val = $a[1];
  if ( ref($alias) eq "Regexp" && $find =~ $alias ) {
    eval $val;
  }
  $find
}
package main;
*f=*my::f;
print "ok" if f(qr/^(.*)$/ => q("\L$1"));'
result[71]="ok"
# object call: method_named with args.
tests[72]='package dummy;sub meth{print "ok"};package main;my dummy $o = bless {},"dummy"; $o->meth("const")'
result[72]='ok'
# object call: dynamic method_named with args.
tests[73]='package dummy;sub meth{print "ok"};package main;my $meth="meth";my $o = bless {},"dummy"; $o->$meth("const")'
result[73]='ok'
tests[74]='package dummy;
my $invoked_as_script = !caller();
__PACKAGE__->script(@ARGV) if $invoked_as_script;
sub script {my($package,@args)=@_;print "ok"}'
result[74]='ok'
# issue 71_2+3: cop_warnings issue76 and const destruction issue71 fixed
# ok with "utf-8-strict"
tests[75]='#TODO 5.8.8-5.10
use Encode;
my $x = "abc";
print "ok" if "abc" eq Encode::decode("UTF-8", $x);'
result[75]='ok'
tests[76]='use warnings;
{ no warnings q(void); # issue76 lexwarn
  length "ok";
  print "ok"
};'
result[76]='ok'
tests[81]='sub int::check {1}  #create int package for types
sub x(int,int) { @_ } #cvproto
my $o = prototype \&x;
if ($o eq "int,int") {print "o"}else{print $o};
sub y($) { @_ } #cvproto
my $p = prototype \&y;
if ($p eq q($)) {print "k"}else{print $p};
require bytes;
sub my::length ($) { # possible prototype mismatch vs _
  if ( bytes->can(q(length)) ) {
     *length = *bytes::length;
     goto &bytes::length;
  }
  return CORE::length( $_[0] );
}
print my::length($p);'
result[81]='ok1'
tests[90]='my $s = q(test string);
$s =~ s/(?<first>test) (?<second>string)/\2 \1/g;
print q(o) if $s eq q(string test);
q(test string) =~ /(?<first>\w+) (?<second>\w+)/;
print q(k) if $+{first} eq q(test);'
result[90]='ok'
tests[901]='my %errs = %!; # t/op/magic.t Errno compiled in
print q(ok) if defined ${"!"}{ENOENT};'
result[901]='ok'
tests[902]='my %errs = %{"!"}; # t/op/magic.t Errno to be loaded at run-time
print q(ok) if defined ${"!"}{ENOENT};'
result[902]='ok'
# issue #199
tests[903]='"abc" =~ /(.)./; print "ok" if "21" eq join"",@+;'
result[903]='ok'
# issue #220
tests[904]='my $content = "ok\n";
while ( $content =~ m{\w}g ) {
    $_ .= "$-[0]$+[0]";
}
print "ok" if $_ eq "0112";'
result[904]='ok'
# IO handles
tests[91]='# issue59
use strict;
use warnings;
use IO::Socket;
my $remote = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "perl.org", PeerPort => "80" );
print $remote "GET / HTTP/1.0" . "\r\n\r\n";
my $result = <$remote>;
$result =~ m|HTTP/1.1 200 OK| ? print "ok" : print $result;
close $remote;'
result[91]='ok'
tests[93]='#SKIP
my ($pid, $out, $in);
BEGIN {
  local(*FPID);
  $pid = open(FPID, "echo <<EOF |");    # DIE
  open($out, ">&STDOUT");		# EASY
  open(my $tmp, ">", "pcc.tmp");	# HARD to get filename, WARN
  print $tmp "test\n";
  close $tmp;				# OK closed
  open($in, "<", "pcc.tmp");		# HARD to get filename, WARN
}
# === run-time ===
print $out "o";
kill 0, $pid; 			     # BAD! warn? die?
print "k" if "test" eq read $in, my $x, 4;
unlink "pcc.tmp";
'
result[93]='o'
tests[931]='my $f;BEGIN{open($f,"<README");}read $f,my $in, 2; print "ok"'
result[931]='ok'
tests[932]='my $f;BEGIN{open($f,">&STDOUT");}print $f "ok"'
result[932]='ok'
tests[95]='#TODO IO::Handle
use IO::Socket::SSL();
my IO::Handle $handle = IO::Socket::SSL->new(SSL_verify_mode =>0);
$handle->blocking(0);
print "ok";'
result[95]='ok'
tests[96]='defined(&B::OP::name) || print q(ok)'
result[96]='ok'
tests[97]='use v5.12; print q(ok);'
result[97]='ok'

# from here on we test CC specifics only

# CC types and arith
tests[101]='my ($r_i,$i_i,$d_d)=(0,2,3.0); $r_i=$i_i*$i_i; $r_i*=$d_d; print $r_i;'
result[101]='12'
# CC cond_expr, stub, scope
tests[102]='if ($x eq "2"){}else{print "ok"}'
result[102]='ok'
# CC stringify, srefgen. TODO: use B; fails
tests[103]='require B; my $x=1e1; my $s="$x"; print ref B::svref_2object(\$s)'
result[103]='B::PV'
# CC reset
tests[104]='@a=(1..4);while($a=shift@a){print $a;}continue{$a=~/2/ and reset q(a);}'
result[104]='12'
# CC -ftype-attr
#tests[105]='$int::dummy=0;$double::dummy=0;my int $r;my $i:int=2;our double $d=3.0; $r=$i*$i; $r*=$d; print $r;'
tests[105]='%int::;%double::;my int $r;my int $i=2;our double $d=3.0; $r=$i*$i; $r*=$d; print $r;'
result[105]='12'

# issue31
tests[131]='package Ccode31i;my $regex = qr/\w+/;sub test {print ("word" =~ m/^$regex$/o ? "ok\n" : "not ok\n");}
package main; &Ccode31i::test();'
result[131]='ok'
# issue35
tests[110]='sub new{}sub test{{my $x=1;my $y=$x+1;}my $x=2;if($x!=3){4;}}'
result[110]=''
# issue36
tests[111]='sub f{shift==2}sub test{while(1){last if f(2);}while(1){last if f(2);}}'
result[111]=''
# issue37
tests[112]='my $x;$x||=1;print "ok" if $x;'
result[112]='ok'
# issue38
tests[113]='my $x=2;$x=$x||3;print "ok" if $x==2;'
result[113]='ok'
# issue39
tests[114]='sub f1{0}sub f2{my $x;if(f1()){}if($x){}else{[$x]}}my @a=f2();print "ok";'
result[114]='ok'
# issue42
tests[115]='sub f1{1}f1();print do{7;2},"\n";'
result[115]='2'
# issue44
tests[116]='my @a=(1,2);print $a[0],"\n";'
result[116]='1'
# issue45
tests[117]='my $x;$x//=1;print "ok" if $x;'
result[117]='ok'
# issue46
tests[118]='my $pattern="x";"foo"=~/$pattern/o;print "ok";'
result[118]='ok'
# issue47
tests[119]='my $f=sub{while(1){return(1);}};print $f->(),"\n";'
result[119]='1'
# issue48
tests[120]='sub f{()}print((my ($v)=f())?1:2,"\n");'
result[120]='2'
# issue49
tests[121]='while(1){while(1){last;}last;}print "ok"'
result[121]='ok'
# issue51
tests[122]='my ($p1,$p2)=(80,80);if($p1<=23&&23<=$p2){print "telnet\n";}elsif ($p1 <= 80 && 80 <= $p2){print "http\n";}else{print "fail\n"}'
result[122]='http'
# issue52
tests[123]='my $x;my $y = 1;$x and $y == 2;print $y == 1 ? "ok\n" : "fail\n";'
result[123]='ok'
# issue125 DynaLoader::bootstrap_inherit [perl #119577]
tests[125]='use Net::LibIDN; print q(ok);'
result[125]='ok'
# saving recursive functions sometimes recurses in the compiler. this not, but Moose stucks in Pod::Simple
tests[99]='package my;sub recurse{my $i=shift;recurse(++$i)unless $i>5000;print"ok";exit};package main;my::recurse(1)'
result[99]='ok'
if [[ $v518 -gt 0 ]]; then
  tests[130]='no warnings "experimental::lexical_subs";use feature "lexical_subs";my sub p{q(ok)}; my $a=\&p;print p;'
  result[130]='ok'
fi
tests[138]='print map { chr $_ } qw/97 98 99/;'
result[138]='abc'
tests[140]='my %a;print "ok" if !%a;'
result[140]='ok'
#tests[141]='print "ok" if "1" > 0'
tests[141]='@x=(0..1);print "ok" if $#x == "1"'
result[141]='ok'
tests[142]='$_ = "abc\x{1234}";chop;print "ok" if $_ eq "abc"'
result[142]='ok'
tests[143]='BEGIN {
  package Net::IDN::Encode;
  our $DOT = qr/[\.]/; #works with my!
  my $RE  = qr/xx/;
  sub domain_to_ascii {
    my $x = shift || "";
    $x =~ m/$RE/o;
    return split( qr/($DOT)/o, $x);
  }
}
package main;
Net::IDN::Encode::domain_to_ascii(42);
print "ok\n";'
result[143]='ok'
tests[1431]='BEGIN{package Foo;our $DOT=qr/[.]/;};package main;print "ok\n" if "dot.dot" =~ m/($Foo::DOT)/'
result[1431]='ok'
tests[1432]='BEGIN{$DOT=qr/[.]/}print "ok\n" if "dot.dot" =~ m/($DOT)/'
result[1432]='ok'
tests[144]='print index("long message\0xx","\0")'
result[144]='12'
tests[145]='my $bits = 0; for (my $i = ~0; $i; $i >>= 1) { ++$bits; }; print $bits'
result[145]=`$PERL -MConfig -e'print 8*$Config{ivsize}'`
tests[146]='my $a = v120.300; my $b = v200.400; $a ^= $b; print sprintf("%vd", $a);'
result[146]='176.188'
tests[148]='open(FH, ">", "ccode148i.tmp"); print FH "1\n"; close FH; print -s "ccode148i.tmp"'
result[148]='2'
tests[150]='print NONEXISTENT "foo"; print "ok" if $! == 9'
result[150]='ok'
tests[1501]='$! = 0; print NONEXISTENT "foo"; print "ok" if $! == 9'
result[1501]='ok'
tests[152]='print "ok" if find PerlIO::Layer "perlio"'
result[152]='ok'
tests[154]='$SIG{__WARN__} = sub { die "warning: $_[0]" }; opendir(DIR, ".");closedir(DIR);print q(ok)'
result[154]='ok'
tests[156]='use warnings;
no warnings qw(portable);
use XSLoader;
XSLoader::load() if $ENV{force_xsloader}; # trick for perlcc to force xloader to be compiled
{
    my $q = 12345678901;
    my $x = sprintf("%llx", $q);
    print "ok\n" if hex $x == 0x2dfdc1c35;
    exit;
}'
result[156]='ok'
tests[157]='$q = 18446744073709551615;print scalar($q)."\n";print scalar(18446744073709551615)."\n";'
result[157]='18446744073709551615
18446744073709551615'
tests[1571]='my $a = 9223372036854775807; print "ok\n" if ++$a == 9223372036854775808;'
result[1571]='ok'
# duplicate of 148
tests[158]='open W, ">ccodetmp" or die "1: $!";print W "foo";close W;open R, "ccodetmp" or die "2: $!";my $e=eof R ? 1 : 0;close R;print "$e\n";'
result[158]='0'
tests[159]='@X::ISA = "Y"; sub Y::z {"Y::z"} print "ok\n" if  X->z eq "Y::z"; delete $X::{z}; exit'
result[159]='ok'
# see 188
tests[160]='sub foo { (shift =~ m?foo?) ? 1 : 0 }
print "ok\n";'
result[160]='ok'
tests[161]='sub PVBM () { foo } { my $dummy = index foo, PVBM } print PVBM'
result[161]='foo'
# duplicate of 142
tests[162]='$x = "\x{1234}"; print "ok\n" if ord($x) == 0x1234;'
result[162]='ok'
tests[163]='# WontFix
my $destroyed = 0;
sub  X::DESTROY { $destroyed = 1 }
{
	my $x;
	BEGIN {$x = sub { }  }
	$x = bless {}, 'X';
}
print qq{ok\n} if $destroyed == 1;'
result[163]='ok'
# duplicate of 148
tests[164]='open(DUPOUT,">&STDOUT");close(STDOUT);open(F,">&DUPOUT");print F "ok\n";'
result[164]='ok'
tests[165]='use warnings;
sub recurse1 {
    unshift @_, "x";
    no warnings "recursion";
    goto &recurse2;
}
sub recurse2 {
    my $x = shift;
    $_[0] ? +1 + recurse1($_[0] - 1) : 0
}
print "ok\n" if recurse1(500) == 500;'
result[165]='ok'
tests[166]='my $ok = 1;
foreach my $chr (60, 200, 600, 6000, 60000) {
  my ($key, $value) = (chr ($chr) . "\x{ABCD}", "$chr\x{ABCD}");
  chop($key, $value);
  my %utf8c = ( $key => $value );
  my $tempval = sprintf q($utf8c{"\x{%x}"}), $chr;
  my $ev = eval $tempval;
  $ok = 0 if !$ev or $ev ne $value;
} print "ok" if $ok'
result[166]='ok'
tests[167]='$a = "a\xFF\x{100}";
eval {$b = crypt($a, "cd")};
print $@;'
result[167]='Wide character in crypt at ccode167.pl line 2.'
tests[168]='my $start_time = time;
eval {
    local $SIG{ALRM} = sub { die "ALARM !\n" };
    alarm 1;
    # perlfunc recommends against using sleep in combination with alarm.
    1 while (time - $start_time < 3);
};
alarm 0;
print $@;
print "ok\n" if $@ eq "ALARM !\n";'
result[168]='ALARM !
ok'
tests[169]='# TODO
package MyTest;
use Attribute::Handlers;
sub Check :ATTR {
    print "called\n";
    print "ok\n" if ref $_[4] eq "ARRAY" && join(",", @{$_[4]}) eq join(",", qw/a b c/);
}
sub a_sub :Check(qw/a b c/) {
    return 42;
}
print a_sub()."\n";'
result[169]='called
ok
42'
# works fine with -O3
tests[170]='#TODO non-O3
eval "sub xyz (\$) : bad ;"; print "~~~~\n$@~~~~\n"'
result[170]='~~~~
Invalid CODE attribute: bad at (eval 1) line 1.
BEGIN failed--compilation aborted at (eval 1) line 1.
~~~~'
tests[172]='package Foo;
use overload q("") => sub { "Foo" };
package main;
my $foo = bless {}, "Foo";
print "ok " if "$foo" eq "Foo";
print "$foo\n";'
result[172]='ok Foo'
tests[173]='# WontFix
use constant BEGIN   => 42; print "ok 1\n" if BEGIN == 42;
use constant INIT   => 42; print "ok 2\n" if INIT == 42;
use constant CHECK   => 42; print "ok 3\n" if CHECK == 42;'
result[173]='Prototype mismatch: sub main::BEGIN () vs none at ./ccode173.pl line 2.
Constant subroutine BEGIN redefined at ./ccode173.pl line 2.
ok 1
ok 2
ok 3'
tests[174]='
my $str = "\x{10000}\x{800}";
no warnings "utf8";
{ use bytes; $str =~ s/\C\C\z//; }
my $ref = "\x{10000}\0";
print "ok 1\n" if ~~$str eq $ref;
$str = "\x{10000}\x{800}";
{ use bytes; $str =~ s/\C\C\z/\0\0\0/; }
my $ref = "\x{10000}\0\0\0\0";
print "ok 2\n" if ~~$str eq $ref;'
result[174]='ok 1
ok 2'
tests[175]='#TODO
{
  # note that moving the use in an eval block solve the problem
  use warnings NONFATAL => all;
  $SIG{__WARN__} = sub { "ok - expected warning\n" };
  my $x = pack( "I,A", 4, "X" );
  print "ok\n";
}'
result[175]='ok - expected warning
ok'
tests[176]='use Math::BigInt; print Math::BigInt::->new(5000000000);'
result[176]='5000000000'
tests[177]='use version; print "ok\n" if version::is_strict("4.2");'
result[177]='ok'
tests[178]='BEGIN { $hash  = { pi => 3.14, e => 2.72, i => -1 } ;} print scalar keys $hash;'
result[178]='3'
tests[179]='#TODO smartmatch subrefs
{
    package Foo;
    sub new { bless {} }
}
package main;
our $foo = Foo->new;
our $bar = $foor; # required to generate the wrong behavior
my $match = eval q($foo ~~ undef) ? 1 : 0;
print "match ? $match\n";'
result[179]='match ? 0'
tests[180]='use feature "switch"; use integer; given(3.14159265) { when(3) { print "ok\n"; } }'
result[180]='ok'
tests[181]='sub End::DESTROY { $_[0]->() };
my $inx = "OOOO";
$SIG{__WARN__} = sub { print$_[0] . "\n" };
{
    $@ = "XXXX";
    my $e = bless( sub { die $inx }, "End")
}'
result[181]=''
tests[182]='#TODO stash-magic delete renames to ANON
my @c; sub foo { @c = caller(0); print $c[3] } my $fooref = delete $::{foo}; $fooref -> ();'
result[182]='main::__ANON__'
tests[183]='main->import()'
result[183]=''
tests[184]='use warnings;
sub xyz { no warnings "redefine"; *xyz = sub { $a <=> $b }; &xyz }
eval { @b = sort xyz 4,1,3,2 };
print defined $b[0] && $b[0] == 1 && $b[1] == 2 && $b[2] == 3 && $b[3] == 4 ? "ok\n" : "fail\n";
exit;
{
    package Foo;
    use overload (qw("" foo));
}
{
    package Bar;
    no warnings "once";
    sub foo { $ENV{fake} }
}
'
result[184]='ok'
# usage: t/testc.sh -O3 -Dp,-UCarp 185
tests[185]='my $a=pack("U",0xFF);use bytes;print "not " unless $a eq "\xc3\xbf" && bytes::length($a) == 2; print "ok\n";'
result[185]='ok'
tests[186]='eval q/require B/; my $sub = do { package one; \&{"one"}; }; delete $one::{one}; my $x = "boom"; print "ok\n";'
result[186]='ok'
# duplicate of 182
tests[187]='my $glob = \*Phoo::glob; undef %Phoo::; print ( ( "$$glob" eq "*__ANON__::glob" ) ? "ok\n" : "fail with $$glob\n" );'
result[187]='ok'
tests[188]='package aiieee;sub zlopp {(shift =~ m?zlopp?) ? 1 : 0;} sub reset_zlopp {reset;}
package main; print aiieee::zlopp(""), aiieee::zlopp("zlopp"), aiieee::zlopp(""), aiieee::zlopp("zlopp");
aiieee::reset_zlopp(); print aiieee::zlopp("zlopp")'
result[188]='01001'
#tests[189]=''
#result[189]=''
#tests[190]=''
#result[190]=''
tests[191]='# WontFix
BEGIN{sub plan{42}} {package Foo::Bar;} print((exists $Foo::{"Bar::"} && $Foo::{"Bar::"} eq "*Foo::Bar::") ? "ok\n":"bad\n"); plan(fake=>0);'
result[191]='ok'
tests[192]='use warnings;
{
 no warnings qw "once void";
 my %h; # We pass a key of this hash to the subroutine to get a PVLV.
 sub { for(shift) {
  # Set up our glob-as-PVLV
  $_ = *hon;
  # Assigning undef to the glob should not overwrite it...
  {
   my $w;
   local $SIG{__WARN__} = sub { $w = shift };
   *$_ = undef;
   print ( $w =~ m/Undefined value assigned to typeglob/ ? "ok" : "not ok");
  }
 }}->($h{k});
}'
result[192]='ok'
tests[193]='unlink q{not.a.file}; $! = 0; open($FOO, q{not.a.file}); print( $! ne 0 ? "ok" : q{error: $! should not be 0}."\n"); close $FOO;'
result[193]='ok'
tests[194]='$0 = q{ccdave}; #print "pid: $$\n";
$s=`ps auxw | grep "$$" | grep "ccdave"|grep -v grep`;
print q(ok) if $s =~ /ccdave/'
result[194]='ok'
# duplicate of 152
tests[195]='use PerlIO;  eval { require PerlIO::scalar }; find PerlIO::Layer "scalar"'
result[195]=''
tests[196]='package Foo;
sub new { bless {}, shift }
DESTROY { $_[0] = "foo" }
package main;
eval q{\\($x, $y, $z) = (1, 2, 3);};
my $m;
$SIG{__DIE__} = sub { $m = shift };
{ my $f = Foo->new }
print "m: $m\n";'
result[196]='m: Modification of a read-only value attempted at ccode196.pl line 3.'
tests[197]='# TODO
package FINALE;
{
    $ref3 = bless ["ok - package destruction"];
    my $ref2 = bless ["ok - lexical destruction\n"];
    local $ref1 = bless ["ok - dynamic destruction\n"];
    1;
}
DESTROY {
    print $_[0][0];
}'
result[197]='ok - dynamic destruction
ok - lexical destruction
ok - package destruction'
# duplicate of 150
tests[198]='{
  open(my $NIL, qq{|/bin/echo 23}) or die "fork failed: $!";
  $! = 1;
  close $NIL;
  if($! == 5) { print}
}'
result[198]='23'
# duplicate of 90
tests[199]='"abc" =~ /(.)./; print @+; print "end\n"'
result[199]='21end'
tests[200]='%u=("\x{123}"=>"fo"); print "ok" if $u{"\x{123}"} eq "fo"'
result[200]='ok'
tests[2001]='BEGIN{%u=("\x{123}"=>"fo");} print "ok" if $u{"\x{123}"} eq "fo";'
result[2001]='ok'
tests[201]='use Storable;*Storable::CAN_FLOCK=sub{1};print qq{ok\n}'
result[201]='ok'
tests[2011]='sub can {require Config; import Config;return $Config{d_flock}}
use IO::File;
can();
print "ok\n";'
result[2011]='ok'
tests[203]='use open(IN => ":crlf", OUT => ":encoding(cp1252)");
open F, "<", "/dev/null";
my %l = map {$_=>1} PerlIO::get_layers(F, input  => 1);
print $l{crlf} ? q(ok) : keys(%l);'
result[203]='ok'
# issue 29
tests[2900]='use open qw(:std :utf8);
BEGIN{ `echo ö > xx.bak`; }
open X, "xx.bak";
$_ = <X>;
print unpack("U*", $_), " ";
print $_ if /\w/;'
result[2900]='24610 ö'
tests[207]='use warnings;
sub asub { }
asub(tests => 48);
my $str = q{0};
$str =~ /^[ET1]/i;
{
    no warnings qw<io deprecated>;
    print "ok 1\n" if opendir(H, "t");
    print "ok 2" if open(H, "<", "TESTS");
}'
result[207]='ok 1
ok 2'
tests[208]='#TODO 197
sub MyKooh::DESTROY { print "${^GLOBAL_PHASE} MyKooh " }  my $k=bless {}, MyKooh;
sub OurKooh::DESTROY { print "${^GLOBAL_PHASE} OurKooh" }our $k=bless {}, OurKooh;'
if [[ `$PERL -e'print (($] < 5.014)?0:1)'` -gt 0 ]]; then
  result[208]='RUN MyKooh DESTRUCT OurKooh'
else
  result[208]=' MyKooh  OurKooh'
fi
tests[212]='$blurfl = 123;
{
    package abc;
    $blurfl = 5;
}
$abc = join(":", sort(keys %abc::));
package abc;
print "variable: $blurfl\n";
print "eval: ". eval q/"$blurfl\n"/;
package main;
sub ok { 1 }'
result[212]='variable: 5
eval: 5'
tests[214]='
my $expected = "foo";
sub check(_) { print( (shift eq $expected) ? "ok\n" : "not ok\n" ) }
$_ = $expected;
check;
undef $expected;
&check; # $_ not passed'
result[214]='ok
ok'
tests[215]='eval { $@ = "t1\n"; do { die "t3\n" }; 1; }; print ":$@:\n";'
result[215]=':t3
:'
tests[216]='eval { $::{q{@}}=42; }; print qq{ok\n}'
result[216]='ok'
# also at 904
tests[220]='#TODO
my $content = "ok\n";
while ( $content =~ m{\w}g ) {
    $_ .= "$-[0]$+[0]";
}
print "ok" if $_ eq "0112";'
result[220]='ok'
tests[223]='use strict; eval q({ $x = sub }); print $@'
result[223]='Illegal declaration of anonymous subroutine at (eval 1) line 1.'
tests[224]='use bytes; my $p = "\xB6"; my $u = "\x{100}"; my $pu = "\xB6\x{100}"; print ( $p.$u eq $pu ? "ko\n" : "ok\n" );'
result[224]='ok'
tests[225]='$_ = $dx = "\x{10f2}"; s/($dx)/$dx$1/; $ok = 1 if $_ eq "$dx$dx"; $_ = $dx = "\x{10f2}"; print qq{end\n};'
result[225]='end'
tests[226]='# WontFix
@INC = (); dbmopen(%H, $file, 0666)'
result[226]='No dbm on this machine at -e line 1.'
tests[227]='open IN, "/dev/null" or die $!; *ARGV = *IN; foreach my $x (<>) { print $x; } close IN; print qq{ok\n}'
result[227]='ok'
tests[229]='sub yyy () { "yyy" } print "ok\n" if( eval q{yyy} eq "yyy");'
result[229]='ok'
#issue 30
tests[230]='sub f1 { my($self) = @_; $self->f2;} sub f2 {} sub new {} print "@ARGV\n";'
result[230]=''
tests[232]='use Carp (); exit unless Carp::longmess(); print qq{ok\n}'
result[232]='ok'
tests[234]='$c = 0; for ("-3" .. "0") { $c++ } ; print "$c"'
result[234]='4'
# t/testc.sh -O3 -Dp,-UCarp,-v 235
tests[235]='BEGIN{$INC{"Carp.pm"}="/dev/null"} $d = pack("U*", 0xe3, 0x81, 0xAF); { use bytes; $ol = bytes::length($d) } print $ol'
result[235]='6'
# -O3
tests[236]='sub t { if ($_[0] == $_[1]) { print "ok\n"; } else { print "not ok - $_[0] == $_[1]\n"; } } t(-1.2, " -1.2");'
result[236]='ok'
tests[237]='print "\000\000\000\000_"'
result[237]='_'
tests[238]='sub f ($);
sub f ($) {
  my $test = $_[0];
  write;
  format STDOUT =
ok @<<<<<<<
$test
.
}
f("");
'
result[238]='ok'
tests[239]='#TODO
my $x="1";
format STDOUT =
ok @<<<<<<<
$x
.
write;print "\n";'
result[239]='ok 1'
tests[240]='my $a = "\x{100}\x{101}Aa";
print "ok\n" if "\U$a" eq "\x{100}\x{100}AA";
my $b = "\U\x{149}cD"; # no pb without that line'
result[240]='ok'
tests[241]='package Pickup; use UNIVERSAL qw( can ); if (can( "Pickup", "can" ) != \&UNIVERSAL::can) { print "not " } print "ok\n";'
result[241]='ok'
tests[242]='$xyz = ucfirst("\x{3C2}");
$a = "\x{3c3}foo.bar";
($c = $a) =~ s/(\p{IsWord}+)/ucfirst($1)/ge;
print "ok\n" if $c eq "\x{3a3}foo.Bar";'
result[242]='ok'
tests[243]='use warnings "deprecated"; print hex(${^WARNINGS}) . " "; print hex(${^H})'
result[243]='0 598'
tests[244]='print "($_)\n" for q{-2}..undef;'
result[244]='(-2)
(-1)
(0)'
tests[245]='sub foo {
    my ( $a, $b ) = @_;
    print "a: ".ord($a)." ; b: ".ord($b)." [ from foo ]\n";
}
print "a: ". ord(lc("\x{1E9E}"))." ; ";
print "b: ". ord("\x{df}")."\n";
foo(lc("\x{1E9E}"), "\x{df}");'
result[245]='a: 223 ; b: 223
a: 223 ; b: 223 [ from foo ]'
# see t/issue235.t test 2
tests[246]='sub foo($\@); eval q/foo "s"/; print $@'
result[246]='Not enough arguments for main::foo at (eval 1) line 2, at EOF'
tests[247]='# WontFix
no warnings; $[ = 1; $big = "N\xabN\xab"; print qq{ok\n} if rindex($big, "N", 3) == 3'
result[247]='ok'
tests[248]='# TODO
{my $s="toto";my $_="titi";{$s =~ /to(?{ print "-$_-$s-\n";})to/;}}'
result[248]='-titi-toto-'
tests[249]='# TODO
use version; print version::is_strict(q{01}) ? 1 : 0'
result[249]='0'
tests[250]='# TODO
use warnings qw/syntax/; use version; $withversion::VERSION = undef; eval q/package withversion 1.1_;/; print $@;'
result[250]='Misplaced _ in number at (eval 1) line 1.
Invalid version format (no underscores) at (eval 1) line 1, near "package withversion "
syntax error at (eval 1) line 1, near "package withversion 1.1_"'
tests[251]='# TODO
sub f;print "ok" if exists &f'
result[251]='ok'
tests[2511]='# TODO
sub f :lvalue;print "ok" if exists &f'
result[2511]='ok'
tests[2512]='# TODO
sub f ();print "ok" if exists &f'
result[2512]='ok'
tests[2513]='# TODO
sub f ($);print "ok" if exists &f'
result[2513]='ok'
tests[2514]='# TODO
sub f;print "ok" if exists &f'
result[2514]='ok'
# duplicate of 234
tests[252]='my $i = 0; for ("-3".."0") { ++$i } print $i'
result[252]='4'
tests[253]='INIT{require "t/test.pl"}plan(tests=>2);is("\x{2665}", v9829);is(v9829,"\x{2665}");'
result[253]='1..2
ok 1
ok 2'
tests[254]='# TODO 197 destroy lexvar
my $flag = 0;
sub  X::DESTROY { $flag = 1 }
{
  my $x;           # x only exists in that scope
  BEGIN {$x = 42 } # initialize variable during compilation
  $x = bless {}, "X";
  # undef($x); # value should be free when exiting scope
}
print "ok\n" if $flag;'
result[254]='ok'
# duplicate of 185, bytes_heavy
tests[255]='$a = chr(300);
my $l = length($a);
my $lb;
{ use bytes; $lb = length($a); }
print( ( $l == 1 && $lb == 2 ) ? "ok\n" : "l -> $l ; lb -> $lb\n" );'
result[255]='ok'
tests[256]='BEGIN{ $| = 1; } print "ok\n" if $| == 1'
result[256]='ok'
tests[259]='use JSON::XS; print encode_json([\0])'
result[259]='[false]'
tests[260]='sub FETCH_SCALAR_ATTRIBUTES {''} sub MODIFY_SCALAR_ATTRIBUTES {''}; my $a :x=1; print $a'
result[260]='1'
tests[261]='q(12-feb-2015) =~ m#(\d\d?)([\-\./])(feb|jan)(?:\2(\d\d+))?#; print $4'
result[261]='2015'
tests[262]='use POSIX'
result[262]=''
tests[263]='use JSON::XS; print encode_json []'
result[263]='[]'
tests[264]='no warnings; warn "$a.\n"'
result[264]='.'
tests[272]='$d{""} = qq{ok\n}; print $d{""};'
result[272]='ok'
tests[2721]='BEGIN{$d{""} = qq{ok\n};} print $d{""};'
result[2721]='ok'
tests[273]='package Foo; use overload; sub import { overload::constant "integer" => sub { return shift }}; package main; BEGIN { $INC{"Foo.pm"} = "/lib/Foo.pm" }; use Foo; my $result = eval "5+6"; print "$result\n"'
result[273]='11'
tests[274]='package Foo;

sub match { shift =~ m?xyz? ? 1 : 0; }
sub match_reset { reset; }

package Bar;

sub match { shift =~ m?xyz? ? 1 : 0; }
sub match_reset { reset; }

package main;
print "1..5\n";

print "ok 1\n" if Bar::match("xyz");
print "ok 2\n" unless Bar::match("xyz");
print "ok 3\n" if Foo::match("xyz");
print "ok 4\n" unless Foo::match("xyz");

Foo::match_reset();
print "ok 5\n" if Foo::match("xyz");'
result[274]='1..5
ok 1
ok 2
ok 3
ok 4
ok 5'
tests[277]='format OUT =
bar ~~
.
open(OUT, ">/dev/null"); write(OUT); close OUT;'
result[277]=''
tests[280]='package M; $| = 1; sub DESTROY {eval {print "Farewell ",ref($_[0])};} package main; bless \$A::B, q{M}; *A:: = \*B::;'
result[280]='Farewell M'
tests[281]='#TODO
"I like pie" =~ /(I) (like) (pie)/; "@-" eq  "0 0 2 7" and print "ok\n"; print "\@- = @-\n\@+ = @+\n"'
result[281]='ok
@- = 0 0 2 7
@+ = 10 1 6 10'
tests[282]='use vars qw($glook $smek $foof); $glook = 3; $smek = 4; $foof = "halt and cool down"; my $rv = \*smek; *glook = $rv; my $pv = ""; $pv = \*smek; *foof = $pv; print "ok\n";'
result[282]='ok'
tests[283]='#238 Undefined format "STDOUT"
format =
ok
.
write'
result[283]='ok'
tests[284]='#-O3 only
my $x="123456789";
format OUT =
^<<~~
$x
.
open OUT, ">ccode.tmp";
write(OUT);
close(OUT);
print `cat "ccode.tmp"`'
result[284]='123
456
789'
tests[289]='#debugging CvCVGV_RC assert only
no warnings; sub z_zwap (&); print qq{ok\n} if eval q{sub z_zwap {return @_}; 1;}'
result[284]='ok'
tests[295]='#TODO
"zzaaabbb" =~ m/(a+)(b+)/ and print "@- : @+\n"'
result[295]='2 2 5 : 8 5 8'

init

# 
# getopts for -q -k -E -Du,-q -v -O2, -a -c -fro-inc
while getopts "haAckoED:B:O:f:q" opt
do
  if [ "$opt" = "q" ]; then 
    QUIET=1
    CCMD="$CCMD -q"
  fi
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "c" ]; then CONT=1; fi
  if [ "$opt" = "k" ]; then KEEP=1; fi
  if [ "$opt" = "E" ]; then CPP=1; fi
  if [ "$opt" = "h" ]; then help; exit; fi
  # -D options: u,-q for quiet, no -D for verbose, -D- for no gcc warnings
  if [ "$opt" = "D" ]; then
    OCMD="$PERL $Mblib -MO=C,-D${OPTARG},"
    if [ $BASE = "testcc.sh" ]; then 
        OCMD="$PERL $Mblib -MO=CC,-D${OPTARG},"
    fi
    if [ -z "${OPTARG/-/}" ]; then
        CCMD="$CCMD -d"
    fi
  fi
  # -B dynamic or -B static
  if [ "$opt" = "B" ]; then 
    CCMD="$CCMD -B${OPTARG}"
  fi
  if [ "$opt" = "O" ]; then OPTIM="$OPTARG"; fi
  if [ "$opt" = "f" ]; then
    OCMD="$(echo $OCMD|sed -e "s/C,/C,-f$OPTARG,/")"
  fi
  if [ "$opt" = "a" ]; then # replace -Du, by -Do
    OCMD="$(echo $OCMD|sed -r -e 's/(-D.*)u,/\1o,/')" 
  fi
  if [ "$opt" = "A" ]; then
      CCMD="$CCMD -DALLOW_PERL_OPTIONS"
  fi
done

if [ "$(perl -V:gccversion)" != "gccversion='';" ]; then
    if [ "$(uname)" = "Darwin" ]; then
	CCMD="$CCMD -g -fno-openmp -fno-var-tracking"
    else
	CCMD="$CCMD -g3"
    fi
fi
if [ -z $OPTIM ]; then OPTIM=-1; fi # all

if [ -z "$QUIET" ]; then
    make 
else
    # O from 5.6 does not support -qq
    qq="`$PERL -e'print (($] < 5.007) ? q() : q(-qq,))'`"
    # replace -D*,-v by -q 
    OCMD="$(echo $OCMD    |sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)" 
    OCMDO1="$(echo $OCMDO1|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO2="$(echo $OCMDO2|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO3="$(echo $OCMDO3|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    OCMDO4="$(echo $OCMDO4|sed -e 's/-D.*,//' -e 's/,-v,/,/' -e s/-MO=/-MO=$qq/)"
    # gnu make?
    make -s >/dev/null || make 2&>1 >/dev/null
fi

# need to shift the options
while [ -n "$1" -a "${1:0:1}" = "-" ]; do shift; done

if [ -n "$1" ]; then
  while [ -n "$1" ]; do
    ctest $1
    shift
  done
else
  for b in $(seq $ntests); do
    ctest $b
  done
  if [ $BASE = "testcc.sh" ]; then
    for b in $(seq 101 $(($ncctests+100))); do
      ctest $b
    done
  fi
fi

# 562  c:  15,25,27
# 58   c:  27,29_i
# 58  cc:  15,18,21,25,26_o,27,29
# 510  c:  15
# 510 cc:  11,15,29
# 511  c:  11,15,16,29

#  http://www.nntp.perl.org/group/perl.perl5.porters/2005/07/msg103315.html
#  FAIL for B::CC should be covered by test 18
