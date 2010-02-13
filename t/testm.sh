#!/bin/bash
# t/testm.sh File::Temp
# => $^X -Mblib blib/script/perlcc -S -e 'use File::Temp; print "ok"' -o file_temp
#
# How to installed skip modules:
# grep ^skip log.modules-bla|cut -c6-| xargs perlbla -S cpan

# TODO: Try to run CPAN::Shell->testcc($module) with -t

function help {
  echo "t/testm.sh [OPTIONS] [module|modules-file]..."
  echo " -k                 keep temp. files on PASS"
  echo " -o                 orig. no -Mblib, use installed modules (5.6, 5.8)"
  echo " -t                 run the module tests also, not only use Module (experimental)"
  echo " -h                 help"
}

# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}

function init {
    BASE=`basename $0`
    # if $] < 5.9 you may want to remove -Mblib for testing the core lib. -o
    #Mblib="`$PERL -e'print (($] < 5.009005) ? q() : q(-Mblib))'`"
    Mblib=${Mblib:--Mblib} # B::C is now fully 5.6+5.8 backwards compatible
    if [ -z $Mblib ]; then 
	VERS="${VERS}_global"; 
	OCMD="$PERL $Mblib -MO=C,-DcAC,"
	if [ $BASE = "testcc.sh" ]; then 
	    OCMD="$PERL $Mblib -MO=CC,-DrOsplt,"
	fi
    else
	OCMD="$PERL $Mblib -MO=C,-DcoOSAHGCMpu,-v,"
	if [ $BASE = "testcc.sh" ]; then
	    OCMD="$PERL $Mblib -MO=CC,-DoOscprSql,-v,"
	fi
    fi
    OCMDO1="$(echo $OCMD|sed -e s/C,-D/C,-O1,-D/)"
    OCMDO2="$(echo $OCMD|sed -e s/C,-D/C,-O2,-D/)"
    OCMDO3="$(echo $OCMD|sed -e s/C,-D/C,-O3,-D/)"
    OCMDO4="$(echo $OCMD|sed -e s/C,-D/C,-O4,-D/)"
    CONT=
    # 5.6: rather use -B static
    #CCMD="$PERL script/cc_harness -g3"
    # rest. -DALLOW_PERL_OPTIONS for -Dtlv
    CCMD="$PERL script/cc_harness -d -g3 -Bdynamic -DALLOW_PERL_OPTIONS"  
    LCMD=
    # On some perls I also had to add $archlib/DynaLoader/DynaLoader.a to libs in Config.pm
}

function vcmd {
    test -n "$QUIET" || echo $*
    $*
}

function pass {
    echo -e -n "\e[1;32mPASS \e[0;0m"
    shift
    echo $*
    echo
}
function fail {
    echo -e -n "\e[1;31mFAIL \e[0;0m"
    shift
    echo $*
    echo
}

init

# 
# getopts for -q -k -E -Du,-q -v -O2, -a -c
while getopts "hckot" opt
do
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "c" ]; then CONT=1; fi
  if [ "$opt" = "k" ]; then KEEP=1; fi
  if [ "$opt" = "t" ]; then TEST="-t"; fi
  if [ "$opt" = "h" ]; then help; exit; fi
done

if [ -z "$QUIET" ]; then
    make 
else
    make --silent >/dev/null
fi

# need to shift the options
while [ -n "$1" -a "${1:0:1}" = "-" ]; do shift; done

if [ -n "$1" ]; then
    if [ -f "$1" ]; then
	# run a mymodules.t like test
	$PERL $Mblib t/modules.t $TEST "$1"
    else
	while [ -n "$1" ]; do
	    # single module
	    name="$(perl -e'$ARGV[0]=~s{::}{_}g; print lc($ARGV[0])' $1)"
	    echo $PERL $Mblib blib/script/perlcc -r -S -e "use $1; print 'ok'" -o $name
	    $PERL $Mblib blib/script/perlcc -r -S -e "use $1; print 'ok'" -o $name
	    mv a.out.c $name.c
	    [ -n "$TEST" ] && $PERL $Mblib -It -MCPAN -Mmodules -e"CPAN::Shell->testcc(q($1))"
	    shift
	done
    fi
else
    $PERL $Mblib t/modules.t $TEST
fi
