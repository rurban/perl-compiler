#directory /usr/src/perl/perl-5.10.1/perl-5.10.1
#directory /usr/src/perl/perl-5.6.2

set breakpoint pending on
break __asan_report_error

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

define run10plc
  run -Mblib -MByteLoader -Dtv bytecode10.plc
end
#set args -Dtv -Mblib -MByteLoader bytecode10.plc
# grep -Hn PL_no_modify *.c|perl -ne'/^([\w.]+:\d+)/ && print "break $1\n";'
#define break_no_modify
#  break av.c:342
#  break av.c:435
#  break av.c:540
#  break av.c:579
#  break av.c:648
#  break av.c:720
#  break av.c:851
#  break doop.c:640
#  break doop.c:1025
#  break doop.c:1111
#  break mg.c:615
#  break mg.c:2361
#  break pp.c:161
#  break pp.c:864
#  break pp.c:881
#  break pp.c:903
#  break pp_hot.c:401
#  break pp_hot.c:2098
#  break pp_hot.c:2966
#  break pp_sort.c:1569
#  break pp_sys.c:1027
#  break regcomp.c:4924
#  break regcomp.c:5225
#  break sv.c:3247
#  break sv.c:3365
#  break sv.c:3424
#  break sv.c:4331
#  break sv.c:4349
#  break sv.c:4748
#  break sv.c:6950
#  break sv.c:7113
#  break sv.c:8390
#  break universal.c:1353
#  break universal.c:1375
#  break universal.c:1396
#  break util.c:3430
#  break util.c:3433
#end

# break Dynaloader.xs:190
# break byteloader_filter
# break perl_destruct
# break byterun.c:77
# break byterun.c:1128
# break Perl_av_extend
# break byterun
# break bl_getc
# break Perl_pp_match
# break Perl_pad_new

# stack dump, sp or PL_sp or my_perl->Istack_sp?
define sp_dump
  if (my_perl && my_perl->broiled)
    p/x **my_perl->Istack_sp
    call Perl_sv_dump(my_perl, *my_perl->Istack_sp)
  else
    p/x **PL_sp
    Perl_sv_dump(*PL_sp)
  end
end
document sp_dump
 => Perl_sv_dump(PL_sp)
end

define op_dump
  if (my_perl && my_perl->broiled)
    p/x *my_perl->Iop
    call Perl_op_dump(my_perl, my_perl->Iop)
  else
    p/x *PL_op
    call Perl_op_dump(PL_op)
  end
end
document op_dump
 => Perl_op_dump(PL_op)
see `odump op`
end

define sv_dump
  p/x *sv
  call Perl_sv_dump(sv)
end
document sv_dump
 => Perl_sv_dump(sv)
see `sdump sv`
end

define tsv_dump
  p/x *sv
  call Perl_sv_dump(my_perl, sv)
end
document tsv_dump
 => Perl_sv_dump(sv)
see `sdump sv`
end

define odump
  p/x *$arg0
  call Perl_op_dump($arg0)
end
document odump
odump op => p/x *op; Perl_op_dump(op)
see `help op_dump` for PL_op
end

define todump
  p/x *$arg0
  call Perl_op_dump(my_perl, $arg0)
end
document todump
todump op => p/x *op; Perl_op_dump(op)
see `help op_dump` for PL_op
end

define sdump
  p/x *$arg0
  call Perl_sv_dump($arg0)
end
document sdump
sdump sv => p/x *sv; Perl_sv_dump(sv)
see `help tsdump`
end

define tsdump
  p/x *$arg0
  call Perl_sv_dump(my_perl, $arg0)
end
document tsdump
tsdump sv => p/x *sv; Perl_sv_dump(my_perl, sv)
see `help sdump`
end
