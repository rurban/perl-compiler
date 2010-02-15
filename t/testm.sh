#!/bin/bash
# t/testm.sh File::Temp
# => $^X -Mblib blib/script/perlcc -S -e 'use File::Temp; print "ok"' -o file_temp
#
# How to installed skip modules:
# grep ^skip log.modules-bla|cut -c6-| xargs perlbla -S cpan

# In work: Try to run CPAN::Shell->testcc($module) with -t

function help {
  echo "t/testm.sh [OPTIONS] [module|modules-file]..."
  echo " -k                 keep temp. files on PASS"
  echo " -o                 orig. no -Mblib, use installed modules (5.6, 5.8)"
  echo " -t                 run the module tests also, not only use Module (experimental)"
  echo " -s                 install skipped (missing) modules"
  echo " -h                 help"
}

# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}

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

# 
# getopts for -q -k -E -Du,-q -v -O2, -a -c
while getopts "hckots" opt
do
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "c" ]; then CONT=1; fi
  if [ "$opt" = "k" ]; then KEEP=1; fi
  if [ "$opt" = "t" ]; then TEST="-t"; fi
  if [ "$opt" = "s" ]; then 
      v=$($PERL -It -Mmodules -e'print perlversion')
      if [ -f log.modules-$v ]; then
          grep ^skip log.modules-$v | cut -c6- | xargs $PERL -S cpan
      else
          $PERL -S cpan $($PERL $Mblib -It -Mmodules -e'$,=" "; print skip_modules')
      fi
      exit
  fi
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
	    echo $PERL $Mblib blib/script/perlcc -r -S -e "\"use $1; print 'ok'\"" -o $name
	    $PERL $Mblib blib/script/perlcc -r -S -e "use $1; print 'ok'" -o $name
	    mv a.out.c $name.c
	    [ -n "$TEST" ] && $PERL $Mblib -It -MCPAN -Mmodules -e"CPAN::Shell->testcc(q($1))"
	    shift
	done
    fi
else
    $PERL $Mblib t/modules.t $TEST
fi
