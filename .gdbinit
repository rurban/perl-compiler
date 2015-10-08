#directory /usr/src/perl/perl-5.10.1/perl-5.10.1
#directory /usr/src/perl/perl-5.6.2
directory /root/workspace/src/perl522-debug-patched
#add-auto-load-safe-path /lib/x86_64-linux-gnu/libthread_db-1.0.so

set breakpoint pending on
#source .gdb/dashboard
source .gdb/perl

#break __asan_report_error
#b Perl_pp_multideref

b Perl_pp_entereval
command
p/x *PL_comppad_name
p *(PL_comppad_name->xpadnl_alloc)[1]
end

b Perl_newPADNAMEouter
command
macro expand (PADNAME_FROM_PV(PadnamePV(outer))
p (long)(&(((struct padname_with_str *)0)->xpadn_str))
p *outer
end

b dump.c:2384
command
echo actions\n
p/x actions
echo action&mask MDEREF_HV_gvhv_helem=13\n
p actions&MDEREF_ACTION_MASK
echo items\n
p *items
echo sv\n
p sv
end

#b bset_obj_store
#command
#b Perl_padnamelist_store
#c
#end

#b XS_DBI__install_method
break Perl_croak_no_modify
#break XS_B__CC__autovivification
#break B.xs:1398
#break B.c:2044
#break B.xs:1858
#break oplist
#break Perl_do_openn
# require %INC
#break pp_ctl.c:3599
#run
#p/x sv_list[3299]
# panic free from wrong pool 5.18.1
#b util.c:252
#b sv.c:3737 if (GV*)dstr->sv_u.svu_gp

r
