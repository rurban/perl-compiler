#!/bin/sh
# cpan Pod::S5

#perl -MTest::Pod -e'pod_file_ok q(frozenperl_2010.pod)' && \
#pod2s5 --theme rurban --creation "Minneapolis Sat Feb 7, 2010" \
#	--name "Frozen Perl 2010" \
#	--where "Reini Urban" frozenperl_2010.pod

perl -MTest::Pod -e'pod_file_ok q(yapceu_2010.pod)' && \
pod2s5 --theme rurban --creation "Pisa Wed Aug 4, 2010" \
	--name "YAPC::EU 2010" \
	--where "Reini Urban" yapceu_2010.pod

#perl -MTest::Pod -e'pod_file_ok q(cp_light.pod)' && \
#pod2s5 --theme rurban --creation "Austin Tue Oct 11, 2011" \
#	--name "bootcamp 2011" \
#	--where "Reini Urban" cp_light.pod
