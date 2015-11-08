/* created at Thu Oct 22 01:29:52 2015 with B::C 1.52_06 -2850-g341501a for /usr/local/bin/perl5.22.0-nt */
#define PERL_CORE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Workaround for mapstart: the only op which needs a different ppaddr */
#undef Perl_pp_mapstart
#define Perl_pp_mapstart Perl_pp_grepstart
#undef OP_MAPSTART
#define OP_MAPSTART OP_GREPSTART

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

#ifndef dVAR
# ifdef PERL_GLOBAL_STRUCT
#  define dVAR		pVAR    = (struct perl_vars*)PERL_GET_VARS()
# else
#  define dVAR		dNOOP
# endif
#endif

#define XPVCVIX0	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[102]}, {(OP*)&unop_list[378]}, 0, NULL, &padlist_list[0], (CV*)&PL_main_cv, 6859, 0x0, 0
#define CVIX287	(XPVCV*)&xpvcv_list[0], 1, 0xd, {0}
#define XPVCVIX1	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[119]}, {(OP*)&unop_list[436]}, 0, NULL, &padlist_list[1], (CV*)&PL_main_cv, 6801, 0x100, 0
#define CVIX350	(XPVCV*)&xpvcv_list[1], 1, 0x100000d, {0}

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
/* unfortunately we have to override this perl5.22 struct.
   The Padname string buffer in xpadn_str is pointed by xpadn_pv.
    */
#define _PADNAME_BASE \
    char *	xpadn_pv;		\
    HV *	xpadn_ourstash;		\
    union {				\
	HV *	xpadn_typestash;	\
	CV *	xpadn_protocv;		\
    } xpadn_type_u;			\
    U32		xpadn_low;		\
    U32		xpadn_high;		\
    U32		xpadn_refcnt;		\
    int		xpadn_gen;		\
    U8		xpadn_len;		\
    U8		xpadn_flags

struct my_padname_with_str {
#ifdef PERL_PADNAME_MINIMAL
    _PADNAME_BASE;
#else
    struct padname	xpadn_padname;
#endif
    char		xpadn_str[60]; /* longer lexical upval names are forbidden for now */
};
typedef struct my_padname_with_str MyPADNAME;
typedef struct p5rx RE;
Static IV PL_sv_objcount; /* deprecated with 5.21.1 but still needed and used */
Static GV *gv_list[24];
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );

Static COP cop_list[121];
Static OP op_list[268];
Static UNOP unop_list[439];
Static BINOP binop_list[101];
Static LOGOP logop_list[15];
Static LISTOP listop_list[49];
Static PMOP pmop_list[2];
Static SVOP svop_list[500];
Static LOOP loop_list[8];
Static UNOP_AUX unopaux_list[2];
Static XPV xpv_list[273];
Static XPVAV xpvav_list[18];
Static XPVHV xpvhv_list[3];
Static XPVCV_or_similar xpvcv_list[2];
Static PADLIST padlist_list[2];
Static MyPADNAME padname_list[18];
Static PADNAMELIST padnamelist_list[3];
Static XPVIV xpviv_list[111];
Static XPVNV xpvnv_list[2];
Static XPVMG xpvmg_list[2];
Static XPVIO xpvio_list[1];
Static SV sv_list[588];
Static const char emptystring[] = "\0";
Static const char xsfile[] = "universal.c";
#define ptr_undef NULL
#undef CopFILE_set
#define CopFILE_set(c,pv)  CopFILEGV_set((c), gv_fetchfile(pv))
/* PadlistNAMES broken as lvalue with v5.21.6-197-g0f94cb1,
   fixed with 5.22.1 and 5.23.0 */
#if (PERL_VERSION == 22) || ( PERL_VERSION == 21 && PERL_SUBVERSION > 5)
# undef PadlistNAMES
# define PadlistNAMES(pl)       *((PADNAMELIST **)PadlistARRAY(pl))
#endif
Static const char pv0[] = "main";
Static HV *hv0;
Static const char pv1[] = "t/CORE/op/list.t";
Static HEK *hek0;
Static HEK *hek1;
Static UNOP_AUX_item unopaux_item0[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* gv_list[6] */
	,{.sv=&sv_list[61]}
};
Static UNOP_AUX_item unopaux_item1[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* gv_list[6] */
	,{.sv=&sv_list[69]}
};
Static HEK *hek2;
Static HV *hv1;
Static char pv2[] = "t/CORE/op/list.c";
Static HV *hv2;
Static HEK *hek3;
Static const char pv3[] = "291";
Static HEK *hek4;
Static HEK *hek5;

Static COP cop_list[121] = {
	{ &op_list[252], (OP*)&unop_list[422], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 171, Nullhv, Nullgv, 0, 6871, pWARN_STD, NULL }, /* cop_list[0]  */
	{ &op_list[2], (OP*)&unop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 8, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[1]  */
	{ &op_list[3], (OP*)&binop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 10, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[2]  */
	{ &op_list[5], (OP*)&unop_list[8], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 11, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[3]  */
	{ &op_list[6], (OP*)&unop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 12, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[4]  */
	{ &op_list[7], (OP*)&binop_list[4], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 14, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[5]  */
	{ &op_list[8], (OP*)&unop_list[18], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 15, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[6]  */
	{ &op_list[9], (OP*)&binop_list[5], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 17, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[7]  */
	{ &op_list[11], (OP*)&unop_list[28], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 18, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[8]  */
	{ &op_list[13], (OP*)&binop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 20, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[9]  */
	{ &op_list[15], (OP*)&unop_list[41], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 21, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[10]  */
	{ &op_list[17], (OP*)&binop_list[17], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 23, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[11]  */
	{ &op_list[19], (OP*)&unop_list[56], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 24, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[12]  */
	{ &op_list[21], (OP*)&binop_list[22], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 26, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[13]  */
	{ &op_list[23], (OP*)&unop_list[69], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 27, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[14]  */
	{ &op_list[25], (OP*)&binop_list[25], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 29, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[15]  */
	{ &op_list[29], (OP*)&unop_list[85], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 30, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[16]  */
	{ &op_list[31], (OP*)&binop_list[29], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 32, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[17]  */
	{ &op_list[35], (OP*)&unop_list[98], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 33, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[18]  */
	{ &op_list[36], (OP*)&unop_list[102], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 34, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[19]  */
	{ &op_list[37], (OP*)&unop_list[106], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 35, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[20]  */
	{ &op_list[39], (OP*)&unop_list[110], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 36, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[21]  */
	{ &op_list[40], (OP*)&binop_list[31], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 38, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[22]  */
	{ &op_list[42], (OP*)&binop_list[32], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 39, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[23]  */
	{ &op_list[44], (OP*)&unop_list[124], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 40, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[24]  */
	{ &op_list[46], (OP*)&binop_list[39], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 42, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[25]  */
	{ &op_list[48], (OP*)&binop_list[40], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 43, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[26]  */
	{ &op_list[50], (OP*)&unop_list[142], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 44, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[27]  */
	{ &op_list[51], (OP*)&unop_list[146], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 45, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[28]  */
	{ &op_list[52], (OP*)&unop_list[150], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 46, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[29]  */
	{ &op_list[53], (OP*)&unop_list[156], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 47, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[30]  */
	{ &op_list[54], (OP*)&binop_list[41], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 49, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[31]  */
	{ &op_list[58], (OP*)&unop_list[168], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 50, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[32]  */
	{ &op_list[60], (OP*)&binop_list[43], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 52, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[33]  */
	{ &op_list[64], (OP*)&unop_list[179], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 53, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[34]  */
	{ &op_list[68], (OP*)&binop_list[45], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 55, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[35]  */
	{ &op_list[71], (OP*)&binop_list[46], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 56, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[36]  */
	{ &op_list[73], (OP*)&unop_list[190], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 57, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[37]  */
	{ (OP*)&loop_list[1], (OP*)&binop_list[47], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 86, Nullhv, Nullgv, 256, 6803, pWARN_STD, NULL }, /* cop_list[38]  */
	{ &op_list[76], (OP*)&listop_list[10], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 60, Nullhv, Nullgv, 0, 6804, pWARN_STD, NULL }, /* cop_list[39]  */
	{ (OP*)&svop_list[211], (OP*)&binop_list[50], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 61, Nullhv, Nullgv, 256, 6805, pWARN_STD, NULL }, /* cop_list[40]  */
	{ &op_list[83], (OP*)&binop_list[52], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 62, Nullhv, Nullgv, 0, 6807, pWARN_STD, NULL }, /* cop_list[41]  */
	{ (OP*)&svop_list[228], (OP*)&unop_list[208], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 67, Nullhv, Nullgv, 256, 6807, pWARN_STD, NULL }, /* cop_list[42]  */
	{ &op_list[93], (OP*)&unop_list[212], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 68, Nullhv, Nullgv, 0, 6809, pWARN_STD, NULL }, /* cop_list[43]  */
	{ &op_list[95], (OP*)&unop_list[215], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 69, Nullhv, Nullgv, 0, 6809, pWARN_STD, NULL }, /* cop_list[44]  */
	{ &op_list[92], (OP*)&unop_list[210], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 70, Nullhv, Nullgv, 256, 6809, pWARN_STD, NULL }, /* cop_list[45]  */
	{ (OP*)&svop_list[242], (OP*)&unop_list[219], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 72, Nullhv, Nullgv, 256, 6811, pWARN_STD, NULL }, /* cop_list[46]  */
	{ &op_list[100], (OP*)&unop_list[223], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 73, Nullhv, Nullgv, 0, 6813, pWARN_STD, NULL }, /* cop_list[47]  */
	{ &op_list[102], (OP*)&unop_list[226], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 74, Nullhv, Nullgv, 0, 6813, pWARN_STD, NULL }, /* cop_list[48]  */
	{ &op_list[99], (OP*)&unop_list[221], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 75, Nullhv, Nullgv, 256, 6813, pWARN_STD, NULL }, /* cop_list[49]  */
	{ (OP*)&svop_list[213], (OP*)&unop_list[197], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 77, Nullhv, Nullgv, 256, 6815, pWARN_STD, NULL }, /* cop_list[50]  */
	{ &op_list[106], (OP*)&unop_list[232], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 78, Nullhv, Nullgv, 0, 6817, pWARN_STD, NULL }, /* cop_list[51]  */
	{ &op_list[108], (OP*)&unop_list[235], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 79, Nullhv, Nullgv, 0, 6817, pWARN_STD, NULL }, /* cop_list[52]  */
	{ &op_list[105], (OP*)&unop_list[230], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 80, Nullhv, Nullgv, 256, 6817, pWARN_STD, NULL }, /* cop_list[53]  */
	{ (OP*)&loop_list[3], (OP*)&binop_list[59], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 86, Nullhv, Nullgv, 256, 6822, pWARN_STD, NULL }, /* cop_list[54]  */
	{ &op_list[112], (OP*)&listop_list[17], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 86, Nullhv, Nullgv, 0, 6823, pWARN_STD, NULL }, /* cop_list[55]  */
	{ (OP*)&svop_list[273], (OP*)&binop_list[62], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 87, Nullhv, Nullgv, 256, 6824, pWARN_STD, NULL }, /* cop_list[56]  */
	{ &op_list[119], (OP*)&binop_list[64], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 88, Nullhv, Nullgv, 256, 6826, pWARN_STD, NULL }, /* cop_list[57]  */
	{ (OP*)&svop_list[277], (OP*)&unop_list[249], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 89, Nullhv, Nullgv, 256, 6827, pWARN_STD, NULL }, /* cop_list[58]  */
	{ &op_list[122], (OP*)&unop_list[251], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 90, Nullhv, Nullgv, 0, 6829, pWARN_STD, NULL }, /* cop_list[59]  */
	{ (OP*)&svop_list[282], (OP*)&binop_list[66], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x81, 0x0, 92, Nullhv, Nullgv, 0, 6832, pWARN_STD, NULL }, /* cop_list[60]  */
	{ &op_list[123], (OP*)&unop_list[254], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 93, Nullhv, Nullgv, 0, 6831, pWARN_STD, NULL }, /* cop_list[61]  */
	{ (OP*)&svop_list[287], (OP*)&unop_list[255], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 96, Nullhv, Nullgv, 0, 6833, pWARN_STD, NULL }, /* cop_list[62]  */
	{ (OP*)&svop_list[290], (OP*)&unop_list[256], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 99, Nullhv, Nullgv, 256, 6836, pWARN_STD, NULL }, /* cop_list[63]  */
	{ &op_list[131], (OP*)&unop_list[260], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 100, Nullhv, Nullgv, 0, 6838, pWARN_STD, NULL }, /* cop_list[64]  */
	{ &op_list[133], (OP*)&unop_list[263], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 101, Nullhv, Nullgv, 0, 6838, pWARN_STD, NULL }, /* cop_list[65]  */
	{ &op_list[130], (OP*)&unop_list[258], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 102, Nullhv, Nullgv, 256, 6838, pWARN_STD, NULL }, /* cop_list[66]  */
	{ (OP*)&svop_list[304], (OP*)&unop_list[267], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 104, Nullhv, Nullgv, 256, 6840, pWARN_STD, NULL }, /* cop_list[67]  */
	{ &op_list[138], (OP*)&unop_list[271], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 105, Nullhv, Nullgv, 0, 6842, pWARN_STD, NULL }, /* cop_list[68]  */
	{ &op_list[140], (OP*)&unop_list[274], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 106, Nullhv, Nullgv, 0, 6842, pWARN_STD, NULL }, /* cop_list[69]  */
	{ &op_list[137], (OP*)&unop_list[269], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 107, Nullhv, Nullgv, 256, 6842, pWARN_STD, NULL }, /* cop_list[70]  */
	{ (OP*)&svop_list[275], (OP*)&unop_list[244], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 109, Nullhv, Nullgv, 256, 6844, pWARN_STD, NULL }, /* cop_list[71]  */
	{ &op_list[144], (OP*)&unop_list[280], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 110, Nullhv, Nullgv, 0, 6846, pWARN_STD, NULL }, /* cop_list[72]  */
	{ &op_list[146], (OP*)&unop_list[283], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 111, Nullhv, Nullgv, 0, 6846, pWARN_STD, NULL }, /* cop_list[73]  */
	{ &op_list[143], (OP*)&unop_list[278], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 112, Nullhv, Nullgv, 256, 6846, pWARN_STD, NULL }, /* cop_list[74]  */
	{ (OP*)&svop_list[332], (OP*)&binop_list[71], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 117, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[75]  */
	{ &op_list[149], (OP*)&binop_list[72], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 118, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[76]  */
	{ &op_list[152], (OP*)&unop_list[296], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 119, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[77]  */
	{ &op_list[154], (OP*)&binop_list[74], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 121, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[78]  */
	{ &op_list[157], (OP*)&unop_list[307], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 122, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[79]  */
	{ &op_list[159], (OP*)&unop_list[311], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 124, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[80]  */
	{ &op_list[160], (OP*)&unop_list[314], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 125, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[81]  */
	{ &op_list[161], (OP*)&unop_list[317], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 126, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[82]  */
	{ &op_list[162], (OP*)&unop_list[320], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 127, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[83]  */
	{ &op_list[163], (OP*)&unop_list[323], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 128, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[84]  */
	{ &op_list[164], (OP*)&unop_list[326], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 129, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[85]  */
	{ &op_list[165], (OP*)&unop_list[329], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 130, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[86]  */
	{ (OP*)&loop_list[5], (OP*)&binop_list[76], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 152, Nullhv, Nullgv, 256, 6851, pWARN_STD, NULL }, /* cop_list[87]  */
	{ &op_list[167], (OP*)&binop_list[77], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 133, Nullhv, Nullgv, 0, 6852, pWARN_STD, NULL }, /* cop_list[88]  */
	{ &op_list[172], (OP*)&binop_list[78], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 134, Nullhv, Nullgv, 0, 6853, pWARN_STD, NULL }, /* cop_list[89]  */
	{ &op_list[178], (OP*)&binop_list[79], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 135, Nullhv, Nullgv, 256, 6854, pWARN_STD, NULL }, /* cop_list[90]  */
	{ &op_list[185], (OP*)&unop_list[343], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 136, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[91]  */
	{ &op_list[188], (OP*)&unop_list[348], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 137, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[92]  */
	{ &op_list[190], (OP*)&binop_list[81], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 139, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[93]  */
	{ &op_list[196], (OP*)&unop_list[355], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 140, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[94]  */
	{ &op_list[199], (OP*)&binop_list[82], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 142, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[95]  */
	{ &op_list[202], (OP*)&binop_list[83], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 143, Nullhv, Nullgv, 256, 6856, pWARN_STD, NULL }, /* cop_list[96]  */
	{ &op_list[208], (OP*)&unop_list[363], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 144, Nullhv, Nullgv, 256, 6856, pWARN_STD, NULL }, /* cop_list[97]  */
	{ &op_list[211], (OP*)&binop_list[84], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 146, Nullhv, Nullgv, 256, 6856, pWARN_STD, NULL }, /* cop_list[98]  */
	{ &op_list[166], (OP*)&unop_list[332], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 147, Nullhv, Nullgv, 256, 6857, pWARN_STD, NULL }, /* cop_list[99]  */
	{ (OP*)&loop_list[6], (OP*)&binop_list[86], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 167, Nullhv, Nullgv, 256, 6858, pWARN_STD, NULL }, /* cop_list[100]  */
	{ &op_list[216], (OP*)&unop_list[373], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 156, Nullhv, Nullgv, 256, 6862, pWARN_STD, NULL }, /* cop_list[101]  */
	{ &op_list[220], (OP*)&binop_list[88], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 153, Nullhv, Nullgv, 0, 6860, pWARN_STD, NULL }, /* cop_list[102]  */
	{ &op_list[219], (OP*)&unop_list[379], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 154, Nullhv, Nullgv, 0, 6861, pWARN_STD, NULL }, /* cop_list[103]  */
	{ &op_list[223], (OP*)&unop_list[384], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 157, Nullhv, Nullgv, 256, 6862, pWARN_STD, NULL }, /* cop_list[104]  */
	{ &op_list[227], (OP*)&unop_list[390], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 158, Nullhv, Nullgv, 256, 6862, pWARN_STD, NULL }, /* cop_list[105]  */
	{ &op_list[231], (OP*)&unop_list[395], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 159, Nullhv, Nullgv, 256, 6862, pWARN_STD, NULL }, /* cop_list[106]  */
	{ &op_list[237], (OP*)&unop_list[402], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 160, Nullhv, Nullgv, 256, 6863, pWARN_STD, NULL }, /* cop_list[107]  */
	{ &op_list[238], (OP*)&binop_list[93], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 160, Nullhv, Nullgv, 0, 6864, pWARN_STD, NULL }, /* cop_list[108]  */
	{ &op_list[240], (OP*)&unop_list[408], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 161, Nullhv, Nullgv, 256, 6865, pWARN_STD, NULL }, /* cop_list[109]  */
	{ &op_list[215], (OP*)&unop_list[371], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 162, Nullhv, Nullgv, 256, 6865, pWARN_STD, NULL }, /* cop_list[110]  */
	{ (OP*)&loop_list[7], (OP*)&binop_list[96], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 171, Nullhv, Nullgv, 256, 6866, pWARN_STD, NULL }, /* cop_list[111]  */
	{ &op_list[246], (OP*)&unop_list[416], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 167, Nullhv, Nullgv, 256, 6867, pWARN_STD, NULL }, /* cop_list[112]  */
	{ &op_list[249], (OP*)&listop_list[44], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 167, Nullhv, Nullgv, 256, 6868, pWARN_STD, NULL }, /* cop_list[113]  */
	{ (OP*)&loop_list[0], (OP*)&binop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 171, Nullhv, Nullgv, 256, 6870, pWARN_STD, NULL }, /* cop_list[114]  */
	{ &op_list[256], (OP*)&binop_list[99], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 172, Nullhv, Nullgv, 0, 6871, pWARN_STD, NULL }, /* cop_list[115]  */
	{ &op_list[259], (OP*)&unop_list[429], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 173, Nullhv, Nullgv, 256, 6872, pWARN_STD, NULL }, /* cop_list[116]  */
	{ &op_list[262], (OP*)&binop_list[100], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 174, Nullhv, Nullgv, 256, 6872, pWARN_STD, NULL }, /* cop_list[117]  */
	{ &op_list[1], (OP*)&unop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 175, Nullhv, Nullgv, 256, 6873, pWARN_STD, NULL }, /* cop_list[118]  */
	{ &op_list[267], (OP*)&listop_list[48], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 4, Nullhv, Nullgv, 0, 6802, pWARN_STD, NULL }, /* cop_list[119]  */
	{ (OP*)&svop_list[497], (OP*)&unop_list[437], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 5, Nullhv, Nullgv, 0, 6802, pWARN_STD, NULL }, /* cop_list[120]  */
};

Static OP op_list[268] = {
	{ (OP*)&cop_list[1], (OP*)&cop_list[1], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0 }, /* op_list[0]  */
	{ &op_list[266], (OP*)&unop_list[434], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[1]  */
	{ (OP*)&svop_list[0], (OP*)&svop_list[0], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[2]  */
	{ (OP*)&svop_list[3], (OP*)&svop_list[3], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[3]  */
	{ (OP*)&svop_list[7], (OP*)&unop_list[7], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[4]  */
	{ (OP*)&svop_list[8], (OP*)&binop_list[2], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[5]  */
	{ (OP*)&svop_list[14], (OP*)&binop_list[3], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[6]  */
	{ (OP*)&svop_list[22], (OP*)&svop_list[22], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[7]  */
	{ (OP*)&svop_list[23], (OP*)&unop_list[20], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[8]  */
	{ (OP*)&svop_list[28], (OP*)&svop_list[28], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[9]  */
	{ (OP*)&svop_list[32], (OP*)&unop_list[24], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[10]  */
	{ (OP*)&svop_list[36], (OP*)&unop_list[30], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[11]  */
	{ (OP*)&svop_list[36], (OP*)&binop_list[6], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[12]  */
	{ (OP*)&pmop_list[0], (OP*)&listop_list[3], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[13]  */
	{ (OP*)&svop_list[49], (OP*)&unop_list[38], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[14]  */
	{ (OP*)&svop_list[52], (OP*)&unop_list[43], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[15]  */
	{ (OP*)&svop_list[52], (OP*)&binop_list[13], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[16]  */
	{ (OP*)&svop_list[61], (OP*)&unop_list[50], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[17]  */
	{ (OP*)&svop_list[64], (OP*)&unop_list[53], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[18]  */
	{ (OP*)&svop_list[67], (OP*)&unop_list[58], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[19]  */
	{ (OP*)&svop_list[67], (OP*)&binop_list[18], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[20]  */
	{ (OP*)&svop_list[76], (OP*)&unop_list[65], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[21]  */
	{ (OP*)&svop_list[78], (OP*)&unop_list[67], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[22]  */
	{ (OP*)&svop_list[80], (OP*)&unop_list[71], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[23]  */
	{ (OP*)&svop_list[80], (OP*)&binop_list[23], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[24]  */
	{ &op_list[27], (OP*)&binop_list[26], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[25]  */
	{ (OP*)&svop_list[91], (OP*)&unop_list[83], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[26]  */
	{ (OP*)&svop_list[87], (OP*)&unop_list[79], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[27]  */
	{ (OP*)&svop_list[89], (OP*)&unop_list[81], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[28]  */
	{ (OP*)&svop_list[93], (OP*)&unop_list[87], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[29]  */
	{ (OP*)&svop_list[93], (OP*)&binop_list[27], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[30]  */
	{ (OP*)&svop_list[100], (OP*)&svop_list[100], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[31]  */
	{ (OP*)&svop_list[104], (OP*)&unop_list[93], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[32]  */
	{ (OP*)&unop_list[94], 0, INT2PTR(void*,OP_NULL), 5, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[33]  */
	{ (OP*)&unopaux_list[0], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[34]  */
	{ (OP*)&svop_list[107], (OP*)&unop_list[100], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[35]  */
	{ (OP*)&svop_list[112], (OP*)&binop_list[30], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[36]  */
	{ (OP*)&unopaux_list[1], (OP*)&unop_list[108], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[37]  */
	{ (OP*)&unopaux_list[1], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[38]  */
	{ (OP*)&svop_list[122], (OP*)&unop_list[112], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[39]  */
	{ (OP*)&svop_list[127], (OP*)&svop_list[127], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[40]  */
	{ (OP*)&svop_list[135], (OP*)&unop_list[116], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[41]  */
	{ (OP*)&svop_list[136], (OP*)&unop_list[119], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[42]  */
	{ (OP*)&svop_list[137], (OP*)&unop_list[120], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[43]  */
	{ (OP*)&svop_list[141], (OP*)&unop_list[126], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[44]  */
	{ (OP*)&svop_list[141], (OP*)&binop_list[33], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[45]  */
	{ (OP*)&svop_list[152], (OP*)&svop_list[152], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[46]  */
	{ (OP*)&svop_list[154], (OP*)&unop_list[134], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[47]  */
	{ (OP*)&svop_list[155], (OP*)&unop_list[137], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[48]  */
	{ (OP*)&svop_list[156], (OP*)&unop_list[138], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[49]  */
	{ (OP*)&svop_list[160], (OP*)&unop_list[144], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[50]  */
	{ (OP*)&svop_list[165], (OP*)&unop_list[148], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[51]  */
	{ (OP*)&svop_list[170], (OP*)&unop_list[152], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[52]  */
	{ (OP*)&svop_list[173], (OP*)&unop_list[158], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[53]  */
	{ &op_list[56], (OP*)&binop_list[42], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[54]  */
	{ (OP*)&svop_list[178], (OP*)&unop_list[167], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[55]  */
	{ (OP*)&svop_list[176], (OP*)&svop_list[176], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[56]  */
	{ (OP*)&svop_list[177], (OP*)&unop_list[166], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[57]  */
	{ &op_list[59], (OP*)&listop_list[4], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[58]  */
	{ (OP*)&svop_list[180], (OP*)&svop_list[180], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[59]  */
	{ &op_list[62], (OP*)&binop_list[44], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[60]  */
	{ (OP*)&svop_list[189], (OP*)&unop_list[178], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[61]  */
	{ (OP*)&svop_list[186], (OP*)&svop_list[186], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[62]  */
	{ (OP*)&svop_list[188], (OP*)&unop_list[177], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[63]  */
	{ &op_list[65], (OP*)&listop_list[5], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[64]  */
	{ (OP*)&svop_list[191], (OP*)&svop_list[191], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[65]  */
	{ (OP*)&svop_list[194], (OP*)&svop_list[194], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[66]  */
	{ (OP*)&svop_list[193], (OP*)&svop_list[193], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[67]  */
	{ &op_list[69], &op_list[70], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[68]  */
	{ (OP*)&svop_list[199], (OP*)&unop_list[186], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[69]  */
	{ (OP*)&unop_list[184], 0, INT2PTR(void*,OP_STUB), 0, 1, 0, 0, 0, 1, 0, 0, 0, 0xb, 0x0 }, /* op_list[70]  */
	{ (OP*)&svop_list[200], (OP*)&svop_list[200], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[71]  */
	{ (OP*)&svop_list[201], (OP*)&unop_list[189], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[72]  */
	{ &op_list[74], (OP*)&listop_list[8], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[73]  */
	{ (OP*)&svop_list[203], (OP*)&svop_list[203], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[74]  */
	{ (OP*)&cop_list[41], (OP*)&cop_list[41], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[75]  */
	{ (OP*)&cop_list[40], &op_list[78], INT2PTR(void*,OP_PADRANGE), 96, 390, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x83 }, /* op_list[76]  */
	{ (OP*)&listop_list[10], 0, INT2PTR(void*,OP_PADSV), 98, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[77]  */
	{ &op_list[79], &op_list[79], INT2PTR(void*,OP_PADSV), 96, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[78]  */
	{ &op_list[77], &op_list[77], INT2PTR(void*,OP_PADSV), 97, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[79]  */
	{ (OP*)&loop_list[2], (OP*)&binop_list[48], INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x81, 0x0 }, /* op_list[80]  */
	{ (OP*)&cop_list[51], (OP*)&cop_list[51], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[81]  */
	{ (OP*)&svop_list[209], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[82]  */
	{ (OP*)&svop_list[215], (OP*)&unop_list[201], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[83]  */
	{ (OP*)&binop_list[52], &op_list[88], INT2PTR(void*,OP_PADRANGE), 96, 390, 0, 0, 0, 1, 0, 0, 0, 0x30, 0x3 }, /* op_list[84]  */
	{ (OP*)&svop_list[217], (OP*)&svop_list[217], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[85]  */
	{ (OP*)&svop_list[222], (OP*)&svop_list[222], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[86]  */
	{ (OP*)&svop_list[225], (OP*)&svop_list[225], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[87]  */
	{ &op_list[89], &op_list[89], INT2PTR(void*,OP_PADSV), 96, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[88]  */
	{ &op_list[90], &op_list[90], INT2PTR(void*,OP_PADSV), 97, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[89]  */
	{ (OP*)&unop_list[200], 0, INT2PTR(void*,OP_PADSV), 98, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[90]  */
	{ (OP*)&cop_list[43], (OP*)&cop_list[43], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[91]  */
	{ &op_list[97], &op_list[97], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[92]  */
	{ &op_list[94], &op_list[94], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[93]  */
	{ (OP*)&svop_list[230], (OP*)&svop_list[230], INT2PTR(void*,OP_PADSV), 96, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[94]  */
	{ &op_list[96], &op_list[96], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[95]  */
	{ (OP*)&svop_list[234], (OP*)&svop_list[234], INT2PTR(void*,OP_PADSV), 97, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[96]  */
	{ (OP*)&svop_list[238], (OP*)&svop_list[238], INT2PTR(void*,OP_PADSV), 98, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[97]  */
	{ (OP*)&cop_list[47], (OP*)&cop_list[47], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[98]  */
	{ &op_list[104], &op_list[104], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[99]  */
	{ &op_list[101], &op_list[101], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[100]  */
	{ (OP*)&svop_list[244], (OP*)&svop_list[244], INT2PTR(void*,OP_PADSV), 96, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[101]  */
	{ &op_list[103], &op_list[103], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[102]  */
	{ (OP*)&svop_list[248], (OP*)&svop_list[248], INT2PTR(void*,OP_PADSV), 97, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[103]  */
	{ (OP*)&svop_list[252], (OP*)&svop_list[252], INT2PTR(void*,OP_PADSV), 98, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[104]  */
	{ &op_list[110], &op_list[110], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[105]  */
	{ &op_list[107], &op_list[107], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[106]  */
	{ (OP*)&svop_list[256], (OP*)&svop_list[256], INT2PTR(void*,OP_PADSV), 96, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[107]  */
	{ &op_list[109], &op_list[109], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[108]  */
	{ (OP*)&svop_list[260], (OP*)&svop_list[260], INT2PTR(void*,OP_PADSV), 97, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[109]  */
	{ (OP*)&svop_list[264], (OP*)&svop_list[264], INT2PTR(void*,OP_PADSV), 98, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[110]  */
	{ (OP*)&cop_list[57], (OP*)&cop_list[57], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[111]  */
	{ (OP*)&cop_list[56], &op_list[114], INT2PTR(void*,OP_PADRANGE), 110, 390, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x83 }, /* op_list[112]  */
	{ (OP*)&listop_list[17], 0, INT2PTR(void*,OP_PADSV), 112, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[113]  */
	{ &op_list[115], &op_list[115], INT2PTR(void*,OP_PADSV), 110, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[114]  */
	{ &op_list[113], &op_list[113], INT2PTR(void*,OP_PADSV), 111, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[115]  */
	{ (OP*)&loop_list[4], (OP*)&binop_list[60], INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x81, 0x0 }, /* op_list[116]  */
	{ (OP*)&cop_list[72], (OP*)&cop_list[72], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[117]  */
	{ (OP*)&svop_list[271], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[118]  */
	{ &op_list[121], (OP*)&unop_list[248], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[119]  */
	{ (OP*)&binop_list[64], &op_list[126], INT2PTR(void*,OP_PADRANGE), 110, 390, 0, 0, 0, 1, 0, 0, 0, 0x30, 0x3 }, /* op_list[120]  */
	{ (OP*)&cop_list[58], (OP*)&cop_list[58], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x3, 0x0 }, /* op_list[121]  */
	{ (OP*)&svop_list[279], (OP*)&svop_list[279], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[122]  */
	{ (OP*)&svop_list[284], (OP*)&svop_list[284], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[123]  */
	{ (OP*)&cop_list[62], (OP*)&cop_list[62], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x3, 0x0 }, /* op_list[124]  */
	{ (OP*)&svop_list[287], (OP*)&svop_list[287], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[125]  */
	{ &op_list[127], &op_list[127], INT2PTR(void*,OP_PADSV), 110, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[126]  */
	{ &op_list[128], &op_list[128], INT2PTR(void*,OP_PADSV), 111, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[127]  */
	{ (OP*)&unop_list[247], 0, INT2PTR(void*,OP_PADSV), 112, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[128]  */
	{ (OP*)&cop_list[64], (OP*)&cop_list[64], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[129]  */
	{ &op_list[135], &op_list[135], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[130]  */
	{ &op_list[132], &op_list[132], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[131]  */
	{ (OP*)&svop_list[292], (OP*)&svop_list[292], INT2PTR(void*,OP_PADSV), 110, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[132]  */
	{ &op_list[134], &op_list[134], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[133]  */
	{ (OP*)&svop_list[296], (OP*)&svop_list[296], INT2PTR(void*,OP_PADSV), 111, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[134]  */
	{ (OP*)&svop_list[300], (OP*)&svop_list[300], INT2PTR(void*,OP_PADSV), 112, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[135]  */
	{ (OP*)&cop_list[68], (OP*)&cop_list[68], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[136]  */
	{ &op_list[142], &op_list[142], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[137]  */
	{ &op_list[139], &op_list[139], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[138]  */
	{ (OP*)&svop_list[306], (OP*)&svop_list[306], INT2PTR(void*,OP_PADSV), 110, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[139]  */
	{ &op_list[141], &op_list[141], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[140]  */
	{ (OP*)&svop_list[310], (OP*)&svop_list[310], INT2PTR(void*,OP_PADSV), 111, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[141]  */
	{ (OP*)&svop_list[314], (OP*)&svop_list[314], INT2PTR(void*,OP_PADSV), 112, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[142]  */
	{ &op_list[148], &op_list[148], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[143]  */
	{ &op_list[145], &op_list[145], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[144]  */
	{ (OP*)&svop_list[318], (OP*)&svop_list[318], INT2PTR(void*,OP_PADSV), 110, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[145]  */
	{ &op_list[147], &op_list[147], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[146]  */
	{ (OP*)&svop_list[322], (OP*)&svop_list[322], INT2PTR(void*,OP_PADSV), 111, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[147]  */
	{ (OP*)&svop_list[326], (OP*)&svop_list[326], INT2PTR(void*,OP_PADSV), 112, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[148]  */
	{ (OP*)&svop_list[334], (OP*)&unop_list[292], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[149]  */
	{ (OP*)&svop_list[339], (OP*)&unop_list[295], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[150]  */
	{ (OP*)&svop_list[336], (OP*)&svop_list[336], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[151]  */
	{ &op_list[153], (OP*)&listop_list[28], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[152]  */
	{ (OP*)&svop_list[341], (OP*)&svop_list[341], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[153]  */
	{ (OP*)&svop_list[346], (OP*)&unop_list[302], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[154]  */
	{ (OP*)&svop_list[351], (OP*)&unop_list[306], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[155]  */
	{ (OP*)&svop_list[348], (OP*)&svop_list[348], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[156]  */
	{ &op_list[158], (OP*)&listop_list[29], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[157]  */
	{ (OP*)&svop_list[353], (OP*)&svop_list[353], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[158]  */
	{ (OP*)&svop_list[358], (OP*)&svop_list[358], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[159]  */
	{ (OP*)&svop_list[363], (OP*)&svop_list[363], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[160]  */
	{ (OP*)&svop_list[368], (OP*)&svop_list[368], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[161]  */
	{ (OP*)&svop_list[373], (OP*)&svop_list[373], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[162]  */
	{ (OP*)&svop_list[378], (OP*)&svop_list[378], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[163]  */
	{ (OP*)&svop_list[383], (OP*)&svop_list[383], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[164]  */
	{ (OP*)&svop_list[388], (OP*)&svop_list[388], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[165]  */
	{ &op_list[214], &op_list[214], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[166]  */
	{ (OP*)&svop_list[393], (OP*)&svop_list[393], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[167]  */
	{ &op_list[171], &op_list[171], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[168]  */
	{ &op_list[170], &op_list[170], INT2PTR(void*,OP_UNDEF), 0, 44, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[169]  */
	{ (OP*)&svop_list[394], (OP*)&svop_list[394], INT2PTR(void*,OP_UNDEF), 0, 44, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[170]  */
	{ (OP*)&binop_list[77], 0, INT2PTR(void*,OP_PADAV), 148, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[171]  */
	{ &op_list[174], (OP*)&listop_list[31], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[172]  */
	{ &op_list[177], &op_list[177], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[173]  */
	{ (OP*)&svop_list[395], (OP*)&unop_list[338], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[174]  */
	{ (OP*)&listop_list[31], 0, INT2PTR(void*,OP_PADAV), 148, 10, 0, 0, 0, 1, 0, 0, 0, 0x12, 0x0 }, /* op_list[175]  */
	{ (OP*)&svop_list[395], (OP*)&svop_list[395], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[176]  */
	{ (OP*)&binop_list[78], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[177]  */
	{ &op_list[180], (OP*)&binop_list[80], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[178]  */
	{ &op_list[184], &op_list[184], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[179]  */
	{ (OP*)&svop_list[397], (OP*)&svop_list[397], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[180]  */
	{ (OP*)&svop_list[399], (OP*)&svop_list[399], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[181]  */
	{ &op_list[183], &op_list[183], INT2PTR(void*,OP_UNDEF), 0, 44, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[182]  */
	{ (OP*)&svop_list[400], (OP*)&svop_list[400], INT2PTR(void*,OP_UNDEF), 0, 44, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[183]  */
	{ (OP*)&binop_list[79], 0, INT2PTR(void*,OP_PADAV), 152, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[184]  */
	{ &op_list[186], (OP*)&unop_list[345], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[185]  */
	{ (OP*)&svop_list[401], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[186]  */
	{ (OP*)&svop_list[402], 0, INT2PTR(void*,OP_PADAV), 152, 10, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[187]  */
	{ &op_list[189], (OP*)&unop_list[350], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[188]  */
	{ (OP*)&svop_list[404], 0, INT2PTR(void*,OP_PADAV), 152, 10, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[189]  */
	{ (OP*)&svop_list[408], (OP*)&svop_list[408], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[190]  */
	{ &op_list[195], &op_list[195], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[191]  */
	{ &op_list[193], &op_list[194], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[192]  */
	{ (OP*)&listop_list[32], 0, INT2PTR(void*,OP_PADAV), 152, 10, 0, 0, 0, 1, 0, 0, 0, 0x12, 0x0 }, /* op_list[193]  */
	{ &op_list[193], &op_list[193], INT2PTR(void*,OP_STUB), 0, 1, 0, 0, 0, 1, 0, 0, 0, 0xb, 0x0 }, /* op_list[194]  */
	{ (OP*)&binop_list[81], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x0 }, /* op_list[195]  */
	{ &op_list[197], (OP*)&listop_list[33], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[196]  */
	{ (OP*)&svop_list[409], (OP*)&svop_list[409], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[197]  */
	{ (OP*)&listop_list[33], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0x3, 0x0 }, /* op_list[198]  */
	{ (OP*)&svop_list[414], (OP*)&svop_list[414], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[199]  */
	{ &op_list[201], &op_list[201], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[200]  */
	{ (OP*)&binop_list[82], 0, INT2PTR(void*,OP_PADHV), 159, 11, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[201]  */
	{ (OP*)&svop_list[416], (OP*)&svop_list[416], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[202]  */
	{ &op_list[207], &op_list[207], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[203]  */
	{ &op_list[205], &op_list[206], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[204]  */
	{ (OP*)&listop_list[34], 0, INT2PTR(void*,OP_PADHV), 159, 11, 0, 0, 0, 1, 0, 0, 0, 0x12, 0x0 }, /* op_list[205]  */
	{ &op_list[205], &op_list[205], INT2PTR(void*,OP_STUB), 0, 1, 0, 0, 0, 1, 0, 0, 0, 0xb, 0x0 }, /* op_list[206]  */
	{ (OP*)&binop_list[83], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x0 }, /* op_list[207]  */
	{ &op_list[209], (OP*)&listop_list[35], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[208]  */
	{ (OP*)&svop_list[417], (OP*)&svop_list[417], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[209]  */
	{ (OP*)&listop_list[35], 0, INT2PTR(void*,OP_PADAV), 150, 10, 0, 0, 0, 1, 0, 0, 0, 0x3, 0x0 }, /* op_list[210]  */
	{ (OP*)&svop_list[422], (OP*)&unop_list[369], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[211]  */
	{ (OP*)&binop_list[85], 0, INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[212]  */
	{ (OP*)&binop_list[84], 0, INT2PTR(void*,OP_PADSV), 164, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[213]  */
	{ (OP*)&svop_list[423], (OP*)&svop_list[423], INT2PTR(void*,OP_PADSV), 164, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[214]  */
	{ (OP*)&svop_list[467], (OP*)&svop_list[467], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[215]  */
	{ (OP*)&svop_list[427], (OP*)&svop_list[427], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[216]  */
	{ (OP*)&svop_list[428], (OP*)&svop_list[428], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[217]  */
	{ (OP*)&svop_list[430], (OP*)&svop_list[430], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[218]  */
	{ (OP*)&svop_list[432], (OP*)&unop_list[381], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[219]  */
	{ &op_list[221], &op_list[221], INT2PTR(void*,OP_SHIFT), 0, 165, 0, 0, 0, 1, 0, 0, 0, 0x82, 0x0 }, /* op_list[220]  */
	{ (OP*)&binop_list[88], 0, INT2PTR(void*,OP_PADSV), 1, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[221]  */
	{ (OP*)&svop_list[434], (OP*)&unop_list[383], INT2PTR(void*,OP_PADSV), 1, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[222]  */
	{ (OP*)&svop_list[436], (OP*)&svop_list[436], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[223]  */
	{ &op_list[225], (OP*)&unop_list[388], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[224]  */
	{ (OP*)&svop_list[438], (OP*)&svop_list[438], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[225]  */
	{ (OP*)&svop_list[440], (OP*)&svop_list[440], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[226]  */
	{ (OP*)&svop_list[443], (OP*)&svop_list[443], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[227]  */
	{ &op_list[229], (OP*)&binop_list[90], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[228]  */
	{ (OP*)&svop_list[444], (OP*)&svop_list[444], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[229]  */
	{ (OP*)&svop_list[446], (OP*)&svop_list[446], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[230]  */
	{ (OP*)&svop_list[449], (OP*)&svop_list[449], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[231]  */
	{ &op_list[234], (OP*)&binop_list[92], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[232]  */
	{ &op_list[236], &op_list[236], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[233]  */
	{ (OP*)&svop_list[450], (OP*)&svop_list[450], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[234]  */
	{ (OP*)&svop_list[452], (OP*)&svop_list[452], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[235]  */
	{ (OP*)&binop_list[91], 0, INT2PTR(void*,OP_PADAV), 169, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[236]  */
	{ (OP*)&svop_list[455], (OP*)&svop_list[455], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[237]  */
	{ (OP*)&svop_list[456], (OP*)&svop_list[456], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[238]  */
	{ (OP*)&svop_list[458], (OP*)&svop_list[458], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[239]  */
	{ (OP*)&svop_list[461], (OP*)&svop_list[461], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[240]  */
	{ (OP*)&svop_list[462], (OP*)&svop_list[462], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[241]  */
	{ (OP*)&svop_list[464], (OP*)&svop_list[464], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[242]  */
	{ (OP*)&svop_list[468], (OP*)&svop_list[468], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[243]  */
	{ (OP*)&binop_list[95], &op_list[245], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[244]  */
	{ (OP*)&unop_list[414], 0, INT2PTR(void*,OP_STUB), 0, 1, 0, 0, 0, 1, 0, 0, 0, 0xb, 0x0 }, /* op_list[245]  */
	{ &op_list[247], (OP*)&listop_list[42], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[246]  */
	{ (OP*)&svop_list[471], (OP*)&svop_list[471], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[247]  */
	{ (OP*)&cop_list[113], (OP*)&cop_list[113], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[248]  */
	{ &op_list[250], (OP*)&binop_list[97], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[249]  */
	{ (OP*)&svop_list[472], (OP*)&svop_list[472], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[250]  */
	{ (OP*)&svop_list[477], (OP*)&pmop_list[1], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[251]  */
	{ &op_list[253], (OP*)&listop_list[45], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[252]  */
	{ (OP*)&svop_list[480], (OP*)&svop_list[480], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[253]  */
	{ (OP*)&svop_list[481], (OP*)&svop_list[481], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[254]  */
	{ (OP*)&svop_list[484], (OP*)&svop_list[484], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[255]  */
	{ (OP*)&svop_list[489], (OP*)&svop_list[489], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[256]  */
	{ &op_list[258], &op_list[258], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[257]  */
	{ (OP*)&binop_list[99], 0, INT2PTR(void*,OP_PADAV), 176, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[258]  */
	{ &op_list[260], (OP*)&listop_list[46], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[259]  */
	{ (OP*)&svop_list[492], (OP*)&svop_list[492], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[260]  */
	{ (OP*)&listop_list[46], 0, INT2PTR(void*,OP_PADAV), 176, 10, 0, 0, 0, 1, 0, 0, 0, 0x3, 0x0 }, /* op_list[261]  */
	{ &op_list[263], &op_list[264], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[262]  */
	{ &op_list[265], &op_list[265], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[263]  */
	{ (OP*)&unop_list[432], 0, INT2PTR(void*,OP_STUB), 0, 1, 0, 0, 0, 1, 0, 0, 0, 0xb, 0x0 }, /* op_list[264]  */
	{ (OP*)&binop_list[100], 0, INT2PTR(void*,OP_PADAV), 180, 10, 0, 0, 0, 1, 0, 0, 0, 0xb3, 0x80 }, /* op_list[265]  */
	{ (OP*)&unop_list[434], 0, INT2PTR(void*,OP_PADAV), 180, 10, 0, 0, 0, 1, 0, 0, 0, 0x12, 0x0 }, /* op_list[266]  */
	{ (OP*)&svop_list[499], (OP*)&unop_list[438], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[267]  */
};

Static UNOP unop_list[439] = {
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_ENTERSUB), 183, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[1] }, /* unop_list[0]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[1] }, /* unop_list[1]  */
	{ (OP*)&cop_list[2], (OP*)&cop_list[2], INT2PTR(void*,OP_ENTERSUB), 1, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[3] }, /* unop_list[2]  */
	{ (OP*)&unop_list[2], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[2] }, /* unop_list[3]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[2] }, /* unop_list[4]  */
	{ &op_list[4], (OP*)&unop_list[6], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[3] }, /* unop_list[5]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[4] }, /* unop_list[6]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_RV2AV), 2, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[7] }, /* unop_list[7]  */
	{ (OP*)&cop_list[4], (OP*)&cop_list[4], INT2PTR(void*,OP_ENTERSUB), 4, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[9] }, /* unop_list[8]  */
	{ (OP*)&unop_list[8], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[5] }, /* unop_list[9]  */
	{ (OP*)&svop_list[9], (OP*)&svop_list[9], INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&svop_list[8] }, /* unop_list[10]  */
	{ (OP*)&unop_list[9], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[13] }, /* unop_list[11]  */
	{ (OP*)&cop_list[5], (OP*)&cop_list[5], INT2PTR(void*,OP_ENTERSUB), 5, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[13] }, /* unop_list[12]  */
	{ (OP*)&unop_list[12], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[6] }, /* unop_list[13]  */
	{ (OP*)&svop_list[15], (OP*)&svop_list[15], INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&svop_list[14] }, /* unop_list[14]  */
	{ (OP*)&unop_list[13], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[19] }, /* unop_list[15]  */
	{ (OP*)&listop_list[2], 0, INT2PTR(void*,OP_RV2AV), 6, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[20] }, /* unop_list[16]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[21] }, /* unop_list[17]  */
	{ (OP*)&cop_list[7], (OP*)&cop_list[7], INT2PTR(void*,OP_ENTERSUB), 8, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[19] }, /* unop_list[18]  */
	{ (OP*)&unop_list[18], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[8] }, /* unop_list[19]  */
	{ (OP*)&svop_list[24], (OP*)&svop_list[24], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[23] }, /* unop_list[20]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[27] }, /* unop_list[21]  */
	{ &op_list[10], (OP*)&unop_list[23], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[9] }, /* unop_list[22]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[10] }, /* unop_list[23]  */
	{ (OP*)&svop_list[33], (OP*)&unop_list[25], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[32] }, /* unop_list[24]  */
	{ (OP*)&svop_list[34], (OP*)&unop_list[26], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[33] }, /* unop_list[25]  */
	{ (OP*)&svop_list[35], (OP*)&unop_list[27], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[34] }, /* unop_list[26]  */
	{ (OP*)&unop_list[23], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[35] }, /* unop_list[27]  */
	{ (OP*)&cop_list[9], (OP*)&cop_list[9], INT2PTR(void*,OP_ENTERSUB), 17, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[29] }, /* unop_list[28]  */
	{ (OP*)&unop_list[28], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[11] }, /* unop_list[29]  */
	{ (OP*)&svop_list[43], (OP*)&svop_list[43], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[12] }, /* unop_list[30]  */
	{ (OP*)&svop_list[37], (OP*)&svop_list[37], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[36] }, /* unop_list[31]  */
	{ (OP*)&binop_list[10], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[38] }, /* unop_list[32]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[40] }, /* unop_list[33]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[42] }, /* unop_list[34]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[46] }, /* unop_list[35]  */
	{ &op_list[14], (OP*)&unop_list[37], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[13] }, /* unop_list[36]  */
	{ (OP*)&binop_list[12], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[14] }, /* unop_list[37]  */
	{ (OP*)&svop_list[50], (OP*)&unop_list[39], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[49] }, /* unop_list[38]  */
	{ (OP*)&svop_list[51], (OP*)&unop_list[40], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[50] }, /* unop_list[39]  */
	{ (OP*)&unop_list[37], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[51] }, /* unop_list[40]  */
	{ (OP*)&cop_list[11], (OP*)&cop_list[11], INT2PTR(void*,OP_ENTERSUB), 25, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[42] }, /* unop_list[41]  */
	{ (OP*)&unop_list[41], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[15] }, /* unop_list[42]  */
	{ (OP*)&svop_list[57], (OP*)&svop_list[57], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[16] }, /* unop_list[43]  */
	{ (OP*)&svop_list[53], (OP*)&svop_list[53], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[52] }, /* unop_list[44]  */
	{ (OP*)&binop_list[15], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[54] }, /* unop_list[45]  */
	{ (OP*)&binop_list[13], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[56] }, /* unop_list[46]  */
	{ (OP*)&unop_list[42], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[60] }, /* unop_list[47]  */
	{ &op_list[18], (OP*)&unop_list[49], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[17] }, /* unop_list[48]  */
	{ (OP*)&binop_list[17], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[18] }, /* unop_list[49]  */
	{ (OP*)&svop_list[62], (OP*)&unop_list[51], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[61] }, /* unop_list[50]  */
	{ (OP*)&svop_list[63], (OP*)&unop_list[52], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[62] }, /* unop_list[51]  */
	{ (OP*)&unop_list[48], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[63] }, /* unop_list[52]  */
	{ (OP*)&svop_list[65], (OP*)&unop_list[54], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[64] }, /* unop_list[53]  */
	{ (OP*)&svop_list[66], (OP*)&unop_list[55], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[65] }, /* unop_list[54]  */
	{ (OP*)&unop_list[49], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[66] }, /* unop_list[55]  */
	{ (OP*)&cop_list[13], (OP*)&cop_list[13], INT2PTR(void*,OP_ENTERSUB), 32, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[57] }, /* unop_list[56]  */
	{ (OP*)&unop_list[56], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[19] }, /* unop_list[57]  */
	{ (OP*)&svop_list[72], (OP*)&svop_list[72], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[20] }, /* unop_list[58]  */
	{ (OP*)&svop_list[68], (OP*)&svop_list[68], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[67] }, /* unop_list[59]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[69] }, /* unop_list[60]  */
	{ (OP*)&binop_list[18], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[71] }, /* unop_list[61]  */
	{ (OP*)&unop_list[57], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[75] }, /* unop_list[62]  */
	{ &op_list[22], (OP*)&unop_list[64], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[21] }, /* unop_list[63]  */
	{ (OP*)&binop_list[22], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[22] }, /* unop_list[64]  */
	{ (OP*)&svop_list[77], (OP*)&unop_list[66], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[76] }, /* unop_list[65]  */
	{ (OP*)&unop_list[63], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[77] }, /* unop_list[66]  */
	{ (OP*)&svop_list[79], (OP*)&unop_list[68], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[78] }, /* unop_list[67]  */
	{ (OP*)&unop_list[64], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[79] }, /* unop_list[68]  */
	{ (OP*)&cop_list[15], (OP*)&cop_list[15], INT2PTR(void*,OP_ENTERSUB), 37, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[70] }, /* unop_list[69]  */
	{ (OP*)&unop_list[69], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[23] }, /* unop_list[70]  */
	{ (OP*)&svop_list[83], (OP*)&svop_list[83], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[24] }, /* unop_list[71]  */
	{ (OP*)&svop_list[81], (OP*)&svop_list[81], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[80] }, /* unop_list[72]  */
	{ (OP*)&binop_list[23], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[82] }, /* unop_list[73]  */
	{ (OP*)&unop_list[70], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[86] }, /* unop_list[74]  */
	{ &op_list[26], (OP*)&unop_list[76], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[25] }, /* unop_list[75]  */
	{ (OP*)&binop_list[25], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[26] }, /* unop_list[76]  */
	{ &op_list[28], (OP*)&unop_list[78], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[27] }, /* unop_list[77]  */
	{ (OP*)&binop_list[26], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[28] }, /* unop_list[78]  */
	{ (OP*)&svop_list[88], (OP*)&unop_list[80], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[87] }, /* unop_list[79]  */
	{ (OP*)&unop_list[77], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[88] }, /* unop_list[80]  */
	{ (OP*)&svop_list[90], (OP*)&unop_list[82], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[89] }, /* unop_list[81]  */
	{ (OP*)&unop_list[78], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[90] }, /* unop_list[82]  */
	{ (OP*)&svop_list[92], (OP*)&unop_list[84], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[91] }, /* unop_list[83]  */
	{ (OP*)&unop_list[76], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[92] }, /* unop_list[84]  */
	{ (OP*)&cop_list[17], (OP*)&cop_list[17], INT2PTR(void*,OP_ENTERSUB), 43, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[86] }, /* unop_list[85]  */
	{ (OP*)&unop_list[85], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[29] }, /* unop_list[86]  */
	{ (OP*)&svop_list[96], (OP*)&svop_list[96], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[30] }, /* unop_list[87]  */
	{ (OP*)&svop_list[94], (OP*)&svop_list[94], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[93] }, /* unop_list[88]  */
	{ (OP*)&binop_list[27], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[95] }, /* unop_list[89]  */
	{ (OP*)&unop_list[86], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[99] }, /* unop_list[90]  */
	{ &op_list[32], (OP*)&unop_list[92], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[31] }, /* unop_list[91]  */
	{ (OP*)&binop_list[29], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[32] }, /* unop_list[92]  */
	{ (OP*)&svop_list[105], (OP*)&unop_list[94], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[104] }, /* unop_list[93]  */
	{ &op_list[34], (OP*)&unop_list[96], INT2PTR(void*,OP_NULL), 138, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unop_list[95] }, /* unop_list[94]  */
	{ &op_list[33], &op_list[33], INT2PTR(void*,OP_NULL), 135, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&svop_list[105] }, /* unop_list[95]  */
	{ (OP*)&svop_list[106], (OP*)&unop_list[97], INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unopaux_list[0] }, /* unop_list[96]  */
	{ (OP*)&unop_list[92], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[106] }, /* unop_list[97]  */
	{ (OP*)&cop_list[19], (OP*)&cop_list[19], INT2PTR(void*,OP_ENTERSUB), 45, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[99] }, /* unop_list[98]  */
	{ (OP*)&unop_list[98], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[35] }, /* unop_list[99]  */
	{ (OP*)&svop_list[108], (OP*)&svop_list[108], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[107] }, /* unop_list[100]  */
	{ (OP*)&unop_list[99], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[111] }, /* unop_list[101]  */
	{ (OP*)&cop_list[20], (OP*)&cop_list[20], INT2PTR(void*,OP_ENTERSUB), 46, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[103] }, /* unop_list[102]  */
	{ (OP*)&unop_list[102], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[36] }, /* unop_list[103]  */
	{ (OP*)&svop_list[113], (OP*)&svop_list[113], INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&svop_list[112] }, /* unop_list[104]  */
	{ (OP*)&unop_list[103], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[117] }, /* unop_list[105]  */
	{ (OP*)&cop_list[21], (OP*)&cop_list[21], INT2PTR(void*,OP_ENTERSUB), 47, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[107] }, /* unop_list[106]  */
	{ (OP*)&unop_list[106], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[37] }, /* unop_list[107]  */
	{ (OP*)&svop_list[118], (OP*)&svop_list[118], INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x42, (OP*)&unopaux_list[1] }, /* unop_list[108]  */
	{ (OP*)&unop_list[107], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[121] }, /* unop_list[109]  */
	{ (OP*)&cop_list[22], (OP*)&cop_list[22], INT2PTR(void*,OP_ENTERSUB), 48, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[111] }, /* unop_list[110]  */
	{ (OP*)&unop_list[110], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[39] }, /* unop_list[111]  */
	{ (OP*)&svop_list[123], (OP*)&svop_list[123], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[122] }, /* unop_list[112]  */
	{ (OP*)&unop_list[111], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[126] }, /* unop_list[113]  */
	{ &op_list[41], (OP*)&unop_list[115], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[40] }, /* unop_list[114]  */
	{ (OP*)&binop_list[31], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[41] }, /* unop_list[115]  */
	{ (OP*)&binop_list[31], 0, INT2PTR(void*,OP_RV2AV), 49, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[135] }, /* unop_list[116]  */
	{ &op_list[43], (OP*)&unop_list[118], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[42] }, /* unop_list[117]  */
	{ (OP*)&binop_list[32], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[43] }, /* unop_list[118]  */
	{ &op_list[43], 0, INT2PTR(void*,OP_RV2AV), 51, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[136] }, /* unop_list[119]  */
	{ (OP*)&svop_list[138], (OP*)&unop_list[121], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[137] }, /* unop_list[120]  */
	{ (OP*)&svop_list[139], (OP*)&unop_list[122], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[138] }, /* unop_list[121]  */
	{ (OP*)&svop_list[140], (OP*)&unop_list[123], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[139] }, /* unop_list[122]  */
	{ (OP*)&unop_list[118], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[140] }, /* unop_list[123]  */
	{ (OP*)&cop_list[25], (OP*)&cop_list[25], INT2PTR(void*,OP_ENTERSUB), 60, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[125] }, /* unop_list[124]  */
	{ (OP*)&unop_list[124], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[44] }, /* unop_list[125]  */
	{ (OP*)&svop_list[148], (OP*)&svop_list[148], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[45] }, /* unop_list[126]  */
	{ (OP*)&svop_list[142], (OP*)&svop_list[142], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[141] }, /* unop_list[127]  */
	{ (OP*)&binop_list[37], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[143] }, /* unop_list[128]  */
	{ (OP*)&binop_list[35], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[145] }, /* unop_list[129]  */
	{ (OP*)&binop_list[33], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[147] }, /* unop_list[130]  */
	{ (OP*)&unop_list[125], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[151] }, /* unop_list[131]  */
	{ &op_list[47], (OP*)&unop_list[133], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[46] }, /* unop_list[132]  */
	{ (OP*)&binop_list[39], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[47] }, /* unop_list[133]  */
	{ (OP*)&binop_list[39], 0, INT2PTR(void*,OP_RV2AV), 61, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[154] }, /* unop_list[134]  */
	{ &op_list[49], (OP*)&unop_list[136], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[48] }, /* unop_list[135]  */
	{ (OP*)&binop_list[40], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[49] }, /* unop_list[136]  */
	{ &op_list[49], 0, INT2PTR(void*,OP_RV2AV), 63, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[155] }, /* unop_list[137]  */
	{ (OP*)&svop_list[157], (OP*)&unop_list[139], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[156] }, /* unop_list[138]  */
	{ (OP*)&svop_list[158], (OP*)&unop_list[140], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[157] }, /* unop_list[139]  */
	{ (OP*)&svop_list[159], (OP*)&unop_list[141], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[158] }, /* unop_list[140]  */
	{ (OP*)&unop_list[136], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[159] }, /* unop_list[141]  */
	{ (OP*)&cop_list[28], (OP*)&cop_list[28], INT2PTR(void*,OP_ENTERSUB), 65, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[143] }, /* unop_list[142]  */
	{ (OP*)&unop_list[142], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[50] }, /* unop_list[143]  */
	{ (OP*)&svop_list[161], (OP*)&svop_list[161], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[160] }, /* unop_list[144]  */
	{ (OP*)&unop_list[143], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[164] }, /* unop_list[145]  */
	{ (OP*)&cop_list[29], (OP*)&cop_list[29], INT2PTR(void*,OP_ENTERSUB), 66, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[147] }, /* unop_list[146]  */
	{ (OP*)&unop_list[146], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[51] }, /* unop_list[147]  */
	{ (OP*)&svop_list[166], (OP*)&svop_list[166], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[165] }, /* unop_list[148]  */
	{ (OP*)&unop_list[147], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[169] }, /* unop_list[149]  */
	{ (OP*)&cop_list[30], (OP*)&cop_list[30], INT2PTR(void*,OP_ENTERSUB), 67, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[151] }, /* unop_list[150]  */
	{ (OP*)&unop_list[150], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[52] }, /* unop_list[151]  */
	{ (OP*)&svop_list[171], (OP*)&svop_list[171], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[153] }, /* unop_list[152]  */
	{ (OP*)&unop_list[152], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[154] }, /* unop_list[153]  */
	{ (OP*)&unop_list[153], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&svop_list[170] }, /* unop_list[154]  */
	{ (OP*)&unop_list[151], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[172] }, /* unop_list[155]  */
	{ (OP*)&cop_list[31], (OP*)&cop_list[31], INT2PTR(void*,OP_ENTERSUB), 68, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[157] }, /* unop_list[156]  */
	{ (OP*)&unop_list[156], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[53] }, /* unop_list[157]  */
	{ (OP*)&svop_list[174], (OP*)&svop_list[174], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[159] }, /* unop_list[158]  */
	{ (OP*)&unop_list[158], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[160] }, /* unop_list[159]  */
	{ (OP*)&unop_list[159], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&svop_list[173] }, /* unop_list[160]  */
	{ (OP*)&unop_list[157], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[175] }, /* unop_list[161]  */
	{ &op_list[55], (OP*)&unop_list[163], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[54] }, /* unop_list[162]  */
	{ (OP*)&binop_list[41], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[55] }, /* unop_list[163]  */
	{ &op_list[57], (OP*)&unop_list[165], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[56] }, /* unop_list[164]  */
	{ (OP*)&binop_list[42], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[57] }, /* unop_list[165]  */
	{ (OP*)&binop_list[42], 0, INT2PTR(void*,OP_RV2AV), 70, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[177] }, /* unop_list[166]  */
	{ (OP*)&binop_list[41], 0, INT2PTR(void*,OP_RV2AV), 69, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[178] }, /* unop_list[167]  */
	{ (OP*)&cop_list[33], (OP*)&cop_list[33], INT2PTR(void*,OP_ENTERSUB), 76, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[169] }, /* unop_list[168]  */
	{ (OP*)&unop_list[168], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[58] }, /* unop_list[169]  */
	{ (OP*)&listop_list[4], 0, INT2PTR(void*,OP_RV2AV), 74, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[179] }, /* unop_list[170]  */
	{ (OP*)&svop_list[179], (OP*)&unop_list[170], INT2PTR(void*,OP_RV2AV), 73, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[181] }, /* unop_list[171]  */
	{ (OP*)&unop_list[169], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[185] }, /* unop_list[172]  */
	{ &op_list[61], (OP*)&unop_list[174], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[60] }, /* unop_list[173]  */
	{ (OP*)&binop_list[43], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[61] }, /* unop_list[174]  */
	{ &op_list[63], (OP*)&unop_list[176], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[62] }, /* unop_list[175]  */
	{ (OP*)&binop_list[44], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[63] }, /* unop_list[176]  */
	{ (OP*)&binop_list[44], 0, INT2PTR(void*,OP_RV2AV), 78, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[188] }, /* unop_list[177]  */
	{ (OP*)&binop_list[43], 0, INT2PTR(void*,OP_RV2AV), 77, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[189] }, /* unop_list[178]  */
	{ (OP*)&cop_list[35], (OP*)&cop_list[35], INT2PTR(void*,OP_ENTERSUB), 86, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[180] }, /* unop_list[179]  */
	{ (OP*)&unop_list[179], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[64] }, /* unop_list[180]  */
	{ (OP*)&listop_list[6], 0, INT2PTR(void*,OP_RV2AV), 83, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[190] }, /* unop_list[181]  */
	{ (OP*)&listop_list[7], 0, INT2PTR(void*,OP_RV2AV), 81, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[192] }, /* unop_list[182]  */
	{ (OP*)&unop_list[180], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[198] }, /* unop_list[183]  */
	{ &op_list[69], (OP*)&unop_list[185], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[68] }, /* unop_list[184]  */
	{ (OP*)&binop_list[45], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[69] }, /* unop_list[185]  */
	{ (OP*)&binop_list[45], 0, INT2PTR(void*,OP_RV2AV), 87, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[199] }, /* unop_list[186]  */
	{ &op_list[72], (OP*)&unop_list[188], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[71] }, /* unop_list[187]  */
	{ (OP*)&binop_list[46], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[72] }, /* unop_list[188]  */
	{ (OP*)&binop_list[46], 0, INT2PTR(void*,OP_RV2AV), 89, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[201] }, /* unop_list[189]  */
	{ (OP*)&cop_list[38], (OP*)&cop_list[38], INT2PTR(void*,OP_ENTERSUB), 95, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[191] }, /* unop_list[190]  */
	{ (OP*)&unop_list[190], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[73] }, /* unop_list[191]  */
	{ (OP*)&listop_list[8], 0, INT2PTR(void*,OP_RV2AV), 93, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[202] }, /* unop_list[192]  */
	{ (OP*)&unop_list[191], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[207] }, /* unop_list[193]  */
	{ (OP*)&binop_list[48], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[0] }, /* unop_list[194]  */
	{ (OP*)&svop_list[210], (OP*)&svop_list[210], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[209] }, /* unop_list[195]  */
	{ (OP*)&binop_list[50], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[212] }, /* unop_list[196]  */
	{ (OP*)&listop_list[12], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[1] }, /* unop_list[197]  */
	{ (OP*)&svop_list[214], (OP*)&svop_list[214], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[213] }, /* unop_list[198]  */
	{ &op_list[84], (OP*)&unop_list[200], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[83] }, /* unop_list[199]  */
	{ (OP*)&binop_list[52], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[84] }, /* unop_list[200]  */
	{ (OP*)&unop_list[199], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&logop_list[2] }, /* unop_list[201]  */
	{ (OP*)&svop_list[216], (OP*)&svop_list[216], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[215] }, /* unop_list[202]  */
	{ (OP*)&unop_list[201], (OP*)&unop_list[204], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[85] }, /* unop_list[203]  */
	{ (OP*)&unop_list[201], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&logop_list[3] }, /* unop_list[204]  */
	{ (OP*)&svop_list[221], (OP*)&svop_list[221], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[220] }, /* unop_list[205]  */
	{ (OP*)&unop_list[204], (OP*)&unop_list[207], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[86] }, /* unop_list[206]  */
	{ (OP*)&unop_list[204], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[87] }, /* unop_list[207]  */
	{ (OP*)&cop_list[46], (OP*)&cop_list[46], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[4] }, /* unop_list[208]  */
	{ (OP*)&svop_list[229], (OP*)&svop_list[229], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[228] }, /* unop_list[209]  */
	{ (OP*)&listop_list[13], 0, INT2PTR(void*,OP_ENTERSUB), 103, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[211] }, /* unop_list[210]  */
	{ (OP*)&unop_list[210], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[92] }, /* unop_list[211]  */
	{ (OP*)&cop_list[44], (OP*)&cop_list[44], INT2PTR(void*,OP_ENTERSUB), 101, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[213] }, /* unop_list[212]  */
	{ (OP*)&unop_list[212], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[93] }, /* unop_list[213]  */
	{ (OP*)&unop_list[213], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[233] }, /* unop_list[214]  */
	{ (OP*)&cop_list[45], (OP*)&cop_list[45], INT2PTR(void*,OP_ENTERSUB), 102, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[216] }, /* unop_list[215]  */
	{ (OP*)&unop_list[215], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[95] }, /* unop_list[216]  */
	{ (OP*)&unop_list[216], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[237] }, /* unop_list[217]  */
	{ (OP*)&unop_list[211], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[241] }, /* unop_list[218]  */
	{ (OP*)&cop_list[50], (OP*)&cop_list[50], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[5] }, /* unop_list[219]  */
	{ (OP*)&svop_list[243], (OP*)&svop_list[243], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[242] }, /* unop_list[220]  */
	{ (OP*)&listop_list[14], 0, INT2PTR(void*,OP_ENTERSUB), 106, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[222] }, /* unop_list[221]  */
	{ (OP*)&unop_list[221], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[99] }, /* unop_list[222]  */
	{ (OP*)&cop_list[48], (OP*)&cop_list[48], INT2PTR(void*,OP_ENTERSUB), 104, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[224] }, /* unop_list[223]  */
	{ (OP*)&unop_list[223], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[100] }, /* unop_list[224]  */
	{ (OP*)&unop_list[224], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[247] }, /* unop_list[225]  */
	{ (OP*)&cop_list[49], (OP*)&cop_list[49], INT2PTR(void*,OP_ENTERSUB), 105, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[227] }, /* unop_list[226]  */
	{ (OP*)&unop_list[226], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[102] }, /* unop_list[227]  */
	{ (OP*)&unop_list[227], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[251] }, /* unop_list[228]  */
	{ (OP*)&unop_list[222], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[255] }, /* unop_list[229]  */
	{ (OP*)&listop_list[15], 0, INT2PTR(void*,OP_ENTERSUB), 109, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[231] }, /* unop_list[230]  */
	{ (OP*)&unop_list[230], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[105] }, /* unop_list[231]  */
	{ (OP*)&cop_list[52], (OP*)&cop_list[52], INT2PTR(void*,OP_ENTERSUB), 107, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[233] }, /* unop_list[232]  */
	{ (OP*)&unop_list[232], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[106] }, /* unop_list[233]  */
	{ (OP*)&unop_list[233], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[259] }, /* unop_list[234]  */
	{ (OP*)&cop_list[53], (OP*)&cop_list[53], INT2PTR(void*,OP_ENTERSUB), 108, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[236] }, /* unop_list[235]  */
	{ (OP*)&unop_list[235], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[108] }, /* unop_list[236]  */
	{ (OP*)&unop_list[236], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[263] }, /* unop_list[237]  */
	{ (OP*)&unop_list[231], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[267] }, /* unop_list[238]  */
	{ (OP*)&svop_list[268], (OP*)&svop_list[268], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[208] }, /* unop_list[239]  */
	{ (OP*)&binop_list[57], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[269] }, /* unop_list[240]  */
	{ (OP*)&binop_list[60], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[6] }, /* unop_list[241]  */
	{ (OP*)&svop_list[272], (OP*)&svop_list[272], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[271] }, /* unop_list[242]  */
	{ (OP*)&binop_list[62], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[274] }, /* unop_list[243]  */
	{ (OP*)&listop_list[19], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[7] }, /* unop_list[244]  */
	{ (OP*)&svop_list[276], (OP*)&svop_list[276], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[275] }, /* unop_list[245]  */
	{ &op_list[120], (OP*)&unop_list[247], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[119] }, /* unop_list[246]  */
	{ (OP*)&binop_list[64], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xbf, 0x0, &op_list[120] }, /* unop_list[247]  */
	{ (OP*)&unop_list[246], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x87, 0x1, (OP*)&listop_list[20] }, /* unop_list[248]  */
	{ (OP*)&listop_list[20], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x1, (OP*)&logop_list[8] }, /* unop_list[249]  */
	{ (OP*)&svop_list[278], (OP*)&svop_list[278], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[277] }, /* unop_list[250]  */
	{ (OP*)&listop_list[21], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[122] }, /* unop_list[251]  */
	{ (OP*)&unop_list[249], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&logop_list[9] }, /* unop_list[252]  */
	{ (OP*)&svop_list[283], (OP*)&svop_list[283], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[282] }, /* unop_list[253]  */
	{ (OP*)&listop_list[23], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[123] }, /* unop_list[254]  */
	{ (OP*)&listop_list[24], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[125] }, /* unop_list[255]  */
	{ (OP*)&cop_list[67], (OP*)&cop_list[67], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[10] }, /* unop_list[256]  */
	{ (OP*)&svop_list[291], (OP*)&svop_list[291], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[290] }, /* unop_list[257]  */
	{ (OP*)&listop_list[25], 0, INT2PTR(void*,OP_ENTERSUB), 117, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[259] }, /* unop_list[258]  */
	{ (OP*)&unop_list[258], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[130] }, /* unop_list[259]  */
	{ (OP*)&cop_list[65], (OP*)&cop_list[65], INT2PTR(void*,OP_ENTERSUB), 115, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[261] }, /* unop_list[260]  */
	{ (OP*)&unop_list[260], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[131] }, /* unop_list[261]  */
	{ (OP*)&unop_list[261], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[295] }, /* unop_list[262]  */
	{ (OP*)&cop_list[66], (OP*)&cop_list[66], INT2PTR(void*,OP_ENTERSUB), 116, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[264] }, /* unop_list[263]  */
	{ (OP*)&unop_list[263], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[133] }, /* unop_list[264]  */
	{ (OP*)&unop_list[264], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[299] }, /* unop_list[265]  */
	{ (OP*)&unop_list[259], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[303] }, /* unop_list[266]  */
	{ (OP*)&cop_list[71], (OP*)&cop_list[71], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[11] }, /* unop_list[267]  */
	{ (OP*)&svop_list[305], (OP*)&svop_list[305], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[304] }, /* unop_list[268]  */
	{ (OP*)&listop_list[26], 0, INT2PTR(void*,OP_ENTERSUB), 120, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[270] }, /* unop_list[269]  */
	{ (OP*)&unop_list[269], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[137] }, /* unop_list[270]  */
	{ (OP*)&cop_list[69], (OP*)&cop_list[69], INT2PTR(void*,OP_ENTERSUB), 118, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[272] }, /* unop_list[271]  */
	{ (OP*)&unop_list[271], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[138] }, /* unop_list[272]  */
	{ (OP*)&unop_list[272], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[309] }, /* unop_list[273]  */
	{ (OP*)&cop_list[70], (OP*)&cop_list[70], INT2PTR(void*,OP_ENTERSUB), 119, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[275] }, /* unop_list[274]  */
	{ (OP*)&unop_list[274], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[140] }, /* unop_list[275]  */
	{ (OP*)&unop_list[275], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[313] }, /* unop_list[276]  */
	{ (OP*)&unop_list[270], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[317] }, /* unop_list[277]  */
	{ (OP*)&listop_list[27], 0, INT2PTR(void*,OP_ENTERSUB), 123, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[279] }, /* unop_list[278]  */
	{ (OP*)&unop_list[278], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[143] }, /* unop_list[279]  */
	{ (OP*)&cop_list[73], (OP*)&cop_list[73], INT2PTR(void*,OP_ENTERSUB), 121, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[281] }, /* unop_list[280]  */
	{ (OP*)&unop_list[280], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[144] }, /* unop_list[281]  */
	{ (OP*)&unop_list[281], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[321] }, /* unop_list[282]  */
	{ (OP*)&cop_list[74], (OP*)&cop_list[74], INT2PTR(void*,OP_ENTERSUB), 122, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[284] }, /* unop_list[283]  */
	{ (OP*)&unop_list[283], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[146] }, /* unop_list[284]  */
	{ (OP*)&unop_list[284], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[325] }, /* unop_list[285]  */
	{ (OP*)&unop_list[279], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[329] }, /* unop_list[286]  */
	{ (OP*)&svop_list[330], (OP*)&svop_list[330], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[270] }, /* unop_list[287]  */
	{ (OP*)&binop_list[69], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[331] }, /* unop_list[288]  */
	{ (OP*)&binop_list[71], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&svop_list[333] }, /* unop_list[289]  */
	{ &op_list[150], (OP*)&unop_list[291], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[149] }, /* unop_list[290]  */
	{ (OP*)&binop_list[72], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[150] }, /* unop_list[291]  */
	{ (OP*)&unop_list[290], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x1, (OP*)&logop_list[12] }, /* unop_list[292]  */
	{ (OP*)&svop_list[335], (OP*)&svop_list[335], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[334] }, /* unop_list[293]  */
	{ (OP*)&unop_list[292], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[151] }, /* unop_list[294]  */
	{ (OP*)&binop_list[72], 0, INT2PTR(void*,OP_RV2AV), 124, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[339] }, /* unop_list[295]  */
	{ (OP*)&cop_list[78], (OP*)&cop_list[78], INT2PTR(void*,OP_ENTERSUB), 128, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[297] }, /* unop_list[296]  */
	{ (OP*)&unop_list[296], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[152] }, /* unop_list[297]  */
	{ (OP*)&listop_list[28], 0, INT2PTR(void*,OP_RV2AV), 126, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[340] }, /* unop_list[298]  */
	{ (OP*)&unop_list[297], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[345] }, /* unop_list[299]  */
	{ &op_list[155], (OP*)&unop_list[301], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[154] }, /* unop_list[300]  */
	{ (OP*)&binop_list[74], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[155] }, /* unop_list[301]  */
	{ (OP*)&unop_list[300], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x1, (OP*)&logop_list[13] }, /* unop_list[302]  */
	{ (OP*)&svop_list[347], (OP*)&unop_list[304], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[346] }, /* unop_list[303]  */
	{ (OP*)&binop_list[75], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[347] }, /* unop_list[304]  */
	{ (OP*)&unop_list[302], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[156] }, /* unop_list[305]  */
	{ (OP*)&binop_list[74], 0, INT2PTR(void*,OP_RV2AV), 129, 135, 0, 0, 0, 1, 0, 0, 0, 0xb7, 0x1, (OP*)&svop_list[351] }, /* unop_list[306]  */
	{ (OP*)&cop_list[80], (OP*)&cop_list[80], INT2PTR(void*,OP_ENTERSUB), 133, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[308] }, /* unop_list[307]  */
	{ (OP*)&unop_list[307], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[157] }, /* unop_list[308]  */
	{ (OP*)&listop_list[29], 0, INT2PTR(void*,OP_RV2AV), 131, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[352] }, /* unop_list[309]  */
	{ (OP*)&unop_list[308], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[357] }, /* unop_list[310]  */
	{ (OP*)&cop_list[81], (OP*)&cop_list[81], INT2PTR(void*,OP_ENTERSUB), 135, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[312] }, /* unop_list[311]  */
	{ (OP*)&unop_list[311], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[159] }, /* unop_list[312]  */
	{ (OP*)&unop_list[312], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[362] }, /* unop_list[313]  */
	{ (OP*)&cop_list[82], (OP*)&cop_list[82], INT2PTR(void*,OP_ENTERSUB), 137, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[315] }, /* unop_list[314]  */
	{ (OP*)&unop_list[314], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[160] }, /* unop_list[315]  */
	{ (OP*)&unop_list[315], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[367] }, /* unop_list[316]  */
	{ (OP*)&cop_list[83], (OP*)&cop_list[83], INT2PTR(void*,OP_ENTERSUB), 139, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[318] }, /* unop_list[317]  */
	{ (OP*)&unop_list[317], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[161] }, /* unop_list[318]  */
	{ (OP*)&unop_list[318], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[372] }, /* unop_list[319]  */
	{ (OP*)&cop_list[84], (OP*)&cop_list[84], INT2PTR(void*,OP_ENTERSUB), 141, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[321] }, /* unop_list[320]  */
	{ (OP*)&unop_list[320], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[162] }, /* unop_list[321]  */
	{ (OP*)&unop_list[321], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[377] }, /* unop_list[322]  */
	{ (OP*)&cop_list[85], (OP*)&cop_list[85], INT2PTR(void*,OP_ENTERSUB), 143, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[324] }, /* unop_list[323]  */
	{ (OP*)&unop_list[323], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[163] }, /* unop_list[324]  */
	{ (OP*)&unop_list[324], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[382] }, /* unop_list[325]  */
	{ (OP*)&cop_list[86], (OP*)&cop_list[86], INT2PTR(void*,OP_ENTERSUB), 145, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[327] }, /* unop_list[326]  */
	{ (OP*)&unop_list[326], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[164] }, /* unop_list[327]  */
	{ (OP*)&unop_list[327], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[387] }, /* unop_list[328]  */
	{ (OP*)&cop_list[87], (OP*)&cop_list[87], INT2PTR(void*,OP_ENTERSUB), 147, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[330] }, /* unop_list[329]  */
	{ (OP*)&unop_list[329], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[165] }, /* unop_list[330]  */
	{ (OP*)&unop_list[330], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[392] }, /* unop_list[331]  */
	{ (OP*)&binop_list[76], 0, INT2PTR(void*,OP_ENTERSUB), 167, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[333] }, /* unop_list[332]  */
	{ (OP*)&unop_list[332], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[166] }, /* unop_list[333]  */
	{ &op_list[168], (OP*)&unop_list[335], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[167] }, /* unop_list[334]  */
	{ (OP*)&binop_list[77], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[168] }, /* unop_list[335]  */
	{ &op_list[173], (OP*)&unop_list[337], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[172] }, /* unop_list[336]  */
	{ (OP*)&binop_list[78], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[173] }, /* unop_list[337]  */
	{ &op_list[175], &op_list[175], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[176] }, /* unop_list[338]  */
	{ &op_list[179], (OP*)&unop_list[340], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[178] }, /* unop_list[339]  */
	{ (OP*)&binop_list[79], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[179] }, /* unop_list[340]  */
	{ &op_list[181], (OP*)&unop_list[342], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[180] }, /* unop_list[341]  */
	{ (OP*)&binop_list[80], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[181] }, /* unop_list[342]  */
	{ (OP*)&cop_list[92], (OP*)&cop_list[92], INT2PTR(void*,OP_ENTERSUB), 154, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[344] }, /* unop_list[343]  */
	{ (OP*)&unop_list[343], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[185] }, /* unop_list[344]  */
	{ (OP*)&svop_list[401], (OP*)&svop_list[401], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[186] }, /* unop_list[345]  */
	{ (OP*)&svop_list[402], (OP*)&svop_list[402], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[187] }, /* unop_list[346]  */
	{ (OP*)&unop_list[344], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[403] }, /* unop_list[347]  */
	{ (OP*)&cop_list[93], (OP*)&cop_list[93], INT2PTR(void*,OP_ENTERSUB), 155, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[349] }, /* unop_list[348]  */
	{ (OP*)&unop_list[348], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[188] }, /* unop_list[349]  */
	{ (OP*)&svop_list[404], (OP*)&svop_list[404], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[189] }, /* unop_list[350]  */
	{ (OP*)&unop_list[349], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[407] }, /* unop_list[351]  */
	{ &op_list[191], (OP*)&unop_list[353], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[190] }, /* unop_list[352]  */
	{ (OP*)&binop_list[81], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[191] }, /* unop_list[353]  */
	{ (OP*)&unop_list[352], 0, INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&listop_list[32] }, /* unop_list[354]  */
	{ (OP*)&cop_list[95], (OP*)&cop_list[95], INT2PTR(void*,OP_ENTERSUB), 158, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[356] }, /* unop_list[355]  */
	{ (OP*)&unop_list[355], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[196] }, /* unop_list[356]  */
	{ (OP*)&unop_list[356], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[413] }, /* unop_list[357]  */
	{ &op_list[200], (OP*)&unop_list[359], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[199] }, /* unop_list[358]  */
	{ (OP*)&binop_list[82], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[200] }, /* unop_list[359]  */
	{ &op_list[203], (OP*)&unop_list[361], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[202] }, /* unop_list[360]  */
	{ (OP*)&binop_list[83], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[203] }, /* unop_list[361]  */
	{ (OP*)&unop_list[360], 0, INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&listop_list[34] }, /* unop_list[362]  */
	{ (OP*)&cop_list[98], (OP*)&cop_list[98], INT2PTR(void*,OP_ENTERSUB), 163, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[364] }, /* unop_list[363]  */
	{ (OP*)&unop_list[363], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[208] }, /* unop_list[364]  */
	{ (OP*)&unop_list[364], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[421] }, /* unop_list[365]  */
	{ &op_list[213], &op_list[213], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&binop_list[85] }, /* unop_list[366]  */
	{ &op_list[212], (OP*)&unop_list[368], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[211] }, /* unop_list[367]  */
	{ (OP*)&binop_list[85], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[212] }, /* unop_list[368]  */
	{ &op_list[212], 0, INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x1, (OP*)&svop_list[422] }, /* unop_list[369]  */
	{ (OP*)&unop_list[333], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[426] }, /* unop_list[370]  */
	{ (OP*)&binop_list[86], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[372] }, /* unop_list[371]  */
	{ (OP*)&unop_list[371], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[215] }, /* unop_list[372]  */
	{ (OP*)&cop_list[104], (OP*)&cop_list[104], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[374] }, /* unop_list[373]  */
	{ (OP*)&unop_list[373], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[216] }, /* unop_list[374]  */
	{ &op_list[218], (OP*)&unop_list[376], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[217] }, /* unop_list[375]  */
	{ (OP*)&binop_list[87], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[218] }, /* unop_list[376]  */
	{ (OP*)&unop_list[374], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[435] }, /* unop_list[377]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[37] }, /* unop_list[378]  */
	{ (OP*)&unop_list[378], 0, INT2PTR(void*,OP_ENTERSUB), 3, 185, 0, 0, 0, 1, 0, 0, 0, 0x44, 0x4, (OP*)&unop_list[380] }, /* unop_list[379]  */
	{ (OP*)&unop_list[379], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[219] }, /* unop_list[380]  */
	{ (OP*)&svop_list[433], (OP*)&svop_list[433], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[382] }, /* unop_list[381]  */
	{ (OP*)&svop_list[433], 0, INT2PTR(void*,OP_RV2AV), 2, 135, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[432] }, /* unop_list[382]  */
	{ (OP*)&unop_list[380], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[434] }, /* unop_list[383]  */
	{ (OP*)&cop_list[105], (OP*)&cop_list[105], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[385] }, /* unop_list[384]  */
	{ (OP*)&unop_list[384], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[223] }, /* unop_list[385]  */
	{ &op_list[226], (OP*)&unop_list[387], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[225] }, /* unop_list[386]  */
	{ (OP*)&binop_list[89], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[226] }, /* unop_list[387]  */
	{ &op_list[225], (OP*)&binop_list[89], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&svop_list[437] }, /* unop_list[388]  */
	{ (OP*)&unop_list[385], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[442] }, /* unop_list[389]  */
	{ (OP*)&cop_list[106], (OP*)&cop_list[106], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[391] }, /* unop_list[390]  */
	{ (OP*)&unop_list[390], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[227] }, /* unop_list[391]  */
	{ &op_list[230], (OP*)&unop_list[393], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[229] }, /* unop_list[392]  */
	{ (OP*)&binop_list[90], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[230] }, /* unop_list[393]  */
	{ (OP*)&unop_list[391], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[448] }, /* unop_list[394]  */
	{ (OP*)&cop_list[107], (OP*)&cop_list[107], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[396] }, /* unop_list[395]  */
	{ (OP*)&unop_list[395], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[231] }, /* unop_list[396]  */
	{ &op_list[233], (OP*)&unop_list[398], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[232] }, /* unop_list[397]  */
	{ (OP*)&binop_list[91], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[233] }, /* unop_list[398]  */
	{ &op_list[235], (OP*)&unop_list[400], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[234] }, /* unop_list[399]  */
	{ (OP*)&binop_list[92], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[235] }, /* unop_list[400]  */
	{ (OP*)&unop_list[396], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[454] }, /* unop_list[401]  */
	{ (OP*)&cop_list[109], (OP*)&cop_list[109], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[403] }, /* unop_list[402]  */
	{ (OP*)&unop_list[402], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[237] }, /* unop_list[403]  */
	{ (OP*)&svop_list[460], (OP*)&unop_list[407], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xa7, 0x1, (OP*)&listop_list[40] }, /* unop_list[404]  */
	{ &op_list[239], (OP*)&unop_list[406], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[238] }, /* unop_list[405]  */
	{ (OP*)&binop_list[93], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[239] }, /* unop_list[406]  */
	{ (OP*)&unop_list[403], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[460] }, /* unop_list[407]  */
	{ (OP*)&cop_list[110], (OP*)&cop_list[110], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[409] }, /* unop_list[408]  */
	{ (OP*)&unop_list[408], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[240] }, /* unop_list[409]  */
	{ &op_list[242], (OP*)&unop_list[411], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[241] }, /* unop_list[410]  */
	{ (OP*)&binop_list[94], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[242] }, /* unop_list[411]  */
	{ (OP*)&unop_list[409], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[466] }, /* unop_list[412]  */
	{ &op_list[244], (OP*)&unop_list[414], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[243] }, /* unop_list[413]  */
	{ (OP*)&binop_list[95], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[244] }, /* unop_list[414]  */
	{ (OP*)&unop_list[372], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[470] }, /* unop_list[415]  */
	{ (OP*)&binop_list[96], 0, INT2PTR(void*,OP_ENTERSUB), 173, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[417] }, /* unop_list[416]  */
	{ (OP*)&unop_list[416], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[246] }, /* unop_list[417]  */
	{ (OP*)&listop_list[42], 0, INT2PTR(void*,OP_RV2AV), 171, 135, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&listop_list[43] }, /* unop_list[418]  */
	{ &op_list[251], (OP*)&unop_list[420], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[250] }, /* unop_list[419]  */
	{ (OP*)&binop_list[97], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[251] }, /* unop_list[420]  */
	{ (OP*)&unop_list[417], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[479] }, /* unop_list[421]  */
	{ (OP*)&cop_list[115], (OP*)&cop_list[115], INT2PTR(void*,OP_ENTERSUB), 175, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[423] }, /* unop_list[422]  */
	{ (OP*)&unop_list[422], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[252] }, /* unop_list[423]  */
	{ &op_list[255], (OP*)&unop_list[425], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[254] }, /* unop_list[424]  */
	{ (OP*)&binop_list[98], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[255] }, /* unop_list[425]  */
	{ (OP*)&unop_list[423], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[488] }, /* unop_list[426]  */
	{ &op_list[257], (OP*)&unop_list[428], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[256] }, /* unop_list[427]  */
	{ (OP*)&binop_list[99], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[257] }, /* unop_list[428]  */
	{ (OP*)&cop_list[117], (OP*)&cop_list[117], INT2PTR(void*,OP_ENTERSUB), 179, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[430] }, /* unop_list[429]  */
	{ (OP*)&unop_list[429], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[259] }, /* unop_list[430]  */
	{ (OP*)&unop_list[430], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[494] }, /* unop_list[431]  */
	{ &op_list[263], (OP*)&unop_list[433], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[262] }, /* unop_list[432]  */
	{ (OP*)&binop_list[100], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[263] }, /* unop_list[433]  */
	{ (OP*)&svop_list[495], (OP*)&svop_list[495], INT2PTR(void*,OP_AV2ARYLEN), 0, 16, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[266] }, /* unop_list[434]  */
	{ (OP*)&unop_list[1], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[496] }, /* unop_list[435]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[47] }, /* unop_list[436]  */
	{ (OP*)&unop_list[436], 0, INT2PTR(void*,OP_REQUIRE), 0, 339, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[497] }, /* unop_list[437]  */
	{ (OP*)&svop_list[498], (OP*)&svop_list[498], INT2PTR(void*,OP_RV2AV), 1, 135, 0, 0, 0, 1, 0, 0, 0, 0x37, 0x1, (OP*)&svop_list[499] }, /* unop_list[438]  */
};

Static BINOP binop_list[101] = {
	{ (OP*)&listop_list[0], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[0], (OP*)&listop_list[1] }, /* binop_list[0]  */
	{ (OP*)&cop_list[3], (OP*)&cop_list[3], INT2PTR(void*,OP_AASSIGN), 3, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[5], (OP*)&unop_list[6] }, /* binop_list[1]  */
	{ (OP*)&svop_list[10], (OP*)&svop_list[10], INT2PTR(void*,OP_AELEM), 0, 138, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x42, (OP*)&unop_list[10], (OP*)&svop_list[9] }, /* binop_list[2]  */
	{ (OP*)&svop_list[16], (OP*)&svop_list[16], INT2PTR(void*,OP_AELEM), 0, 138, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x42, (OP*)&unop_list[14], (OP*)&svop_list[15] }, /* binop_list[3]  */
	{ (OP*)&cop_list[6], (OP*)&cop_list[6], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&listop_list[2], (OP*)&unop_list[17] }, /* binop_list[4]  */
	{ (OP*)&cop_list[8], (OP*)&cop_list[8], INT2PTR(void*,OP_AASSIGN), 9, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[22], (OP*)&unop_list[23] }, /* binop_list[5]  */
	{ (OP*)&svop_list[43], 0, INT2PTR(void*,OP_CONCAT), 15, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[7], (OP*)&unop_list[34] }, /* binop_list[6]  */
	{ (OP*)&svop_list[42], (OP*)&unop_list[34], INT2PTR(void*,OP_CONCAT), 14, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[8], (OP*)&svop_list[41] }, /* binop_list[7]  */
	{ (OP*)&svop_list[41], (OP*)&svop_list[41], INT2PTR(void*,OP_CONCAT), 13, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[9], (OP*)&unop_list[33] }, /* binop_list[8]  */
	{ (OP*)&svop_list[40], (OP*)&unop_list[33], INT2PTR(void*,OP_CONCAT), 12, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[10], (OP*)&svop_list[39] }, /* binop_list[9]  */
	{ (OP*)&svop_list[39], (OP*)&svop_list[39], INT2PTR(void*,OP_CONCAT), 11, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[11], (OP*)&unop_list[32] }, /* binop_list[10]  */
	{ (OP*)&svop_list[38], (OP*)&unop_list[32], INT2PTR(void*,OP_CONCAT), 10, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[31], (OP*)&svop_list[37] }, /* binop_list[11]  */
	{ (OP*)&cop_list[10], (OP*)&cop_list[10], INT2PTR(void*,OP_AASSIGN), 19, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[36], (OP*)&unop_list[37] }, /* binop_list[12]  */
	{ (OP*)&svop_list[57], 0, INT2PTR(void*,OP_CONCAT), 23, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[14], (OP*)&unop_list[46] }, /* binop_list[13]  */
	{ (OP*)&svop_list[56], (OP*)&unop_list[46], INT2PTR(void*,OP_CONCAT), 22, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[15], (OP*)&svop_list[55] }, /* binop_list[14]  */
	{ (OP*)&svop_list[55], (OP*)&svop_list[55], INT2PTR(void*,OP_CONCAT), 21, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[16], (OP*)&unop_list[45] }, /* binop_list[15]  */
	{ (OP*)&svop_list[54], (OP*)&unop_list[45], INT2PTR(void*,OP_CONCAT), 20, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[44], (OP*)&svop_list[53] }, /* binop_list[16]  */
	{ (OP*)&cop_list[12], (OP*)&cop_list[12], INT2PTR(void*,OP_AASSIGN), 26, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[48], (OP*)&unop_list[49] }, /* binop_list[17]  */
	{ (OP*)&svop_list[72], 0, INT2PTR(void*,OP_CONCAT), 30, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[19], (OP*)&unop_list[61] }, /* binop_list[18]  */
	{ (OP*)&svop_list[71], (OP*)&unop_list[61], INT2PTR(void*,OP_CONCAT), 29, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[20], (OP*)&svop_list[70] }, /* binop_list[19]  */
	{ (OP*)&svop_list[70], (OP*)&svop_list[70], INT2PTR(void*,OP_CONCAT), 28, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[21], (OP*)&unop_list[60] }, /* binop_list[20]  */
	{ (OP*)&svop_list[69], (OP*)&unop_list[60], INT2PTR(void*,OP_CONCAT), 27, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[59], (OP*)&svop_list[68] }, /* binop_list[21]  */
	{ (OP*)&cop_list[14], (OP*)&cop_list[14], INT2PTR(void*,OP_AASSIGN), 33, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[63], (OP*)&unop_list[64] }, /* binop_list[22]  */
	{ (OP*)&svop_list[83], 0, INT2PTR(void*,OP_CONCAT), 35, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[24], (OP*)&unop_list[73] }, /* binop_list[23]  */
	{ (OP*)&svop_list[82], (OP*)&unop_list[73], INT2PTR(void*,OP_CONCAT), 34, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[72], (OP*)&svop_list[81] }, /* binop_list[24]  */
	{ (OP*)&cop_list[16], (OP*)&cop_list[16], INT2PTR(void*,OP_AASSIGN), 39, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[75], (OP*)&unop_list[76] }, /* binop_list[25]  */
	{ &op_list[26], 0, INT2PTR(void*,OP_AASSIGN), 38, 38, 0, 0, 0, 1, 0, 0, 0, 0x47, 0x40, (OP*)&unop_list[77], (OP*)&unop_list[78] }, /* binop_list[26]  */
	{ (OP*)&svop_list[96], 0, INT2PTR(void*,OP_CONCAT), 41, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[28], (OP*)&unop_list[89] }, /* binop_list[27]  */
	{ (OP*)&svop_list[95], (OP*)&unop_list[89], INT2PTR(void*,OP_CONCAT), 40, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[88], (OP*)&svop_list[94] }, /* binop_list[28]  */
	{ (OP*)&cop_list[18], (OP*)&cop_list[18], INT2PTR(void*,OP_AASSIGN), 44, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[91], (OP*)&unop_list[92] }, /* binop_list[29]  */
	{ (OP*)&svop_list[114], (OP*)&svop_list[114], INT2PTR(void*,OP_AELEM), 0, 138, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x42, (OP*)&unop_list[104], (OP*)&svop_list[113] }, /* binop_list[30]  */
	{ (OP*)&cop_list[23], (OP*)&cop_list[23], INT2PTR(void*,OP_AASSIGN), 50, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[114], (OP*)&unop_list[115] }, /* binop_list[31]  */
	{ (OP*)&cop_list[24], (OP*)&cop_list[24], INT2PTR(void*,OP_AASSIGN), 52, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[117], (OP*)&unop_list[118] }, /* binop_list[32]  */
	{ (OP*)&svop_list[148], 0, INT2PTR(void*,OP_CONCAT), 58, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[34], (OP*)&unop_list[130] }, /* binop_list[33]  */
	{ (OP*)&svop_list[147], (OP*)&unop_list[130], INT2PTR(void*,OP_CONCAT), 57, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[35], (OP*)&svop_list[146] }, /* binop_list[34]  */
	{ (OP*)&svop_list[146], (OP*)&svop_list[146], INT2PTR(void*,OP_CONCAT), 56, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[36], (OP*)&unop_list[129] }, /* binop_list[35]  */
	{ (OP*)&svop_list[145], (OP*)&unop_list[129], INT2PTR(void*,OP_CONCAT), 55, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[37], (OP*)&svop_list[144] }, /* binop_list[36]  */
	{ (OP*)&svop_list[144], (OP*)&svop_list[144], INT2PTR(void*,OP_CONCAT), 54, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[38], (OP*)&unop_list[128] }, /* binop_list[37]  */
	{ (OP*)&svop_list[143], (OP*)&unop_list[128], INT2PTR(void*,OP_CONCAT), 53, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[127], (OP*)&svop_list[142] }, /* binop_list[38]  */
	{ (OP*)&cop_list[26], (OP*)&cop_list[26], INT2PTR(void*,OP_AASSIGN), 62, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[132], (OP*)&unop_list[133] }, /* binop_list[39]  */
	{ (OP*)&cop_list[27], (OP*)&cop_list[27], INT2PTR(void*,OP_AASSIGN), 64, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[135], (OP*)&unop_list[136] }, /* binop_list[40]  */
	{ (OP*)&cop_list[32], (OP*)&cop_list[32], INT2PTR(void*,OP_AASSIGN), 72, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[162], (OP*)&unop_list[163] }, /* binop_list[41]  */
	{ &op_list[55], 0, INT2PTR(void*,OP_AASSIGN), 71, 38, 0, 0, 0, 1, 0, 0, 0, 0x47, 0x0, (OP*)&unop_list[164], (OP*)&unop_list[165] }, /* binop_list[42]  */
	{ (OP*)&cop_list[34], (OP*)&cop_list[34], INT2PTR(void*,OP_AASSIGN), 80, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[173], (OP*)&unop_list[174] }, /* binop_list[43]  */
	{ &op_list[61], 0, INT2PTR(void*,OP_AASSIGN), 79, 38, 0, 0, 0, 1, 0, 0, 0, 0x47, 0x0, (OP*)&unop_list[175], (OP*)&unop_list[176] }, /* binop_list[44]  */
	{ (OP*)&cop_list[36], (OP*)&cop_list[36], INT2PTR(void*,OP_AASSIGN), 88, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[184], (OP*)&unop_list[185] }, /* binop_list[45]  */
	{ (OP*)&cop_list[37], (OP*)&cop_list[37], INT2PTR(void*,OP_AASSIGN), 92, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[187], (OP*)&unop_list[188] }, /* binop_list[46]  */
	{ (OP*)&cop_list[54], (OP*)&cop_list[54], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[1], (OP*)&listop_list[9] }, /* binop_list[47]  */
	{ (OP*)&binop_list[47], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[2], (OP*)&unop_list[194] }, /* binop_list[48]  */
	{ (OP*)&logop_list[0], (OP*)&listop_list[11], INT2PTR(void*,OP_LT), 0, 71, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[195], (OP*)&svop_list[210] }, /* binop_list[49]  */
	{ &op_list[80], &op_list[80], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[211], (OP*)&unop_list[196] }, /* binop_list[50]  */
	{ (OP*)&logop_list[1], (OP*)&listop_list[15], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[198], (OP*)&svop_list[214] }, /* binop_list[51]  */
	{ (OP*)&cop_list[42], (OP*)&cop_list[42], INT2PTR(void*,OP_AASSIGN), 100, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[199], (OP*)&unop_list[200] }, /* binop_list[52]  */
	{ (OP*)&logop_list[2], (OP*)&unop_list[203], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[202], (OP*)&svop_list[216] }, /* binop_list[53]  */
	{ (OP*)&logop_list[3], (OP*)&unop_list[206], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[205], (OP*)&svop_list[221] }, /* binop_list[54]  */
	{ (OP*)&logop_list[4], (OP*)&listop_list[13], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[209], (OP*)&svop_list[229] }, /* binop_list[55]  */
	{ (OP*)&logop_list[5], (OP*)&listop_list[14], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[220], (OP*)&svop_list[243] }, /* binop_list[56]  */
	{ &op_list[82], &op_list[82], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&binop_list[58], (OP*)&unop_list[240] }, /* binop_list[57]  */
	{ (OP*)&svop_list[269], (OP*)&unop_list[240], INT2PTR(void*,OP_ADD), 99, 63, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[239], (OP*)&svop_list[268] }, /* binop_list[58]  */
	{ (OP*)&cop_list[75], (OP*)&cop_list[75], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[3], (OP*)&listop_list[16] }, /* binop_list[59]  */
	{ (OP*)&binop_list[59], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[4], (OP*)&unop_list[241] }, /* binop_list[60]  */
	{ (OP*)&logop_list[6], (OP*)&listop_list[18], INT2PTR(void*,OP_LT), 0, 71, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[242], (OP*)&svop_list[272] }, /* binop_list[61]  */
	{ &op_list[116], &op_list[116], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[273], (OP*)&unop_list[243] }, /* binop_list[62]  */
	{ (OP*)&logop_list[7], (OP*)&listop_list[27], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[245], (OP*)&svop_list[276] }, /* binop_list[63]  */
	{ (OP*)&cop_list[63], (OP*)&cop_list[63], INT2PTR(void*,OP_AASSIGN), 114, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[246], (OP*)&unop_list[247] }, /* binop_list[64]  */
	{ (OP*)&logop_list[8], (OP*)&listop_list[21], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[250], (OP*)&svop_list[278] }, /* binop_list[65]  */
	{ (OP*)&logop_list[9], 0, INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[253], (OP*)&svop_list[283] }, /* binop_list[66]  */
	{ (OP*)&logop_list[10], (OP*)&listop_list[25], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[257], (OP*)&svop_list[291] }, /* binop_list[67]  */
	{ (OP*)&logop_list[11], (OP*)&listop_list[26], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[268], (OP*)&svop_list[305] }, /* binop_list[68]  */
	{ &op_list[118], &op_list[118], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&binop_list[70], (OP*)&unop_list[288] }, /* binop_list[69]  */
	{ (OP*)&svop_list[331], (OP*)&unop_list[288], INT2PTR(void*,OP_ADD), 113, 63, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[287], (OP*)&svop_list[330] }, /* binop_list[70]  */
	{ (OP*)&cop_list[76], (OP*)&cop_list[76], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[332], (OP*)&unop_list[289] }, /* binop_list[71]  */
	{ (OP*)&cop_list[77], (OP*)&cop_list[77], INT2PTR(void*,OP_AASSIGN), 125, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[290], (OP*)&unop_list[291] }, /* binop_list[72]  */
	{ (OP*)&logop_list[12], (OP*)&unop_list[294], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[293], (OP*)&svop_list[335] }, /* binop_list[73]  */
	{ (OP*)&cop_list[79], (OP*)&cop_list[79], INT2PTR(void*,OP_AASSIGN), 130, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&unop_list[300], (OP*)&unop_list[301] }, /* binop_list[74]  */
	{ (OP*)&logop_list[13], (OP*)&unop_list[305], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[303], (OP*)&unop_list[304] }, /* binop_list[75]  */
	{ (OP*)&cop_list[100], (OP*)&cop_list[100], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[5], (OP*)&listop_list[30] }, /* binop_list[76]  */
	{ (OP*)&cop_list[89], (OP*)&cop_list[89], INT2PTR(void*,OP_AASSIGN), 149, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[334], (OP*)&unop_list[335] }, /* binop_list[77]  */
	{ (OP*)&cop_list[90], (OP*)&cop_list[90], INT2PTR(void*,OP_AASSIGN), 151, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[336], (OP*)&unop_list[337] }, /* binop_list[78]  */
	{ (OP*)&cop_list[91], (OP*)&cop_list[91], INT2PTR(void*,OP_AASSIGN), 153, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[339], (OP*)&unop_list[340] }, /* binop_list[79]  */
	{ &op_list[179], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[341], (OP*)&unop_list[342] }, /* binop_list[80]  */
	{ (OP*)&cop_list[94], (OP*)&cop_list[94], INT2PTR(void*,OP_AASSIGN), 156, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[352], (OP*)&unop_list[353] }, /* binop_list[81]  */
	{ (OP*)&cop_list[96], (OP*)&cop_list[96], INT2PTR(void*,OP_AASSIGN), 160, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[358], (OP*)&unop_list[359] }, /* binop_list[82]  */
	{ (OP*)&cop_list[97], (OP*)&cop_list[97], INT2PTR(void*,OP_AASSIGN), 161, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[360], (OP*)&unop_list[361] }, /* binop_list[83]  */
	{ (OP*)&cop_list[99], (OP*)&cop_list[99], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[366], &op_list[213] }, /* binop_list[84]  */
	{ &op_list[213], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[367], (OP*)&unop_list[368] }, /* binop_list[85]  */
	{ (OP*)&cop_list[111], (OP*)&cop_list[111], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[6], (OP*)&listop_list[36] }, /* binop_list[86]  */
	{ (OP*)&svop_list[435], (OP*)&unop_list[377], INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x2, (OP*)&unop_list[375], (OP*)&unop_list[376] }, /* binop_list[87]  */
	{ (OP*)&cop_list[103], (OP*)&cop_list[103], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, &op_list[220], &op_list[221] }, /* binop_list[88]  */
	{ (OP*)&listop_list[38], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x2, (OP*)&unop_list[386], (OP*)&unop_list[387] }, /* binop_list[89]  */
	{ (OP*)&listop_list[39], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[392], (OP*)&unop_list[393] }, /* binop_list[90]  */
	{ (OP*)&svop_list[454], (OP*)&unop_list[401], INT2PTR(void*,OP_AASSIGN), 170, 38, 0, 0, 0, 1, 0, 0, 0, 0x67, 0x0, (OP*)&unop_list[397], (OP*)&unop_list[398] }, /* binop_list[91]  */
	{ &op_list[233], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[399], (OP*)&unop_list[400] }, /* binop_list[92]  */
	{ (OP*)&svop_list[460], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[405], (OP*)&unop_list[406] }, /* binop_list[93]  */
	{ (OP*)&svop_list[466], (OP*)&unop_list[412], INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x2, (OP*)&unop_list[410], (OP*)&unop_list[411] }, /* binop_list[94]  */
	{ (OP*)&svop_list[470], (OP*)&unop_list[415], INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x2, (OP*)&unop_list[413], (OP*)&unop_list[414] }, /* binop_list[95]  */
	{ (OP*)&cop_list[114], (OP*)&cop_list[114], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[7], (OP*)&listop_list[41] }, /* binop_list[96]  */
	{ (OP*)&listop_list[44], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[419], (OP*)&unop_list[420] }, /* binop_list[97]  */
	{ (OP*)&listop_list[45], 0, INT2PTR(void*,OP_LSLICE), 0, 159, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x2, (OP*)&unop_list[424], (OP*)&unop_list[425] }, /* binop_list[98]  */
	{ (OP*)&cop_list[116], (OP*)&cop_list[116], INT2PTR(void*,OP_AASSIGN), 177, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[427], (OP*)&unop_list[428] }, /* binop_list[99]  */
	{ (OP*)&cop_list[118], (OP*)&cop_list[118], INT2PTR(void*,OP_AASSIGN), 181, 38, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[432], (OP*)&unop_list[433] }, /* binop_list[100]  */
};

Static LOGOP logop_list[15] = {
	{ (OP*)&binop_list[48], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[49], &op_list[75] }, /* logop_list[0]  */
	{ (OP*)&listop_list[12], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[51], &op_list[81] }, /* logop_list[1]  */
	{ (OP*)&svop_list[220], 0, INT2PTR(void*,OP_COND_EXPR), 0, 180, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&binop_list[53], (OP*)&svop_list[217] }, /* logop_list[2]  */
	{ (OP*)&svop_list[225], 0, INT2PTR(void*,OP_COND_EXPR), 0, 180, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&binop_list[54], (OP*)&svop_list[222] }, /* logop_list[3]  */
	{ (OP*)&cop_list[46], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[55], &op_list[91] }, /* logop_list[4]  */
	{ (OP*)&cop_list[50], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[56], &op_list[98] }, /* logop_list[5]  */
	{ (OP*)&binop_list[60], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[61], &op_list[111] }, /* logop_list[6]  */
	{ (OP*)&listop_list[19], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[63], &op_list[117] }, /* logop_list[7]  */
	{ (OP*)&svop_list[282], 0, INT2PTR(void*,OP_COND_EXPR), 0, 180, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&binop_list[65], (OP*)&svop_list[279] }, /* logop_list[8]  */
	{ &op_list[124], 0, INT2PTR(void*,OP_COND_EXPR), 0, 180, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&listop_list[22], (OP*)&svop_list[284] }, /* logop_list[9]  */
	{ (OP*)&cop_list[67], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[67], &op_list[129] }, /* logop_list[10]  */
	{ (OP*)&cop_list[71], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[68], &op_list[136] }, /* logop_list[11]  */
	{ &op_list[150], 0, INT2PTR(void*,OP_OR), 0, 177, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&binop_list[73], (OP*)&svop_list[336] }, /* logop_list[12]  */
	{ &op_list[155], 0, INT2PTR(void*,OP_OR), 0, 177, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&binop_list[75], (OP*)&svop_list[348] }, /* logop_list[13]  */
	{ (OP*)&svop_list[442], (OP*)&unop_list[389], INT2PTR(void*,OP_GREPWHILE), 168, 170, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x0, (OP*)&listop_list[38], (OP*)&svop_list[437] }, /* logop_list[14]  */
};

Static LISTOP listop_list[49] = {
	{ 0, 0, INT2PTR(void*,OP_LEAVE), 1, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x40, &op_list[0], (OP*)&binop_list[0] }, /* listop_list[0]  */
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[0], (OP*)&unop_list[0] }, /* listop_list[1]  */
	{ (OP*)&svop_list[21], (OP*)&unop_list[17], INT2PTR(void*,OP_JOIN), 7, 157, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[7], (OP*)&unop_list[16] }, /* listop_list[2]  */
	{ &op_list[14], 0, INT2PTR(void*,OP_SPLIT), 18, 156, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x80, (OP*)&pmop_list[0], (OP*)&svop_list[47] }, /* listop_list[3]  */
	{ (OP*)&svop_list[182], (OP*)&svop_list[182], INT2PTR(void*,OP_JOIN), 75, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[59], (OP*)&unop_list[170] }, /* listop_list[4]  */
	{ (OP*)&svop_list[195], (OP*)&svop_list[195], INT2PTR(void*,OP_JOIN), 85, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[65], (OP*)&listop_list[6] }, /* listop_list[5]  */
	{ (OP*)&listop_list[5], 0, INT2PTR(void*,OP_JOIN), 84, 157, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[66], (OP*)&unop_list[181] }, /* listop_list[6]  */
	{ &op_list[66], (OP*)&listop_list[6], INT2PTR(void*,OP_JOIN), 82, 157, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[67], (OP*)&unop_list[182] }, /* listop_list[7]  */
	{ (OP*)&svop_list[204], (OP*)&svop_list[204], INT2PTR(void*,OP_JOIN), 94, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[74], (OP*)&unop_list[192] }, /* listop_list[8]  */
	{ (OP*)&binop_list[47], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[39], (OP*)&binop_list[48] }, /* listop_list[9]  */
	{ (OP*)&cop_list[40], (OP*)&cop_list[40], INT2PTR(void*,OP_LIST), 0, 158, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[76], &op_list[77] }, /* listop_list[10]  */
	{ (OP*)&unop_list[194], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&listop_list[12], &op_list[82] }, /* listop_list[11]  */
	{ (OP*)&svop_list[208], (OP*)&binop_list[57], INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[75], (OP*)&unop_list[197] }, /* listop_list[12]  */
	{ (OP*)&cop_list[46], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[91], (OP*)&unop_list[210] }, /* listop_list[13]  */
	{ (OP*)&cop_list[50], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[98], (OP*)&unop_list[221] }, /* listop_list[14]  */
	{ (OP*)&listop_list[12], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[81], (OP*)&unop_list[230] }, /* listop_list[15]  */
	{ (OP*)&binop_list[59], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[55], (OP*)&binop_list[60] }, /* listop_list[16]  */
	{ (OP*)&cop_list[56], (OP*)&cop_list[56], INT2PTR(void*,OP_LIST), 0, 158, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[112], &op_list[113] }, /* listop_list[17]  */
	{ (OP*)&unop_list[241], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&listop_list[19], &op_list[118] }, /* listop_list[18]  */
	{ (OP*)&svop_list[270], (OP*)&binop_list[69], INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[111], (OP*)&unop_list[244] }, /* listop_list[19]  */
	{ &op_list[120], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[121], (OP*)&unop_list[249] }, /* listop_list[20]  */
	{ (OP*)&unop_list[249], (OP*)&unop_list[252], INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, (OP*)&cop_list[59], (OP*)&unop_list[251] }, /* listop_list[21]  */
	{ (OP*)&logop_list[9], (OP*)&listop_list[23], INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[60], (OP*)&binop_list[66] }, /* listop_list[22]  */
	{ (OP*)&unop_list[252], (OP*)&listop_list[24], INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, (OP*)&cop_list[61], (OP*)&unop_list[254] }, /* listop_list[23]  */
	{ (OP*)&listop_list[20], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xf, 0x0, &op_list[124], (OP*)&unop_list[255] }, /* listop_list[24]  */
	{ (OP*)&cop_list[67], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[129], (OP*)&unop_list[258] }, /* listop_list[25]  */
	{ (OP*)&cop_list[71], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[136], (OP*)&unop_list[269] }, /* listop_list[26]  */
	{ (OP*)&listop_list[19], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[117], (OP*)&unop_list[278] }, /* listop_list[27]  */
	{ (OP*)&svop_list[342], (OP*)&svop_list[342], INT2PTR(void*,OP_JOIN), 127, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[153], (OP*)&unop_list[298] }, /* listop_list[28]  */
	{ (OP*)&svop_list[354], (OP*)&svop_list[354], INT2PTR(void*,OP_JOIN), 132, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[158], (OP*)&unop_list[309] }, /* listop_list[29]  */
	{ (OP*)&binop_list[76], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[88], (OP*)&unop_list[332] }, /* listop_list[30]  */
	{ &op_list[173], 0, INT2PTR(void*,OP_ASLICE), 0, 139, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[174], &op_list[175] }, /* listop_list[31]  */
	{ &op_list[191], 0, INT2PTR(void*,OP_ASLICE), 0, 139, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, &op_list[192], &op_list[193] }, /* listop_list[32]  */
	{ (OP*)&svop_list[410], (OP*)&svop_list[410], INT2PTR(void*,OP_JOIN), 157, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[197], &op_list[198] }, /* listop_list[33]  */
	{ &op_list[203], 0, INT2PTR(void*,OP_HSLICE), 0, 151, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, &op_list[204], &op_list[205] }, /* listop_list[34]  */
	{ (OP*)&svop_list[418], (OP*)&svop_list[418], INT2PTR(void*,OP_JOIN), 162, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[209], &op_list[210] }, /* listop_list[35]  */
	{ (OP*)&binop_list[86], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[101], (OP*)&unop_list[371] }, /* listop_list[36]  */
	{ (OP*)&unop_list[378], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[102], (OP*)&unop_list[379] }, /* listop_list[37]  */
	{ (OP*)&logop_list[14], 0, INT2PTR(void*,OP_GREPSTART), 0, 169, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[224], (OP*)&binop_list[89] }, /* listop_list[38]  */
	{ (OP*)&svop_list[448], (OP*)&unop_list[394], INT2PTR(void*,OP_SORT), 0, 167, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x0, &op_list[228], (OP*)&binop_list[90] }, /* listop_list[39]  */
	{ (OP*)&unop_list[404], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, (OP*)&cop_list[108], (OP*)&binop_list[93] }, /* listop_list[40]  */
	{ (OP*)&binop_list[96], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[112], (OP*)&unop_list[416] }, /* listop_list[41]  */
	{ (OP*)&svop_list[478], (OP*)&svop_list[478], INT2PTR(void*,OP_JOIN), 172, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[247], (OP*)&unop_list[418] }, /* listop_list[42]  */
	{ (OP*)&unop_list[418], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xe, 0x0, &op_list[248], (OP*)&listop_list[44] }, /* listop_list[43]  */
	{ (OP*)&listop_list[43], 0, INT2PTR(void*,OP_ANONLIST), 0, 160, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, &op_list[249], (OP*)&binop_list[97] }, /* listop_list[44]  */
	{ (OP*)&svop_list[487], (OP*)&svop_list[487], INT2PTR(void*,OP_JOIN), 174, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[253], (OP*)&binop_list[98] }, /* listop_list[45]  */
	{ (OP*)&svop_list[493], (OP*)&svop_list[493], INT2PTR(void*,OP_JOIN), 178, 157, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, &op_list[260], &op_list[261] }, /* listop_list[46]  */
	{ (OP*)&unop_list[436], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[119], (OP*)&unop_list[437] }, /* listop_list[47]  */
	{ (OP*)&cop_list[120], (OP*)&cop_list[120], INT2PTR(void*,OP_UNSHIFT), 2, 166, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, &op_list[267], (OP*)&svop_list[498] }, /* listop_list[48]  */
};

Static PMOP pmop_list[2] = {
	{ (OP*)&svop_list[48], (OP*)&svop_list[48], INT2PTR(void*,OP_PUSHRE), 0, 13, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, 0, 0, 0, 0x0, {0}, {NULL} }, /* pmop_list[0]  */
	{ (OP*)&binop_list[97], 0, INT2PTR(void*,OP_MATCH), 0, 31, 0, 0, 0, 1, 0, 0, 0, 0x47, 0x40, (OP*)&svop_list[477], (OP*)&svop_list[477], 0, 0x1000000, {0}, {NULL} }, /* pmop_list[1]  */
};

Static SVOP svop_list[500] = {
	{ (OP*)&svop_list[1], (OP*)&svop_list[1], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, &sv_list[1] }, /* svop_list[0]  */
	{ (OP*)&svop_list[2], (OP*)&unop_list[4], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[2] }, /* svop_list[1]  */
	{ (OP*)&unop_list[2], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[0] */ }, /* svop_list[2]  */
	{ (OP*)&svop_list[4], (OP*)&svop_list[4], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[3] }, /* svop_list[3]  */
	{ (OP*)&svop_list[5], (OP*)&svop_list[5], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[4] }, /* svop_list[4]  */
	{ (OP*)&svop_list[6], (OP*)&svop_list[6], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[5] }, /* svop_list[5]  */
	{ &op_list[4], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[6] }, /* svop_list[6]  */
	{ (OP*)&unop_list[7], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[7]  */
	{ (OP*)&unop_list[10], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[8]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[8] }, /* svop_list[9]  */
	{ (OP*)&svop_list[11], (OP*)&svop_list[11], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[9] }, /* svop_list[10]  */
	{ (OP*)&svop_list[12], (OP*)&svop_list[12], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[10] }, /* svop_list[11]  */
	{ (OP*)&svop_list[13], (OP*)&unop_list[11], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[11] }, /* svop_list[12]  */
	{ (OP*)&unop_list[8], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[13]  */
	{ (OP*)&unop_list[14], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[14]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[12] }, /* svop_list[15]  */
	{ (OP*)&svop_list[17], (OP*)&svop_list[17], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[13] }, /* svop_list[16]  */
	{ (OP*)&svop_list[18], (OP*)&svop_list[18], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[14] }, /* svop_list[17]  */
	{ (OP*)&svop_list[19], (OP*)&unop_list[15], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[15] }, /* svop_list[18]  */
	{ (OP*)&unop_list[12], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[19]  */
	{ (OP*)&unop_list[16], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[20]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[21]  */
	{ (OP*)&svop_list[20], (OP*)&unop_list[16], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[16] }, /* svop_list[22]  */
	{ (OP*)&svop_list[24], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[23]  */
	{ (OP*)&svop_list[25], (OP*)&svop_list[25], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[17] }, /* svop_list[24]  */
	{ (OP*)&svop_list[26], (OP*)&svop_list[26], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[18] }, /* svop_list[25]  */
	{ (OP*)&svop_list[27], (OP*)&unop_list[21], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[19] }, /* svop_list[26]  */
	{ (OP*)&unop_list[18], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[27]  */
	{ (OP*)&svop_list[29], (OP*)&svop_list[29], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[28]  */
	{ (OP*)&svop_list[30], (OP*)&svop_list[30], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[21] }, /* svop_list[29]  */
	{ (OP*)&svop_list[31], (OP*)&svop_list[31], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[22] }, /* svop_list[30]  */
	{ &op_list[10], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[23] }, /* svop_list[31]  */
	{ (OP*)&svop_list[33], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[32]  */
	{ (OP*)&svop_list[34], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[33]  */
	{ (OP*)&svop_list[35], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[34]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[35]  */
	{ (OP*)&svop_list[37], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[36]  */
	{ (OP*)&binop_list[11], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[31] }, /* svop_list[37]  */
	{ (OP*)&binop_list[10], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[38]  */
	{ (OP*)&binop_list[9], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[32] }, /* svop_list[39]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[40]  */
	{ (OP*)&binop_list[7], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[33] }, /* svop_list[41]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[42]  */
	{ (OP*)&svop_list[44], (OP*)&svop_list[44], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[34] }, /* svop_list[43]  */
	{ (OP*)&svop_list[45], (OP*)&svop_list[45], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[35] }, /* svop_list[44]  */
	{ (OP*)&svop_list[46], (OP*)&unop_list[35], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[36] }, /* svop_list[45]  */
	{ (OP*)&unop_list[28], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[46]  */
	{ (OP*)&listop_list[3], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[37] }, /* svop_list[47]  */
	{ (OP*)&svop_list[47], (OP*)&svop_list[47], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[38] }, /* svop_list[48]  */
	{ (OP*)&svop_list[50], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[49]  */
	{ (OP*)&svop_list[51], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[50]  */
	{ (OP*)&binop_list[12], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[51]  */
	{ (OP*)&svop_list[53], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[52]  */
	{ (OP*)&binop_list[16], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[39] }, /* svop_list[53]  */
	{ (OP*)&binop_list[15], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[54]  */
	{ (OP*)&binop_list[14], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[40] }, /* svop_list[55]  */
	{ (OP*)&binop_list[13], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[56]  */
	{ (OP*)&svop_list[58], (OP*)&svop_list[58], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[41] }, /* svop_list[57]  */
	{ (OP*)&svop_list[59], (OP*)&svop_list[59], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[42] }, /* svop_list[58]  */
	{ (OP*)&svop_list[60], (OP*)&unop_list[47], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[43] }, /* svop_list[59]  */
	{ (OP*)&unop_list[41], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[60]  */
	{ (OP*)&svop_list[62], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[61]  */
	{ (OP*)&svop_list[63], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[62]  */
	{ &op_list[18], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[63]  */
	{ (OP*)&svop_list[65], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[64]  */
	{ (OP*)&svop_list[66], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[65]  */
	{ (OP*)&binop_list[17], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[66]  */
	{ (OP*)&svop_list[68], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[67]  */
	{ (OP*)&binop_list[21], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[44] }, /* svop_list[68]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[69]  */
	{ (OP*)&binop_list[19], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[45] }, /* svop_list[70]  */
	{ (OP*)&binop_list[18], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[71]  */
	{ (OP*)&svop_list[73], (OP*)&svop_list[73], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[46] }, /* svop_list[72]  */
	{ (OP*)&svop_list[74], (OP*)&svop_list[74], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[47] }, /* svop_list[73]  */
	{ (OP*)&svop_list[75], (OP*)&unop_list[62], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[48] }, /* svop_list[74]  */
	{ (OP*)&unop_list[56], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[75]  */
	{ (OP*)&svop_list[77], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[76]  */
	{ &op_list[22], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[77]  */
	{ (OP*)&svop_list[79], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[78]  */
	{ (OP*)&binop_list[22], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[79]  */
	{ (OP*)&svop_list[81], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[80]  */
	{ (OP*)&binop_list[24], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[49] }, /* svop_list[81]  */
	{ (OP*)&binop_list[23], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[82]  */
	{ (OP*)&svop_list[84], (OP*)&svop_list[84], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[50] }, /* svop_list[83]  */
	{ (OP*)&svop_list[85], (OP*)&svop_list[85], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[51] }, /* svop_list[84]  */
	{ (OP*)&svop_list[86], (OP*)&unop_list[74], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[52] }, /* svop_list[85]  */
	{ (OP*)&unop_list[69], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[86]  */
	{ (OP*)&svop_list[88], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[87]  */
	{ &op_list[28], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[88]  */
	{ (OP*)&svop_list[90], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[89]  */
	{ (OP*)&binop_list[26], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[90]  */
	{ (OP*)&svop_list[92], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[91]  */
	{ (OP*)&binop_list[25], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[92]  */
	{ (OP*)&svop_list[94], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[93]  */
	{ (OP*)&binop_list[28], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[53] }, /* svop_list[94]  */
	{ (OP*)&binop_list[27], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[95]  */
	{ (OP*)&svop_list[97], (OP*)&svop_list[97], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[54] }, /* svop_list[96]  */
	{ (OP*)&svop_list[98], (OP*)&svop_list[98], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[55] }, /* svop_list[97]  */
	{ (OP*)&svop_list[99], (OP*)&unop_list[90], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[56] }, /* svop_list[98]  */
	{ (OP*)&unop_list[85], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[99]  */
	{ (OP*)&svop_list[101], (OP*)&svop_list[101], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[57] }, /* svop_list[100]  */
	{ (OP*)&svop_list[102], (OP*)&svop_list[102], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[58] }, /* svop_list[101]  */
	{ (OP*)&svop_list[103], (OP*)&svop_list[103], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[59] }, /* svop_list[102]  */
	{ &op_list[32], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[60] }, /* svop_list[103]  */
	{ (OP*)&svop_list[105], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[104]  */
	{ (OP*)&unopaux_list[0], 0, INT2PTR(void*,OP_AELEMFAST), 0, 136, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x1, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[105]  */
	{ (OP*)&binop_list[29], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[106]  */
	{ (OP*)&svop_list[108], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[107]  */
	{ (OP*)&svop_list[109], (OP*)&svop_list[109], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[62] }, /* svop_list[108]  */
	{ (OP*)&svop_list[110], (OP*)&svop_list[110], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[63] }, /* svop_list[109]  */
	{ (OP*)&svop_list[111], (OP*)&unop_list[101], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[64] }, /* svop_list[110]  */
	{ (OP*)&unop_list[98], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[111]  */
	{ (OP*)&unop_list[104], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[112]  */
	{ (OP*)&binop_list[30], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[65] }, /* svop_list[113]  */
	{ (OP*)&svop_list[115], (OP*)&svop_list[115], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[66] }, /* svop_list[114]  */
	{ (OP*)&svop_list[116], (OP*)&svop_list[116], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[67] }, /* svop_list[115]  */
	{ (OP*)&svop_list[117], (OP*)&unop_list[105], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[68] }, /* svop_list[116]  */
	{ (OP*)&unop_list[102], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[117]  */
	{ (OP*)&svop_list[119], (OP*)&svop_list[119], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[70] }, /* svop_list[118]  */
	{ (OP*)&svop_list[120], (OP*)&svop_list[120], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[71] }, /* svop_list[119]  */
	{ (OP*)&svop_list[121], (OP*)&unop_list[109], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[72] }, /* svop_list[120]  */
	{ (OP*)&unop_list[106], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[121]  */
	{ (OP*)&svop_list[123], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[122]  */
	{ (OP*)&svop_list[124], (OP*)&svop_list[124], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[73] }, /* svop_list[123]  */
	{ (OP*)&svop_list[125], (OP*)&svop_list[125], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[74] }, /* svop_list[124]  */
	{ (OP*)&svop_list[126], (OP*)&unop_list[113], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[75] }, /* svop_list[125]  */
	{ (OP*)&unop_list[110], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[126]  */
	{ (OP*)&svop_list[128], (OP*)&svop_list[128], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[76] }, /* svop_list[127]  */
	{ (OP*)&svop_list[129], (OP*)&svop_list[129], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[77] }, /* svop_list[128]  */
	{ (OP*)&svop_list[130], (OP*)&svop_list[130], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[78] }, /* svop_list[129]  */
	{ (OP*)&svop_list[131], (OP*)&svop_list[131], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[79] }, /* svop_list[130]  */
	{ (OP*)&svop_list[132], (OP*)&svop_list[132], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[80] }, /* svop_list[131]  */
	{ (OP*)&svop_list[133], (OP*)&svop_list[133], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[81] }, /* svop_list[132]  */
	{ (OP*)&svop_list[134], (OP*)&svop_list[134], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[82] }, /* svop_list[133]  */
	{ &op_list[41], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[83] }, /* svop_list[134]  */
	{ (OP*)&unop_list[116], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[135]  */
	{ (OP*)&unop_list[119], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[136]  */
	{ (OP*)&svop_list[138], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[137]  */
	{ (OP*)&svop_list[139], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[138]  */
	{ (OP*)&svop_list[140], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[139]  */
	{ (OP*)&binop_list[32], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[140]  */
	{ (OP*)&svop_list[142], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[141]  */
	{ (OP*)&binop_list[38], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[84] }, /* svop_list[142]  */
	{ (OP*)&binop_list[37], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[143]  */
	{ (OP*)&binop_list[36], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[85] }, /* svop_list[144]  */
	{ (OP*)&binop_list[35], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[145]  */
	{ (OP*)&binop_list[34], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[86] }, /* svop_list[146]  */
	{ (OP*)&binop_list[33], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[147]  */
	{ (OP*)&svop_list[149], (OP*)&svop_list[149], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[87] }, /* svop_list[148]  */
	{ (OP*)&svop_list[150], (OP*)&svop_list[150], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[88] }, /* svop_list[149]  */
	{ (OP*)&svop_list[151], (OP*)&unop_list[131], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[89] }, /* svop_list[150]  */
	{ (OP*)&unop_list[124], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[151]  */
	{ (OP*)&svop_list[153], (OP*)&svop_list[153], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[90] }, /* svop_list[152]  */
	{ &op_list[47], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[91] }, /* svop_list[153]  */
	{ (OP*)&unop_list[134], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[154]  */
	{ (OP*)&unop_list[137], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[155]  */
	{ (OP*)&svop_list[157], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[156]  */
	{ (OP*)&svop_list[158], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[157]  */
	{ (OP*)&svop_list[159], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[158]  */
	{ (OP*)&binop_list[40], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[159]  */
	{ (OP*)&svop_list[161], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[160]  */
	{ (OP*)&svop_list[162], (OP*)&svop_list[162], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[92] }, /* svop_list[161]  */
	{ (OP*)&svop_list[163], (OP*)&svop_list[163], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[93] }, /* svop_list[162]  */
	{ (OP*)&svop_list[164], (OP*)&unop_list[145], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[94] }, /* svop_list[163]  */
	{ (OP*)&unop_list[142], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[164]  */
	{ (OP*)&svop_list[166], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[165]  */
	{ (OP*)&svop_list[167], (OP*)&svop_list[167], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[95] }, /* svop_list[166]  */
	{ (OP*)&svop_list[168], (OP*)&svop_list[168], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[96] }, /* svop_list[167]  */
	{ (OP*)&svop_list[169], (OP*)&unop_list[149], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[97] }, /* svop_list[168]  */
	{ (OP*)&unop_list[146], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[169]  */
	{ (OP*)&unop_list[153], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[170]  */
	{ (OP*)&svop_list[172], (OP*)&unop_list[155], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[98] }, /* svop_list[171]  */
	{ (OP*)&unop_list[150], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[172]  */
	{ (OP*)&unop_list[159], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[173]  */
	{ (OP*)&svop_list[175], (OP*)&unop_list[161], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[99] }, /* svop_list[174]  */
	{ (OP*)&unop_list[156], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[175]  */
	{ &op_list[57], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0xa, 0x0, &sv_list[100] }, /* svop_list[176]  */
	{ (OP*)&unop_list[166], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[177]  */
	{ (OP*)&unop_list[167], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[178]  */
	{ (OP*)&unop_list[170], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[179]  */
	{ (OP*)&svop_list[181], (OP*)&unop_list[171], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[102] }, /* svop_list[180]  */
	{ (OP*)&unop_list[171], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[181]  */
	{ (OP*)&svop_list[183], (OP*)&svop_list[183], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[103] }, /* svop_list[182]  */
	{ (OP*)&svop_list[184], (OP*)&svop_list[184], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[104] }, /* svop_list[183]  */
	{ (OP*)&svop_list[185], (OP*)&unop_list[172], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[105] }, /* svop_list[184]  */
	{ (OP*)&unop_list[168], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[185]  */
	{ (OP*)&svop_list[187], (OP*)&svop_list[187], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[106] }, /* svop_list[186]  */
	{ &op_list[63], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[107] }, /* svop_list[187]  */
	{ (OP*)&unop_list[177], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[188]  */
	{ (OP*)&unop_list[178], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[189]  */
	{ (OP*)&unop_list[181], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[190]  */
	{ &op_list[67], (OP*)&listop_list[7], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[108] }, /* svop_list[191]  */
	{ (OP*)&unop_list[182], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[192]  */
	{ (OP*)&svop_list[192], (OP*)&unop_list[182], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[109] }, /* svop_list[193]  */
	{ (OP*)&svop_list[190], (OP*)&unop_list[181], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[110] }, /* svop_list[194]  */
	{ (OP*)&svop_list[196], (OP*)&svop_list[196], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[111] }, /* svop_list[195]  */
	{ (OP*)&svop_list[197], (OP*)&svop_list[197], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[112] }, /* svop_list[196]  */
	{ (OP*)&svop_list[198], (OP*)&unop_list[183], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[113] }, /* svop_list[197]  */
	{ (OP*)&unop_list[179], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[198]  */
	{ (OP*)&unop_list[186], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[199]  */
	{ &op_list[72], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[114] }, /* svop_list[200]  */
	{ (OP*)&unop_list[189], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[201]  */
	{ (OP*)&unop_list[192], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[202]  */
	{ (OP*)&svop_list[202], (OP*)&unop_list[192], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[115] }, /* svop_list[203]  */
	{ (OP*)&svop_list[205], (OP*)&svop_list[205], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[116] }, /* svop_list[204]  */
	{ (OP*)&svop_list[206], (OP*)&svop_list[206], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[117] }, /* svop_list[205]  */
	{ (OP*)&svop_list[207], (OP*)&unop_list[193], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[118] }, /* svop_list[206]  */
	{ (OP*)&unop_list[190], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[207]  */
	{ (OP*)&svop_list[268], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[208]  */
	{ (OP*)&svop_list[210], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[209]  */
	{ (OP*)&binop_list[49], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[120] }, /* svop_list[210]  */
	{ (OP*)&svop_list[212], (OP*)&unop_list[196], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[121] }, /* svop_list[211]  */
	{ (OP*)&binop_list[50], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[212]  */
	{ (OP*)&svop_list[214], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[213]  */
	{ (OP*)&binop_list[51], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[122] }, /* svop_list[214]  */
	{ (OP*)&svop_list[216], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[215]  */
	{ (OP*)&binop_list[53], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[123] }, /* svop_list[216]  */
	{ (OP*)&svop_list[218], (OP*)&svop_list[218], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[124] }, /* svop_list[217]  */
	{ (OP*)&svop_list[219], (OP*)&svop_list[219], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[125] }, /* svop_list[218]  */
	{ &op_list[84], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[126] }, /* svop_list[219]  */
	{ (OP*)&svop_list[221], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[220]  */
	{ (OP*)&binop_list[54], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[127] }, /* svop_list[221]  */
	{ (OP*)&svop_list[223], (OP*)&svop_list[223], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[128] }, /* svop_list[222]  */
	{ (OP*)&svop_list[224], (OP*)&svop_list[224], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[129] }, /* svop_list[223]  */
	{ &op_list[84], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[130] }, /* svop_list[224]  */
	{ (OP*)&svop_list[226], (OP*)&svop_list[226], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[131] }, /* svop_list[225]  */
	{ (OP*)&svop_list[227], (OP*)&svop_list[227], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[132] }, /* svop_list[226]  */
	{ &op_list[84], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[133] }, /* svop_list[227]  */
	{ (OP*)&svop_list[229], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[228]  */
	{ (OP*)&binop_list[55], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[134] }, /* svop_list[229]  */
	{ (OP*)&svop_list[231], (OP*)&svop_list[231], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[135] }, /* svop_list[230]  */
	{ (OP*)&svop_list[232], (OP*)&svop_list[232], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[136] }, /* svop_list[231]  */
	{ (OP*)&svop_list[233], (OP*)&unop_list[214], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[137] }, /* svop_list[232]  */
	{ (OP*)&unop_list[212], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[233]  */
	{ (OP*)&svop_list[235], (OP*)&svop_list[235], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[138] }, /* svop_list[234]  */
	{ (OP*)&svop_list[236], (OP*)&svop_list[236], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[139] }, /* svop_list[235]  */
	{ (OP*)&svop_list[237], (OP*)&unop_list[217], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[140] }, /* svop_list[236]  */
	{ (OP*)&unop_list[215], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[237]  */
	{ (OP*)&svop_list[239], (OP*)&svop_list[239], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[141] }, /* svop_list[238]  */
	{ (OP*)&svop_list[240], (OP*)&svop_list[240], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[142] }, /* svop_list[239]  */
	{ (OP*)&svop_list[241], (OP*)&unop_list[218], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[143] }, /* svop_list[240]  */
	{ (OP*)&unop_list[210], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[241]  */
	{ (OP*)&svop_list[243], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[242]  */
	{ (OP*)&binop_list[56], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[144] }, /* svop_list[243]  */
	{ (OP*)&svop_list[245], (OP*)&svop_list[245], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[145] }, /* svop_list[244]  */
	{ (OP*)&svop_list[246], (OP*)&svop_list[246], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[146] }, /* svop_list[245]  */
	{ (OP*)&svop_list[247], (OP*)&unop_list[225], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[147] }, /* svop_list[246]  */
	{ (OP*)&unop_list[223], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[247]  */
	{ (OP*)&svop_list[249], (OP*)&svop_list[249], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[148] }, /* svop_list[248]  */
	{ (OP*)&svop_list[250], (OP*)&svop_list[250], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[149] }, /* svop_list[249]  */
	{ (OP*)&svop_list[251], (OP*)&unop_list[228], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[150] }, /* svop_list[250]  */
	{ (OP*)&unop_list[226], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[251]  */
	{ (OP*)&svop_list[253], (OP*)&svop_list[253], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[151] }, /* svop_list[252]  */
	{ (OP*)&svop_list[254], (OP*)&svop_list[254], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[152] }, /* svop_list[253]  */
	{ (OP*)&svop_list[255], (OP*)&unop_list[229], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[153] }, /* svop_list[254]  */
	{ (OP*)&unop_list[221], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[255]  */
	{ (OP*)&svop_list[257], (OP*)&svop_list[257], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[154] }, /* svop_list[256]  */
	{ (OP*)&svop_list[258], (OP*)&svop_list[258], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[155] }, /* svop_list[257]  */
	{ (OP*)&svop_list[259], (OP*)&unop_list[234], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[156] }, /* svop_list[258]  */
	{ (OP*)&unop_list[232], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[259]  */
	{ (OP*)&svop_list[261], (OP*)&svop_list[261], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[157] }, /* svop_list[260]  */
	{ (OP*)&svop_list[262], (OP*)&svop_list[262], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[158] }, /* svop_list[261]  */
	{ (OP*)&svop_list[263], (OP*)&unop_list[237], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[159] }, /* svop_list[262]  */
	{ (OP*)&unop_list[235], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[263]  */
	{ (OP*)&svop_list[265], (OP*)&svop_list[265], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[160] }, /* svop_list[264]  */
	{ (OP*)&svop_list[266], (OP*)&svop_list[266], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[161] }, /* svop_list[265]  */
	{ (OP*)&svop_list[267], (OP*)&unop_list[238], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[162] }, /* svop_list[266]  */
	{ (OP*)&unop_list[230], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[267]  */
	{ (OP*)&binop_list[58], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[163] }, /* svop_list[268]  */
	{ (OP*)&binop_list[57], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[269]  */
	{ (OP*)&svop_list[330], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[270]  */
	{ (OP*)&svop_list[272], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[271]  */
	{ (OP*)&binop_list[61], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[164] }, /* svop_list[272]  */
	{ (OP*)&svop_list[274], (OP*)&unop_list[243], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[165] }, /* svop_list[273]  */
	{ (OP*)&binop_list[62], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[274]  */
	{ (OP*)&svop_list[276], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[275]  */
	{ (OP*)&binop_list[63], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[166] }, /* svop_list[276]  */
	{ (OP*)&svop_list[278], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[277]  */
	{ (OP*)&binop_list[65], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[167] }, /* svop_list[278]  */
	{ (OP*)&svop_list[280], (OP*)&svop_list[280], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[168] }, /* svop_list[279]  */
	{ (OP*)&svop_list[281], (OP*)&svop_list[281], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[169] }, /* svop_list[280]  */
	{ (OP*)&listop_list[20], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[170] }, /* svop_list[281]  */
	{ (OP*)&svop_list[283], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[282]  */
	{ (OP*)&binop_list[66], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[171] }, /* svop_list[283]  */
	{ (OP*)&svop_list[285], (OP*)&svop_list[285], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[172] }, /* svop_list[284]  */
	{ (OP*)&svop_list[286], (OP*)&svop_list[286], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[173] }, /* svop_list[285]  */
	{ (OP*)&listop_list[20], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[174] }, /* svop_list[286]  */
	{ (OP*)&svop_list[288], (OP*)&svop_list[288], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[175] }, /* svop_list[287]  */
	{ (OP*)&svop_list[289], (OP*)&svop_list[289], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[176] }, /* svop_list[288]  */
	{ (OP*)&listop_list[24], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[177] }, /* svop_list[289]  */
	{ (OP*)&svop_list[291], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[290]  */
	{ (OP*)&binop_list[67], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[178] }, /* svop_list[291]  */
	{ (OP*)&svop_list[293], (OP*)&svop_list[293], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[179] }, /* svop_list[292]  */
	{ (OP*)&svop_list[294], (OP*)&svop_list[294], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[180] }, /* svop_list[293]  */
	{ (OP*)&svop_list[295], (OP*)&unop_list[262], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[181] }, /* svop_list[294]  */
	{ (OP*)&unop_list[260], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[295]  */
	{ (OP*)&svop_list[297], (OP*)&svop_list[297], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[182] }, /* svop_list[296]  */
	{ (OP*)&svop_list[298], (OP*)&svop_list[298], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[183] }, /* svop_list[297]  */
	{ (OP*)&svop_list[299], (OP*)&unop_list[265], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[184] }, /* svop_list[298]  */
	{ (OP*)&unop_list[263], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[299]  */
	{ (OP*)&svop_list[301], (OP*)&svop_list[301], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[185] }, /* svop_list[300]  */
	{ (OP*)&svop_list[302], (OP*)&svop_list[302], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[186] }, /* svop_list[301]  */
	{ (OP*)&svop_list[303], (OP*)&unop_list[266], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[187] }, /* svop_list[302]  */
	{ (OP*)&unop_list[258], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[303]  */
	{ (OP*)&svop_list[305], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[304]  */
	{ (OP*)&binop_list[68], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[188] }, /* svop_list[305]  */
	{ (OP*)&svop_list[307], (OP*)&svop_list[307], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[189] }, /* svop_list[306]  */
	{ (OP*)&svop_list[308], (OP*)&svop_list[308], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[190] }, /* svop_list[307]  */
	{ (OP*)&svop_list[309], (OP*)&unop_list[273], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[191] }, /* svop_list[308]  */
	{ (OP*)&unop_list[271], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[309]  */
	{ (OP*)&svop_list[311], (OP*)&svop_list[311], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[192] }, /* svop_list[310]  */
	{ (OP*)&svop_list[312], (OP*)&svop_list[312], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[193] }, /* svop_list[311]  */
	{ (OP*)&svop_list[313], (OP*)&unop_list[276], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[194] }, /* svop_list[312]  */
	{ (OP*)&unop_list[274], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[313]  */
	{ (OP*)&svop_list[315], (OP*)&svop_list[315], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[195] }, /* svop_list[314]  */
	{ (OP*)&svop_list[316], (OP*)&svop_list[316], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[196] }, /* svop_list[315]  */
	{ (OP*)&svop_list[317], (OP*)&unop_list[277], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[197] }, /* svop_list[316]  */
	{ (OP*)&unop_list[269], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[317]  */
	{ (OP*)&svop_list[319], (OP*)&svop_list[319], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[198] }, /* svop_list[318]  */
	{ (OP*)&svop_list[320], (OP*)&svop_list[320], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[199] }, /* svop_list[319]  */
	{ (OP*)&svop_list[321], (OP*)&unop_list[282], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[200] }, /* svop_list[320]  */
	{ (OP*)&unop_list[280], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[321]  */
	{ (OP*)&svop_list[323], (OP*)&svop_list[323], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[201] }, /* svop_list[322]  */
	{ (OP*)&svop_list[324], (OP*)&svop_list[324], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[202] }, /* svop_list[323]  */
	{ (OP*)&svop_list[325], (OP*)&unop_list[285], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[203] }, /* svop_list[324]  */
	{ (OP*)&unop_list[283], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[325]  */
	{ (OP*)&svop_list[327], (OP*)&svop_list[327], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[204] }, /* svop_list[326]  */
	{ (OP*)&svop_list[328], (OP*)&svop_list[328], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[205] }, /* svop_list[327]  */
	{ (OP*)&svop_list[329], (OP*)&unop_list[286], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[206] }, /* svop_list[328]  */
	{ (OP*)&unop_list[278], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[329]  */
	{ (OP*)&binop_list[70], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[207] }, /* svop_list[330]  */
	{ (OP*)&binop_list[69], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[331]  */
	{ (OP*)&svop_list[333], (OP*)&unop_list[289], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[208] }, /* svop_list[332]  */
	{ (OP*)&binop_list[71], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[333]  */
	{ (OP*)&svop_list[335], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[334]  */
	{ (OP*)&binop_list[73], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[209] }, /* svop_list[335]  */
	{ (OP*)&svop_list[337], (OP*)&svop_list[337], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[210] }, /* svop_list[336]  */
	{ (OP*)&svop_list[338], (OP*)&svop_list[338], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[211] }, /* svop_list[337]  */
	{ &op_list[150], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[212] }, /* svop_list[338]  */
	{ (OP*)&unop_list[295], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[339]  */
	{ (OP*)&unop_list[298], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[340]  */
	{ (OP*)&svop_list[340], (OP*)&unop_list[298], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[213] }, /* svop_list[341]  */
	{ (OP*)&svop_list[343], (OP*)&svop_list[343], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[214] }, /* svop_list[342]  */
	{ (OP*)&svop_list[344], (OP*)&svop_list[344], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[215] }, /* svop_list[343]  */
	{ (OP*)&svop_list[345], (OP*)&unop_list[299], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[216] }, /* svop_list[344]  */
	{ (OP*)&unop_list[296], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[345]  */
	{ (OP*)&svop_list[347], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[346]  */
	{ (OP*)&binop_list[75], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[347]  */
	{ (OP*)&svop_list[349], (OP*)&svop_list[349], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[217] }, /* svop_list[348]  */
	{ (OP*)&svop_list[350], (OP*)&svop_list[350], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[218] }, /* svop_list[349]  */
	{ &op_list[155], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[219] }, /* svop_list[350]  */
	{ (OP*)&unop_list[306], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[351]  */
	{ (OP*)&unop_list[309], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[352]  */
	{ (OP*)&svop_list[352], (OP*)&unop_list[309], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[220] }, /* svop_list[353]  */
	{ (OP*)&svop_list[355], (OP*)&svop_list[355], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[221] }, /* svop_list[354]  */
	{ (OP*)&svop_list[356], (OP*)&svop_list[356], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[222] }, /* svop_list[355]  */
	{ (OP*)&svop_list[357], (OP*)&unop_list[310], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[223] }, /* svop_list[356]  */
	{ (OP*)&unop_list[307], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[357]  */
	{ (OP*)&svop_list[359], (OP*)&svop_list[359], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[224] }, /* svop_list[358]  */
	{ (OP*)&svop_list[360], (OP*)&svop_list[360], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[225] }, /* svop_list[359]  */
	{ (OP*)&svop_list[361], (OP*)&svop_list[361], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[226] }, /* svop_list[360]  */
	{ (OP*)&svop_list[362], (OP*)&unop_list[313], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[227] }, /* svop_list[361]  */
	{ (OP*)&unop_list[311], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[362]  */
	{ (OP*)&svop_list[364], (OP*)&svop_list[364], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[228] }, /* svop_list[363]  */
	{ (OP*)&svop_list[365], (OP*)&svop_list[365], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[229] }, /* svop_list[364]  */
	{ (OP*)&svop_list[366], (OP*)&svop_list[366], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[230] }, /* svop_list[365]  */
	{ (OP*)&svop_list[367], (OP*)&unop_list[316], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[231] }, /* svop_list[366]  */
	{ (OP*)&unop_list[314], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[367]  */
	{ (OP*)&svop_list[369], (OP*)&svop_list[369], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[232] }, /* svop_list[368]  */
	{ (OP*)&svop_list[370], (OP*)&svop_list[370], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[233] }, /* svop_list[369]  */
	{ (OP*)&svop_list[371], (OP*)&svop_list[371], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[234] }, /* svop_list[370]  */
	{ (OP*)&svop_list[372], (OP*)&unop_list[319], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[235] }, /* svop_list[371]  */
	{ (OP*)&unop_list[317], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[372]  */
	{ (OP*)&svop_list[374], (OP*)&svop_list[374], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[236] }, /* svop_list[373]  */
	{ (OP*)&svop_list[375], (OP*)&svop_list[375], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[237] }, /* svop_list[374]  */
	{ (OP*)&svop_list[376], (OP*)&svop_list[376], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[238] }, /* svop_list[375]  */
	{ (OP*)&svop_list[377], (OP*)&unop_list[322], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[239] }, /* svop_list[376]  */
	{ (OP*)&unop_list[320], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[377]  */
	{ (OP*)&svop_list[379], (OP*)&svop_list[379], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[240] }, /* svop_list[378]  */
	{ (OP*)&svop_list[380], (OP*)&svop_list[380], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[241] }, /* svop_list[379]  */
	{ (OP*)&svop_list[381], (OP*)&svop_list[381], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[242] }, /* svop_list[380]  */
	{ (OP*)&svop_list[382], (OP*)&unop_list[325], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[243] }, /* svop_list[381]  */
	{ (OP*)&unop_list[323], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[382]  */
	{ (OP*)&svop_list[384], (OP*)&svop_list[384], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[244] }, /* svop_list[383]  */
	{ (OP*)&svop_list[385], (OP*)&svop_list[385], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[245] }, /* svop_list[384]  */
	{ (OP*)&svop_list[386], (OP*)&svop_list[386], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[246] }, /* svop_list[385]  */
	{ (OP*)&svop_list[387], (OP*)&unop_list[328], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[247] }, /* svop_list[386]  */
	{ (OP*)&unop_list[326], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[387]  */
	{ (OP*)&svop_list[389], (OP*)&svop_list[389], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[248] }, /* svop_list[388]  */
	{ (OP*)&svop_list[390], (OP*)&svop_list[390], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[249] }, /* svop_list[389]  */
	{ (OP*)&svop_list[391], (OP*)&svop_list[391], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[250] }, /* svop_list[390]  */
	{ (OP*)&svop_list[392], (OP*)&unop_list[331], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[251] }, /* svop_list[391]  */
	{ (OP*)&unop_list[329], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[392]  */
	{ &op_list[169], &op_list[169], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[252] }, /* svop_list[393]  */
	{ &op_list[168], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[253] }, /* svop_list[394]  */
	{ (OP*)&svop_list[396], (OP*)&svop_list[396], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[254] }, /* svop_list[395]  */
	{ &op_list[175], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[255] }, /* svop_list[396]  */
	{ (OP*)&svop_list[398], (OP*)&svop_list[398], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[256] }, /* svop_list[397]  */
	{ &op_list[181], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[257] }, /* svop_list[398]  */
	{ &op_list[182], &op_list[182], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[258] }, /* svop_list[399]  */
	{ (OP*)&binop_list[80], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[259] }, /* svop_list[400]  */
	{ &op_list[187], (OP*)&unop_list[346], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[260] }, /* svop_list[401]  */
	{ (OP*)&svop_list[403], (OP*)&unop_list[347], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[261] }, /* svop_list[402]  */
	{ (OP*)&unop_list[343], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[403]  */
	{ (OP*)&svop_list[405], (OP*)&svop_list[405], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[262] }, /* svop_list[404]  */
	{ (OP*)&svop_list[406], (OP*)&svop_list[406], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[263] }, /* svop_list[405]  */
	{ (OP*)&svop_list[407], (OP*)&unop_list[351], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[264] }, /* svop_list[406]  */
	{ (OP*)&unop_list[348], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[407]  */
	{ &op_list[192], (OP*)&unop_list[354], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[265] }, /* svop_list[408]  */
	{ &op_list[198], &op_list[198], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[266] }, /* svop_list[409]  */
	{ (OP*)&svop_list[411], (OP*)&svop_list[411], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[267] }, /* svop_list[410]  */
	{ (OP*)&svop_list[412], (OP*)&svop_list[412], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[268] }, /* svop_list[411]  */
	{ (OP*)&svop_list[413], (OP*)&unop_list[357], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[269] }, /* svop_list[412]  */
	{ (OP*)&unop_list[355], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[413]  */
	{ (OP*)&svop_list[415], (OP*)&svop_list[415], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, &sv_list[270] }, /* svop_list[414]  */
	{ &op_list[200], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[271] }, /* svop_list[415]  */
	{ &op_list[204], (OP*)&unop_list[362], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[272] }, /* svop_list[416]  */
	{ &op_list[210], &op_list[210], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[273] }, /* svop_list[417]  */
	{ (OP*)&svop_list[419], (OP*)&svop_list[419], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[274] }, /* svop_list[418]  */
	{ (OP*)&svop_list[420], (OP*)&svop_list[420], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[275] }, /* svop_list[419]  */
	{ (OP*)&svop_list[421], (OP*)&unop_list[365], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[276] }, /* svop_list[420]  */
	{ (OP*)&unop_list[363], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[421]  */
	{ (OP*)&unop_list[369], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[277] }, /* svop_list[422]  */
	{ (OP*)&svop_list[424], (OP*)&svop_list[424], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[279] }, /* svop_list[423]  */
	{ (OP*)&svop_list[425], (OP*)&svop_list[425], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[280] }, /* svop_list[424]  */
	{ (OP*)&svop_list[426], (OP*)&unop_list[370], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[281] }, /* svop_list[425]  */
	{ (OP*)&unop_list[332], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[426]  */
	{ &op_list[217], (OP*)&binop_list[87], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[282] }, /* svop_list[427]  */
	{ (OP*)&svop_list[429], (OP*)&svop_list[429], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[283] }, /* svop_list[428]  */
	{ &op_list[218], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[284] }, /* svop_list[429]  */
	{ (OP*)&svop_list[431], (OP*)&svop_list[431], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[285] }, /* svop_list[430]  */
	{ (OP*)&binop_list[87], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[286] }, /* svop_list[431]  */
	{ (OP*)&unop_list[382], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[432]  */
	{ &op_list[222], &op_list[222], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[288] }, /* svop_list[433]  */
	{ (OP*)&unop_list[379], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[434]  */
	{ (OP*)&unop_list[373], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[435]  */
	{ &op_list[224], (OP*)&logop_list[14], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[295] }, /* svop_list[436]  */
	{ (OP*)&logop_list[14], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[296] }, /* svop_list[437]  */
	{ (OP*)&svop_list[439], (OP*)&svop_list[439], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[297] }, /* svop_list[438]  */
	{ &op_list[226], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[298] }, /* svop_list[439]  */
	{ (OP*)&svop_list[441], (OP*)&svop_list[441], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[299] }, /* svop_list[440]  */
	{ (OP*)&binop_list[89], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[300] }, /* svop_list[441]  */
	{ (OP*)&unop_list[384], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[442]  */
	{ &op_list[228], (OP*)&listop_list[39], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[301] }, /* svop_list[443]  */
	{ (OP*)&svop_list[445], (OP*)&svop_list[445], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[302] }, /* svop_list[444]  */
	{ &op_list[230], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[303] }, /* svop_list[445]  */
	{ (OP*)&svop_list[447], (OP*)&svop_list[447], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[304] }, /* svop_list[446]  */
	{ (OP*)&binop_list[90], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[305] }, /* svop_list[447]  */
	{ (OP*)&unop_list[390], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[448]  */
	{ &op_list[232], (OP*)&binop_list[91], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[306] }, /* svop_list[449]  */
	{ (OP*)&svop_list[451], (OP*)&svop_list[451], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[307] }, /* svop_list[450]  */
	{ &op_list[235], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[308] }, /* svop_list[451]  */
	{ (OP*)&svop_list[453], (OP*)&svop_list[453], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[309] }, /* svop_list[452]  */
	{ (OP*)&binop_list[92], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[310] }, /* svop_list[453]  */
	{ (OP*)&unop_list[395], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[454]  */
	{ &op_list[238], (OP*)&unop_list[404], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[311] }, /* svop_list[455]  */
	{ (OP*)&svop_list[457], (OP*)&svop_list[457], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[312] }, /* svop_list[456]  */
	{ &op_list[239], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[313] }, /* svop_list[457]  */
	{ (OP*)&svop_list[459], (OP*)&svop_list[459], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[314] }, /* svop_list[458]  */
	{ (OP*)&binop_list[93], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[315] }, /* svop_list[459]  */
	{ (OP*)&unop_list[402], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[460]  */
	{ &op_list[241], (OP*)&binop_list[94], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[316] }, /* svop_list[461]  */
	{ (OP*)&svop_list[463], (OP*)&svop_list[463], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[317] }, /* svop_list[462]  */
	{ &op_list[242], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[318] }, /* svop_list[463]  */
	{ (OP*)&svop_list[465], (OP*)&svop_list[465], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[319] }, /* svop_list[464]  */
	{ (OP*)&binop_list[94], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[320] }, /* svop_list[465]  */
	{ (OP*)&unop_list[408], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[466]  */
	{ &op_list[243], (OP*)&binop_list[95], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[321] }, /* svop_list[467]  */
	{ (OP*)&svop_list[469], (OP*)&svop_list[469], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[322] }, /* svop_list[468]  */
	{ &op_list[244], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[323] }, /* svop_list[469]  */
	{ (OP*)&unop_list[371], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[294] }, /* svop_list[470]  */
	{ &op_list[248], (OP*)&unop_list[418], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[324] }, /* svop_list[471]  */
	{ (OP*)&svop_list[473], (OP*)&svop_list[473], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[325] }, /* svop_list[472]  */
	{ (OP*)&svop_list[474], (OP*)&svop_list[474], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[326] }, /* svop_list[473]  */
	{ (OP*)&svop_list[475], (OP*)&svop_list[475], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[327] }, /* svop_list[474]  */
	{ (OP*)&svop_list[476], (OP*)&svop_list[476], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[328] }, /* svop_list[475]  */
	{ &op_list[251], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[329] }, /* svop_list[476]  */
	{ (OP*)&pmop_list[1], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[330] }, /* svop_list[477]  */
	{ (OP*)&svop_list[479], (OP*)&unop_list[421], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[331] }, /* svop_list[478]  */
	{ (OP*)&unop_list[416], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[479]  */
	{ &op_list[254], (OP*)&binop_list[98], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[332] }, /* svop_list[480]  */
	{ (OP*)&svop_list[482], (OP*)&svop_list[482], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[333] }, /* svop_list[481]  */
	{ (OP*)&svop_list[483], (OP*)&svop_list[483], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[334] }, /* svop_list[482]  */
	{ &op_list[255], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[335] }, /* svop_list[483]  */
	{ (OP*)&svop_list[485], (OP*)&svop_list[485], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[336] }, /* svop_list[484]  */
	{ (OP*)&svop_list[486], (OP*)&svop_list[486], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[337] }, /* svop_list[485]  */
	{ (OP*)&binop_list[98], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[338] }, /* svop_list[486]  */
	{ (OP*)&svop_list[488], (OP*)&unop_list[426], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[339] }, /* svop_list[487]  */
	{ (OP*)&unop_list[422], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[488]  */
	{ (OP*)&svop_list[490], (OP*)&svop_list[490], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[340] }, /* svop_list[489]  */
	{ (OP*)&svop_list[491], (OP*)&svop_list[491], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[341] }, /* svop_list[490]  */
	{ &op_list[257], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[342] }, /* svop_list[491]  */
	{ &op_list[261], &op_list[261], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[343] }, /* svop_list[492]  */
	{ (OP*)&svop_list[494], (OP*)&unop_list[431], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[344] }, /* svop_list[493]  */
	{ (OP*)&unop_list[429], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[494]  */
	{ (OP*)&svop_list[496], (OP*)&unop_list[435], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[345] }, /* svop_list[495]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[496]  */
	{ (OP*)&unop_list[437], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[351] }, /* svop_list[497]  */
	{ (OP*)&listop_list[48], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[352] }, /* svop_list[498]  */
	{ (OP*)&unop_list[438], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_incgv */ }, /* svop_list[499]  */
};

Static LOOP loop_list[8] = {
	{ (OP*)&cop_list[0], (OP*)&listop_list[1], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[0], (OP*)&binop_list[0], (OP*)&binop_list[0] }, /* loop_list[0]  */
	{ (OP*)&cop_list[39], (OP*)&listop_list[9], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[39], (OP*)&binop_list[47], (OP*)&binop_list[47] }, /* loop_list[1]  */
	{ (OP*)&svop_list[209], (OP*)&unop_list[194], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, &op_list[75], (OP*)&svop_list[208], (OP*)&binop_list[48] }, /* loop_list[2]  */
	{ (OP*)&cop_list[55], (OP*)&listop_list[16], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[55], (OP*)&binop_list[59], (OP*)&binop_list[59] }, /* loop_list[3]  */
	{ (OP*)&svop_list[271], (OP*)&unop_list[241], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, &op_list[111], (OP*)&svop_list[270], (OP*)&binop_list[60] }, /* loop_list[4]  */
	{ (OP*)&cop_list[88], (OP*)&listop_list[30], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[88], (OP*)&binop_list[76], (OP*)&binop_list[76] }, /* loop_list[5]  */
	{ (OP*)&cop_list[101], (OP*)&listop_list[36], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[101], (OP*)&binop_list[86], (OP*)&binop_list[86] }, /* loop_list[6]  */
	{ (OP*)&cop_list[112], (OP*)&listop_list[41], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[112], (OP*)&binop_list[96], (OP*)&binop_list[96] }, /* loop_list[7]  */
};

Static UNOP_AUX unopaux_list[2] = {
	{ (OP*)&svop_list[106], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x0, &op_list[34], unopaux_item0+1 }, /* unopaux_list[0]  */
	{ (OP*)&svop_list[118], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x40, &op_list[38], unopaux_item1+1 }, /* unopaux_list[1]  */
};

Static XPV xpv_list[273] = {
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 10, 16 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[9]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[10]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[11]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[12]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[13]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[14]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[15]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[16]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[17]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[18]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[19]  */
	{ Nullhv, {0}, 19, 24 }, /* xpv_list[20]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[21]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[22]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[23]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[24]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[25]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[26]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[27]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[28]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[29]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[30]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[31]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[32]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[33]  */
	{ Nullhv, {0}, 1, 0 }, /* xpv_list[34]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[35]  */
	{ Nullhv, {0}, 21, 24 }, /* xpv_list[36]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[37]  */
	{ Nullhv, {0}, 20, 24 }, /* xpv_list[38]  */
	{ Nullhv, {0}, 1, 0 }, /* xpv_list[39]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[40]  */
	{ Nullhv, {0}, 20, 24 }, /* xpv_list[41]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[42]  */
	{ Nullhv, {0}, 26, 32 }, /* xpv_list[43]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[44]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[45]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[46]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[47]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[48]  */
	{ Nullhv, {0}, 16, 24 }, /* xpv_list[49]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[50]  */
	{ Nullhv, {0}, 20, 24 }, /* xpv_list[51]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[52]  */
	{ Nullhv, {0}, 20, 24 }, /* xpv_list[53]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[54]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[55]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[56]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[57]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[58]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[59]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[60]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[61]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[62]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[63]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[64]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[65]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[66]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[67]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[68]  */
	{ Nullhv, {0}, 22, 24 }, /* xpv_list[69]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[70]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[71]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[72]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[73]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[74]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[75]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[76]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[77]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[78]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[79]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[80]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[81]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[82]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[83]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[84]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[85]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[86]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[87]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[88]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[89]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[90]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[91]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[92]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[93]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[94]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[95]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[96]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[97]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[98]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[99]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[100]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[101]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[102]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[103]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[104]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[105]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[106]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[107]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[108]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[109]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[110]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[111]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[112]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[113]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[114]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[115]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[116]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[117]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[118]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[119]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[120]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[121]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[122]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[123]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[124]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[125]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[126]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[127]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[128]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[129]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[130]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[131]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[132]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[133]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[134]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[135]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[136]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[137]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[138]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[139]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[140]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[141]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[142]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[143]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[144]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[145]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[146]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[147]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[148]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[149]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[150]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[151]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[152]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[153]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[154]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[155]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[156]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[157]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[158]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[159]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[160]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[161]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[162]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[163]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[164]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[165]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[166]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[167]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[168]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[169]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[170]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[171]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[172]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[173]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[174]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[175]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[176]  */
	{ Nullhv, {0}, 14, 16 }, /* xpv_list[177]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[178]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[179]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[180]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[181]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[182]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[183]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[184]  */
	{ Nullhv, {0}, 13, 16 }, /* xpv_list[185]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[186]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[187]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[188]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[189]  */
	{ Nullhv, {0}, 14, 16 }, /* xpv_list[190]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[191]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[192]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[193]  */
	{ Nullhv, {0}, 17, 24 }, /* xpv_list[194]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[195]  */
	{ Nullhv, {0}, 17, 24 }, /* xpv_list[196]  */
	{ Nullhv, {0}, 19, 24 }, /* xpv_list[197]  */
	{ Nullhv, {0}, 22, 24 }, /* xpv_list[198]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[199]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[200]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[201]  */
	{ Nullhv, {0}, 19, 24 }, /* xpv_list[202]  */
	{ Nullhv, {0}, 0, 8 }, /* xpv_list[203]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[204]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[205]  */
	{ Nullhv, {0}, 0, 8 }, /* xpv_list[206]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[207]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[208]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[209]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[210]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[211]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[212]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[213]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[214]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[215]  */
	{ Nullhv, {0}, 14, 0 }, /* xpv_list[216]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[217]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[218]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[219]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[220]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[221]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[222]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[223]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[224]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[225]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[226]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[227]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[228]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[229]  */
	{ Nullhv, {0}, 44, 48 }, /* xpv_list[230]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[231]  */
	{ Nullhv, {0}, 34, 40 }, /* xpv_list[232]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[233]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[234]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[235]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[236]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[237]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[238]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[239]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[240]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[241]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[242]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[243]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[244]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[245]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[246]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[247]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[248]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[249]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[250]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[251]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[252]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[253]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[254]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[255]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[256]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[257]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[258]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[259]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[260]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[261]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[262]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[263]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[264]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[265]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[266]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[267]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[268]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[269]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[270]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[271]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[272]  */
};

Static XPVAV xpvav_list[18] = {
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[1]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[2]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[3]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[4]  */
	{ Nullhv, {0}, 3, 3, 0 }, /* xpvav_list[5]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[6]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[7]  */
	{ Nullhv, {0}, 54, 54, 0 }, /* xpvav_list[8]  */
	{ Nullhv, {0}, 2, 2, 0 }, /* xpvav_list[9]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[10]  */
	{ Nullhv, {0}, 183, 183, 0 }, /* xpvav_list[11]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[12]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[13]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[14]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[15]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[16]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[17]  */
};

Static XPVHV xpvhv_list[3] = {
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[0]  */
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[1]  */
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[2]  */
};

Static XPVCV_or_similar xpvcv_list[2] = {
	{ XPVCVIX0 }, /* xpvcv_list[0]  */
	{ XPVCVIX1 }, /* xpvcv_list[1]  */
};

Static PADLIST padlist_list[2] = {
	{ 1, NULL, 535, 1 }, /* padlist_list[0]  */
	{ 1, NULL, 534, 1 }, /* padlist_list[1]  */
};

Static MyPADNAME padname_list[18] = {
	{ NULL, (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 0xffffff45, 0, 0, 0x0, 0 }, /* padname_list[0]  */
	{ ((char*)&padname_list[1])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6860, 6861, 2 /* +1 */, 0, 10, 0x4, "$test_name" }, /* padname_list[1]  */
	{ ((char*)&padname_list[2])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6804, 6821, 2 /* +1 */, 0, 2, 0x4, "$a" }, /* padname_list[2]  */
	{ ((char*)&padname_list[3])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6804, 6821, 2 /* +1 */, 0, 2, 0x4, "$b" }, /* padname_list[3]  */
	{ ((char*)&padname_list[4])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6804, 6821, 2 /* +1 */, 0, 2, 0x4, "$c" }, /* padname_list[4]  */
	{ ((char*)&padname_list[5])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6823, 6850, 2 /* +1 */, 0, 2, 0x4, "$a" }, /* padname_list[5]  */
	{ ((char*)&padname_list[6])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6823, 6850, 2 /* +1 */, 0, 2, 0x4, "$b" }, /* padname_list[6]  */
	{ ((char*)&padname_list[7])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6823, 6850, 2 /* +1 */, 0, 2, 0x4, "$c" }, /* padname_list[7]  */
	{ ((char*)&padname_list[8])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6852, 6857, 2 /* +1 */, 349, 2, 0x0, "@a" }, /* padname_list[8]  */
	{ ((char*)&padname_list[9])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6853, 6857, 2 /* +1 */, 353, 2, 0x4, "@b" }, /* padname_list[9]  */
	{ ((char*)&padname_list[10])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6854, 6857, 2 /* +1 */, 351, 2, 0x4, "@c" }, /* padname_list[10]  */
	{ ((char*)&padname_list[11])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6855, 6857, 2 /* +1 */, 353, 2, 0x0, "%h" }, /* padname_list[11]  */
	{ ((char*)&padname_list[12])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6856, 6857, 2 /* +1 */, 0, 5, 0x4, "$size" }, /* padname_list[12]  */
	{ ((char*)&padname_list[13])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6856, 6857, 2 /* +1 */, 0, 1, 0x2, "$" }, /* padname_list[13]  */
	{ ((char*)&padname_list[14])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6856, 6857, 2 /* +1 */, 0, 1, 0x2, "$" }, /* padname_list[14]  */
	{ ((char*)&padname_list[15])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6862, 6865, 2 /* +1 */, 355, 4, 0x0, "@tmp" }, /* padname_list[15]  */
	{ ((char*)&padname_list[16])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6871, 6873, 2 /* +1 */, 356, 2, 0x0, "@a" }, /* padname_list[16]  */
	{ ((char*)&padname_list[17])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6872, 6873, 2 /* +1 */, 357, 2, 0x0, "@b" }, /* padname_list[17]  */
};

Static PADNAMELIST padnamelist_list[3] = {
	{ 3, NULL, 3, 1, 2 /* +1 */ }, /* padnamelist_list[0]  */
	{ 2, NULL, 2, 0, 2 /* +1 */ }, /* padnamelist_list[1]  */
	{ 180, NULL, 180, 180, 2 /* +1 */ }, /* padnamelist_list[2]  */
};

Static XPVIV xpviv_list[111] = {
	{ Nullhv, {0}, 0, 0, {63} }, /* xpviv_list[0]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[1]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[2]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[3]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[4]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[5]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[6]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[7]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[8]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[9]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[10]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[11]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[12]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[13]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[14]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[15]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[16]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[17]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[18]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[19]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[20]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[21]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[22]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[23]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[24]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[25]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[26]  */
	{ Nullhv, {0}, 0, 0, {5} }, /* xpviv_list[27]  */
	{ Nullhv, {0}, 0, 0, {6} }, /* xpviv_list[28]  */
	{ Nullhv, {0}, 0, 0, {7} }, /* xpviv_list[29]  */
	{ Nullhv, {0}, 0, 0, {8} }, /* xpviv_list[30]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[31]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[32]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[33]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[34]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[35]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[36]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[37]  */
	{ Nullhv, {0}, 0, 0, {6} }, /* xpviv_list[38]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[39]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[40]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[41]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[42]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[43]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[44]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[45]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[46]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[47]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[48]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[49]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[50]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[51]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[52]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[53]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[54]  */
	{ Nullhv, {0}, 0, 0, {666} }, /* xpviv_list[55]  */
	{ Nullhv, {0}, 0, 0, {12345} }, /* xpviv_list[56]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[57]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[58]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[59]  */
	{ Nullhv, {0}, 0, 0, {4} }, /* xpviv_list[60]  */
	{ Nullhv, {0}, 0, 0, {5} }, /* xpviv_list[61]  */
	{ Nullhv, {0}, 0, 0, {6} }, /* xpviv_list[62]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[63]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[64]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[65]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[66]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[67]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[68]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[69]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[70]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[71]  */
	{ Nullhv, {0}, 0, 0, {29} }, /* xpviv_list[72]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[73]  */
	{ Nullhv, {0}, 0, 0, {30} }, /* xpviv_list[74]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[75]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[76]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[77]  */
	{ Nullhv, {0}, 0, 0, {10} }, /* xpviv_list[78]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[79]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[80]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[81]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[82]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[83]  */
	{ Nullhv, {0}, 0, 0, {10} }, /* xpviv_list[84]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[85]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[86]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[87]  */
	{ Nullhv, {0}, 0, 0, {10} }, /* xpviv_list[88]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[89]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[90]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[91]  */
	{ Nullhv, {0}, 0, 0, {10} }, /* xpviv_list[92]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[93]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[94]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[95]  */
	{ Nullhv, {0}, 0, 0, {10} }, /* xpviv_list[96]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[97]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[98]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[99]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[100]  */
	{ Nullhv, {0}, 0, 0, {3} }, /* xpviv_list[101]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[102]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[103]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[104]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[105]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[106]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[107]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[108]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[109]  */
	{ Nullhv, {0}, 0, 0, {-1} }, /* xpviv_list[110]  */
};

Static XPVNV xpvnv_list[2] = {
	{ Nullhv, {0}, 0, 0, {0}, {} }, /* xpvnv_list[0]  */
	{ Nullhv, {0}, 0, 0, {0}, {} }, /* xpvnv_list[1]  */
};

Static XPVMG xpvmg_list[2] = {
	{ Nullhv, {0}, 16, 24, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 3, 4, {291}, {0.00} }, /* xpvmg_list[1]  */
};

Static XPVIO xpvio_list[1] = {
	{ Nullhv,{0},0,0,{0},0,{0},0,60,60,NULL,Nullgv,NULL,Nullgv,NULL,Nullgv,'>',0x0 }, /* xpvio_list[0]  */
};

Static SV sv_list[588] = {
	{ 0, 588, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */
	{ &xpv_list[0], 2147483647, 0x18014403, {0} }, /* sv_list[1]  */
	{ &xpviv_list[0], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[2]  */
	{ &xpviv_list[1], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[3]  */
	{ &xpviv_list[2], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[4]  */
	{ &xpviv_list[3], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[5]  */
	{ &xpviv_list[4], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[6]  */
	{ &xpvav_list[0], 1, 0x4000000b, {0} }, /* sv_list[7]  */
	{ &xpviv_list[5], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[8]  */
	{ &xpv_list[1], 2147483647, 0x18014403, {0} }, /* sv_list[9]  */
	{ &xpviv_list[6], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[10]  */
	{ &xpv_list[2], 2147483647, 0x18014403, {0} }, /* sv_list[11]  */
	{ &xpviv_list[7], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[12]  */
	{ &xpv_list[3], 2147483647, 0x18014403, {0} }, /* sv_list[13]  */
	{ &xpviv_list[8], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[14]  */
	{ &xpv_list[4], 2147483647, 0x18014403, {0} }, /* sv_list[15]  */
	{ &xpv_list[5], 2147483647, 0x18014403, {0} }, /* sv_list[16]  */
	{ &xpv_list[6], 2147483647, 0x18014403, {0} }, /* sv_list[17]  */
	{ &xpv_list[7], 2147483647, 0x18014403, {0} }, /* sv_list[18]  */
	{ &xpv_list[8], 2147483647, 0x18014403, {0} }, /* sv_list[19]  */
	{ &xpviv_list[9], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[20]  */
	{ &xpviv_list[10], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[21]  */
	{ &xpviv_list[11], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[22]  */
	{ &xpviv_list[12], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[23]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[24]  */
	{ &xpvav_list[1], 1, 0x4000000b, {0} }, /* sv_list[25]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[26]  */
	{ &xpvav_list[2], 1, 0x4000000b, {0} }, /* sv_list[27]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[28]  */
	{ &xpvhv_list[0], 1, 0x2000000c, {0} }, /* sv_list[29]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[30]  */
	{ &xpv_list[9], 2147483647, 0x8014403, {0} }, /* sv_list[31]  */
	{ &xpv_list[10], 2147483647, 0x8014403, {0} }, /* sv_list[32]  */
	{ &xpv_list[11], 2147483647, 0x8014403, {0} }, /* sv_list[33]  */
	{ &xpv_list[12], 2147483647, 0x18014403, {0} }, /* sv_list[34]  */
	{ &xpv_list[13], 2147483647, 0x18014403, {0} }, /* sv_list[35]  */
	{ &xpv_list[14], 2147483647, 0x18014403, {0} }, /* sv_list[36]  */
	{ &xpviv_list[13], 1, 0x1101, {.svu_pv=NULL} }, /* sv_list[37]  */
	{ &xpv_list[15], 2147483647, 0x18014403, {0} }, /* sv_list[38]  */
	{ &xpv_list[16], 2147483647, 0x8014403, {0} }, /* sv_list[39]  */
	{ &xpv_list[17], 2147483647, 0x8014403, {0} }, /* sv_list[40]  */
	{ &xpv_list[18], 2147483647, 0x18014403, {0} }, /* sv_list[41]  */
	{ &xpv_list[19], 2147483647, 0x18014403, {0} }, /* sv_list[42]  */
	{ &xpv_list[20], 2147483647, 0x18014403, {0} }, /* sv_list[43]  */
	{ &xpv_list[21], 2147483647, 0x8014403, {0} }, /* sv_list[44]  */
	{ &xpv_list[22], 2147483647, 0x8014403, {0} }, /* sv_list[45]  */
	{ &xpv_list[23], 2147483647, 0x18014403, {0} }, /* sv_list[46]  */
	{ &xpv_list[24], 2147483647, 0x18014403, {0} }, /* sv_list[47]  */
	{ &xpv_list[25], 2147483647, 0x18014403, {0} }, /* sv_list[48]  */
	{ &xpv_list[26], 2147483647, 0x8014403, {0} }, /* sv_list[49]  */
	{ &xpv_list[27], 2147483647, 0x18014403, {0} }, /* sv_list[50]  */
	{ &xpv_list[28], 2147483647, 0x18014403, {0} }, /* sv_list[51]  */
	{ &xpv_list[29], 2147483647, 0x18014403, {0} }, /* sv_list[52]  */
	{ &xpv_list[30], 2147483647, 0x8014403, {0} }, /* sv_list[53]  */
	{ &xpv_list[31], 2147483647, 0x18014403, {0} }, /* sv_list[54]  */
	{ &xpv_list[32], 2147483647, 0x18014403, {0} }, /* sv_list[55]  */
	{ &xpv_list[33], 2147483647, 0x18014403, {0} }, /* sv_list[56]  */
	{ &xpviv_list[14], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[57]  */
	{ &xpviv_list[15], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[58]  */
	{ &xpviv_list[16], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[59]  */
	{ &xpviv_list[17], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[60]  */
	{ &xpv_list[34], 1, 0x10004403, {0} }, /* sv_list[61]  */
	{ &xpv_list[35], 2147483647, 0x18014403, {0} }, /* sv_list[62]  */
	{ &xpviv_list[18], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[63]  */
	{ &xpv_list[36], 2147483647, 0x18014403, {0} }, /* sv_list[64]  */
	{ &xpviv_list[19], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[65]  */
	{ &xpv_list[37], 2147483647, 0x18014403, {0} }, /* sv_list[66]  */
	{ &xpviv_list[20], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[67]  */
	{ &xpv_list[38], 2147483647, 0x18014403, {0} }, /* sv_list[68]  */
	{ &xpv_list[39], 1, 0x10004403, {0} }, /* sv_list[69]  */
	{ &xpv_list[40], 2147483647, 0x18014403, {0} }, /* sv_list[70]  */
	{ &xpviv_list[21], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[71]  */
	{ &xpv_list[41], 2147483647, 0x18014403, {0} }, /* sv_list[72]  */
	{ &xpv_list[42], 2147483647, 0x18014403, {0} }, /* sv_list[73]  */
	{ &xpviv_list[22], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[74]  */
	{ &xpv_list[43], 2147483647, 0x18014403, {0} }, /* sv_list[75]  */
	{ &xpviv_list[23], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[76]  */
	{ &xpviv_list[24], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[77]  */
	{ &xpviv_list[25], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[78]  */
	{ &xpviv_list[26], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[79]  */
	{ &xpviv_list[27], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[80]  */
	{ &xpviv_list[28], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[81]  */
	{ &xpviv_list[29], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[82]  */
	{ &xpviv_list[30], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[83]  */
	{ &xpv_list[44], 2147483647, 0x8014403, {0} }, /* sv_list[84]  */
	{ &xpv_list[45], 2147483647, 0x8014403, {0} }, /* sv_list[85]  */
	{ &xpv_list[46], 2147483647, 0x8014403, {0} }, /* sv_list[86]  */
	{ &xpv_list[47], 2147483647, 0x18014403, {0} }, /* sv_list[87]  */
	{ &xpv_list[48], 2147483647, 0x18014403, {0} }, /* sv_list[88]  */
	{ &xpv_list[49], 2147483647, 0x18014403, {0} }, /* sv_list[89]  */
	{ &xpviv_list[31], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[90]  */
	{ &xpviv_list[32], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[91]  */
	{ &xpv_list[50], 2147483647, 0x18014403, {0} }, /* sv_list[92]  */
	{ &xpviv_list[33], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[93]  */
	{ &xpv_list[51], 2147483647, 0x18014403, {0} }, /* sv_list[94]  */
	{ &xpv_list[52], 2147483647, 0x18014403, {0} }, /* sv_list[95]  */
	{ &xpviv_list[34], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[96]  */
	{ &xpv_list[53], 2147483647, 0x18014403, {0} }, /* sv_list[97]  */
	{ &xpv_list[54], 2147483647, 0x18014403, {0} }, /* sv_list[98]  */
	{ &xpv_list[55], 2147483647, 0x18014403, {0} }, /* sv_list[99]  */
	{ &xpviv_list[35], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[100]  */
	{ &xpvav_list[3], 1, 0x4000000b, {0} }, /* sv_list[101]  */
	{ &xpv_list[56], 2147483647, 0x18014403, {0} }, /* sv_list[102]  */
	{ &xpv_list[57], 2147483647, 0x18014403, {0} }, /* sv_list[103]  */
	{ &xpv_list[58], 2147483647, 0x18014403, {0} }, /* sv_list[104]  */
	{ &xpv_list[59], 2147483647, 0x18014403, {0} }, /* sv_list[105]  */
	{ &xpviv_list[36], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[106]  */
	{ &xpviv_list[37], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[107]  */
	{ &xpv_list[60], 2147483647, 0x18014403, {0} }, /* sv_list[108]  */
	{ &xpv_list[61], 2147483647, 0x18014403, {0} }, /* sv_list[109]  */
	{ &xpv_list[62], 2147483647, 0x18014403, {0} }, /* sv_list[110]  */
	{ &xpv_list[63], 2147483647, 0x18014403, {0} }, /* sv_list[111]  */
	{ &xpv_list[64], 2147483647, 0x18014403, {0} }, /* sv_list[112]  */
	{ &xpv_list[65], 2147483647, 0x18014403, {0} }, /* sv_list[113]  */
	{ &xpviv_list[38], 1, 0x8031101, {.svu_pv=NULL} }, /* sv_list[114]  */
	{ &xpv_list[66], 2147483647, 0x18014403, {0} }, /* sv_list[115]  */
	{ &xpv_list[67], 2147483647, 0x18014403, {0} }, /* sv_list[116]  */
	{ &xpv_list[68], 2147483647, 0x18014403, {0} }, /* sv_list[117]  */
	{ &xpv_list[69], 2147483647, 0x18014403, {0} }, /* sv_list[118]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[119]  */
	{ &xpviv_list[39], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[120]  */
	{ &xpviv_list[40], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[121]  */
	{ &xpviv_list[41], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[122]  */
	{ &xpviv_list[42], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[123]  */
	{ &xpv_list[70], 2147483647, 0x18014403, {0} }, /* sv_list[124]  */
	{ &xpv_list[71], 2147483647, 0x18014403, {0} }, /* sv_list[125]  */
	{ &xpv_list[72], 2147483647, 0x18014403, {0} }, /* sv_list[126]  */
	{ &xpviv_list[43], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[127]  */
	{ &xpv_list[73], 2147483647, 0x18014403, {0} }, /* sv_list[128]  */
	{ &xpv_list[74], 2147483647, 0x18014403, {0} }, /* sv_list[129]  */
	{ &xpv_list[75], 2147483647, 0x18014403, {0} }, /* sv_list[130]  */
	{ &xpv_list[76], 2147483647, 0x18014403, {0} }, /* sv_list[131]  */
	{ &xpv_list[77], 2147483647, 0x18014403, {0} }, /* sv_list[132]  */
	{ &xpv_list[78], 2147483647, 0x18014403, {0} }, /* sv_list[133]  */
	{ &xpviv_list[44], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[134]  */
	{ &xpv_list[79], 2147483647, 0x18014403, {0} }, /* sv_list[135]  */
	{ &xpv_list[80], 2147483647, 0x18014403, {0} }, /* sv_list[136]  */
	{ &xpv_list[81], 2147483647, 0x18014403, {0} }, /* sv_list[137]  */
	{ &xpv_list[82], 2147483647, 0x18014403, {0} }, /* sv_list[138]  */
	{ &xpv_list[83], 2147483647, 0x18014403, {0} }, /* sv_list[139]  */
	{ &xpv_list[84], 2147483647, 0x18014403, {0} }, /* sv_list[140]  */
	{ &xpv_list[85], 2147483647, 0x18014403, {0} }, /* sv_list[141]  */
	{ &xpv_list[86], 2147483647, 0x18014403, {0} }, /* sv_list[142]  */
	{ &xpv_list[87], 2147483647, 0x18014403, {0} }, /* sv_list[143]  */
	{ &xpviv_list[45], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[144]  */
	{ &xpv_list[88], 2147483647, 0x18014403, {0} }, /* sv_list[145]  */
	{ &xpv_list[89], 2147483647, 0x18014403, {0} }, /* sv_list[146]  */
	{ &xpv_list[90], 2147483647, 0x18014403, {0} }, /* sv_list[147]  */
	{ &xpv_list[91], 2147483647, 0x18014403, {0} }, /* sv_list[148]  */
	{ &xpv_list[92], 2147483647, 0x18014403, {0} }, /* sv_list[149]  */
	{ &xpv_list[93], 2147483647, 0x18014403, {0} }, /* sv_list[150]  */
	{ &xpv_list[94], 2147483647, 0x18014403, {0} }, /* sv_list[151]  */
	{ &xpv_list[95], 2147483647, 0x18014403, {0} }, /* sv_list[152]  */
	{ &xpv_list[96], 2147483647, 0x18014403, {0} }, /* sv_list[153]  */
	{ &xpv_list[97], 2147483647, 0x18014403, {0} }, /* sv_list[154]  */
	{ &xpv_list[98], 2147483647, 0x18014403, {0} }, /* sv_list[155]  */
	{ &xpv_list[99], 2147483647, 0x18014403, {0} }, /* sv_list[156]  */
	{ &xpv_list[100], 2147483647, 0x18014403, {0} }, /* sv_list[157]  */
	{ &xpv_list[101], 2147483647, 0x18014403, {0} }, /* sv_list[158]  */
	{ &xpv_list[102], 2147483647, 0x18014403, {0} }, /* sv_list[159]  */
	{ &xpv_list[103], 2147483647, 0x18014403, {0} }, /* sv_list[160]  */
	{ &xpv_list[104], 2147483647, 0x18014403, {0} }, /* sv_list[161]  */
	{ &xpv_list[105], 2147483647, 0x18014403, {0} }, /* sv_list[162]  */
	{ &xpviv_list[46], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[163]  */
	{ &xpviv_list[47], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[164]  */
	{ &xpviv_list[48], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[165]  */
	{ &xpviv_list[49], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[166]  */
	{ &xpviv_list[50], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[167]  */
	{ &xpv_list[106], 2147483647, 0x18014403, {0} }, /* sv_list[168]  */
	{ &xpv_list[107], 2147483647, 0x18014403, {0} }, /* sv_list[169]  */
	{ &xpv_list[108], 2147483647, 0x18014403, {0} }, /* sv_list[170]  */
	{ &xpviv_list[51], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[171]  */
	{ &xpv_list[109], 2147483647, 0x18014403, {0} }, /* sv_list[172]  */
	{ &xpv_list[110], 2147483647, 0x18014403, {0} }, /* sv_list[173]  */
	{ &xpv_list[111], 2147483647, 0x18014403, {0} }, /* sv_list[174]  */
	{ &xpv_list[112], 2147483647, 0x18014403, {0} }, /* sv_list[175]  */
	{ &xpv_list[113], 2147483647, 0x18014403, {0} }, /* sv_list[176]  */
	{ &xpv_list[114], 2147483647, 0x18014403, {0} }, /* sv_list[177]  */
	{ &xpviv_list[52], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[178]  */
	{ &xpv_list[115], 2147483647, 0x18014403, {0} }, /* sv_list[179]  */
	{ &xpv_list[116], 2147483647, 0x18014403, {0} }, /* sv_list[180]  */
	{ &xpv_list[117], 2147483647, 0x18014403, {0} }, /* sv_list[181]  */
	{ &xpv_list[118], 2147483647, 0x18014403, {0} }, /* sv_list[182]  */
	{ &xpv_list[119], 2147483647, 0x18014403, {0} }, /* sv_list[183]  */
	{ &xpv_list[120], 2147483647, 0x18014403, {0} }, /* sv_list[184]  */
	{ &xpv_list[121], 2147483647, 0x18014403, {0} }, /* sv_list[185]  */
	{ &xpv_list[122], 2147483647, 0x18014403, {0} }, /* sv_list[186]  */
	{ &xpv_list[123], 2147483647, 0x18014403, {0} }, /* sv_list[187]  */
	{ &xpviv_list[53], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[188]  */
	{ &xpv_list[124], 2147483647, 0x18014403, {0} }, /* sv_list[189]  */
	{ &xpv_list[125], 2147483647, 0x18014403, {0} }, /* sv_list[190]  */
	{ &xpv_list[126], 2147483647, 0x18014403, {0} }, /* sv_list[191]  */
	{ &xpv_list[127], 2147483647, 0x18014403, {0} }, /* sv_list[192]  */
	{ &xpv_list[128], 2147483647, 0x18014403, {0} }, /* sv_list[193]  */
	{ &xpv_list[129], 2147483647, 0x18014403, {0} }, /* sv_list[194]  */
	{ &xpv_list[130], 2147483647, 0x18014403, {0} }, /* sv_list[195]  */
	{ &xpv_list[131], 2147483647, 0x18014403, {0} }, /* sv_list[196]  */
	{ &xpv_list[132], 2147483647, 0x18014403, {0} }, /* sv_list[197]  */
	{ &xpv_list[133], 2147483647, 0x18014403, {0} }, /* sv_list[198]  */
	{ &xpv_list[134], 2147483647, 0x18014403, {0} }, /* sv_list[199]  */
	{ &xpv_list[135], 2147483647, 0x18014403, {0} }, /* sv_list[200]  */
	{ &xpv_list[136], 2147483647, 0x18014403, {0} }, /* sv_list[201]  */
	{ &xpv_list[137], 2147483647, 0x18014403, {0} }, /* sv_list[202]  */
	{ &xpv_list[138], 2147483647, 0x18014403, {0} }, /* sv_list[203]  */
	{ &xpv_list[139], 2147483647, 0x18014403, {0} }, /* sv_list[204]  */
	{ &xpv_list[140], 2147483647, 0x18014403, {0} }, /* sv_list[205]  */
	{ &xpv_list[141], 2147483647, 0x18014403, {0} }, /* sv_list[206]  */
	{ &xpviv_list[54], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[207]  */
	{ &xpviv_list[55], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[208]  */
	{ &xpviv_list[56], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[209]  */
	{ &xpviv_list[57], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[210]  */
	{ &xpviv_list[58], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[211]  */
	{ &xpviv_list[59], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[212]  */
	{ &xpv_list[142], 2147483647, 0x18014403, {0} }, /* sv_list[213]  */
	{ &xpv_list[143], 2147483647, 0x18014403, {0} }, /* sv_list[214]  */
	{ &xpv_list[144], 2147483647, 0x18014403, {0} }, /* sv_list[215]  */
	{ &xpv_list[145], 2147483647, 0x18014403, {0} }, /* sv_list[216]  */
	{ &xpviv_list[60], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[217]  */
	{ &xpviv_list[61], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[218]  */
	{ &xpviv_list[62], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[219]  */
	{ &xpv_list[146], 2147483647, 0x18014403, {0} }, /* sv_list[220]  */
	{ &xpv_list[147], 2147483647, 0x18014403, {0} }, /* sv_list[221]  */
	{ &xpv_list[148], 2147483647, 0x18014403, {0} }, /* sv_list[222]  */
	{ &xpv_list[149], 2147483647, 0x18014403, {0} }, /* sv_list[223]  */
	{ &xpv_list[150], 2147483647, 0x8034403, {0} }, /* sv_list[224]  */
	{ &xpv_list[151], 2147483647, 0x18014403, {0} }, /* sv_list[225]  */
	{ &xpv_list[152], 2147483647, 0x18014403, {0} }, /* sv_list[226]  */
	{ &xpv_list[153], 2147483647, 0x18014403, {0} }, /* sv_list[227]  */
	{ &xpv_list[154], 2147483647, 0x8034403, {0} }, /* sv_list[228]  */
	{ &xpv_list[155], 2147483647, 0x18014403, {0} }, /* sv_list[229]  */
	{ &xpv_list[156], 2147483647, 0x18014403, {0} }, /* sv_list[230]  */
	{ &xpv_list[157], 2147483647, 0x18014403, {0} }, /* sv_list[231]  */
	{ &xpv_list[158], 2147483647, 0x8034403, {0} }, /* sv_list[232]  */
	{ &xpv_list[159], 2147483647, 0x18014403, {0} }, /* sv_list[233]  */
	{ &xpv_list[160], 2147483647, 0x18014403, {0} }, /* sv_list[234]  */
	{ &xpv_list[161], 2147483647, 0x18014403, {0} }, /* sv_list[235]  */
	{ &xpv_list[162], 2147483647, 0x8034403, {0} }, /* sv_list[236]  */
	{ &xpv_list[163], 2147483647, 0x18014403, {0} }, /* sv_list[237]  */
	{ &xpv_list[164], 2147483647, 0x18014403, {0} }, /* sv_list[238]  */
	{ &xpv_list[165], 2147483647, 0x18014403, {0} }, /* sv_list[239]  */
	{ &xpv_list[166], 2147483647, 0x8034403, {0} }, /* sv_list[240]  */
	{ &xpv_list[167], 2147483647, 0x18014403, {0} }, /* sv_list[241]  */
	{ &xpv_list[168], 2147483647, 0x18014403, {0} }, /* sv_list[242]  */
	{ &xpv_list[169], 2147483647, 0x18014403, {0} }, /* sv_list[243]  */
	{ &xpv_list[170], 2147483647, 0x8034403, {0} }, /* sv_list[244]  */
	{ &xpv_list[171], 2147483647, 0x18014403, {0} }, /* sv_list[245]  */
	{ &xpv_list[172], 2147483647, 0x18014403, {0} }, /* sv_list[246]  */
	{ &xpv_list[173], 2147483647, 0x18014403, {0} }, /* sv_list[247]  */
	{ &xpv_list[174], 2147483647, 0x8034403, {0} }, /* sv_list[248]  */
	{ &xpv_list[175], 2147483647, 0x18014403, {0} }, /* sv_list[249]  */
	{ &xpv_list[176], 2147483647, 0x18014403, {0} }, /* sv_list[250]  */
	{ &xpv_list[177], 2147483647, 0x18014403, {0} }, /* sv_list[251]  */
	{ &xpviv_list[63], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[252]  */
	{ &xpviv_list[64], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[253]  */
	{ &xpviv_list[65], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[254]  */
	{ &xpviv_list[66], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[255]  */
	{ &xpviv_list[67], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[256]  */
	{ &xpviv_list[68], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[257]  */
	{ &xpviv_list[69], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[258]  */
	{ &xpviv_list[70], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[259]  */
	{ &xpv_list[178], 2147483647, 0x18014403, {0} }, /* sv_list[260]  */
	{ &xpv_list[179], 2147483647, 0x18014403, {0} }, /* sv_list[261]  */
	{ &xpv_list[180], 2147483647, 0x18014403, {0} }, /* sv_list[262]  */
	{ &xpviv_list[71], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[263]  */
	{ &xpv_list[181], 2147483647, 0x18014403, {0} }, /* sv_list[264]  */
	{ &xpviv_list[72], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[265]  */
	{ &xpv_list[182], 2147483647, 0x18014403, {0} }, /* sv_list[266]  */
	{ &xpv_list[183], 2147483647, 0x18014403, {0} }, /* sv_list[267]  */
	{ &xpv_list[184], 2147483647, 0x18014403, {0} }, /* sv_list[268]  */
	{ &xpv_list[185], 2147483647, 0x18014403, {0} }, /* sv_list[269]  */
	{ &xpv_list[186], 2147483647, 0x18014403, {0} }, /* sv_list[270]  */
	{ &xpviv_list[73], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[271]  */
	{ &xpviv_list[74], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[272]  */
	{ &xpv_list[187], 2147483647, 0x18014403, {0} }, /* sv_list[273]  */
	{ &xpv_list[188], 2147483647, 0x18014403, {0} }, /* sv_list[274]  */
	{ &xpv_list[189], 2147483647, 0x18014403, {0} }, /* sv_list[275]  */
	{ &xpv_list[190], 2147483647, 0x18014403, {0} }, /* sv_list[276]  */
	{ &xpvav_list[4], 1, 0x4801000b, {0} }, /* sv_list[277]  */
	{ &xpviv_list[75], 1, 0x8031101, {.svu_pv=NULL} }, /* sv_list[278]  */
	{ &xpv_list[191], 2147483647, 0x18014403, {0} }, /* sv_list[279]  */
	{ &xpv_list[192], 2147483647, 0x18014403, {0} }, /* sv_list[280]  */
	{ &xpv_list[193], 2147483647, 0x18014403, {0} }, /* sv_list[281]  */
	{ &xpv_list[194], 2147483647, 0x18014403, {0} }, /* sv_list[282]  */
	{ &xpviv_list[76], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[283]  */
	{ &xpviv_list[77], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[284]  */
	{ &xpviv_list[78], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[285]  */
	{ &xpviv_list[79], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[286]  */
	{ CVIX287 }, /* sv_list[287]  */
	{ &xpviv_list[80], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[288]  */
	{ &xpvav_list[5], 1, 0x4000000b, {0} }, /* sv_list[289]  */
	{ &xpvav_list[6], 1, 0x8000000b, {0} }, /* sv_list[290]  */
	{ 0, 1, 0x40000, {0} }, /* sv_list[291]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[292]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[293]  */
	{ ptr_undef, 8, 0x801, {.svu_rv=&sv_list[287]} }, /* sv_list[294]  */
	{ &xpv_list[195], 2147483647, 0x18014403, {0} }, /* sv_list[295]  */
	{ &xpviv_list[81], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[296]  */
	{ &xpviv_list[82], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[297]  */
	{ &xpviv_list[83], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[298]  */
	{ &xpviv_list[84], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[299]  */
	{ &xpviv_list[85], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[300]  */
	{ &xpv_list[196], 2147483647, 0x18014403, {0} }, /* sv_list[301]  */
	{ &xpviv_list[86], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[302]  */
	{ &xpviv_list[87], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[303]  */
	{ &xpviv_list[88], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[304]  */
	{ &xpviv_list[89], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[305]  */
	{ &xpv_list[197], 2147483647, 0x18014403, {0} }, /* sv_list[306]  */
	{ &xpviv_list[90], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[307]  */
	{ &xpviv_list[91], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[308]  */
	{ &xpviv_list[92], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[309]  */
	{ &xpviv_list[93], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[310]  */
	{ &xpv_list[198], 2147483647, 0x18014403, {0} }, /* sv_list[311]  */
	{ &xpviv_list[94], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[312]  */
	{ &xpviv_list[95], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[313]  */
	{ &xpviv_list[96], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[314]  */
	{ &xpviv_list[97], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[315]  */
	{ &xpv_list[199], 2147483647, 0x18014403, {0} }, /* sv_list[316]  */
	{ &xpviv_list[98], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[317]  */
	{ &xpviv_list[99], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[318]  */
	{ &xpv_list[200], 2147483647, 0x18014403, {0} }, /* sv_list[319]  */
	{ &xpv_list[201], 2147483647, 0x18014403, {0} }, /* sv_list[320]  */
	{ &xpv_list[202], 2147483647, 0x18014403, {0} }, /* sv_list[321]  */
	{ &xpviv_list[100], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[322]  */
	{ &xpviv_list[101], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[323]  */
	{ &xpv_list[203], 2147483647, 0x18014403, {0} }, /* sv_list[324]  */
	{ &xpviv_list[102], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[325]  */
	{ &xpviv_list[103], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[326]  */
	{ &xpviv_list[104], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[327]  */
	{ &xpviv_list[105], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[328]  */
	{ &xpviv_list[106], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[329]  */
	{ &xpv_list[204], 2147483647, 0x18014403, {0} }, /* sv_list[330]  */
	{ &xpv_list[205], 2147483647, 0x18014403, {0} }, /* sv_list[331]  */
	{ &xpv_list[206], 2147483647, 0x18014403, {0} }, /* sv_list[332]  */
	{ &xpviv_list[107], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[333]  */
	{ &xpviv_list[108], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[334]  */
	{ &xpviv_list[109], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[335]  */
	{ &xpv_list[207], 2147483647, 0x18014403, {0} }, /* sv_list[336]  */
	{ &xpv_list[208], 2147483647, 0x18014403, {0} }, /* sv_list[337]  */
	{ &xpv_list[209], 2147483647, 0x18014403, {0} }, /* sv_list[338]  */
	{ &xpv_list[210], 2147483647, 0x18014403, {0} }, /* sv_list[339]  */
	{ &xpv_list[211], 2147483647, 0x18014403, {0} }, /* sv_list[340]  */
	{ &xpv_list[212], 2147483647, 0x18014403, {0} }, /* sv_list[341]  */
	{ &xpv_list[213], 2147483647, 0x18014403, {0} }, /* sv_list[342]  */
	{ &xpv_list[214], 2147483647, 0x18014403, {0} }, /* sv_list[343]  */
	{ &xpv_list[215], 2147483647, 0x18014403, {0} }, /* sv_list[344]  */
	{ &xpviv_list[110], 1, 0x8031101, {.svu_pv=NULL} }, /* sv_list[345]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[346]  */
	{ &xpvmg_list[0], 1, 0x10604407, {.svu_pv=(char*)pv2} }, /* sv_list[347]  */
	{ &xpvmg_list[1], 1, 0x605507, {.svu_pv=(char*)pv3} }, /* sv_list[348]  */
	{ &xpvav_list[7], 1, 0x4000000b, {0} }, /* sv_list[349]  */
	{ CVIX350 }, /* sv_list[350]  */
	{ &xpv_list[216], 2147483647, 0x18014403, {0} }, /* sv_list[351]  */
	{ &xpv_list[217], 2147483647, 0x18014403, {0} }, /* sv_list[352]  */
	{ &xpvav_list[8], 1, 0x4000000b, {0} }, /* sv_list[353]  */
	{ &xpv_list[218], 1, 0x4403, {0} }, /* sv_list[354]  */
	{ &xpv_list[219], 1, 0x4403, {0} }, /* sv_list[355]  */
	{ &xpv_list[220], 1, 0x4403, {0} }, /* sv_list[356]  */
	{ &xpv_list[221], 1, 0x4403, {0} }, /* sv_list[357]  */
	{ &xpv_list[222], 1, 0x4403, {0} }, /* sv_list[358]  */
	{ &xpv_list[223], 1, 0x4403, {0} }, /* sv_list[359]  */
	{ &xpv_list[224], 1, 0x4403, {0} }, /* sv_list[360]  */
	{ &xpv_list[225], 1, 0x4403, {0} }, /* sv_list[361]  */
	{ &xpv_list[226], 1, 0x4403, {0} }, /* sv_list[362]  */
	{ &xpv_list[227], 1, 0x4403, {0} }, /* sv_list[363]  */
	{ &xpv_list[228], 1, 0x4403, {0} }, /* sv_list[364]  */
	{ &xpv_list[229], 1, 0x4403, {0} }, /* sv_list[365]  */
	{ &xpv_list[230], 1, 0x4403, {0} }, /* sv_list[366]  */
	{ &xpv_list[231], 1, 0x4403, {0} }, /* sv_list[367]  */
	{ &xpv_list[232], 1, 0x4403, {0} }, /* sv_list[368]  */
	{ &xpv_list[233], 1, 0x4403, {0} }, /* sv_list[369]  */
	{ &xpv_list[234], 1, 0x4403, {0} }, /* sv_list[370]  */
	{ &xpv_list[235], 1, 0x4403, {0} }, /* sv_list[371]  */
	{ &xpv_list[236], 1, 0x4403, {0} }, /* sv_list[372]  */
	{ &xpv_list[237], 1, 0x4403, {0} }, /* sv_list[373]  */
	{ &xpv_list[238], 1, 0x4403, {0} }, /* sv_list[374]  */
	{ &xpv_list[239], 1, 0x4403, {0} }, /* sv_list[375]  */
	{ &xpv_list[240], 1, 0x4403, {0} }, /* sv_list[376]  */
	{ &xpv_list[241], 1, 0x4403, {0} }, /* sv_list[377]  */
	{ &xpv_list[242], 1, 0x4403, {0} }, /* sv_list[378]  */
	{ &xpv_list[243], 1, 0x4403, {0} }, /* sv_list[379]  */
	{ &xpv_list[244], 1, 0x4403, {0} }, /* sv_list[380]  */
	{ &xpv_list[245], 1, 0x4403, {0} }, /* sv_list[381]  */
	{ &xpv_list[246], 1, 0x4403, {0} }, /* sv_list[382]  */
	{ &xpv_list[247], 1, 0x4403, {0} }, /* sv_list[383]  */
	{ &xpv_list[248], 1, 0x4403, {0} }, /* sv_list[384]  */
	{ &xpv_list[249], 1, 0x4403, {0} }, /* sv_list[385]  */
	{ &xpv_list[250], 1, 0x4403, {0} }, /* sv_list[386]  */
	{ &xpv_list[251], 1, 0x4403, {0} }, /* sv_list[387]  */
	{ &xpv_list[252], 1, 0x4403, {0} }, /* sv_list[388]  */
	{ &xpv_list[253], 1, 0x4403, {0} }, /* sv_list[389]  */
	{ &xpv_list[254], 1, 0x4403, {0} }, /* sv_list[390]  */
	{ &xpv_list[255], 1, 0x4403, {0} }, /* sv_list[391]  */
	{ &xpv_list[256], 1, 0x4403, {0} }, /* sv_list[392]  */
	{ &xpv_list[257], 1, 0x4403, {0} }, /* sv_list[393]  */
	{ &xpv_list[258], 1, 0x4403, {0} }, /* sv_list[394]  */
	{ &xpv_list[259], 1, 0x4403, {0} }, /* sv_list[395]  */
	{ &xpv_list[260], 1, 0x4403, {0} }, /* sv_list[396]  */
	{ &xpv_list[261], 1, 0x4403, {0} }, /* sv_list[397]  */
	{ &xpv_list[262], 1, 0x4403, {0} }, /* sv_list[398]  */
	{ &xpv_list[263], 1, 0x4403, {0} }, /* sv_list[399]  */
	{ &xpv_list[264], 1, 0x4403, {0} }, /* sv_list[400]  */
	{ &xpv_list[265], 1, 0x4403, {0} }, /* sv_list[401]  */
	{ &xpv_list[266], 1, 0x4403, {0} }, /* sv_list[402]  */
	{ &xpv_list[267], 1, 0x4403, {0} }, /* sv_list[403]  */
	{ &xpv_list[268], 1, 0x4403, {0} }, /* sv_list[404]  */
	{ &xpv_list[269], 1, 0x4403, {0} }, /* sv_list[405]  */
	{ &xpv_list[270], 1, 0x4403, {0} }, /* sv_list[406]  */
	{ &xpv_list[271], 1, 0x4403, {0} }, /* sv_list[407]  */
	{ &xpv_list[272], 1, 0x4403, {0} }, /* sv_list[408]  */
	{ &xpvav_list[9], 1, 0x4000000b, {0} }, /* sv_list[409]  */
	{ &xpvav_list[10], 1, 0x8000000b, {0} }, /* sv_list[410]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[411]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[412]  */
	{ &xpvav_list[11], 1, 0x4000000b, {0} }, /* sv_list[413]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[414]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[415]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[416]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[417]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[418]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[419]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[420]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[421]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[422]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[423]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[424]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[425]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[426]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[427]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[428]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[429]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[430]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[431]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[432]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[433]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[434]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[435]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[436]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[437]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[438]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[439]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[440]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[441]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[442]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[443]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[444]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[445]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[446]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[447]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[448]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[449]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[450]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[451]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[452]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[453]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[454]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[455]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[456]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[457]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[458]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[459]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[460]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[461]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[462]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[463]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[464]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[465]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[466]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[467]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[468]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[469]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[470]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[471]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[472]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[473]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[474]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[475]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[476]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[477]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[478]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[479]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[480]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[481]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[482]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[483]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[484]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[485]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[486]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[487]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[488]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[489]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[490]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[491]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[492]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[493]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[494]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[495]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[496]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[497]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[498]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[499]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[500]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[501]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[502]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[503]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[504]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[505]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[506]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[507]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[508]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[509]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[510]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[511]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[512]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[513]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[514]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[515]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[516]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[517]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[518]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[519]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[520]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[521]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[522]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[523]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[524]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[525]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[526]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[527]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[528]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[529]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[530]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[531]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[532]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[533]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[534]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[535]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[536]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[537]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[538]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[539]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[540]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[541]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[542]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[543]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[544]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[545]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[546]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[547]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[548]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[549]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[550]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[551]  */
	{ &xpvav_list[12], 1, 0x4000000b, {0} }, /* sv_list[552]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[553]  */
	{ &xpvav_list[13], 1, 0x4000000b, {0} }, /* sv_list[554]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[555]  */
	{ &xpvav_list[14], 1, 0x4000000b, {0} }, /* sv_list[556]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[557]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[558]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[559]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[560]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[561]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[562]  */
	{ &xpvhv_list[1], 1, 0x2000000c, {0} }, /* sv_list[563]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[564]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[565]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[566]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[567]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[568]  */
	{ &xpvnv_list[0], 1, 0x6 , {.svu_pv=(char*)NULL} }, /* sv_list[569]  */
	{ &xpvnv_list[1], 1, 0x6 , {.svu_pv=(char*)NULL} }, /* sv_list[570]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[571]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[572]  */
	{ &xpvav_list[15], 1, 0x4000000b, {0} }, /* sv_list[573]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[574]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[575]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[576]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[577]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[578]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[579]  */
	{ &xpvav_list[16], 1, 0x4000000b, {0} }, /* sv_list[580]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[581]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[582]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[583]  */
	{ &xpvav_list[17], 1, 0x4000000b, {0} }, /* sv_list[584]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[585]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[586]  */
	{ &xpvhv_list[2], 1, 0x2200000c, {0} }, /* sv_list[587]  */
};

static void perl_init0(pTHX) /* fixup_ppaddr */
{
	register int i;
	for (i = 0; i < 101; ++i) {
		binop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(binop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 121; ++i) {
		cop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(cop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 49; ++i) {
		listop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(listop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 15; ++i) {
		logop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(logop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 8; ++i) {
		loop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(loop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 268; ++i) {
		op_list[i].op_ppaddr = PL_ppaddr[PTR2IV(op_list[i].op_ppaddr)];
	}
	for (i = 0; i < 2; ++i) {
		pmop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(pmop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 500; ++i) {
		svop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(svop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 439; ++i) {
		unop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(unop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 2; ++i) {
		unopaux_list[i].op_ppaddr = PL_ppaddr[PTR2IV(unopaux_list[i].op_ppaddr)];
	}
};

static void perl_init_aaaa(pTHX)
{
	hv0 = gv_stashpvn(pv0, 4, 4|GV_ADD);
	CopSTASH_set(&cop_list[0], hv0);
	CopFILE_set(&cop_list[0], pv1);
	CopSTASH_set(&cop_list[1], hv0);
	CopFILE_set(&cop_list[1], pv1);
	sv_list[1].sv_u.svu_pv = savepvn("tests\000\001", 7);
	gv_list[0] = gv_fetchpvn_flags("plan", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[0]) = 0x8009;
	GvFLAGS(gv_list[0]) = 0x2; 
	GvLINE(gv_list[0]) = 8;
	SvREFCNT(gv_list[0]) = 2;
	hek0 = share_hek("t/CORE/op/list.t", 16, 0);
	GvFILE_HEK(gv_list[0]) = hek0;
	
	svop_list[2].op_sv = (SV*)gv_list[0];
	CopSTASH_set(&cop_list[2], hv0);
	CopFILE_set(&cop_list[2], pv1);
	gv_list[1] = gv_fetchpvn_flags("foo", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[1]) = 0x8009;
	GvFLAGS(gv_list[1]) = 0x2; 
	GvLINE(gv_list[1]) = 10;
	SvREFCNT(gv_list[1]) = 16;
	GvAV(gv_list[1]) = (AV*)&sv_list[7];
	GvFILE_HEK(gv_list[1]) = share_hek_hek(hek0);
	
	svop_list[7].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[3], hv0);
	CopFILE_set(&cop_list[3], pv1);
	svop_list[8].op_sv = (SV*)gv_list[1];
	sv_list[9].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[11].sv_u.svu_pv = savepvn("first elem\000\001", 12);
	gv_list[2] = gv_fetchpvn_flags("cmp_ok", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[2]) = 0x8009;
	GvFLAGS(gv_list[2]) = 0x2; 
	GvLINE(gv_list[2]) = 11;
	SvREFCNT(gv_list[2]) = 51;
	GvFILE_HEK(gv_list[2]) = share_hek_hek(hek0);
	
	svop_list[13].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[4], hv0);
	CopFILE_set(&cop_list[4], pv1);
	svop_list[14].op_sv = (SV*)gv_list[1];
	sv_list[13].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[15].sv_u.svu_pv = savepvn("last elem\000\001", 11);
	svop_list[19].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[5], hv0);
	CopFILE_set(&cop_list[5], pv1);
	svop_list[20].op_sv = (SV*)gv_list[1];
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x2; 
	GvLINE(PL_defgv) = 0;
	SvREFCNT(PL_defgv) = 513;
	svop_list[21].op_sv = (SV*)PL_defgv;
	sv_list[16].sv_u.svu_pv = savepvn(":\000\001", 3);
	CopSTASH_set(&cop_list[6], hv0);
	CopFILE_set(&cop_list[6], pv1);
	svop_list[23].op_sv = (SV*)PL_defgv;
	sv_list[17].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[18].sv_u.svu_pv = savepvn("1:2:3:4\000\001", 9);
	sv_list[19].sv_u.svu_pv = savepvn("join list\000\001", 11);
	svop_list[27].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[7], hv0);
	CopFILE_set(&cop_list[7], pv1);
	gv_list[4] = gv_fetchpvn_flags("a", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[4]) = 0x8009;
	GvFLAGS(gv_list[4]) = 0x2; 
	GvLINE(gv_list[4]) = 17;
	SvREFCNT(gv_list[4]) = 25;
	GvSVn(gv_list[4]) = (SV*)&sv_list[24];
	GvAV(gv_list[4]) = (AV*)&sv_list[25];
	GvFILE_HEK(gv_list[4]) = share_hek_hek(hek0);
	
	svop_list[32].op_sv = (SV*)gv_list[4];
	gv_list[5] = gv_fetchpvn_flags("b", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[5]) = 0x8009;
	GvFLAGS(gv_list[5]) = 0x2; 
	GvLINE(gv_list[5]) = 17;
	SvREFCNT(gv_list[5]) = 21;
	GvSVn(gv_list[5]) = (SV*)&sv_list[26];
	GvAV(gv_list[5]) = (AV*)&sv_list[27];
	GvFILE_HEK(gv_list[5]) = share_hek_hek(hek0);
	
	svop_list[33].op_sv = (SV*)gv_list[5];
	gv_list[6] = gv_fetchpvn_flags("c", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[6]) = 0x8009;
	GvFLAGS(gv_list[6]) = 0x2; 
	GvLINE(gv_list[6]) = 17;
	SvREFCNT(gv_list[6]) = 14;
	GvSVn(gv_list[6]) = (SV*)&sv_list[28];
	HvTOTALKEYS((HV*)&sv_list[29]) = 0;
	GvHV(gv_list[6]) = (HV*)&sv_list[29];
	GvFILE_HEK(gv_list[6]) = share_hek_hek(hek0);
	
	svop_list[34].op_sv = (SV*)gv_list[6];
	gv_list[7] = gv_fetchpvn_flags("d", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[7]) = 0x8009;
	GvFLAGS(gv_list[7]) = 0x2; 
	GvLINE(gv_list[7]) = 17;
	SvREFCNT(gv_list[7]) = 9;
	GvSVn(gv_list[7]) = (SV*)&sv_list[30];
	GvFILE_HEK(gv_list[7]) = share_hek_hek(hek0);
	
	svop_list[35].op_sv = (SV*)gv_list[7];
	CopSTASH_set(&cop_list[8], hv0);
	CopFILE_set(&cop_list[8], pv1);
	svop_list[36].op_sv = (SV*)gv_list[4];
	sv_list[31].sv_u.svu_pv = savepvn(";", 1);
	svop_list[38].op_sv = (SV*)gv_list[5];
	sv_list[32].sv_u.svu_pv = savepvn(";", 1);
	svop_list[40].op_sv = (SV*)gv_list[6];
	sv_list[33].sv_u.svu_pv = savepvn(";", 1);
	svop_list[42].op_sv = (SV*)gv_list[7];
	sv_list[34].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[35].sv_u.svu_pv = savepvn("1;2;3;4\000\001", 9);
	sv_list[36].sv_u.svu_pv = savepvn("list assign\000\001", 13);
	svop_list[46].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[9], hv0);
	CopFILE_set(&cop_list[9], pv1);
	pmop_list[0].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[0], CALLREGCOMP(newSVpvn_flags(" ", 1, SVs_TEMP|0), 0x0));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[0])) = 0x680000;
	sv_list[38].sv_u.svu_pv = savepvn("111 222 333\000\001", 13);
	svop_list[49].op_sv = (SV*)gv_list[6];
	svop_list[50].op_sv = (SV*)gv_list[5];
	svop_list[51].op_sv = (SV*)gv_list[4];
	CopSTASH_set(&cop_list[10], hv0);
	CopFILE_set(&cop_list[10], pv1);
	svop_list[52].op_sv = (SV*)gv_list[4];
	sv_list[39].sv_u.svu_pv = savepvn(";", 1);
	svop_list[54].op_sv = (SV*)gv_list[5];
	sv_list[40].sv_u.svu_pv = savepvn(";", 1);
	svop_list[56].op_sv = (SV*)gv_list[6];
	sv_list[41].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[42].sv_u.svu_pv = savepvn("333;222;111\000\001", 13);
	sv_list[43].sv_u.svu_pv = savepvn("list split on space\000\001", 21);
	svop_list[60].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[11], hv0);
	CopFILE_set(&cop_list[11], pv1);
	svop_list[61].op_sv = (SV*)gv_list[6];
	svop_list[62].op_sv = (SV*)gv_list[5];
	svop_list[63].op_sv = (SV*)gv_list[4];
	svop_list[64].op_sv = (SV*)gv_list[4];
	svop_list[65].op_sv = (SV*)gv_list[5];
	svop_list[66].op_sv = (SV*)gv_list[6];
	CopSTASH_set(&cop_list[12], hv0);
	CopFILE_set(&cop_list[12], pv1);
	svop_list[67].op_sv = (SV*)gv_list[4];
	sv_list[44].sv_u.svu_pv = savepvn(";", 1);
	svop_list[69].op_sv = (SV*)gv_list[5];
	sv_list[45].sv_u.svu_pv = savepvn(";", 1);
	svop_list[71].op_sv = (SV*)gv_list[6];
	sv_list[46].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[47].sv_u.svu_pv = savepvn("111;222;333\000\001", 13);
	sv_list[48].sv_u.svu_pv = savepvn("trio rotate\000\001", 13);
	svop_list[75].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[13], hv0);
	CopFILE_set(&cop_list[13], pv1);
	svop_list[76].op_sv = (SV*)gv_list[5];
	svop_list[77].op_sv = (SV*)gv_list[4];
	svop_list[78].op_sv = (SV*)gv_list[4];
	svop_list[79].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[14], hv0);
	CopFILE_set(&cop_list[14], pv1);
	svop_list[80].op_sv = (SV*)gv_list[4];
	sv_list[49].sv_u.svu_pv = savepvn("-", 1);
	svop_list[82].op_sv = (SV*)gv_list[5];
	sv_list[50].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[51].sv_u.svu_pv = savepvn("222-111\000\001", 9);
	sv_list[52].sv_u.svu_pv = savepvn("duo swap\000\001", 10);
	svop_list[86].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[15], hv0);
	CopFILE_set(&cop_list[15], pv1);
	svop_list[87].op_sv = (SV*)gv_list[4];
	svop_list[88].op_sv = (SV*)gv_list[5];
	svop_list[89].op_sv = (SV*)gv_list[5];
	svop_list[90].op_sv = (SV*)gv_list[4];
	svop_list[91].op_sv = (SV*)gv_list[4];
	svop_list[92].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[16], hv0);
	CopFILE_set(&cop_list[16], pv1);
	svop_list[93].op_sv = (SV*)gv_list[4];
	sv_list[53].sv_u.svu_pv = savepvn("-", 1);
	svop_list[95].op_sv = (SV*)gv_list[5];
	sv_list[54].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[55].sv_u.svu_pv = savepvn("222-111\000\001", 9);
	sv_list[56].sv_u.svu_pv = savepvn("duo swap swap\000\001", 15);
	svop_list[99].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[17], hv0);
	CopFILE_set(&cop_list[17], pv1);
	svop_list[104].op_sv = (SV*)gv_list[4];
	svop_list[105].op_sv = (SV*)gv_list[5];
	hek1 = share_hek("2", 1, 0);
	sv_list[61].sv_u.svu_pv = HEK_KEY(hek1);
	svop_list[106].op_sv = (SV*)gv_list[7];
	CopSTASH_set(&cop_list[18], hv0);
	CopFILE_set(&cop_list[18], pv1);
	svop_list[107].op_sv = (SV*)gv_list[4];
	sv_list[62].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[64].sv_u.svu_pv = savepvn("assign scalar in list\000\001", 23);
	svop_list[111].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[19], hv0);
	CopFILE_set(&cop_list[19], pv1);
	svop_list[112].op_sv = (SV*)gv_list[5];
	sv_list[66].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[68].sv_u.svu_pv = savepvn("assign aelem in list\000\001", 22);
	svop_list[117].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[20], hv0);
	CopFILE_set(&cop_list[20], pv1);
	sv_list[69].sv_u.svu_pv = HEK_KEY(share_hek_hek(hek1));
	sv_list[70].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[72].sv_u.svu_pv = savepvn("assign helem in list\000\001", 22);
	svop_list[121].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[21], hv0);
	CopFILE_set(&cop_list[21], pv1);
	svop_list[122].op_sv = (SV*)gv_list[7];
	sv_list[73].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[75].sv_u.svu_pv = savepvn("assign last scalar in list\000\001", 28);
	svop_list[126].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[22], hv0);
	CopFILE_set(&cop_list[22], pv1);
	svop_list[135].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[23], hv0);
	CopFILE_set(&cop_list[23], pv1);
	svop_list[136].op_sv = (SV*)gv_list[1];
	svop_list[137].op_sv = (SV*)gv_list[4];
	svop_list[138].op_sv = (SV*)gv_list[5];
	svop_list[139].op_sv = (SV*)gv_list[6];
	svop_list[140].op_sv = (SV*)gv_list[7];
	CopSTASH_set(&cop_list[24], hv0);
	CopFILE_set(&cop_list[24], pv1);
	svop_list[141].op_sv = (SV*)gv_list[4];
	sv_list[84].sv_u.svu_pv = savepvn("/", 1);
	svop_list[143].op_sv = (SV*)gv_list[5];
	sv_list[85].sv_u.svu_pv = savepvn("/", 1);
	svop_list[145].op_sv = (SV*)gv_list[6];
	sv_list[86].sv_u.svu_pv = savepvn("/", 1);
	svop_list[147].op_sv = (SV*)gv_list[7];
	sv_list[87].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[88].sv_u.svu_pv = savepvn("1/2/3/4\000\001", 9);
	sv_list[89].sv_u.svu_pv = savepvn("long list assign\000\001", 18);
	svop_list[151].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[25], hv0);
	CopFILE_set(&cop_list[25], pv1);
	svop_list[154].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[26], hv0);
	CopFILE_set(&cop_list[26], pv1);
	svop_list[155].op_sv = (SV*)gv_list[1];
	svop_list[156].op_sv = (SV*)gv_list[4];
	svop_list[157].op_sv = (SV*)gv_list[5];
	svop_list[158].op_sv = (SV*)gv_list[6];
	svop_list[159].op_sv = (SV*)gv_list[7];
	CopSTASH_set(&cop_list[27], hv0);
	CopFILE_set(&cop_list[27], pv1);
	svop_list[160].op_sv = (SV*)gv_list[4];
	sv_list[92].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[94].sv_u.svu_pv = savepvn("short list 1 defined\000\001", 22);
	svop_list[164].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[28], hv0);
	CopFILE_set(&cop_list[28], pv1);
	svop_list[165].op_sv = (SV*)gv_list[5];
	sv_list[95].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[97].sv_u.svu_pv = savepvn("short list 2 defined\000\001", 22);
	svop_list[169].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[29], hv0);
	CopFILE_set(&cop_list[29], pv1);
	svop_list[170].op_sv = (SV*)gv_list[6];
	sv_list[98].sv_u.svu_pv = savepvn("short list 3 undef\000\001", 20);
	gv_list[8] = gv_fetchpvn_flags("ok", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[8]) = 0x8009;
	GvFLAGS(gv_list[8]) = 0x2; 
	GvLINE(gv_list[8]) = 46;
	SvREFCNT(gv_list[8]) = 3;
	GvFILE_HEK(gv_list[8]) = share_hek_hek(hek0);
	
	svop_list[172].op_sv = (SV*)gv_list[8];
	CopSTASH_set(&cop_list[30], hv0);
	CopFILE_set(&cop_list[30], pv1);
	svop_list[173].op_sv = (SV*)gv_list[7];
	sv_list[99].sv_u.svu_pv = savepvn("short list 4 undef\000\001", 20);
	svop_list[175].op_sv = (SV*)gv_list[8];
	CopSTASH_set(&cop_list[31], hv0);
	CopFILE_set(&cop_list[31], pv1);
	gv_list[9] = gv_fetchpvn_flags("bar", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[9]) = 0x8009;
	GvFLAGS(gv_list[9]) = 0x2; 
	GvLINE(gv_list[9]) = 49;
	SvREFCNT(gv_list[9]) = 5;
	GvAV(gv_list[9]) = (AV*)&sv_list[101];
	GvFILE_HEK(gv_list[9]) = share_hek_hek(hek0);
	
	svop_list[177].op_sv = (SV*)gv_list[9];
	svop_list[178].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[32], hv0);
	CopFILE_set(&cop_list[32], pv1);
	svop_list[179].op_sv = (SV*)gv_list[9];
	sv_list[102].sv_u.svu_pv = savepvn(":\000\001", 3);
	svop_list[181].op_sv = (SV*)gv_list[1];
	sv_list[103].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[104].sv_u.svu_pv = savepvn("1:1\000\001", 5);
	sv_list[105].sv_u.svu_pv = savepvn("list reassign\000\001", 15);
	svop_list[185].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[33], hv0);
	CopFILE_set(&cop_list[33], pv1);
	svop_list[188].op_sv = (SV*)gv_list[9];
	svop_list[189].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[34], hv0);
	CopFILE_set(&cop_list[34], pv1);
	svop_list[190].op_sv = (SV*)gv_list[9];
	sv_list[108].sv_u.svu_pv = savepvn(":\000\001", 3);
	svop_list[192].op_sv = (SV*)gv_list[1];
	sv_list[109].sv_u.svu_pv = savepvn("+\000\001", 3);
	sv_list[110].sv_u.svu_pv = savepvn("-\000\001", 3);
	sv_list[111].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[112].sv_u.svu_pv = savepvn("2+3:2-3\000\001", 9);
	sv_list[113].sv_u.svu_pv = savepvn("long list reassign\000\001", 20);
	svop_list[198].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[35], hv0);
	CopFILE_set(&cop_list[35], pv1);
	svop_list[199].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[36], hv0);
	CopFILE_set(&cop_list[36], pv1);
	svop_list[201].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[37], hv0);
	CopFILE_set(&cop_list[37], pv1);
	svop_list[202].op_sv = (SV*)gv_list[1];
	sv_list[115].sv_u.svu_pv = savepvn(":\000\001", 3);
	sv_list[116].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[117].sv_u.svu_pv = savepvn("6\000\001", 3);
	sv_list[118].sv_u.svu_pv = savepvn("scalar assign to array\000\001", 24);
	svop_list[207].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[38], hv0);
	CopFILE_set(&cop_list[38], pv1);
	CopSTASH_set(&cop_list[39], hv0);
	CopFILE_set(&cop_list[39], pv1);
	gv_list[10] = gv_fetchpvn_flags("x", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[10]) = 0x8009;
	GvFLAGS(gv_list[10]) = 0x2; 
	GvLINE(gv_list[10]) = 61;
	SvREFCNT(gv_list[10]) = 23;
	GvSVn(gv_list[10]) = (SV*)&sv_list[119];
	GvFILE_HEK(gv_list[10]) = share_hek_hek(hek0);
	
	svop_list[208].op_sv = (SV*)gv_list[10];
	svop_list[209].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[40], hv0);
	CopFILE_set(&cop_list[40], pv1);
	svop_list[212].op_sv = (SV*)gv_list[10];
	svop_list[213].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[41], hv0);
	CopFILE_set(&cop_list[41], pv1);
	svop_list[215].op_sv = (SV*)gv_list[10];
	sv_list[124].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[125].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[126].sv_u.svu_pv = savepvn("c\000\001", 3);
	svop_list[220].op_sv = (SV*)gv_list[10];
	sv_list[128].sv_u.svu_pv = savepvn("d\000\001", 3);
	sv_list[129].sv_u.svu_pv = savepvn("e\000\001", 3);
	sv_list[130].sv_u.svu_pv = savepvn("f\000\001", 3);
	sv_list[131].sv_u.svu_pv = savepvn("g\000\001", 3);
	sv_list[132].sv_u.svu_pv = savepvn("h\000\001", 3);
	sv_list[133].sv_u.svu_pv = savepvn("i\000\001", 3);
	CopSTASH_set(&cop_list[42], hv0);
	CopFILE_set(&cop_list[42], pv1);
	svop_list[228].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[43], hv0);
	CopFILE_set(&cop_list[43], pv1);
	sv_list[135].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[136].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[137].sv_u.svu_pv = savepvn("ternary for a 1\000\001", 17);
	svop_list[233].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[44], hv0);
	CopFILE_set(&cop_list[44], pv1);
	sv_list[138].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[139].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[140].sv_u.svu_pv = savepvn("ternary for b 1\000\001", 17);
	svop_list[237].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[45], hv0);
	CopFILE_set(&cop_list[45], pv1);
	sv_list[141].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[142].sv_u.svu_pv = savepvn("c\000\001", 3);
	sv_list[143].sv_u.svu_pv = savepvn("ternary for c 1\000\001", 17);
	svop_list[241].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[46], hv0);
	CopFILE_set(&cop_list[46], pv1);
	svop_list[242].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[47], hv0);
	CopFILE_set(&cop_list[47], pv1);
	sv_list[145].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[146].sv_u.svu_pv = savepvn("d\000\001", 3);
	sv_list[147].sv_u.svu_pv = savepvn("ternary for a 2\000\001", 17);
	svop_list[247].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[48], hv0);
	CopFILE_set(&cop_list[48], pv1);
	sv_list[148].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[149].sv_u.svu_pv = savepvn("e\000\001", 3);
	sv_list[150].sv_u.svu_pv = savepvn("ternary for b 2\000\001", 17);
	svop_list[251].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[49], hv0);
	CopFILE_set(&cop_list[49], pv1);
	sv_list[151].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[152].sv_u.svu_pv = savepvn("f\000\001", 3);
	sv_list[153].sv_u.svu_pv = savepvn("ternary for c 2\000\001", 17);
	svop_list[255].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[50], hv0);
	CopFILE_set(&cop_list[50], pv1);
	CopSTASH_set(&cop_list[51], hv0);
	CopFILE_set(&cop_list[51], pv1);
	sv_list[154].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[155].sv_u.svu_pv = savepvn("g\000\001", 3);
	sv_list[156].sv_u.svu_pv = savepvn("ternary for a 3\000\001", 17);
	svop_list[259].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[52], hv0);
	CopFILE_set(&cop_list[52], pv1);
	sv_list[157].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[158].sv_u.svu_pv = savepvn("h\000\001", 3);
	sv_list[159].sv_u.svu_pv = savepvn("ternary for b 3\000\001", 17);
	svop_list[263].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[53], hv0);
	CopFILE_set(&cop_list[53], pv1);
	sv_list[160].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[161].sv_u.svu_pv = savepvn("i\000\001", 3);
	sv_list[162].sv_u.svu_pv = savepvn("ternary for c 3\000\001", 17);
	svop_list[267].op_sv = (SV*)gv_list[2];
	svop_list[269].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[54], hv0);
	CopFILE_set(&cop_list[54], pv1);
	CopSTASH_set(&cop_list[55], hv0);
	CopFILE_set(&cop_list[55], pv1);
	svop_list[270].op_sv = (SV*)gv_list[10];
	svop_list[271].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[56], hv0);
	CopFILE_set(&cop_list[56], pv1);
	svop_list[274].op_sv = (SV*)gv_list[10];
	svop_list[275].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[57], hv0);
	CopFILE_set(&cop_list[57], pv1);
	svop_list[277].op_sv = (SV*)gv_list[10];
	sv_list[168].sv_u.svu_pv = savepvn("a\000\001", 3);
	CopSTASH_set(&cop_list[58], hv0);
	CopFILE_set(&cop_list[58], pv1);
	CopSTASH_set(&cop_list[59], hv0);
	CopFILE_set(&cop_list[59], pv1);
	sv_list[169].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[170].sv_u.svu_pv = savepvn("c\000\001", 3);
	CopSTASH_set(&cop_list[60], hv0);
	CopFILE_set(&cop_list[60], pv1);
	svop_list[282].op_sv = (SV*)gv_list[10];
	sv_list[172].sv_u.svu_pv = savepvn("d\000\001", 3);
	CopSTASH_set(&cop_list[61], hv0);
	CopFILE_set(&cop_list[61], pv1);
	sv_list[173].sv_u.svu_pv = savepvn("e\000\001", 3);
	sv_list[174].sv_u.svu_pv = savepvn("f\000\001", 3);
	CopSTASH_set(&cop_list[62], hv0);
	CopFILE_set(&cop_list[62], pv1);
	sv_list[175].sv_u.svu_pv = savepvn("g\000\001", 3);
	sv_list[176].sv_u.svu_pv = savepvn("h\000\001", 3);
	sv_list[177].sv_u.svu_pv = savepvn("i\000\001", 3);
	CopSTASH_set(&cop_list[63], hv0);
	CopFILE_set(&cop_list[63], pv1);
	svop_list[290].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[64], hv0);
	CopFILE_set(&cop_list[64], pv1);
	sv_list[179].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[180].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[181].sv_u.svu_pv = savepvn("block for a 1\000\001", 15);
	svop_list[295].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[65], hv0);
	CopFILE_set(&cop_list[65], pv1);
	sv_list[182].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[183].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[184].sv_u.svu_pv = savepvn("block for b 1\000\001", 15);
	svop_list[299].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[66], hv0);
	CopFILE_set(&cop_list[66], pv1);
	sv_list[185].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[186].sv_u.svu_pv = savepvn("c\000\001", 3);
	sv_list[187].sv_u.svu_pv = savepvn("block for c 1\000\001", 15);
	svop_list[303].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[67], hv0);
	CopFILE_set(&cop_list[67], pv1);
	svop_list[304].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[68], hv0);
	CopFILE_set(&cop_list[68], pv1);
	sv_list[189].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[190].sv_u.svu_pv = savepvn("d\000\001", 3);
	sv_list[191].sv_u.svu_pv = savepvn("block for a 2\000\001", 15);
	svop_list[309].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[69], hv0);
	CopFILE_set(&cop_list[69], pv1);
	sv_list[192].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[193].sv_u.svu_pv = savepvn("e\000\001", 3);
	sv_list[194].sv_u.svu_pv = savepvn("block for b 2\000\001", 15);
	svop_list[313].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[70], hv0);
	CopFILE_set(&cop_list[70], pv1);
	sv_list[195].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[196].sv_u.svu_pv = savepvn("f\000\001", 3);
	sv_list[197].sv_u.svu_pv = savepvn("block for c 2\000\001", 15);
	svop_list[317].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[71], hv0);
	CopFILE_set(&cop_list[71], pv1);
	CopSTASH_set(&cop_list[72], hv0);
	CopFILE_set(&cop_list[72], pv1);
	sv_list[198].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[199].sv_u.svu_pv = savepvn("g\000\001", 3);
	sv_list[200].sv_u.svu_pv = savepvn("block for a 3\000\001", 15);
	svop_list[321].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[73], hv0);
	CopFILE_set(&cop_list[73], pv1);
	sv_list[201].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[202].sv_u.svu_pv = savepvn("h\000\001", 3);
	sv_list[203].sv_u.svu_pv = savepvn("block for b 3\000\001", 15);
	svop_list[325].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[74], hv0);
	CopFILE_set(&cop_list[74], pv1);
	sv_list[204].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[205].sv_u.svu_pv = savepvn("i\000\001", 3);
	sv_list[206].sv_u.svu_pv = savepvn("block for c 3\000\001", 15);
	svop_list[329].op_sv = (SV*)gv_list[2];
	svop_list[331].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[75], hv0);
	CopFILE_set(&cop_list[75], pv1);
	svop_list[333].op_sv = (SV*)gv_list[10];
	CopSTASH_set(&cop_list[76], hv0);
	CopFILE_set(&cop_list[76], pv1);
	svop_list[334].op_sv = (SV*)gv_list[10];
	svop_list[339].op_sv = (SV*)gv_list[4];
	CopSTASH_set(&cop_list[77], hv0);
	CopFILE_set(&cop_list[77], pv1);
	svop_list[340].op_sv = (SV*)gv_list[4];
	sv_list[213].sv_u.svu_pv = savepvn("*\000\001", 3);
	sv_list[214].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[215].sv_u.svu_pv = savepvn("1*2*3\000\001", 7);
	sv_list[216].sv_u.svu_pv = savepvn("logical or f\000\001", 14);
	svop_list[345].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[78], hv0);
	CopFILE_set(&cop_list[78], pv1);
	svop_list[346].op_sv = (SV*)gv_list[10];
	svop_list[347].op_sv = (SV*)gv_list[10];
	svop_list[351].op_sv = (SV*)gv_list[4];
	CopSTASH_set(&cop_list[79], hv0);
	CopFILE_set(&cop_list[79], pv1);
	svop_list[352].op_sv = (SV*)gv_list[4];
	sv_list[220].sv_u.svu_pv = savepvn("*\000\001", 3);
	sv_list[221].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[222].sv_u.svu_pv = savepvn("1\000\001", 3);
	sv_list[223].sv_u.svu_pv = savepvn("logical or t\000\001", 14);
	svop_list[357].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[80], hv0);
	CopFILE_set(&cop_list[80], pv1);
	sv_list[224].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[225].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[226].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[227].sv_u.svu_pv = savepvn("list ..(...)\000\001", 14);
	svop_list[362].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[81], hv0);
	CopFILE_set(&cop_list[81], pv1);
	sv_list[228].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[229].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[230].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[231].sv_u.svu_pv = savepvn("list (.....)\000\001", 14);
	svop_list[367].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[82], hv0);
	CopFILE_set(&cop_list[82], pv1);
	sv_list[232].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[233].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[234].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[235].sv_u.svu_pv = savepvn("list (....).\000\001", 14);
	svop_list[372].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[83], hv0);
	CopFILE_set(&cop_list[83], pv1);
	sv_list[236].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[237].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[238].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[239].sv_u.svu_pv = savepvn("list .(...).\000\001", 14);
	svop_list[377].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[84], hv0);
	CopFILE_set(&cop_list[84], pv1);
	sv_list[240].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[241].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[242].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[243].sv_u.svu_pv = savepvn("list ..(..).\000\001", 14);
	svop_list[382].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[85], hv0);
	CopFILE_set(&cop_list[85], pv1);
	sv_list[244].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[245].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[246].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[247].sv_u.svu_pv = savepvn("list ...(.).\000\001", 14);
	svop_list[387].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[86], hv0);
	CopFILE_set(&cop_list[86], pv1);
	sv_list[248].sv_u.svu_pv = savepvn("12345", 5);
	sv_list[249].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[250].sv_u.svu_pv = savepvn("12345\000\001", 7);
	sv_list[251].sv_u.svu_pv = savepvn("list (..).(..)\000\001", 16);
	svop_list[392].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[87], hv0);
	CopFILE_set(&cop_list[87], pv1);
	CopSTASH_set(&cop_list[88], hv0);
	CopFILE_set(&cop_list[88], pv1);
	CopSTASH_set(&cop_list[89], hv0);
	CopFILE_set(&cop_list[89], pv1);
	CopSTASH_set(&cop_list[90], hv0);
	CopFILE_set(&cop_list[90], pv1);
	CopSTASH_set(&cop_list[91], hv0);
	CopFILE_set(&cop_list[91], pv1);
	sv_list[260].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[261].sv_u.svu_pv = savepvn("slice and slice\000\001", 17);
	svop_list[403].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[92], hv0);
	CopFILE_set(&cop_list[92], pv1);
	sv_list[262].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[264].sv_u.svu_pv = savepvn("slice len\000\001", 11);
	svop_list[407].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[93], hv0);
	CopFILE_set(&cop_list[93], pv1);
	CopSTASH_set(&cop_list[94], hv0);
	CopFILE_set(&cop_list[94], pv1);
	sv_list[266].sv_u.svu_pv = savepvn(":\000\001", 3);
	sv_list[267].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[268].sv_u.svu_pv = savepvn("29:\000\001", 5);
	sv_list[269].sv_u.svu_pv = savepvn("slice ary nil\000\001", 15);
	svop_list[413].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[95], hv0);
	CopFILE_set(&cop_list[95], pv1);
	sv_list[270].sv_u.svu_pv = savepvn("a\000\001", 3);
	CopSTASH_set(&cop_list[96], hv0);
	CopFILE_set(&cop_list[96], pv1);
	CopSTASH_set(&cop_list[97], hv0);
	CopFILE_set(&cop_list[97], pv1);
	sv_list[273].sv_u.svu_pv = savepvn(":\000\001", 3);
	sv_list[274].sv_u.svu_pv = savepvn("eq\000\001", 4);
	sv_list[275].sv_u.svu_pv = savepvn("30:\000\001", 5);
	sv_list[276].sv_u.svu_pv = savepvn("slice hash nil\000\001", 16);
	svop_list[421].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[98], hv0);
	CopFILE_set(&cop_list[98], pv1);
	SvREADONLY_off((SV*)(AV*)&sv_list[277]);
	SvREADONLY_on((SV*)(AV*)&sv_list[277]);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[277];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&sv_list[278];
	}
	CopSTASH_set(&cop_list[99], hv0);
	CopFILE_set(&cop_list[99], pv1);
	sv_list[279].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[280].sv_u.svu_pv = savepvn("0\000\001", 3);
	sv_list[281].sv_u.svu_pv = savepvn("size nil\000\001", 10);
	svop_list[426].op_sv = (SV*)gv_list[2];
	CopSTASH_set(&cop_list[100], hv0);
	CopFILE_set(&cop_list[100], pv1);
	CopSTASH_set(&cop_list[101], hv0);
	CopFILE_set(&cop_list[101], pv1);
	sv_list[282].sv_u.svu_pv = savepvn("simple list slice\000\001", 19);
	CopSTASH_set(&cop_list[102], hv0);
	CopFILE_set(&cop_list[102], pv1);
	CopSTASH_set(&cop_list[103], hv0);
	CopFILE_set(&cop_list[103], pv1);
	svop_list[432].op_sv = (SV*)PL_defgv;
	gv_list[11] = gv_fetchpvn_flags("is", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[11]) = 0x8009;
	GvFLAGS(gv_list[11]) = 0x2; 
	GvLINE(gv_list[11]) = 154;
	SvREFCNT(gv_list[11]) = 6;
	GvFILE_HEK(gv_list[11]) = share_hek_hek(hek0);
	
	svop_list[434].op_sv = (SV*)gv_list[11];
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[0];
		Newxz(svp, 4, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[1];
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[289];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(4 * sizeof(SV*));
	#else
		svp = (SV**)malloc(4 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[290];
		for (gcount=291; gcount<294; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[0];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[0];
		*svp++ = (PAD*)(AV*)&sv_list[289];
	}
	{ /* &main::test_zero_args needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[0], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[287]) = pad;
	}
	GvXPVGV(&sv_list[287])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[287]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[287])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	gv_list[12] = gv_fetchpvn_flags("test_zero_args", 14, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[12]) = 0x808009;
	GvFLAGS(gv_list[12]) = 0x2; 
	GvLINE(gv_list[12]) = 3533;
	SvREFCNT(gv_list[12]) = 8;
	GvCV_set(gv_list[12], (CV*)(&sv_list[287]));
	sv_magic((SV*)gv_list[12], (SV*)&sv_list[287], '<', 0, 0);
	CvCVGV_RC_off(&sv_list[287]);
	hek2 = share_hek("blib/lib/B/C.pm", 15, 0);
	GvFILE_HEK(gv_list[12]) = hek2;
	
	CvGV_set((CV*)&sv_list[287], (GV*)gv_list[12]);
	CvSTART(&sv_list[287]) = (OP*)&cop_list[102];
	CvFILE(&sv_list[287]) = "t/CORE/op/list.t";
	hv1 = gv_stashpvn("main", 4, GV_ADD);
	CvSTASH_set((CV*)&sv_list[287], hv1);
	CopSTASH_set(&cop_list[104], hv0);
	CopFILE_set(&cop_list[104], pv1);
	sv_list[295].sv_u.svu_pv = savepvn("grepped list slice\000\001", 20);
	CopSTASH_set(&cop_list[105], hv0);
	CopFILE_set(&cop_list[105], pv1);
	sv_list[301].sv_u.svu_pv = savepvn("sorted list slice\000\001", 19);
	CopSTASH_set(&cop_list[106], hv0);
	CopFILE_set(&cop_list[106], pv1);
	sv_list[306].sv_u.svu_pv = savepvn("assigned list slice\000\001", 21);
	CopSTASH_set(&cop_list[107], hv0);
	CopFILE_set(&cop_list[107], pv1);
	sv_list[311].sv_u.svu_pv = savepvn("do-returned list slice\000\001", 24);
	CopSTASH_set(&cop_list[108], hv0);
	CopFILE_set(&cop_list[108], pv1);
	CopSTASH_set(&cop_list[109], hv0);
	CopFILE_set(&cop_list[109], pv1);
	sv_list[316].sv_u.svu_pv = savepvn("list literal slice\000\001", 20);
	sv_list[319].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[320].sv_u.svu_pv = savepvn("b\000\001", 3);
	CopSTASH_set(&cop_list[110], hv0);
	CopFILE_set(&cop_list[110], pv1);
	sv_list[321].sv_u.svu_pv = savepvn("empty literal slice\000\001", 21);
	CopSTASH_set(&cop_list[111], hv0);
	CopFILE_set(&cop_list[111], pv1);
	CopSTASH_set(&cop_list[112], hv0);
	CopFILE_set(&cop_list[112], pv1);
	sv_list[324].sv_u.svu_pv = savepvn("\000\001", 2);
	CopSTASH_set(&cop_list[113], hv0);
	CopFILE_set(&cop_list[113], pv1);
	pmop_list[1].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[1], CALLREGCOMP(newSVpvn_flags(".", 1, SVs_TEMP|0), 0x1000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[1])) = 0x0;
	sv_list[330].sv_u.svu_pv = savepvn("abc\000\001", 5);
	sv_list[331].sv_u.svu_pv = savepvn("abcba\000\001", 7);
	svop_list[479].op_sv = (SV*)gv_list[11];
	CopSTASH_set(&cop_list[114], hv0);
	CopFILE_set(&cop_list[114], pv1);
	sv_list[332].sv_u.svu_pv = savepvn("\000\001", 2);
	sv_list[336].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[337].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[338].sv_u.svu_pv = savepvn("c\000\001", 3);
	sv_list[339].sv_u.svu_pv = savepvn("cab\000\001", 5);
	svop_list[488].op_sv = (SV*)gv_list[11];
	CopSTASH_set(&cop_list[115], hv0);
	CopFILE_set(&cop_list[115], pv1);
	sv_list[340].sv_u.svu_pv = savepvn("a\000\001", 3);
	sv_list[341].sv_u.svu_pv = savepvn("b\000\001", 3);
	sv_list[342].sv_u.svu_pv = savepvn("c\000\001", 3);
	CopSTASH_set(&cop_list[116], hv0);
	CopFILE_set(&cop_list[116], pv1);
	sv_list[343].sv_u.svu_pv = savepvn(":\000\001", 3);
	sv_list[344].sv_u.svu_pv = savepvn("a:b:c\000\001", 7);
	svop_list[494].op_sv = (SV*)gv_list[11];
	CopSTASH_set(&cop_list[117], hv0);
	CopFILE_set(&cop_list[117], pv1);
	CopSTASH_set(&cop_list[118], hv0);
	CopFILE_set(&cop_list[118], pv1);
	svop_list[496].op_sv = (SV*)gv_list[11];
	
	/* done main optree, extra subs which might be unused */
	gv_list[13] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[13]) = 2;
	gv_list[14] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[14]) = 2;
	gv_list[15] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[15]) = 2;
	gv_list[16] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[16]) = 0x8009;
	GvFLAGS(gv_list[16]) = 0x2; 
	GvLINE(gv_list[16]) = 0;
	SvREFCNT(gv_list[16]) = 23;
	GvREFCNT(gv_list[16]) += 1;
	GvFILE_HEK(gv_list[16]) = share_hek_hek(hek0);
	IoIFP((IO*)&sv_list[346]) = IoOFP((IO*)&sv_list[346]) = PerlIO_stdout();
	GvIOp(gv_list[16]) = (IO*)&sv_list[346];
	
	SvFLAGS(PL_stdingv) = 0x8009;
	GvFLAGS(PL_stdingv) = 0x2; 
	GvLINE(PL_stdingv) = 0;
	SvREFCNT(PL_stdingv) = 2;
	GvREFCNT(PL_stdingv) += 1;
	SvFLAGS(PL_stderrgv) = 0x8009;
	GvFLAGS(PL_stderrgv) = 0x2; 
	GvLINE(PL_stderrgv) = 0;
	SvREFCNT(PL_stderrgv) = 12;
	GvREFCNT(PL_stderrgv) += 1;
	gv_list[19] = gv_fetchpvn_flags("INIT", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[19]) = 0x808009;
	GvFLAGS(gv_list[19]) = 0x2; 
	GvLINE(gv_list[19]) = 6;
	SvREFCNT(gv_list[19]) = 2;
	GvREFCNT(gv_list[19]) += 1;
	GvFILE_HEK(gv_list[19]) = share_hek_hek(hek0);
	
	gv_list[20] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[20]) = 0x8009;
	GvFLAGS(gv_list[20]) = 0x2; 
	GvLINE(gv_list[20]) = 363;
	SvREFCNT(gv_list[20]) = 9;
	GvREFCNT(gv_list[20]) += 1;
	sv_list[347].sv_u.svu_pv = savepvn("t/CORE/op/list.c\000\001", 18);
	hv2 = gv_stashpvn("main::2", 7, GV_ADD);
	sv_magic((SV*)&sv_list[347], (SV*)gv_list[20], '\000', 0, 2);
	GvSVn(gv_list[20]) = (SV*)&sv_list[347];
	hek3 = share_hek("/usr/local/lib/perl5/5.22.0/Carp.pm", 35, 0);
	GvFILE_HEK(gv_list[20]) = hek3;
	
	gv_list[21] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[21]) = 0x8009;
	GvFLAGS(gv_list[21]) = 0x2; 
	GvLINE(gv_list[21]) = 102;
	SvREFCNT(gv_list[21]) = 48;
	GvREFCNT(gv_list[21]) += 1;
	sv_list[348].sv_u.svu_pv = savepvn("291", 3);
	sv_magic((SV*)&sv_list[348], (SV*)gv_list[21], '\000', 0, 1);
	GvSVn(gv_list[21]) = (SV*)&sv_list[348];
	hek4 = share_hek("/usr/local/lib/perl5/5.22.0/darwin/B.pm", 39, 0);
	GvFILE_HEK(gv_list[21]) = hek4;
	
	gv_list[22] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[22]) = 3;
	/* done extras */
	/* honor -w */
	PL_dowarn = ( 0 ) ? G_WARN_ON : G_WARN_OFF;
	CopSTASH_set(&cop_list[119], hv1);
	CopFILE_set(&cop_list[119], "t/CORE/op/list.t");
	hek5 = share_hek("t/CORE/test.pl", 14, 0);
	sv_list[351].sv_u.svu_pv = HEK_KEY(hek5);
	sv_list[352].sv_u.svu_pv = savepvn("./lib\000\001", 7);
	SvFLAGS(PL_incgv) = 0x8009;
	GvFLAGS(PL_incgv) = 0x2; 
	GvLINE(PL_incgv) = 0;
	SvREFCNT(PL_incgv) = 41;
	sv_list[354].sv_u.svu_pv = savepvn("blib/arch", 9);
	sv_list[355].sv_u.svu_pv = savepvn("blib/lib", 8);
	sv_list[356].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[357].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[358].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[359].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[360].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[361].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[362].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[363].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[364].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[365].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[366].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0/darwin", 44);
	sv_list[367].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0", 37);
	sv_list[368].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0/darwin", 34);
	sv_list[369].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0", 27);
	sv_list[370].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.11", 38);
	sv_list[371].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.10", 38);
	sv_list[372].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.9", 37);
	sv_list[373].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.8", 37);
	sv_list[374].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.5", 37);
	sv_list[375].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.4", 37);
	sv_list[376].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.3", 37);
	sv_list[377].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.2", 37);
	sv_list[378].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.1", 37);
	sv_list[379].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.2", 37);
	sv_list[380].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.1", 37);
	sv_list[381].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.0", 37);
	sv_list[382].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.9", 37);
	sv_list[383].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.8", 37);
	sv_list[384].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.6", 37);
	sv_list[385].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.4", 37);
	sv_list[386].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.2", 37);
	sv_list[387].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.4", 37);
	sv_list[388].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.2", 37);
	sv_list[389].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.1", 37);
	sv_list[390].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.0", 37);
	sv_list[391].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.3", 37);
	sv_list[392].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.1", 37);
	sv_list[393].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.15.8", 37);
	sv_list[394].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.4", 37);
	sv_list[395].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.3", 37);
	sv_list[396].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.2", 37);
	sv_list[397].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.1", 37);
	sv_list[398].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.0", 37);
	sv_list[399].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.5", 37);
	sv_list[400].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.4", 37);
	sv_list[401].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.10.1", 37);
	sv_list[402].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.9", 36);
	sv_list[403].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.8", 36);
	sv_list[404].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.5", 36);
	sv_list[405].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.4", 36);
	sv_list[406].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.6.2", 36);
	sv_list[407].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl", 30);
	sv_list[408].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[353];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(55 * sizeof(SV*));
	#else
		svp = (SV**)malloc(55 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=354; gcount<409; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvAV(PL_incgv) = (AV*)&sv_list[353];
	svop_list[499].op_sv = (SV*)PL_incgv;
	CopSTASH_set(&cop_list[120], hv1);
	CopFILE_set(&cop_list[120], "t/CORE/op/list.t");
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[1];
		Newxz(svp, 3, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[409];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[410];
		*svp++ = (SV*)&sv_list[411];
		*svp++ = (SV*)&sv_list[412];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[1];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[1];
		*svp++ = (PAD*)(AV*)&sv_list[409];
	}
	{ /* &main::INIT needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[1], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[350]) = pad;
	}
	GvXPVGV(&sv_list[350])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[350]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[350])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[350], (GV*)gv_list[19]);
	CvSTART(&sv_list[350]) = (OP*)&cop_list[119];
	CvFILE(&sv_list[350]) = "t/CORE/op/list.t";
	CvSTASH_set((CV*)&sv_list[350], hv1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[349];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&sv_list[350];
	}
	/* END block */
	/* startpoints */
	PL_main_root = (OP*)&listop_list[0];
	PL_main_start = &op_list[0];
	PL_initav = (AV*)&sv_list[349];
	PL_endav = (AV*)Nullsv;
	/* curpad names */
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[2];
		Newxz(svp, 181, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[2];
		*svp++ = (PADNAME*)&padname_list[3];
		*svp++ = (PADNAME*)&padname_list[4];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[5];
		*svp++ = (PADNAME*)&padname_list[6];
		*svp++ = (PADNAME*)&padname_list[7];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[8];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[9];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[10];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[11];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[12];
		*svp++ = (PADNAME*)&padname_list[13];
		*svp++ = (PADNAME*)&padname_list[14];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[15];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[16];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[17];
	}
	/* curpad syms */
	HvTOTALKEYS((HV*)&sv_list[563]) = 0;
	sv_list[569].sv_u.svu_pv = savepvn("", 0);
	sv_list[570].sv_u.svu_pv = savepvn("", 0);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[413];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(184 * sizeof(SV*));
	#else
		svp = (SV**)malloc(184 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		for (gcount=414; gcount<503; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)Nullsv;
		for (gcount=503; gcount<545; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[545];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[546];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[547];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[548];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[549];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[550];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[551];
		*svp++ = (SV*)(AV*)&sv_list[552];
		*svp++ = (SV*)&sv_list[553];
		*svp++ = (SV*)(AV*)&sv_list[554];
		*svp++ = (SV*)&sv_list[555];
		*svp++ = (SV*)(AV*)&sv_list[556];
		for (gcount=557; gcount<563; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)(HV*)&sv_list[563];
		for (gcount=564; gcount<573; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)(AV*)&sv_list[573];
		for (gcount=574; gcount<580; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)(AV*)&sv_list[580];
		for (gcount=581; gcount<584; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)(AV*)&sv_list[584];
		*svp++ = (SV*)&sv_list[585];
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)&sv_list[586];
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[587]) = a;
		HvRITER_set(&sv_list[587], -1);
	}
	HvTOTALKEYS((HV*)&sv_list[587]) = 0;
	/* @INC */
	GvHV(PL_incgv) = (HV*)&sv_list[587];
	GvAV(PL_incgv) = (AV*)&sv_list[353];
	PL_curpad = AvARRAY((AV*)&sv_list[413]);
	PL_comppad = (AV*)&sv_list[413];
	PL_stack_sp = PL_stack_base;
	PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = &padnamelist_list[2]; /* namepad */
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)(AV*)&sv_list[413]; /* curpad */
	
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
static void perl_init2_aaaa(pTHX)
{
	unopaux_item0[2].sv = (SV*)gv_list[6];
	unopaux_item1[2].sv = (SV*)gv_list[6];
	Gv_AMG(hv2); /* init AMG overload for main::2 */
	
}
static int perl_init2(pTHX)
{
	perl_init2_aaaa(aTHX);
	return 0;
}

/* The first assignment got already refcount bumped */
HEK *
my_share_hek( pTHX_ const char *str, I32 len, register U32 hash ) {
    if (!hash) {
      PERL_HASH(hash, str, abs(len));
    }
    return share_hek_hek(Perl_share_hek(aTHX_ str, len, hash));
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
	boot_DynaLoader(aTHX_ get_cv("DynaLoader::bootstrap", GV_ADD));
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
    sv_setpv_mg(get_sv("", GV_ADD|GV_NOTQUAL), "/usr/local/bin/perl5.22.0-nt"); /* $^X */
    TAINT_NOT;

    #if PERL_VERSION < 10 || ((PERL_VERSION == 10) && (PERL_SUBVERSION < 1))
      PL_compcv = 0;
    #else
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
