#!/bin/sh
# run all perls on a single core test
t=${1:-t/CORE/v5.22/comp/proto.t}
echo perlall='5.*-nt' perlall -m --nolog do $t
perlall='5.*-nt' perlall -m --nolog do $t 2>&1 | egrep '(^not ok|/perl5.)'
