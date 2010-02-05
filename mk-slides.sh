#!/bin/sh
# 

perl -MTest::Pod -e'pod_file_ok q(frozenperl_2010.pod)' && \
pod2s5 --theme rurban --creation "Minneapolis Sat Feb 7, 2010" \
	--name "Frozen Perl 2010" \
	--where "Reini Urban" frozenperl_2010.pod