#!/bin/bash
# t/testm.sh File::Temp
# => $^X -Mblib blib/script/perlcc -S -e 'use File::Temp; print "ok"' -o file_temp
#
# How to installed skip modules: 
# t/testm.sh -s runs:
#   grep ^skip log.modules-$ver|perl -lane'print $F[1]'| xargs perl$ver -S cpan
# perl$ver -S cpan `grep -v '#' t/mymodules`
#
# -t runs CPAN::Shell->testcc($module)
# Example:
# cwd=~/Perl/B-C; perl5.12.2d-nt -I$cwd/blib/arch -I$cwd/blib/lib $cwd/blib/script/perlcc -S -r -Wb=-O1 -v 4 t/test.t

function help {
  echo "t/testm.sh [OPTIONS] [module|modules-file]..."
  echo " -q                 quiet"
  echo " -k                 keep temp. files on PASS"
  echo " -D<arg>            add debugging flags"
  echo " -f<arg>            add optimisation flags"
  echo " -O<arg>            add optimisation flags"
  echo " -l                 log"
  echo " -o                 orig. no -Mblib, use installed modules (5.6, 5.8)"
  echo " -t                 run the module tests also, not only use Module (experimental)"
  echo " -F                 run failing modules only"
  echo " -s                 install skipped (missing) modules"
  echo " -T                 time compilation and run"
  echo " -h                 help"
}

# use the actual perl from the Makefile (perl5.8.8, 
# perl5.10.0d-nt, perl5.11.0, ...)
PERL=`grep "^PERL =" Makefile|cut -c8-`
PERL=${PERL:-perl}
Mblib=-Mblib
v513="`$PERL -e'print (($] < 5.013005) ? q() : q(-fno-fold,-fno-warnings))'`"

function vcmd {
    test -n "$QUIET" || echo $*
    $*
}

function pass {
    echo -e -n "\033[1;32mPASS \033[0;0m"
    shift
    echo $*
    echo
}
function fail {
    echo -e -n "\033[1;31mFAIL \033[0;0m"
    shift
    echo $*
    echo
}
[ -n "$v513" ] && PERLCC_OPTS="$PERLCC_OPTS -Wb=$v513"
#PERLCC_OPTS=v513
while getopts "hokltTsFD:O:f:qv" opt
do
  if [ "$opt" = "o" ]; then Mblib=" "; init; fi
  if [ "$opt" = "q" ]; then QUIET=1; fi
  if [ "$opt" = "v" ]; then QUIET=0; PERLCC_OPTS="$PERLCC_OPTS -v6"; fi
  if [ "$opt" = "k" ]; then KEEP="-S"; fi
  if [ "$opt" = "D" ]; then PERLCC_OPTS="$PERLCC_OPTS -Wb=-D${OPTARG}"; COPTS="$COPTS,-D${OPTARG}"; fi
  if [ "$opt" = "O" ]; then PERLCC_OPTS="$PERLCC_OPTS -Wb=-O${OPTARG}"; COPTS="$COPTS,-O${OPTARG}"; fi
  if [ "$opt" = "f" ]; then PERLCC_OPTS="$PERLCC_OPTS -Wb=-f${OPTARG}"; COPTS="$COPTS,-f${OPTARG}"; fi
  if [ "$opt" = "l" ]; then TEST="-log"; fi
  if [ "$opt" = "t" ]; then TEST="-t"; fi
  if [ "$opt" = "T" ]; then PERLCC_OPTS="$PERLCC_OPTS --time"; PERLCC_TIMEOUT=120; fi
  if [ "$opt" = "s" ]; then 
      v=$($PERL -It -Mmodules -e'print perlversion')
      if [ -f log.modules-$v ]; then # and not older than a few days
	  echo $PERL -S cpan `grep ^skip log.modules-$v | perl -anle 'print $F[1]'`
          $PERL -S cpan $(grep ^skip log.modules-$v | perl -anle 'print $F[1]')
      else
	  echo $PERL -S cpan $($PERL $Mblib -It -Mmodules -e'$,=" "; print skip_modules')
          $PERL -S cpan $($PERL $Mblib -It -Mmodules -e'$,=" "; print skip_modules')
      fi
      exit
  fi
  if [ "$opt" = "F" ]; then 
      v=$($PERL -It -Mmodules -e'print perlversion')
      if [ -f log.modules-$v ]; then # and not older than a few days
	  echo t/testm.sh `grep ^fail log.modules-$v | perl -anle 'print $F[1]'`
          for m in $(grep ^fail log.modules-$v | perl -anle 'print $F[1]'); do t/testm.sh -q $m; done
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

PERLCC_TIMEOUT=360
if [ -n "$1" ]; then
    if [ -f "$1" ]; then
	# run a mymodules.t like test
	$PERL $Mblib t/modules.t $TEST "$1"
    else
        [ -z "$QUIET" ] && PERLCC_OPTS="$PERLCC_OPTS -v4"
	while [ -n "$1" ]; do
	    # single module. update,setup,install are UAC terms
	    name="$(perl -e'$a=shift;$a=~s{::}{_}g;$a=~s{(install|setup|update)}{substr($1,0,4)}ie;print lc($a)' $1)"
	    if [ "${COPTS/,-D/}" != "$COPTS" ]; then
              COPTS="${COPTS:1}"
	      echo $PERL $Mblib -MO=C,$COPTS,-o$name.c -e "\"use $1; print qq(ok\\n)\""
	      $PERL $Mblib -MO=C,$COPTS,-o$name.c -e "use $1; print qq(ok\\n)"
	      if [ -f $name.c ]; then
		echo $PERL $Mblib script/cc_harness -d -g3 -o $name $name.c
		$PERL $Mblib script/cc_harness -d -g3 -o $name $name.c
		if [ -f $name ]; then
		  echo "running ./$name"
		  ./$name
		fi
	      fi
	    else
	      echo $PERL $Mblib blib/script/perlcc $PERLCC_OPTS -r $KEEP -e "\"use $1; print qq(ok\\n)\"" -o $name
	      $PERL $Mblib blib/script/perlcc $PERLCC_OPTS -r $KEEP -e "use $1; print qq(ok\\n)" -o $name
              # test -f a.out.c && mv a.out.c $name.c
            fi
	    if [ "$TEST" = "-t" ]; then 
		$PERL $Mblib -It -MCPAN -Mmodules -e "CPAN::Shell->testcc(q($1))"
	    fi
	    shift
	done
    fi
else
    $PERL $Mblib t/modules.t $TEST
fi
