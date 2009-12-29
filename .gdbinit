#directory /usr/src/perl/perl-5.10.1/perl-5.10.1

define run10plc
  run -Mblib -MByteLoader -Dtv bytecode10.plc
end
#set args -Dtv -Mblib -MByteLoader bytecode10.plc
# grep -Hn PL_no_modify *.c|perl -ne'/^([\w.]+:\d+)/ && print "break $1\n";'
define break_no_modify
  break av.c:342
  break av.c:435
  break av.c:540
  break av.c:579
  break av.c:648
  break av.c:720
  break av.c:851
  break doop.c:640
  break doop.c:1025
  break doop.c:1111
  break mg.c:615
  break mg.c:2361
  break pp.c:161
  break pp.c:864
  break pp.c:881
  break pp.c:903
  break pp_hot.c:401
  break pp_hot.c:2098
  break pp_hot.c:2966
  break pp_sort.c:1569
  break pp_sys.c:1027
  break regcomp.c:4924
  break regcomp.c:5225
  break sv.c:3247
  break sv.c:3365
  break sv.c:3424
  break sv.c:4331
  break sv.c:4349
  break sv.c:4748
  break sv.c:6950
  break sv.c:7113
  break sv.c:8390
  break universal.c:1353
  break universal.c:1375
  break universal.c:1396
  break util.c:3430
  break util.c:3433
end

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

# threaded
define stack_dump
  call Perl_sv_dump(my_perl, *sp)
end
# non-threaded
define stack_dump_nt
  call Perl_sv_dump(*sp)
end
define op_dump
  call Perl_op_dump(my_perl, PL_op)
end
define op_dump_nt
  call Perl_op_dump(PL_op)
end
define sv_dump
  call Perl_sv_dump(my_perl, sv)
end
define sv_dump_nt
  call Perl_sv_dump(sv)
end
