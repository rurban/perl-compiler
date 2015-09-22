/* created at Tue Sep 22 10:12:06 2015 with B::C 1.52-2728-g25895ba */
#define PERL_CORE /* Needed for some extensions perl core refeses to export (win32 only)*/
#include "EXTERN.h" /* Embedded interface */
#include "perl.h"   /* API interface */
#include "XSUB.h"   /* XS interface */

/* Workaround for mapstart: the only op which needs a different ppaddr */
#undef Perl_pp_mapstart
#define Perl_pp_mapstart Perl_pp_grepstart
#undef OP_MAPSTART
#define OP_MAPSTART OP_GREPSTART

/* TODO: Why was this removed from perl core? */
/* No longer available when C<PERL_CORE> is defined. */
#ifndef Nullsv
#  define Null(type) ((type)NULL)
#  define Nullsv Null(SV*)
#  define Nullhv Null(HV*)
#  define Nullgv Null(GV*)
#  define Nullop Null(OP*)
#endif
#ifndef GV_NOTQUAL
#  define GV_NOTQUAL 0
#endif
/* Since 5.8.8 */
#ifndef Newx
#  define Newx(v,n,t)    New(0,v,n,t)
#endif
#define XS_DynaLoader_boot_DynaLoader boot_DynaLoader
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void xs_init (pTHX);
static void dl_init (pTHX);
int fast_perl_destruct( PerlInterpreter *my_perl );
static void my_curse( pTHX_ SV* const sv );

/* TODO: Not provided in perl core? */
#ifndef dVAR
# ifdef PERL_GLOBAL_STRUCT
#  define dVAR		pVAR    = (struct perl_vars*)PERL_GET_VARS()
# else
#  define dVAR		dNOOP
# endif
#endif


#ifdef BROKEN_STATIC_REDECL
#define Static extern
#else
#define Static static
#endif /* BROKEN_STATIC_REDECL */

#ifdef BROKEN_UNION_INIT
#error BROKEN_UNION_INIT no longer needed, as Perl requires an ANSI compiler
#endif

#define XPVCV_or_similar XPVCV
#define ANYINIT(i) {i}
#define Nullany ANYINIT(0)

#define UNUSED 0
#define sym_0 0
typedef struct p5rx RE;
Static GV *gv_list[10];
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );


Static COP cop_list[4];
Static OP op_list[9];
Static UNOP unop_list[1];
Static BINOP binop_list[6];
Static LISTOP listop_list[2];
Static SVOP svop_list[4];
Static XPV xpv_list[10];
Static XPVAV xpvav_list[3];
Static XPVHV xpvhv_list[1];
Static XPVIV xpviv_list[2];
Static XPVNV xpvnv_list[3];
Static XPVMG xpvmg_list[2];
Static XPVIO xpvio_list[1];
Static SV sv_list[30];
Static const char emptystring[] = "\0";
Static const char xsfile[] = "universal.c";
#define ptr_undef NULL
#undef CopFILE_set
#define CopFILE_set(c,pv)  CopFILEGV_set((c), gv_fetchfile(pv))
Static const char pv0[] = "main";
Static const char pv1[] = "hello_world.pl";
Static const char pv2[] = "4";
Static HEK *hek0;
Static char pv3[] = "hello_world.c";
Static HEK *hek1;
Static HEK *hek2;

/* copsect - array of cops in the code. for debugging, line number info. State/Context op. "Every ; is a cop." */
Static COP cop_list[4] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private, line, stash, file, hints, seq, warn_sv, hints_hash */
	{ (OP*)&svop_list[0], (OP*)&binop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 184, 0, 0, 0, 1, 0, 0, 0x1, 0x0, 3, Nullhv, Nullgv, 256, 4010, pWARN_STD, NULL }, /* cop_list[0]  */
	{ (OP*)&svop_list[1], (OP*)&binop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 184, 0, 0, 0, 1, 0, 0, 0x1, 0x0, 4, Nullhv, Nullgv, 256, 4011, pWARN_STD, NULL }, /* cop_list[1]  */
	{ &op_list[5], (OP*)&binop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 184, 0, 0, 0, 1, 0, 0, 0x1, 0x0, 5, Nullhv, Nullgv, 256, 4012, pWARN_STD, NULL }, /* cop_list[2]  */
	{ &op_list[1], (OP*)&listop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 184, 0, 0, 0, 1, 0, 0, 0x1, 0x0, 6, Nullhv, Nullgv, 256, 4013, pWARN_STD, NULL }, /* cop_list[3]  */
};

/* Chain of operations.*/

Static OP op_list[9] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private */
	{ (OP*)&cop_list[0], (OP*)&cop_list[0], INT2PTR(void*,OP_ENTER), 0, 187, 0, 0, 0, 1, 0, 0, 0x0, 0x0 }, /* op_list[0]  */
	{ (OP*)&svop_list[2], (OP*)&unop_list[0], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0x2, 0x0 }, /* op_list[1]  */
	{ (OP*)&svop_list[2], (OP*)&binop_list[4], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0x2, 0x0 }, /* op_list[2]  */
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_PADSV), 1, 9, 0, 0, 0, 1, 0, 0, 0xb2, 0x80 }, /* op_list[3]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0xb2, 0x80 }, /* op_list[4]  */
	{ &op_list[6], &op_list[6], INT2PTR(void*,OP_PADSV), 1, 9, 0, 0, 0, 1, 0, 0, 0x2, 0x0 }, /* op_list[5]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0x2, 0x0 }, /* op_list[6]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_PADSV), 3, 9, 0, 0, 0, 1, 0, 0, 0xb2, 0x80 }, /* op_list[7]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_PADSV), 3, 9, 0, 0, 0, 1, 0, 0, 0x2, 0x0 }, /* op_list[8]  */
};

/* Unary operations */

Static UNOP unop_list[1] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private, first */
	{ (OP*)&listop_list[1], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0x6, 0x1, &op_list[2] }, /* unop_list[0]  */
};

/* Binary argument operations */
/* first/last aren't useful to runtime but might be introspected by certain modules. */

Static BINOP binop_list[6] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private, first, last */
	{ (OP*)&cop_list[1], (OP*)&cop_list[1], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0x45, 0x2, (OP*)&svop_list[0], &op_list[3] }, /* binop_list[0]  */
	{ (OP*)&cop_list[2], (OP*)&cop_list[2], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0x45, 0x2, (OP*)&svop_list[1], &op_list[4] }, /* binop_list[1]  */
	{ (OP*)&cop_list[3], (OP*)&cop_list[3], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0x45, 0x2, (OP*)&binop_list[3], &op_list[7] }, /* binop_list[2]  */
	{ &op_list[7], &op_list[7], INT2PTR(void*,OP_ADD), 4, 63, 0, 0, 0, 1, 0, 0, 0x6, 0x2, &op_list[5], &op_list[6] }, /* binop_list[3]  */
	{ (OP*)&listop_list[1], 0, INT2PTR(void*,OP_CONCAT), 6, 67, 0, 0, 0, 1, 0, 0, 0x46, 0x2, (OP*)&binop_list[5], (OP*)&svop_list[3] }, /* binop_list[4]  */
	{ (OP*)&svop_list[3], (OP*)&svop_list[3], INT2PTR(void*,OP_CONCAT), 5, 67, 0, 0, 0, 1, 0, 0, 0x6, 0x2, (OP*)&svop_list[2], &op_list[8] }, /* binop_list[5]  */
};

/* Op chains run.c */

Static LISTOP listop_list[2] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private, first, last */
	{ 0, 0, INT2PTR(void*,OP_LEAVE), 1, 188, 0, 0, 0, 1, 0, 0, 0xd, 0x40, &op_list[0], (OP*)&listop_list[1] }, /* listop_list[0]  */
	{ (OP*)&listop_list[0], 0, INT2PTR(void*,OP_PRINT), 0, 226, 0, 0, 0, 1, 0, 0, 0x5, 0x0, &op_list[1], (OP*)&unop_list[0] }, /* listop_list[1]  */
};

/* ALL scalars  */

Static SVOP svop_list[4] = {
	/* next, sibling, ppaddr, targ, type, opt, slabbed, savefree, static, folded, spare, flags, private, sv */
	{ &op_list[3], &op_list[3], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0x2, 0x0, (SV*)&sv_list[1] }, /* svop_list[0]  */
	{ &op_list[4], &op_list[4], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0x2, 0x0, (SV*)&sv_list[2] }, /* svop_list[1]  */
	{ &op_list[8], &op_list[8], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0x2, 0x0, (SV*)&sv_list[3] }, /* svop_list[2]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0x2, 0x0, (SV*)&sv_list[4] }, /* svop_list[3]  */
};


/* Additional DATA for SVs */
/* PV body */
Static XPV xpv_list[10] = {
	/* stash, magic, cur, len, */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 1, 4 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 17, 20 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 73, 76 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 56, 60 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 69, 72 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 52, 56 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 47, 48 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 1, 4 }, /* xpv_list[9]  */
};

/* Additional data for arrays */

Static XPVAV xpvav_list[3] = {
	{ Nullhv, {0}, 3, 3, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, 7, 7, 0 }, /* xpvav_list[1]  */
	{ Nullhv, {0}, 7, 7, 0 }, /* xpvav_list[2]  */
};

/* Additional data for hashes */
Static XPVHV xpvhv_list[1] = {
	/* stash mgu max keys */
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[0]  */
};

/* Additional data for PVIV */

Static XPVIV xpviv_list[2] = {
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[0]  */
	{ Nullhv, {0}, 0, 0, {7} }, /* xpviv_list[1]  */
};

/* Additional data for PVNV */

Static XPVNV xpvnv_list[3] = {
	/* STASH, MAGIC, cur, len, IVX, _xnvu */
	{ Nullhv, {0}, 2, 4, {0}, {.xpad_cop_seq.xlow = 4010, .xpad_cop_seq.xhigh = 4013} }, /* xpvnv_list[0]  */
	{ Nullhv, {0}, 2, 4, {0}, {.xpad_cop_seq.xlow = 4011, .xpad_cop_seq.xhigh = 4013} }, /* xpvnv_list[1]  */
	{ Nullhv, {0}, 2, 4, {0}, {.xpad_cop_seq.xlow = 4012, .xpad_cop_seq.xhigh = 4013} }, /* xpvnv_list[2]  */
};

/* magic */

Static XPVMG xpvmg_list[2] = {
	/* STASH, MAGIC, cur, len, xiv_u, xnv_u */
	{ Nullhv, {0}, 1, 2, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 13, 16, {0}, {0.00} }, /* xpvmg_list[1]  */
};

/* iosect - initial state of all file handles*/

Static XPVIO xpvio_list[1] = {
	/* STASH, xmg_u, cur, len, xiv_u, xio_ofp, xio_dirpu, page, page_len, ..., type, flags */
	{ Nullhv, /*STASH later*/
	{0}, /*MAGIC later*/
	0, /*cur*/
	0, /*len*/
	{0}, /*LINES*/
	0, /*OFP later*/
	{0}, /*dirp_u later*/
	0, /*PAGE*/
	60, /*PAGE_LEN*/
	60, /*LINES_LEFT*/
	NULL, /*TOP_NAME*/
	Nullgv, /*top_gv later*/
	NULL, /*fmt_name*/
	Nullgv, /*fmt_gv later*/
	NULL, /*bottom_name*/
	Nullgv, /*bottom_gv later*/
	'>', /*type*/
	0x0 /*flags*/ }, /* xpvio_list[0]  */
};

/*  */

Static SV sv_list[30] = {
	/* body, refcnt, flags with type, union (pv?) */
	{ 0, 30, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */ /* fast destruction */
	{ &xpviv_list[0], 1, 0x8001101, {.svu_pv=NULL} }, /* sv_list[1]  */
	{ &xpviv_list[1], 1, 0x8001101, {.svu_pv=NULL} }, /* sv_list[2]  */
	{ &xpv_list[0], 1, 0x8004403, {0} }, /* sv_list[3]  */
	{ &xpv_list[1], 1, 0x8004403, {0} }, /* sv_list[4]  */
	{ &xpvmg_list[0], 1, 0x604407, {.svu_pv=(char*)pv2} }, /* sv_list[5]  */
	{ &xpvmg_list[1], 1, 0x614407, {.svu_pv=(char*)pv3} }, /* sv_list[6]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[7]  */
	{ &xpvav_list[0], 1, 0x4000800b, {0} }, /* sv_list[8]  */
	{ &xpvnv_list[0], 1, 0x4406 , {.svu_pv=(char*)NULL} }, /* sv_list[9]  */
	{ &xpvnv_list[1], 1, 0x4406 , {.svu_pv=(char*)NULL} }, /* sv_list[10]  */
	{ &xpvnv_list[2], 1, 0x4406 , {.svu_pv=(char*)NULL} }, /* sv_list[11]  */
	{ &xpvav_list[1], 1, 0x4000000b, {0} }, /* sv_list[12]  */
	{ 0, 1, 0x40000, {0} }, /* sv_list[13]  */
	{ 0, 1, 0x40000, {0} }, /* sv_list[14]  */
	{ 0, 1, 0x40000, {0} }, /* sv_list[15]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[16]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[17]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[18]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[19]  */
	{ &xpvhv_list[0], 1, 0x2200000c, {0} }, /* sv_list[20]  */
	{ &xpvav_list[2], 1, 0x4000000b, {0} }, /* sv_list[21]  */
	{ &xpv_list[2], 1, 0x4403, {0} }, /* sv_list[22]  */
	{ &xpv_list[3], 1, 0x4403, {0} }, /* sv_list[23]  */
	{ &xpv_list[4], 1, 0x4403, {0} }, /* sv_list[24]  */
	{ &xpv_list[5], 1, 0x4403, {0} }, /* sv_list[25]  */
	{ &xpv_list[6], 1, 0x4403, {0} }, /* sv_list[26]  */
	{ &xpv_list[7], 1, 0x4403, {0} }, /* sv_list[27]  */
	{ &xpv_list[8], 1, 0x4403, {0} }, /* sv_list[28]  */
	{ &xpv_list[9], 1, 0x4403, {0} }, /* sv_list[29]  */
};

static int perl_init0(pTHX) /* fixup_ppaddr */
{	{
	    register int i;
	    for( i = 0; i < 6; ++i ) {
	        binop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(binop_list[i].op_ppaddr)];
	    }
	}
	{
	    register int i;
	    for( i = 0; i < 4; ++i ) {
	        cop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(cop_list[i].op_ppaddr)];
	    }
	}
	{
	    register int i;
	    for( i = 0; i < 2; ++i ) {
	        listop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(listop_list[i].op_ppaddr)];
	    }
	}
	{
	    register int i;
	    for( i = 0; i < 9; ++i ) {
	        op_list[i].op_ppaddr = PL_ppaddr[PTR2IV(op_list[i].op_ppaddr)];
	    }
	}
	{
	    register int i;
	    for( i = 0; i < 4; ++i ) {
	        svop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(svop_list[i].op_ppaddr)];
	    }
	}
	{
	    register int i;
	    for( i = 0; i < 1; ++i ) {
	        unop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(unop_list[i].op_ppaddr)];
	    }
	}
};

static int perl_init_aaaa(pTHX)
{
	CopSTASHPV_set(&cop_list[0], pv0);
	CopFILE_set(&cop_list[0], pv1);
	CopSTASHPV_set(&cop_list[1], pv0);
	CopFILE_set(&cop_list[1], pv1);
	CopSTASHPV_set(&cop_list[2], pv0);
	CopFILE_set(&cop_list[2], pv1);
	CopSTASHPV_set(&cop_list[3], pv0);
	CopFILE_set(&cop_list[3], pv1);
	sv_list[3].sv_u.svu_pv = savepvn("Hello World ", 12);
	sv_list[4].sv_u.svu_pv = savepvn("\n", 1);
	
	/* done main optree, extra subs which might be unused */
	gv_list[0] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[0]) = 3;
	gv_list[1] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD | SVf_UTF8, SVt_PV);
	SvFLAGS(gv_list[1]) = 0x8009;
	GvFLAGS(gv_list[1]) = 0x2; 
	GvLINE(gv_list[1]) = 95;
	SvREFCNT(gv_list[1]) = 51;
	GvREFCNT(gv_list[1]) += 1;
	sv_list[5].sv_u.svu_pv = savepvn("4", 1);
	sv_magic((SV*)&sv_list[5], (SV*)gv_list[1], '\000', 0, 1);
	GvSVn(gv_list[1]) = (SV*)&sv_list[5];
	hek0 = share_hek("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/5.20.2/i386-linux-64int/B.pm", 74, 0);
	GvFILE_HEK(gv_list[1]) = hek0;
	
	gv_list[2] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD | SVf_UTF8, SVt_PV);
	SvFLAGS(gv_list[2]) = 0x8009;
	GvFLAGS(gv_list[2]) = 0x2; 
	GvLINE(gv_list[2]) = 329;
	SvREFCNT(gv_list[2]) = 8;
	GvREFCNT(gv_list[2]) += 1;
	sv_list[6].sv_u.svu_pv = savepvn("hello_world.c\000\001", 15);
	sv_magic((SV*)&sv_list[6], (SV*)gv_list[2], '\000', 0, 2);
	GvSVn(gv_list[2]) = (SV*)&sv_list[6];
	hek1 = share_hek("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/5.20.2/Carp.pm", 60, 0);
	GvFILE_HEK(gv_list[2]) = hek1;
	
	SvFLAGS(PL_stderrgv) = 0x8009;
	GvFLAGS(PL_stderrgv) = 0x2; 
	GvLINE(PL_stderrgv) = 0;
	SvREFCNT(PL_stderrgv) = 5;
	GvREFCNT(PL_stderrgv) += 1;
	SvFLAGS(PL_stdingv) = 0x8009;
	GvFLAGS(PL_stdingv) = 0x2; 
	GvLINE(PL_stdingv) = 0;
	SvREFCNT(PL_stdingv) = 2;
	GvREFCNT(PL_stdingv) += 1;
	gv_list[5] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD | SVf_UTF8, SVt_PV);
	SvFLAGS(gv_list[5]) = 0x8009;
	GvFLAGS(gv_list[5]) = 0x2; 
	GvLINE(gv_list[5]) = 0;
	SvREFCNT(gv_list[5]) = 23;
	GvREFCNT(gv_list[5]) += 1;
	hek2 = share_hek("hello_world.pl", 14, 0);
	GvFILE_HEK(gv_list[5]) = hek2;
	IoIFP((IO*)&sv_list[7]) = IoOFP((IO*)&sv_list[7]) = PerlIO_stdout();
	GvIOp(gv_list[5]) = (IO*)&sv_list[7];
	
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x12; 
	GvLINE(PL_defgv) = 142;
	SvREFCNT(PL_defgv) = 510;
	GvREFCNT(PL_defgv) += 1;
	gv_list[7] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[7]) = 2;
	gv_list[8] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[8]) = 2;
	gv_list[9] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[9]) = 2;
	/* done extras */
	/* no %SIG in BEGIN block */
	/* honor -w */
	PL_dowarn = ( 0 ) ? G_WARN_ON : G_WARN_OFF;
	/* END block */
	/* startpoints */
	PL_main_root = (OP*)&listop_list[0];
	PL_main_start = &op_list[0];
	PL_initav = (AV*)Nullsv;
	PL_endav = (AV*)Nullsv;
	/* curpad names */
	sv_list[9].sv_u.svu_pv = savepvn("$a", 2);
	sv_list[10].sv_u.svu_pv = savepvn("$b", 2);
	sv_list[11].sv_u.svu_pv = savepvn("$c", 2);
	{ /* Slow array init mode. */
		SV **svp;
		AV *av = (AV*)&sv_list[8];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(4 * sizeof(SV*));
	#else
		svp = (SV**)malloc(4 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&PL_sv_undef;
		for (gcount=9; gcount<12; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	/* curpad syms */
	{
		SV **svp;
		AV *av = (AV*)&sv_list[12];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(8 * sizeof(SV*));
	#else
		svp = (SV**)malloc(8 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		for (gcount=13; gcount<20; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[20]) = a;
		HvRITER_set(&sv_list[20], -1);
	}
	HvTOTALKEYS((HV*)&sv_list[20]) = 0;

	/* @INC */
	sv_list[22].sv_u.svu_pv = savepvn("/usr/local/cpanel", 17);
	sv_list[23].sv_u.svu_pv = savepvn("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/cpanel_lib/i386-linux-64int", 73);
	sv_list[24].sv_u.svu_pv = savepvn("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/cpanel_lib", 56);
	sv_list[25].sv_u.svu_pv = savepvn("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/5.20.2/i386-linux-64int", 69);
	sv_list[26].sv_u.svu_pv = savepvn("/usr/local/cpanel/3rdparty/perl/520/lib/perl5/5.20.2", 52);
	sv_list[27].sv_u.svu_pv = savepvn("/opt/cpanel/perl5/520/site_lib/i386-linux-64int", 47);
	sv_list[28].sv_u.svu_pv = savepvn("/opt/cpanel/perl5/520/site_lib", 30);
	sv_list[29].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[21];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(8 * sizeof(SV*));
	#else
		svp = (SV**)malloc(8 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=22; gcount<30; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvHV(PL_incgv) = (HV*)&sv_list[20];
	GvAV(PL_incgv) = (AV*)&sv_list[21];
	PL_curpad = AvARRAY((AV*)&sv_list[12]);
	PL_comppad = (AV*)&sv_list[12];
	PL_stack_sp = PL_stack_base;
	PadlistARRAY(CvPADLIST(PL_main_cv))[0] = PL_comppad_name = (PAD*)SvREFCNT_inc((AV*)&sv_list[8]); /* namepad */
	PadnamelistMAXNAMED(PL_comppad_name) = AvFILL((AV*)&sv_list[8]);
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)SvREFCNT_inc((AV*)&sv_list[12]); /* curpad */
	return 0;
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
/* deferred init of XS/Dyna loaded modules */
static int perl_init2_aaaa(pTHX)
{
	return 0;
}
static int perl_init2(pTHX)
{
	perl_init2_aaaa(aTHX);
	return 0;
}

HEK *
my_share_hek( pTHX_ const char *str, I32 len, register U32 hash ) {
    if (!hash) {
      PERL_HASH(hash, str, abs(len));
    }
    return Perl_share_hek(aTHX_ str, len, hash);
}


#ifndef SvDESTROYABLE
#define SvDESTROYABLE(sv) 1
#endif
/* 5.8 */
#ifndef CvISXSUB
#define CvISXSUB(sv) CvXSUB(sv)
#endif
#ifndef SvRV_set
#define SvRV_set(a,b) SvRV(a) = (b)
#endif
/* 5.6 */
#ifndef PERL_EXIT_DESTRUCT_END
#define PERL_EXIT_DESTRUCT_END 2
#endif

static void
my_curse( pTHX_ SV* const sv ) {
    dSP;
    dVAR;
    HV* stash;

#if PERL_VERSION > 7
    assert(SvOBJECT(sv));
    do {
        stash = SvSTASH(sv);
        assert(SvTYPE(stash) == SVt_PVHV);
	if (HvNAME(stash)) {
	    CV* destructor = NULL;
	    if (!SvOBJECT(stash)) destructor = (CV *)SvSTASH(stash);
	    if (!destructor
#if (PERL_VERSION > 18) || (PERL_VERSION == 18 && PERL_SUBVERSION > 1)
                || HvMROMETA(stash)->destroy_gen != PL_sub_generation
#endif
	    ) {
		GV * const gv = gv_fetchmeth_autoload(stash, "DESTROY", 7, 0);
		if (gv) destructor = GvCV(gv);
		if (!SvOBJECT(stash))
		{
		    SvSTASH(stash) =
			destructor ? (HV *)destructor : ((HV *)0)+1;
#if (PERL_VERSION > 18) || (PERL_VERSION == 18 && PERL_SUBVERSION > 1)
		    HvAUX(stash)->xhv_mro_meta->destroy_gen = PL_sub_generation;
#endif
		}
	    }
	    assert(!destructor || destructor == ((CV *)0)+1
		   || SvTYPE(destructor) == SVt_PVCV);
	    if (destructor && destructor != ((CV *)0)+1
		/* A constant subroutine can have no side effects, so
		   don't bother calling it.  */
		&& !CvCONST(destructor)
		/* Don't bother calling an empty destructor or one that
		   returns immediately. */
		&& (CvISXSUB(destructor)
		|| (CvSTART(destructor)
		    && (CvSTART(destructor)->op_next->op_type != OP_LEAVESUB)
		    && (CvSTART(destructor)->op_next->op_type != OP_PUSHMARK
			|| CvSTART(destructor)->op_next->op_next->op_type != OP_RETURN
		       )
		   ))
	       )
	    {
		SV* const tmpref = newRV(sv);
		DEBUG_D(PerlIO_printf(Perl_debug_log, "Calling %s::DESTROY\n", HvNAME(stash)));
		SvREADONLY_on(tmpref); /* DESTROY() could be naughty */
		ENTER;
		PUSHSTACKi(PERLSI_DESTROY);
		EXTEND(SP, 2);
		PUSHMARK(SP);
		PUSHs(tmpref);
		PUTBACK;
		call_sv((SV*)destructor, G_DISCARD|G_EVAL|G_KEEPERR|G_VOID);
		POPSTACK;
		SPAGAIN;
		LEAVE;
		if(SvREFCNT(tmpref) < 2) {
		    /* tmpref is not kept alive! */
		    SvREFCNT(sv)--;
		    SvRV_set(tmpref, NULL);
		    SvROK_off(tmpref);
		}
		SvREFCNT_dec(tmpref);
	    }
	}
    } while (SvOBJECT(sv) && SvSTASH(sv) != stash);

    if (SvOBJECT(sv)) {
	/* Curse before freeing the stash, as freeing the stash could cause
	   a recursive call into S_curse. */
	SvOBJECT_off(sv);	/* Curse the object. */
	SvSTASH_set(sv,0);	/* SvREFCNT_dec may try to read this */
    }
#endif
}

int fast_perl_destruct( PerlInterpreter *my_perl ) {
    dVAR;
    VOL signed char destruct_level;  /* see possible values in intrpvar.h */
    HV *hv;
#ifdef DEBUG_LEAKING_SCALARS_FORK_DUMP
    pid_t child;
#endif

#ifndef MULTIPLICITY
#   ifndef PERL_UNUSED_ARG
#     define PERL_UNUSED_ARG(x) ((void)x)
#   endif
    PERL_UNUSED_ARG(my_perl);
#endif

    assert(PL_scopestack_ix == 1);

    /* wait for all pseudo-forked children to finish */
    PERL_WAIT_FOR_CHILDREN;

    destruct_level = PL_perl_destruct_level;
#ifdef DEBUGGING
    {
	const char * const s = PerlEnv_getenv("PERL_DESTRUCT_LEVEL");
	if (s) {
            const int i = atoi(s);
#ifdef DEBUGGING
	    if (destruct_level < i) destruct_level = i;
#endif
#ifdef PERL_TRACK_MEMPOOL
            /* RT #114496, for perl_free */
            PL_perl_destruct_level = i;
#endif
	}
    }
#endif

    if (PL_exit_flags & PERL_EXIT_DESTRUCT_END) {
        dJMPENV;
        int x = 0;

        JMPENV_PUSH(x);
        if (PL_endav && !PL_minus_c) {
#if PERL_VERSION > 13
	    PL_phase = PERL_PHASE_END;
#endif
            call_list(PL_scopestack_ix, PL_endav);
        }
        JMPENV_POP;
    }
    LEAVE;
    FREETMPS;
    assert(PL_scopestack_ix == 0);

    /* Need to flush since END blocks can produce output */
    my_fflush_all();

    PL_main_start = NULL;
    PL_main_cv = NULL;
    PL_curcop = &PL_compiling;
#if PERL_VERSION >= 13
    PL_phase = PERL_PHASE_DESTRUCT;
#endif

#if PERL_VERSION > 7
    if (PL_threadhook(aTHX)) {
        /* Threads hook has vetoed further cleanup */
#if (PERL_VERSION > 8) || ((PERL_VERSION == 8) && (PERL_SUBVERSION > 8))
	PL_veto_cleanup = TRUE;
        return STATUS_EXIT;
#else
        return STATUS_NATIVE_EXPORT;
#endif
    }
    PerlIO_destruct(aTHX);

    /* B::C -O3 specific: first curse (i.e. call DESTROY) all our static SVs */
    if (PL_sv_objcount) {
        int i = 1;
        DEBUG_D(PerlIO_printf(Perl_debug_log, "\nCursing named global static sv_arena:\n"));
        PL_in_clean_all = 1;
        for (; i < SvREFCNT(&sv_list[0]); i++) {
            SV *sv = &sv_list[i];
            if (SvREFCNT(sv)) {
#if PERL_VERSION > 11
                if (SvTYPE(sv) == SVt_IV && SvROK(sv))
#else
                if (SvTYPE(sv) == SVt_RV)
#endif
                    sv = SvRV(sv);
                if (sv && SvOBJECT(sv) && SvTYPE(sv) >= SVt_PVMG && SvSTASH(sv)
                    && SvTYPE(sv) != SVt_PVCV && SvTYPE(sv) != SVt_PVIO
                    && PL_defstash /* Still have a symbol table? */
                    && SvDESTROYABLE(sv))
                {
	            SvREFCNT(sv) = 0;
                    my_curse(aTHX_ sv);
                }
            }
        }
    }
    if (DEBUG_D_TEST) {
        SV* sva;
        PerlIO_printf(Perl_debug_log, "\n");
        for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
            PerlIO_printf(Perl_debug_log, "sv_arena: 0x%p - 0x%p (%u)\n",
              sva, sva+SvREFCNT(sva), SvREFCNT(sva));
        }
    }
#endif

    if (PL_sv_objcount) {
	PL_in_clean_all = 1;
	sv_clean_objs(); /* and now curse the rest */
	PL_sv_objcount = 0;
    }
    PL_warnhook = NULL;
    PL_diehook = NULL;
    /* call exit list functions */
    while (PL_exitlistlen-- > 0)
	PL_exitlist[PL_exitlistlen].fn(aTHX_ PL_exitlist[PL_exitlistlen].ptr);
    PL_exitlist = NULL;

#if defined(PERLIO_LAYERS)
    PerlIO_cleanup(aTHX);
#endif
    return 0;
}

/* yanked from perl.c */
static void
xs_init(pTHX)
{
	char *file = __FILE__;
	dTARG; dSP;

#ifdef USE_DYNAMIC_LOADING
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
#endif
/* XS bootstrapping code*/
	SAVETMPS;
	targ=sv_newmortal();
#ifdef USE_DYNAMIC_LOADING
	PUSHMARK(sp);
	XPUSHp("DynaLoader", 10);
	PUTBACK;
	boot_DynaLoader(aTHX_ NULL);
	SPAGAIN;
#endif
	FREETMPS;
/* end XS bootstrapping code */
}

static void
dl_init(pTHX)
{
	char *file = __FILE__;
}

/* if USE_IMPLICIT_SYS, we need a 'real' exit */
#if defined(exit)
#undef exit
#endif

int
main(int argc, char **argv, char **env)
{
    int exitstatus;
    int i;
    char **fakeargv;
    int options_count;
    PerlInterpreter *my_perl;

    PERL_SYS_INIT3(&argc,&argv,&env);

#ifdef WIN32
#define PL_do_undump 0
#endif
    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct( my_perl );
	PL_perl_destruct_level = 0;
    }
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
#ifndef PERL_USE_SAFE_PUTENV
    PL_use_safe_putenv = 0;
#endif
#ifdef ALLOW_PERL_OPTIONS
#define EXTRA_OPTIONS 3
#else
#define EXTRA_OPTIONS 4
#endif /* ALLOW_PERL_OPTIONS */
    Newx(fakeargv, argc + EXTRA_OPTIONS + 1, char *);
    fakeargv[0] = argv[0];
    fakeargv[1] = "-e";
    fakeargv[2] = "";
    options_count = 3;
#ifndef ALLOW_PERL_OPTIONS
    fakeargv[options_count] = "--";
    ++options_count;
#endif /* ALLOW_PERL_OPTIONS */
    for (i = 1; i < argc; i++)
	fakeargv[i + options_count - 1] = argv[i];
    fakeargv[argc + options_count - 1] = 0;

    exitstatus = perl_parse(my_perl, xs_init, argc + options_count - 1,
			    fakeargv, env);
    if (exitstatus)
	exit( exitstatus );

    TAINT;
    sv_setpv_mg(get_sv("0", GV_ADD|GV_NOTQUAL), argv[0]);
    CopFILE_set(&PL_compiling, argv[0]);
    PL_hints = 256;
    sv_setpv_mg(get_sv("", GV_ADD|GV_NOTQUAL), "/usr/local/cpanel/3rdparty/perl/520/bin/perl"); /* $^X */
    TAINT_NOT;

    #if PERL_VERSION < 10 || ((PERL_VERSION == 10) && (PERL_SUBVERSION < 1))
      PL_compcv = 0;
    #else
    /* PL_compcv used during compilation. */
      PL_compcv = MUTABLE_CV(newSV_type(SVt_PVCV));
      CvUNIQUE_on(PL_compcv);
      CvPADLIST(PL_compcv) = pad_new(0);
    #endif

    /* our special compiled init */
    perl_init(aTHX);

    dl_init(aTHX);
    perl_init2(aTHX);
    exitstatus = perl_run( my_perl );
    fast_perl_destruct( my_perl );
    perl_free( my_perl );

    PERL_SYS_TERM();

    exit( exitstatus );
}
