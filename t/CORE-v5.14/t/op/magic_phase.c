/* created at Thu Oct 22 01:30:32 2015 with B::C 1.52_06 -2850-g341501a for /usr/local/bin/perl5.22.0-nt */
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

#define XPVCVIX0	Nullhv, {0}, 2, 3, Nullhv, {(OP*)&cop_list[5]}, {(OP*)&unop_list[7]}, 0, NULL, &padlist_list[0], (CV*)&PL_main_cv, 6804, 0x0, 0
#define CVIX11	(XPVCV*)&xpvcv_list[0], 1, 0x440d, {0}
#define XPVCVIX1	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[12]}, {(OP*)&unop_list[24]}, 0, NULL, &padlist_list[1], (CV*)&PL_main_cv, 6820, 0x0, 0
#define CVIX28	(XPVCV*)&xpvcv_list[1], 1, 0xd, {0}
#define XPVCVIX2	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[13]}, {(OP*)&unop_list[29]}, 0, NULL, &padlist_list[2], (CV*)&PL_main_cv, 6823, 0x0, 0
#define CVIX33	(XPVCV*)&xpvcv_list[2], 1, 0xd, {0}
#define XPVCVIX3	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[14]}, {(OP*)&unop_list[34]}, 0, NULL, &padlist_list[3], (CV*)&PL_main_cv, 6812, 0x100, 0
#define CVIX41	(XPVCV*)&xpvcv_list[3], 1, 0x100000d, {0}
#define XPVCVIX4	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[15]}, {(OP*)&unop_list[37]}, 0, NULL, &padlist_list[4], (CV*)&PL_main_cv, 6826, 0x100, 0
#define CVIX46	(XPVCV*)&xpvcv_list[4], 1, 0x100000d, {0}

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
Static GV *gv_list[20];
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );

Static COP cop_list[16];
Static OP op_list[30];
Static UNOP unop_list[42];
Static BINOP binop_list[11];
Static LOGOP logop_list[4];
Static LISTOP listop_list[16];
Static PMOP pmop_list[1];
Static SVOP svop_list[34];
Static LOOP loop_list[1];
Static UNOP_AUX unopaux_list[2];
Static XPV xpv_list[84];
Static XPVAV xpvav_list[14];
Static XPVHV xpvhv_list[2];
Static XPVCV_or_similar xpvcv_list[5];
Static PADLIST padlist_list[5];
Static MyPADNAME padname_list[5];
Static PADNAMELIST padnamelist_list[6];
Static XPVMG xpvmg_list[6];
Static XPVIO xpvio_list[1];
Static SV sv_list[121];
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
Static const char pv1[] = "t/CORE/op/magic_phase.t";
Static HEK *hek0;
Static UNOP_AUX_item unopaux_item0[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x6d} 	/* action: 109 */
	,{.sv=Nullsv} 	/* gv_list[0] */
	,{.uv=0x2} 	/* action: 2 */
};
Static HEK *hek1;
Static HEK *hek2;
Static HV *hv1;
Static const char pv2[] = "CHECK";
Static HEK *hek3;
Static char pv3[] = "t/CORE/op/magic_phase.c";
Static HV *hv2;
Static HEK *hek4;
Static HEK *hek5;
Static HEK *hek6;
Static UNOP_AUX_item unopaux_item1[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* gv_list[0] */
	,{.sv=&sv_list[42]}
};

Static COP cop_list[16] = {
	{ (OP*)&listop_list[0], 0, INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 61, Nullhv, Nullgv, 2018, 6828, pWARN_ALL, NULL }, /* cop_list[0]  */
	{ &op_list[1], (OP*)&listop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 13, Nullhv, Nullgv, 2018, 6804, pWARN_ALL, NULL }, /* cop_list[1]  */
	{ &op_list[3], (OP*)&binop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 38, Nullhv, Nullgv, 2018, 6814, pWARN_ALL, NULL }, /* cop_list[2]  */
	{ (OP*)&pmop_list[0], (OP*)&binop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 39, Nullhv, Nullgv, 2018, 6817, pWARN_ALL, NULL }, /* cop_list[3]  */
	{ &op_list[8], (OP*)&unop_list[3], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 40, Nullhv, Nullgv, 2018, 6818, pWARN_ALL, NULL }, /* cop_list[4]  */
	{ (OP*)&svop_list[7], (OP*)&unop_list[8], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 16, Nullhv, Nullgv, 1762, 6805, pWARN_ALL, NULL }, /* cop_list[5]  */
	{ &op_list[15], (OP*)&listop_list[6], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 17, Nullhv, Nullgv, 1762, 6805, pWARN_ALL, NULL }, /* cop_list[6]  */
	{ (OP*)&svop_list[10], (OP*)&unop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 18, Nullhv, Nullgv, 2018, 6805, pWARN_ALL, NULL }, /* cop_list[7]  */
	{ &op_list[12], (OP*)&listop_list[4], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 19, Nullhv, Nullgv, 2018, 6805, pWARN_ALL, NULL }, /* cop_list[8]  */
	{ &op_list[20], (OP*)&unop_list[19], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 45, Nullhv, Nullgv, 2018, 6820, pWARN_ALL, NULL }, /* cop_list[9]  */
	{ &op_list[23], (OP*)&binop_list[5], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 51, Nullhv, Nullgv, 2018, 6822, pWARN_ALL, NULL }, /* cop_list[10]  */
	{ &op_list[25], (OP*)&binop_list[6], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 57, Nullhv, Nullgv, 2018, 6825, pWARN_ALL, NULL }, /* cop_list[11]  */
	{ &op_list[26], (OP*)&unop_list[25], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 48, Nullhv, Nullgv, 1762, 6821, pWARN_ALL, NULL }, /* cop_list[12]  */
	{ &op_list[27], (OP*)&unop_list[30], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 54, Nullhv, Nullgv, 1762, 6824, pWARN_ALL, NULL }, /* cop_list[13]  */
	{ (OP*)&svop_list[29], (OP*)&binop_list[9], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 35, Nullhv, Nullgv, 1762, 6813, pWARN_ALL, NULL }, /* cop_list[14]  */
	{ &op_list[29], (OP*)&unop_list[38], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 60, Nullhv, Nullgv, 1762, 6827, pWARN_ALL, NULL }, /* cop_list[15]  */
};

Static OP op_list[30] = {
	{ (OP*)&cop_list[1], (OP*)&cop_list[1], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0 }, /* op_list[0]  */
	{ (OP*)&svop_list[0], (OP*)&svop_list[0], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[1]  */
	{ &op_list[3], (OP*)&unop_list[0], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[2]  */
	{ (OP*)&svop_list[1], (OP*)&svop_list[1], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[3]  */
	{ &op_list[5], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[4]  */
	{ (OP*)&logop_list[0], (OP*)&listop_list[2], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[5]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_PADSV), 3, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[6]  */
	{ &op_list[6], 0, INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[7]  */
	{ (OP*)&unopaux_list[0], (OP*)&binop_list[2], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[8]  */
	{ (OP*)&unopaux_list[0], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[9]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_PADSV), 3, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[10]  */
	{ (OP*)&svop_list[13], (OP*)&unop_list[6], INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[11]  */
	{ (OP*)&svop_list[6], (OP*)&svop_list[6], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[12]  */
	{ (OP*)&svop_list[8], (OP*)&svop_list[8], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[13]  */
	{ (OP*)&unop_list[10], 0, INT2PTR(void*,OP_NULL), 5, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[14]  */
	{ (OP*)&svop_list[9], (OP*)&svop_list[9], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[15]  */
	{ (OP*)&svop_list[11], (OP*)&unop_list[16], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[16]  */
	{ (OP*)&unop_list[14], 0, INT2PTR(void*,OP_NULL), 5, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[17]  */
	{ (OP*)&svop_list[11], (OP*)&binop_list[3], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[18]  */
	{ (OP*)&unop_list[17], 0, INT2PTR(void*,OP_NULL), 5, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[19]  */
	{ (OP*)&svop_list[14], (OP*)&binop_list[4], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[20]  */
	{ &op_list[23], (OP*)&listop_list[9], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[21]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[22]  */
	{ (OP*)&listop_list[9], 0, INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[23]  */
	{ &op_list[25], (OP*)&listop_list[11], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[24]  */
	{ (OP*)&listop_list[11], 0, INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[25]  */
	{ (OP*)&svop_list[21], (OP*)&binop_list[7], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[26]  */
	{ (OP*)&svop_list[25], (OP*)&binop_list[8], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[27]  */
	{ (OP*)&unopaux_list[1], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[28]  */
	{ (OP*)&svop_list[30], (OP*)&binop_list[10], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[29]  */
};

Static UNOP unop_list[42] = {
	{ (OP*)&loop_list[0], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x0, &op_list[3] }, /* unop_list[0]  */
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[0] }, /* unop_list[1]  */
	{ &op_list[6], &op_list[6], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&logop_list[1] }, /* unop_list[2]  */
	{ &op_list[4], &op_list[4], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[4] }, /* unop_list[3]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[8] }, /* unop_list[4]  */
	{ &op_list[10], &op_list[10], INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unopaux_list[0] }, /* unop_list[5]  */
	{ (OP*)&unop_list[4], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[13] }, /* unop_list[6]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[3] }, /* unop_list[7]  */
	{ (OP*)&cop_list[6], (OP*)&cop_list[6], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[2] }, /* unop_list[8]  */
	{ (OP*)&logop_list[2], (OP*)&listop_list[5], INT2PTR(void*,OP_NULL), 103, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[10] }, /* unop_list[9]  */
	{ (OP*)&unop_list[9], 0, INT2PTR(void*,OP_NULL), 138, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[11] }, /* unop_list[10]  */
	{ &op_list[14], &op_list[14], INT2PTR(void*,OP_NULL), 135, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x3, (OP*)&svop_list[7] }, /* unop_list[11]  */
	{ (OP*)&cop_list[8], (OP*)&cop_list[8], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[3] }, /* unop_list[12]  */
	{ (OP*)&logop_list[3], (OP*)&listop_list[7], INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[14] }, /* unop_list[13]  */
	{ (OP*)&unop_list[13], 0, INT2PTR(void*,OP_NULL), 138, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[15] }, /* unop_list[14]  */
	{ &op_list[17], &op_list[17], INT2PTR(void*,OP_NULL), 135, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x3, (OP*)&svop_list[10] }, /* unop_list[15]  */
	{ (OP*)&listop_list[7], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[18] }, /* unop_list[16]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_NULL), 138, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&unop_list[18] }, /* unop_list[17]  */
	{ &op_list[19], &op_list[19], INT2PTR(void*,OP_NULL), 135, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x3, (OP*)&svop_list[12] }, /* unop_list[18]  */
	{ (OP*)&cop_list[10], (OP*)&cop_list[10], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[20] }, /* unop_list[19]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[20] }, /* unop_list[20]  */
	{ (OP*)&svop_list[15], (OP*)&svop_list[15], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[14] }, /* unop_list[21]  */
	{ (OP*)&unop_list[20], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa3, (OP*)&svop_list[17] }, /* unop_list[22]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x43, (OP*)&svop_list[20] }, /* unop_list[23]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[12] }, /* unop_list[24]  */
	{ (OP*)&unop_list[24], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x44, 0x2, (OP*)&unop_list[26] }, /* unop_list[25]  */
	{ (OP*)&unop_list[25], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[26] }, /* unop_list[26]  */
	{ (OP*)&svop_list[22], (OP*)&svop_list[22], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[21] }, /* unop_list[27]  */
	{ (OP*)&unop_list[26], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa3, (OP*)&svop_list[24] }, /* unop_list[28]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[13] }, /* unop_list[29]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x44, 0x2, (OP*)&unop_list[31] }, /* unop_list[30]  */
	{ (OP*)&unop_list[30], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[27] }, /* unop_list[31]  */
	{ (OP*)&svop_list[26], (OP*)&svop_list[26], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[25] }, /* unop_list[32]  */
	{ (OP*)&unop_list[31], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa3, (OP*)&svop_list[28] }, /* unop_list[33]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[14] }, /* unop_list[34]  */
	{ &op_list[28], (OP*)&unop_list[36], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[29] }, /* unop_list[35]  */
	{ (OP*)&binop_list[9], 0, INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unopaux_list[1] }, /* unop_list[36]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[15] }, /* unop_list[37]  */
	{ (OP*)&unop_list[37], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x44, 0x2, (OP*)&unop_list[39] }, /* unop_list[38]  */
	{ (OP*)&unop_list[38], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[29] }, /* unop_list[39]  */
	{ (OP*)&svop_list[31], (OP*)&svop_list[31], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[30] }, /* unop_list[40]  */
	{ (OP*)&unop_list[39], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa3, (OP*)&svop_list[33] }, /* unop_list[41]  */
};

Static BINOP binop_list[11] = {
	{ (OP*)&cop_list[9], (OP*)&cop_list[9], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[0], (OP*)&unop_list[1] }, /* binop_list[0]  */
	{ (OP*)&cop_list[4], (OP*)&cop_list[4], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[2], &op_list[6] }, /* binop_list[1]  */
	{ &op_list[11], &op_list[11], INT2PTR(void*,OP_SEQ), 0, 89, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[5], &op_list[10] }, /* binop_list[2]  */
	{ (OP*)&listop_list[7], 0, INT2PTR(void*,OP_CONCAT), 1, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[11], (OP*)&unop_list[17] }, /* binop_list[3]  */
	{ (OP*)&svop_list[16], (OP*)&svop_list[16], INT2PTR(void*,OP_SEQ), 0, 89, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[21], (OP*)&svop_list[15] }, /* binop_list[4]  */
	{ (OP*)&cop_list[11], (OP*)&cop_list[11], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&listop_list[8], &op_list[22] }, /* binop_list[5]  */
	{ (OP*)&listop_list[0], (OP*)&cop_list[0], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&listop_list[10], (OP*)&unop_list[23] }, /* binop_list[6]  */
	{ (OP*)&svop_list[23], (OP*)&svop_list[23], INT2PTR(void*,OP_SEQ), 0, 89, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[27], (OP*)&svop_list[22] }, /* binop_list[7]  */
	{ (OP*)&svop_list[27], (OP*)&svop_list[27], INT2PTR(void*,OP_SEQ), 0, 89, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[32], (OP*)&svop_list[26] }, /* binop_list[8]  */
	{ (OP*)&unop_list[34], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&unop_list[35], (OP*)&unop_list[36] }, /* binop_list[9]  */
	{ (OP*)&svop_list[32], (OP*)&svop_list[32], INT2PTR(void*,OP_SEQ), 0, 89, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[40], (OP*)&svop_list[31] }, /* binop_list[10]  */
};

Static LOGOP logop_list[4] = {
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[5], (OP*)&cop_list[3] }, /* logop_list[0]  */
	{ &op_list[7], 0, INT2PTR(void*,OP_COND_EXPR), 0, 180, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&pmop_list[0], (OP*)&svop_list[5] }, /* logop_list[1]  */
	{ (OP*)&cop_list[6], 0, INT2PTR(void*,OP_OR), 0, 177, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&unop_list[9], &op_list[13] }, /* logop_list[2]  */
	{ (OP*)&cop_list[8], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&unop_list[13], &op_list[16] }, /* logop_list[3]  */
};

Static LISTOP listop_list[16] = {
	{ 0, 0, INT2PTR(void*,OP_LEAVE), 1, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x40, &op_list[0], (OP*)&cop_list[0] }, /* listop_list[0]  */
	{ (OP*)&cop_list[2], (OP*)&cop_list[2], INT2PTR(void*,OP_PRINT), 0, 238, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, &op_list[1], (OP*)&svop_list[0] }, /* listop_list[1]  */
	{ (OP*)&unop_list[1], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[3], &op_list[4] }, /* listop_list[2]  */
	{ (OP*)&unop_list[7], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[5], (OP*)&listop_list[4] }, /* listop_list[3]  */
	{ (OP*)&unop_list[7], 0, INT2PTR(void*,OP_PRINT), 0, 238, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, &op_list[12], (OP*)&svop_list[6] }, /* listop_list[4]  */
	{ (OP*)&cop_list[6], 0, INT2PTR(void*,OP_PRINT), 0, 238, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, &op_list[13], (OP*)&svop_list[8] }, /* listop_list[5]  */
	{ (OP*)&cop_list[7], (OP*)&cop_list[7], INT2PTR(void*,OP_PRINT), 0, 238, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, &op_list[15], (OP*)&svop_list[9] }, /* listop_list[6]  */
	{ (OP*)&cop_list[8], 0, INT2PTR(void*,OP_PRINT), 0, 238, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, &op_list[16], (OP*)&unop_list[16] }, /* listop_list[7]  */
	{ &op_list[22], &op_list[22], INT2PTR(void*,OP_BLESS), 0, 23, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[21], (OP*)&svop_list[18] }, /* listop_list[8]  */
	{ (OP*)&svop_list[18], (OP*)&svop_list[18], INT2PTR(void*,OP_ANONHASH), 0, 161, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x0, &op_list[23], &op_list[23] }, /* listop_list[9]  */
	{ (OP*)&svop_list[20], (OP*)&unop_list[23], INT2PTR(void*,OP_BLESS), 0, 23, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[24], (OP*)&svop_list[19] }, /* listop_list[10]  */
	{ (OP*)&svop_list[19], (OP*)&svop_list[19], INT2PTR(void*,OP_ANONHASH), 0, 161, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x0, &op_list[25], &op_list[25] }, /* listop_list[11]  */
	{ (OP*)&unop_list[24], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[12], (OP*)&unop_list[25] }, /* listop_list[12]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[13], (OP*)&unop_list[30] }, /* listop_list[13]  */
	{ (OP*)&unop_list[34], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[14], (OP*)&binop_list[9] }, /* listop_list[14]  */
	{ (OP*)&unop_list[37], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[15], (OP*)&unop_list[38] }, /* listop_list[15]  */
};

Static PMOP pmop_list[1] = {
	{ (OP*)&logop_list[1], (OP*)&svop_list[5], INT2PTR(void*,OP_MATCH), 2, 31, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, 0, 0, 0, 0x0, {0}, {NULL} }, /* pmop_list[0]  */
};

Static SVOP svop_list[34] = {
	{ (OP*)&listop_list[1], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[1] }, /* svop_list[0]  */
	{ (OP*)&svop_list[2], (OP*)&svop_list[2], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[2] }, /* svop_list[1]  */
	{ (OP*)&svop_list[3], (OP*)&svop_list[3], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[3] }, /* svop_list[2]  */
	{ (OP*)&svop_list[4], (OP*)&svop_list[4], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[4] }, /* svop_list[3]  */
	{ (OP*)&loop_list[0], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[5] }, /* svop_list[4]  */
	{ &op_list[6], &op_list[7], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[6] }, /* svop_list[5]  */
	{ (OP*)&listop_list[4], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[12] }, /* svop_list[6]  */
	{ (OP*)&logop_list[2], 0, INT2PTR(void*,OP_AELEMFAST), 0, 136, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[7]  */
	{ (OP*)&listop_list[5], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[13] }, /* svop_list[8]  */
	{ (OP*)&listop_list[6], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[14] }, /* svop_list[9]  */
	{ (OP*)&unop_list[13], 0, INT2PTR(void*,OP_AELEMFAST), 0, 136, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x1, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[10]  */
	{ (OP*)&svop_list[12], (OP*)&unop_list[17], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[15] }, /* svop_list[11]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_AELEMFAST), 0, 136, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x1, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[12]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[13]  */
	{ (OP*)&svop_list[15], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[14]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[22] }, /* svop_list[15]  */
	{ (OP*)&svop_list[17], (OP*)&unop_list[22], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[23] }, /* svop_list[16]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[17]  */
	{ (OP*)&listop_list[8], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, &sv_list[24] }, /* svop_list[18]  */
	{ (OP*)&listop_list[10], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, &sv_list[25] }, /* svop_list[19]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[20]  */
	{ (OP*)&svop_list[22], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[21]  */
	{ (OP*)&binop_list[7], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[29] }, /* svop_list[22]  */
	{ (OP*)&svop_list[24], (OP*)&unop_list[28], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[30] }, /* svop_list[23]  */
	{ (OP*)&unop_list[25], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[24]  */
	{ (OP*)&svop_list[26], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[25]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[34] }, /* svop_list[26]  */
	{ (OP*)&svop_list[28], (OP*)&unop_list[33], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[35] }, /* svop_list[27]  */
	{ (OP*)&unop_list[30], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[28]  */
	{ (OP*)&unopaux_list[1], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[29]  */
	{ (OP*)&svop_list[31], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[30]  */
	{ (OP*)&binop_list[10], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[47] }, /* svop_list[31]  */
	{ (OP*)&svop_list[33], (OP*)&unop_list[41], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[48] }, /* svop_list[32]  */
	{ (OP*)&unop_list[38], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[33]  */
};

Static LOOP loop_list[1] = {
	{ &op_list[5], (OP*)&unop_list[1], INT2PTR(void*,OP_ENTERITER), 2, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x80, &op_list[2], (OP*)&unop_list[0], (OP*)&cop_list[3], &op_list[4], (OP*)&binop_list[0] }, /* loop_list[0]  */
};

Static UNOP_AUX unopaux_list[2] = {
	{ &op_list[10], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[9], unopaux_item0+1 }, /* unopaux_list[0]  */
	{ (OP*)&binop_list[9], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x2, &op_list[28], unopaux_item1+1 }, /* unopaux_list[1]  */
};

Static XPV xpv_list[84] = {
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[9]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[10]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[11]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[12]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[13]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[14]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[15]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[16]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[17]  */
	{ Nullhv, {0}, 4, 0 }, /* xpv_list[18]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[19]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[20]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[21]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[22]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[23]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[24]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[25]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[26]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[27]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[28]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[29]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[30]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[31]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[32]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[33]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[34]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[35]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[36]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[37]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[38]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[39]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[40]  */
	{ Nullhv, {0}, 44, 48 }, /* xpv_list[41]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[42]  */
	{ Nullhv, {0}, 34, 40 }, /* xpv_list[43]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[44]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[45]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[46]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[47]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[48]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[49]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[50]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[51]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[52]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[53]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[54]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[55]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[56]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[57]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[58]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[59]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[60]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[61]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[62]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[63]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[64]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[65]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[66]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[67]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[68]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[69]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[70]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[71]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[72]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[73]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[74]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[75]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[76]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[77]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[78]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[79]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[80]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[81]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[82]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[83]  */
};

Static XPVAV xpvav_list[14] = {
	{ Nullhv, {0}, 3, 3, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[1]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[2]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[3]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[4]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[5]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[6]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[7]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[8]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[9]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[10]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[11]  */
	{ Nullhv, {0}, 5, 5, 0 }, /* xpvav_list[12]  */
	{ Nullhv, {0}, 62, 62, 0 }, /* xpvav_list[13]  */
};

Static XPVHV xpvhv_list[2] = {
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[0]  */
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[1]  */
};

Static XPVCV_or_similar xpvcv_list[5] = {
	{ XPVCVIX0 }, /* xpvcv_list[0]  */
	{ XPVCVIX1 }, /* xpvcv_list[1]  */
	{ XPVCVIX2 }, /* xpvcv_list[2]  */
	{ XPVCVIX3 }, /* xpvcv_list[3]  */
	{ XPVCVIX4 }, /* xpvcv_list[4]  */
};

Static PADLIST padlist_list[5] = {
	{ 1, NULL, 537, 1 }, /* padlist_list[0]  */
	{ 1, NULL, 542, 1 }, /* padlist_list[1]  */
	{ 1, NULL, 543, 1 }, /* padlist_list[2]  */
	{ 1, NULL, 541, 1 }, /* padlist_list[3]  */
	{ 1, NULL, 544, 1 }, /* padlist_list[4]  */
};

Static MyPADNAME padname_list[5] = {
	{ NULL, (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 0xffffff45, 0, 0, 0x0, 0 }, /* padname_list[0]  */
	{ ((char*)&padname_list[1])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6815, 6819, 2 /* +1 */, 2147483647, 6, 0x4, "$phase" }, /* padname_list[1]  */
	{ ((char*)&padname_list[2])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6817, 6818, 2 /* +1 */, 0, 10, 0x0, "$should_be" }, /* padname_list[2]  */
	{ ((char*)&padname_list[3])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6822, 6828, 2 /* +1 */, 0, 6, 0x0, "$tiger" }, /* padname_list[3]  */
	{ ((char*)&padname_list[4])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6825, 6828, 2 /* +1 */, 0, 5, 0x10, "$affe" }, /* padname_list[4]  */
};

Static PADNAMELIST padnamelist_list[6] = {
	{ 3, NULL, 3, 0, 2 /* +1 */ }, /* padnamelist_list[0]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[1]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[2]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[3]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[4]  */
	{ 5, NULL, 5, 5, 2 /* +1 */ }, /* padnamelist_list[5]  */
};

Static XPVMG xpvmg_list[6] = {
	{ Nullhv, {0}, 5, 8, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 5, 8, {0}, {0.00} }, /* xpvmg_list[1]  */
	{ Nullhv, {0}, 5, 8, {0}, {0.00} }, /* xpvmg_list[2]  */
	{ Nullhv, {0}, 5, 6, {0}, {0.00} }, /* xpvmg_list[3]  */
	{ Nullhv, {0}, 23, 32, {0}, {0.00} }, /* xpvmg_list[4]  */
	{ Nullhv, {0}, 4, 5, {18}, {0.00} }, /* xpvmg_list[5]  */
};

Static XPVIO xpvio_list[1] = {
	{ Nullhv,{0},0,0,{0},0,{0},0,60,60,NULL,Nullgv,NULL,Nullgv,NULL,Nullgv,'>',0x0 }, /* xpvio_list[0]  */
};

Static SV sv_list[121] = {
	{ 0, 121, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */
	{ &xpv_list[0], 2147483647, 0x18014403, {0} }, /* sv_list[1]  */
	{ &xpv_list[1], 2147483647, 0x18014403, {0} }, /* sv_list[2]  */
	{ &xpv_list[2], 2147483647, 0x18014403, {0} }, /* sv_list[3]  */
	{ &xpv_list[3], 2147483647, 0x18014403, {0} }, /* sv_list[4]  */
	{ &xpv_list[4], 2147483647, 0x18014403, {0} }, /* sv_list[5]  */
	{ &xpv_list[5], 2147483647, 0x18014403, {0} }, /* sv_list[6]  */
	{ &xpvhv_list[0], 1, 0x2000000c, {0} }, /* sv_list[7]  */
	{ &xpvmg_list[0], 1, 0x4407, {0} }, /* sv_list[8]  */
	{ &xpvmg_list[1], 1, 0x4407, {0} }, /* sv_list[9]  */
	{ &xpvmg_list[2], 1, 0x4407, {0} }, /* sv_list[10]  */
	{ CVIX11 }, /* sv_list[11]  */
	{ &xpv_list[6], 2147483647, 0x18014403, {0} }, /* sv_list[12]  */
	{ &xpv_list[7], 2147483647, 0x18014403, {0} }, /* sv_list[13]  */
	{ &xpv_list[8], 2147483647, 0x18014403, {0} }, /* sv_list[14]  */
	{ &xpv_list[9], 2147483647, 0x8014403, {0} }, /* sv_list[15]  */
	{ &xpvav_list[0], 1, 0x4000000b, {0} }, /* sv_list[16]  */
	{ &xpvav_list[1], 1, 0x8000000b, {0} }, /* sv_list[17]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[18]  */
	{ 0, 1, 0x40000, {0} }, /* sv_list[19]  */
	{ ptr_undef, 6, 0x801, {.svu_rv=&sv_list[11]} }, /* sv_list[20]  */
	{ &xpvmg_list[3], 1, 0x8604407, {.svu_pv=(char*)pv2} }, /* sv_list[21]  */
	{ &xpv_list[10], 2147483647, 0x18014403, {0} }, /* sv_list[22]  */
	{ &xpv_list[11], 2147483647, 0x18014403, {0} }, /* sv_list[23]  */
	{ &xpv_list[12], 2147483647, 0x18014403, {0} }, /* sv_list[24]  */
	{ &xpv_list[13], 2147483647, 0x18014403, {0} }, /* sv_list[25]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[26]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[27]  */
	{ CVIX28 }, /* sv_list[28]  */
	{ &xpv_list[14], 2147483647, 0x18014403, {0} }, /* sv_list[29]  */
	{ &xpv_list[15], 2147483647, 0x18014403, {0} }, /* sv_list[30]  */
	{ &xpvav_list[2], 1, 0x4000000b, {0} }, /* sv_list[31]  */
	{ &xpvav_list[3], 1, 0x8000000b, {0} }, /* sv_list[32]  */
	{ CVIX33 }, /* sv_list[33]  */
	{ &xpv_list[16], 2147483647, 0x18014403, {0} }, /* sv_list[34]  */
	{ &xpv_list[17], 2147483647, 0x18014403, {0} }, /* sv_list[35]  */
	{ &xpvav_list[4], 1, 0x4000000b, {0} }, /* sv_list[36]  */
	{ &xpvav_list[5], 1, 0x8000000b, {0} }, /* sv_list[37]  */
	{ &xpvmg_list[4], 1, 0x10604407, {.svu_pv=(char*)pv3} }, /* sv_list[38]  */
	{ &xpvmg_list[5], 1, 0x604407, {.svu_pv=(char*)pv0} }, /* sv_list[39]  */
	{ &xpvav_list[6], 1, 0x4000000b, {0} }, /* sv_list[40]  */
	{ CVIX41 }, /* sv_list[41]  */
	{ &xpv_list[18], 1, 0x10004403, {0} }, /* sv_list[42]  */
	{ &xpvav_list[7], 1, 0x4000000b, {0} }, /* sv_list[43]  */
	{ &xpvav_list[8], 1, 0x8000000b, {0} }, /* sv_list[44]  */
	{ &xpvav_list[9], 1, 0x4000000b, {0} }, /* sv_list[45]  */
	{ CVIX46 }, /* sv_list[46]  */
	{ &xpv_list[19], 2147483647, 0x18014403, {0} }, /* sv_list[47]  */
	{ &xpv_list[20], 2147483647, 0x18014403, {0} }, /* sv_list[48]  */
	{ &xpvav_list[10], 1, 0x4000000b, {0} }, /* sv_list[49]  */
	{ &xpvav_list[11], 1, 0x8000000b, {0} }, /* sv_list[50]  */
	{ &xpvav_list[12], 1, 0x4000000b, {0} }, /* sv_list[51]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[52]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[53]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[54]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[55]  */
	{ &xpvhv_list[1], 1, 0x2200000c, {0} }, /* sv_list[56]  */
	{ &xpvav_list[13], 1, 0x4000000b, {0} }, /* sv_list[57]  */
	{ &xpv_list[21], 1, 0x4403, {0} }, /* sv_list[58]  */
	{ &xpv_list[22], 1, 0x4403, {0} }, /* sv_list[59]  */
	{ &xpv_list[23], 1, 0x4403, {0} }, /* sv_list[60]  */
	{ &xpv_list[24], 1, 0x4403, {0} }, /* sv_list[61]  */
	{ &xpv_list[25], 1, 0x4403, {0} }, /* sv_list[62]  */
	{ &xpv_list[26], 1, 0x4403, {0} }, /* sv_list[63]  */
	{ &xpv_list[27], 1, 0x4403, {0} }, /* sv_list[64]  */
	{ &xpv_list[28], 1, 0x4403, {0} }, /* sv_list[65]  */
	{ &xpv_list[29], 1, 0x4403, {0} }, /* sv_list[66]  */
	{ &xpv_list[30], 1, 0x4403, {0} }, /* sv_list[67]  */
	{ &xpv_list[31], 1, 0x4403, {0} }, /* sv_list[68]  */
	{ &xpv_list[32], 1, 0x4403, {0} }, /* sv_list[69]  */
	{ &xpv_list[33], 1, 0x4403, {0} }, /* sv_list[70]  */
	{ &xpv_list[34], 1, 0x4403, {0} }, /* sv_list[71]  */
	{ &xpv_list[35], 1, 0x4403, {0} }, /* sv_list[72]  */
	{ &xpv_list[36], 1, 0x4403, {0} }, /* sv_list[73]  */
	{ &xpv_list[37], 1, 0x4403, {0} }, /* sv_list[74]  */
	{ &xpv_list[38], 1, 0x4403, {0} }, /* sv_list[75]  */
	{ &xpv_list[39], 1, 0x4403, {0} }, /* sv_list[76]  */
	{ &xpv_list[40], 1, 0x4403, {0} }, /* sv_list[77]  */
	{ &xpv_list[41], 1, 0x4403, {0} }, /* sv_list[78]  */
	{ &xpv_list[42], 1, 0x4403, {0} }, /* sv_list[79]  */
	{ &xpv_list[43], 1, 0x4403, {0} }, /* sv_list[80]  */
	{ &xpv_list[44], 1, 0x4403, {0} }, /* sv_list[81]  */
	{ &xpv_list[45], 1, 0x4403, {0} }, /* sv_list[82]  */
	{ &xpv_list[46], 1, 0x4403, {0} }, /* sv_list[83]  */
	{ &xpv_list[47], 1, 0x4403, {0} }, /* sv_list[84]  */
	{ &xpv_list[48], 1, 0x4403, {0} }, /* sv_list[85]  */
	{ &xpv_list[49], 1, 0x4403, {0} }, /* sv_list[86]  */
	{ &xpv_list[50], 1, 0x4403, {0} }, /* sv_list[87]  */
	{ &xpv_list[51], 1, 0x4403, {0} }, /* sv_list[88]  */
	{ &xpv_list[52], 1, 0x4403, {0} }, /* sv_list[89]  */
	{ &xpv_list[53], 1, 0x4403, {0} }, /* sv_list[90]  */
	{ &xpv_list[54], 1, 0x4403, {0} }, /* sv_list[91]  */
	{ &xpv_list[55], 1, 0x4403, {0} }, /* sv_list[92]  */
	{ &xpv_list[56], 1, 0x4403, {0} }, /* sv_list[93]  */
	{ &xpv_list[57], 1, 0x4403, {0} }, /* sv_list[94]  */
	{ &xpv_list[58], 1, 0x4403, {0} }, /* sv_list[95]  */
	{ &xpv_list[59], 1, 0x4403, {0} }, /* sv_list[96]  */
	{ &xpv_list[60], 1, 0x4403, {0} }, /* sv_list[97]  */
	{ &xpv_list[61], 1, 0x4403, {0} }, /* sv_list[98]  */
	{ &xpv_list[62], 1, 0x4403, {0} }, /* sv_list[99]  */
	{ &xpv_list[63], 1, 0x4403, {0} }, /* sv_list[100]  */
	{ &xpv_list[64], 1, 0x4403, {0} }, /* sv_list[101]  */
	{ &xpv_list[65], 1, 0x4403, {0} }, /* sv_list[102]  */
	{ &xpv_list[66], 1, 0x4403, {0} }, /* sv_list[103]  */
	{ &xpv_list[67], 1, 0x4403, {0} }, /* sv_list[104]  */
	{ &xpv_list[68], 1, 0x4403, {0} }, /* sv_list[105]  */
	{ &xpv_list[69], 1, 0x4403, {0} }, /* sv_list[106]  */
	{ &xpv_list[70], 1, 0x4403, {0} }, /* sv_list[107]  */
	{ &xpv_list[71], 1, 0x4403, {0} }, /* sv_list[108]  */
	{ &xpv_list[72], 1, 0x4403, {0} }, /* sv_list[109]  */
	{ &xpv_list[73], 1, 0x4403, {0} }, /* sv_list[110]  */
	{ &xpv_list[74], 1, 0x4403, {0} }, /* sv_list[111]  */
	{ &xpv_list[75], 1, 0x4403, {0} }, /* sv_list[112]  */
	{ &xpv_list[76], 1, 0x4403, {0} }, /* sv_list[113]  */
	{ &xpv_list[77], 1, 0x4403, {0} }, /* sv_list[114]  */
	{ &xpv_list[78], 1, 0x4403, {0} }, /* sv_list[115]  */
	{ &xpv_list[79], 1, 0x4403, {0} }, /* sv_list[116]  */
	{ &xpv_list[80], 1, 0x4403, {0} }, /* sv_list[117]  */
	{ &xpv_list[81], 1, 0x4403, {0} }, /* sv_list[118]  */
	{ &xpv_list[82], 1, 0x4403, {0} }, /* sv_list[119]  */
	{ &xpv_list[83], 1, 0x4403, {0} }, /* sv_list[120]  */
};

static void perl_init0(pTHX) /* fixup_ppaddr */
{
	register int i;
	for (i = 0; i < 11; ++i) {
		binop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(binop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 16; ++i) {
		cop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(cop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 16; ++i) {
		listop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(listop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 4; ++i) {
		logop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(logop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 1; ++i) {
		loop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(loop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 30; ++i) {
		op_list[i].op_ppaddr = PL_ppaddr[PTR2IV(op_list[i].op_ppaddr)];
	}
	for (i = 0; i < 1; ++i) {
		pmop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(pmop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 34; ++i) {
		svop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(svop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 42; ++i) {
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
	sv_list[1].sv_u.svu_pv = savepvn("1..8\n\000\001", 7);
	CopSTASH_set(&cop_list[2], hv0);
	CopFILE_set(&cop_list[2], pv1);
	CopSTASH_set(&cop_list[3], hv0);
	CopFILE_set(&cop_list[3], pv1);
	sv_list[2].sv_u.svu_pv = savepvn("BEGIN\000\001", 7);
	sv_list[3].sv_u.svu_pv = savepvn("UNITCHECK\000\001", 11);
	sv_list[4].sv_u.svu_pv = savepvn("CHECK\000\001", 7);
	sv_list[5].sv_u.svu_pv = savepvn("INIT\000\001", 6);
	pmop_list[0].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[0], CALLREGCOMP(newSVpvn_flags("^(:?BEGIN|UNITCHECK)", 20, SVs_TEMP|0), 0x0));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[0])) = 0x1000000;
	sv_list[6].sv_u.svu_pv = savepvn("START\000\001", 7);
	CopSTASH_set(&cop_list[4], hv0);
	CopFILE_set(&cop_list[4], pv1);
	gv_list[0] = gv_fetchpvn_flags("compile_time", 12, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[0]) = 0x8009;
	GvFLAGS(gv_list[0]) = 0x42; 
	GvLINE(gv_list[0]) = 35;
	SvREFCNT(gv_list[0]) = 6;
	sv_list[8].sv_u.svu_pv = savepvn("CHECK", 5);
	sv_list[9].sv_u.svu_pv = savepvn("START", 5);
	sv_list[10].sv_u.svu_pv = savepvn("START", 5);
	{
		HV *hv = (HV*)&sv_list[7];
		hv_store(hv, "CHECK", 5, &sv_list[8], 0);
		hv_store(hv, "BEGIN", 5, &sv_list[9], 0);
		hv_store(hv, "UNITCHECK", 9, &sv_list[10], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[7]) = 3;
	GvHV(gv_list[0]) = (HV*)&sv_list[7];
	hek0 = share_hek("/usr/local/lib/perl5/5.22.0/vars.pm", 35, 0);
	GvFILE_HEK(gv_list[0]) = hek0;
	
	CopSTASH_set(&cop_list[5], hv0);
	CopFILE_set(&cop_list[5], pv1);
	sv_list[12].sv_u.svu_pv = savepvn("\n\000\001", 3);
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x2; 
	GvLINE(PL_defgv) = 0;
	SvREFCNT(PL_defgv) = 513;
	svop_list[7].op_sv = (SV*)PL_defgv;
	sv_list[13].sv_u.svu_pv = savepvn("not \000\001", 6);
	CopSTASH_set(&cop_list[6], hv0);
	CopFILE_set(&cop_list[6], pv1);
	sv_list[14].sv_u.svu_pv = savepvn("ok\000\001", 4);
	CopSTASH_set(&cop_list[7], hv0);
	CopFILE_set(&cop_list[7], pv1);
	svop_list[10].op_sv = (SV*)PL_defgv;
	sv_list[15].sv_u.svu_pv = savepvn(" - ", 3);
	svop_list[12].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[8], hv0);
	CopFILE_set(&cop_list[8], pv1);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[0];
		Newxz(svp, 4, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[16];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(4 * sizeof(SV*));
	#else
		svp = (SV**)malloc(4 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[17];
		*svp++ = (SV*)&sv_list[18];
		*svp++ = (SV*)&sv_list[19];
		*svp++ = (SV*)Nullsv;
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[0];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[0];
		*svp++ = (PAD*)(AV*)&sv_list[16];
	}
	{ /* &main::ok needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[0], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[11]) = pad;
	}
	hek1 = share_hek("$$", 2, 0);
	GvXPVGV(&sv_list[11])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[11]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[11])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	gv_list[2] = gv_fetchpvn_flags("ok", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[2]) = 0x808009;
	GvFLAGS(gv_list[2]) = 0x2; 
	GvLINE(gv_list[2]) = 3533;
	SvREFCNT(gv_list[2]) = 6;
	GvCV_set(gv_list[2], (CV*)(&sv_list[11]));
	sv_magic((SV*)gv_list[2], (SV*)&sv_list[11], '<', 0, 0);
	CvCVGV_RC_off(&sv_list[11]);
	hek2 = share_hek("blib/lib/B/C.pm", 15, 0);
	GvFILE_HEK(gv_list[2]) = hek2;
	
	CvGV_set((CV*)&sv_list[11], (GV*)gv_list[2]);
	CvSTART(&sv_list[11]) = (OP*)&cop_list[5];
	CvFILE(&sv_list[11]) = "t/CORE/op/magic_phase.t";
	hv1 = gv_stashpvn("main", 4, GV_ADD);
	CvSTASH_set((CV*)&sv_list[11], hv1);
	SvPVX(&sv_list[11]) = HEK_KEY(hek1);
	CopSTASH_set(&cop_list[9], hv0);
	CopFILE_set(&cop_list[9], pv1);
	gv_list[3] = gv_fetchpvn_flags("\aLOBAL_PHASE", 12, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[3]) = 0x8009;
	GvFLAGS(gv_list[3]) = 0x2; 
	GvLINE(gv_list[3]) = 23;
	SvREFCNT(gv_list[3]) = 9;
	sv_list[21].sv_u.svu_pv = savepvn("CHECK", 5);
	SvREADONLY_off((SV*)&sv_list[21]);
	sv_magic((SV*)&sv_list[21], (SV*)gv_list[3], '\000', "\aLOBAL_PHASE", 12);
	SvREADONLY_on((SV*)&sv_list[21]);
	GvSVn(gv_list[3]) = (SV*)&sv_list[21];
	hek3 = share_hek("t/CORE/op/magic_phase.t", 23, 0);
	GvFILE_HEK(gv_list[3]) = hek3;
	
	svop_list[14].op_sv = (SV*)gv_list[3];
	sv_list[22].sv_u.svu_pv = savepvn("RUN\000\001", 5);
	sv_list[23].sv_u.svu_pv = savepvn("RUN\000\001", 5);
	CopSTASH_set(&cop_list[10], hv0);
	CopFILE_set(&cop_list[10], pv1);
	sv_list[24].sv_u.svu_pv = savepvn("Moo\000\001", 5);
	CopSTASH_set(&cop_list[11], hv0);
	CopFILE_set(&cop_list[11], pv1);
	sv_list[25].sv_u.svu_pv = savepvn("Kooh\000\001", 6);
	gv_list[4] = gv_fetchpvn_flags("affe", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[4]) = 0x8009;
	GvFLAGS(gv_list[4]) = 0x2; 
	GvLINE(gv_list[4]) = 57;
	SvREFCNT(gv_list[4]) = 2;
	GvSVn(gv_list[4]) = (SV*)&sv_list[26];
	GvFILE_HEK(gv_list[4]) = share_hek_hek(hek3);
	
	svop_list[20].op_sv = (SV*)gv_list[4];
	
	/* done main optree, extra subs which might be unused */
	gv_list[5] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[5]) = 2;
	gv_list[6] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[6]) = 2;
	gv_list[7] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[7]) = 2;
	gv_list[8] = gv_fetchpvn_flags("UNITCHECK", 9, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[8]) = 0x808009;
	GvFLAGS(gv_list[8]) = 0x2; 
	GvLINE(gv_list[8]) = 28;
	SvREFCNT(gv_list[8]) = 2;
	GvREFCNT(gv_list[8]) += 1;
	GvFILE_HEK(gv_list[8]) = share_hek_hek(hek3);
	
	gv_list[9] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[9]) = 0x8009;
	GvFLAGS(gv_list[9]) = 0x2; 
	GvLINE(gv_list[9]) = 0;
	SvREFCNT(gv_list[9]) = 23;
	GvREFCNT(gv_list[9]) += 1;
	GvFILE_HEK(gv_list[9]) = share_hek_hek(hek3);
	IoIFP((IO*)&sv_list[27]) = IoOFP((IO*)&sv_list[27]) = PerlIO_stdout();
	GvIOp(gv_list[9]) = (IO*)&sv_list[27];
	
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
	gv_list[12] = gv_fetchpvn_flags("Moo::DESTROY", 12, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[12]) = 0x808009;
	GvFLAGS(gv_list[12]) = 0x2; 
	GvLINE(gv_list[12]) = 49;
	SvREFCNT(gv_list[12]) = 2;
	GvREFCNT(gv_list[12]) += 1;
	CopSTASH_set(&cop_list[12], hv0);
	CopFILE_set(&cop_list[12], pv1);
	svop_list[21].op_sv = (SV*)gv_list[3];
	sv_list[29].sv_u.svu_pv = savepvn("RUN\000\001", 5);
	sv_list[30].sv_u.svu_pv = savepvn("DESTROY is run-time too, usually\000\001", 34);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[1];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[31];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[32];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[1];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[1];
		*svp++ = (PAD*)(AV*)&sv_list[31];
	}
	{ /* &Moo::DESTROY needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[1], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[28]) = pad;
	}
	GvXPVGV(&sv_list[28])->xnv_u.xgv_stash = 0;
	CvOUTSIDE(&sv_list[28]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[28])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[28], (GV*)gv_list[12]);
	CvSTART(&sv_list[28]) = (OP*)&cop_list[12];
	CvFILE(&sv_list[28]) = "t/CORE/op/magic_phase.t";
	CvSTASH_set((CV*)&sv_list[28], hv1);
	++PL_sv_objcount;
	GvCV_set(gv_list[12], (CV*)(&sv_list[28]));
	sv_magic((SV*)gv_list[12], (SV*)&sv_list[28], '<', 0, 0);
	CvCVGV_RC_off(&sv_list[28]);
	GvFILE_HEK(gv_list[12]) = share_hek_hek(hek3);
	
	gv_list[13] = gv_fetchpvn_flags("Kooh::DESTROY", 13, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[13]) = 0x808009;
	GvFLAGS(gv_list[13]) = 0x2; 
	GvLINE(gv_list[13]) = 55;
	SvREFCNT(gv_list[13]) = 2;
	GvREFCNT(gv_list[13]) += 1;
	CopSTASH_set(&cop_list[13], hv0);
	CopFILE_set(&cop_list[13], pv1);
	svop_list[25].op_sv = (SV*)gv_list[3];
	sv_list[34].sv_u.svu_pv = savepvn("DESTRUCT\000\001", 10);
	sv_list[35].sv_u.svu_pv = savepvn("DESTRUCT\000\001", 10);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[2];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[36];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[37];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[2];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[2];
		*svp++ = (PAD*)(AV*)&sv_list[36];
	}
	{ /* &Kooh::DESTROY needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[2], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[33]) = pad;
	}
	GvXPVGV(&sv_list[33])->xnv_u.xgv_stash = 0;
	CvOUTSIDE(&sv_list[33]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[33])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[33], (GV*)gv_list[13]);
	CvSTART(&sv_list[33]) = (OP*)&cop_list[13];
	CvFILE(&sv_list[33]) = "t/CORE/op/magic_phase.t";
	CvSTASH_set((CV*)&sv_list[33], hv1);
	++PL_sv_objcount;
	GvCV_set(gv_list[13], (CV*)(&sv_list[33]));
	sv_magic((SV*)gv_list[13], (SV*)&sv_list[33], '<', 0, 0);
	CvCVGV_RC_off(&sv_list[33]);
	GvFILE_HEK(gv_list[13]) = share_hek_hek(hek3);
	
	gv_list[14] = gv_fetchpvn_flags("INIT", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[14]) = 0x808009;
	GvFLAGS(gv_list[14]) = 0x2; 
	GvLINE(gv_list[14]) = 36;
	SvREFCNT(gv_list[14]) = 2;
	GvREFCNT(gv_list[14]) += 1;
	GvFILE_HEK(gv_list[14]) = share_hek_hek(hek3);
	
	gv_list[15] = gv_fetchpvn_flags("END", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[15]) = 0x808009;
	GvFLAGS(gv_list[15]) = 0x2; 
	GvLINE(gv_list[15]) = 61;
	SvREFCNT(gv_list[15]) = 2;
	GvREFCNT(gv_list[15]) += 1;
	GvFILE_HEK(gv_list[15]) = share_hek_hek(hek3);
	
	gv_list[16] = gv_fetchpvn_flags("CHECK", 5, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[16]) = 0x808009;
	GvFLAGS(gv_list[16]) = 0x2; 
	GvLINE(gv_list[16]) = 32;
	SvREFCNT(gv_list[16]) = 2;
	GvREFCNT(gv_list[16]) += 1;
	GvFILE_HEK(gv_list[16]) = share_hek_hek(hek3);
	
	gv_list[17] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[17]) = 0x8009;
	GvFLAGS(gv_list[17]) = 0x2; 
	GvLINE(gv_list[17]) = 363;
	SvREFCNT(gv_list[17]) = 9;
	GvREFCNT(gv_list[17]) += 1;
	sv_list[38].sv_u.svu_pv = savepvn("t/CORE/op/magic_phase.c\000\001", 25);
	hv2 = gv_stashpvn("main::2", 7, GV_ADD);
	sv_magic((SV*)&sv_list[38], (SV*)gv_list[17], '\000', 0, 2);
	GvSVn(gv_list[17]) = (SV*)&sv_list[38];
	hek4 = share_hek("/usr/local/lib/perl5/5.22.0/Carp.pm", 35, 0);
	GvFILE_HEK(gv_list[17]) = hek4;
	
	gv_list[18] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[18]) = 0x8009;
	GvFLAGS(gv_list[18]) = 0x2; 
	GvLINE(gv_list[18]) = 102;
	SvREFCNT(gv_list[18]) = 48;
	GvREFCNT(gv_list[18]) += 1;
	sv_list[39].sv_u.svu_pv = savepvn("main", 4);
	sv_magic((SV*)&sv_list[39], (SV*)gv_list[18], '\000', 0, 1);
	GvSVn(gv_list[18]) = (SV*)&sv_list[39];
	hek5 = share_hek("/usr/local/lib/perl5/5.22.0/darwin/B.pm", 39, 0);
	GvFILE_HEK(gv_list[18]) = hek5;
	
	gv_list[19] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[19]) = 3;
	/* done extras */
	/* honor -w */
	PL_dowarn = ( 0 ) ? G_WARN_ON : G_WARN_OFF;
	CopSTASH_set(&cop_list[14], hv1);
	CopFILE_set(&cop_list[14], "t/CORE/op/magic_phase.t");
	svop_list[29].op_sv = (SV*)gv_list[3];
	hek6 = share_hek("INIT", 4, 0);
	sv_list[42].sv_u.svu_pv = HEK_KEY(hek6);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[3];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[43];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[44];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[3];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[3];
		*svp++ = (PAD*)(AV*)&sv_list[43];
	}
	{ /* &main::INIT needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[3], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[41]) = pad;
	}
	GvXPVGV(&sv_list[41])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[41]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[41])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[41], (GV*)gv_list[14]);
	CvSTART(&sv_list[41]) = (OP*)&cop_list[14];
	CvFILE(&sv_list[41]) = "t/CORE/op/magic_phase.t";
	CvSTASH_set((CV*)&sv_list[41], hv1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[40];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&sv_list[41];
	}
	/* END block */
	CopSTASH_set(&cop_list[15], hv1);
	CopFILE_set(&cop_list[15], "t/CORE/op/magic_phase.t");
	svop_list[30].op_sv = (SV*)gv_list[3];
	sv_list[47].sv_u.svu_pv = savepvn("END\000\001", 5);
	sv_list[48].sv_u.svu_pv = savepvn("END\000\001", 5);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[4];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[49];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[50];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[4];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[4];
		*svp++ = (PAD*)(AV*)&sv_list[49];
	}
	{ /* &main::END needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[4], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[46]) = pad;
	}
	GvXPVGV(&sv_list[46])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[46]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[46])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[46], (GV*)gv_list[15]);
	CvSTART(&sv_list[46]) = (OP*)&cop_list[15];
	CvFILE(&sv_list[46]) = "t/CORE/op/magic_phase.t";
	CvSTASH_set((CV*)&sv_list[46], hv1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[45];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&sv_list[46];
	}
	/* startpoints */
	PL_main_root = (OP*)&listop_list[0];
	PL_main_start = &op_list[0];
	PL_initav = (AV*)&sv_list[40];
	PL_endav = (AV*)&sv_list[45];
	/* curpad names */
	SvOURSTASH_set(&padname_list[4], hv1);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[5];
		Newxz(svp, 6, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[1];
		*svp++ = (PADNAME*)&padname_list[2];
		*svp++ = (PADNAME*)&padname_list[3];
		*svp++ = (PADNAME*)&padname_list[4];
	}
	/* curpad syms */
	{
		SV **svp;
		AV *av = (AV*)&sv_list[51];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(6 * sizeof(SV*));
	#else
		svp = (SV**)malloc(6 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)Nullsv;
		for (gcount=52; gcount<56; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[56]) = a;
		HvRITER_set(&sv_list[56], -1);
	}
	HvTOTALKEYS((HV*)&sv_list[56]) = 0;
	/* @INC */
	sv_list[58].sv_u.svu_pv = savepvn("blib/arch", 9);
	sv_list[59].sv_u.svu_pv = savepvn("blib/lib", 8);
	sv_list[60].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[61].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[62].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[63].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[64].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[65].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[66].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[67].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[68].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[69].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[70].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[71].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[72].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[73].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[74].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[75].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[76].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[77].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[78].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0/darwin", 44);
	sv_list[79].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0", 37);
	sv_list[80].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0/darwin", 34);
	sv_list[81].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0", 27);
	sv_list[82].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.11", 38);
	sv_list[83].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.10", 38);
	sv_list[84].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.9", 37);
	sv_list[85].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.8", 37);
	sv_list[86].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.5", 37);
	sv_list[87].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.4", 37);
	sv_list[88].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.3", 37);
	sv_list[89].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.2", 37);
	sv_list[90].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.1", 37);
	sv_list[91].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.2", 37);
	sv_list[92].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.1", 37);
	sv_list[93].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.0", 37);
	sv_list[94].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.9", 37);
	sv_list[95].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.8", 37);
	sv_list[96].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.6", 37);
	sv_list[97].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.4", 37);
	sv_list[98].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.2", 37);
	sv_list[99].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.4", 37);
	sv_list[100].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.2", 37);
	sv_list[101].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.1", 37);
	sv_list[102].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.0", 37);
	sv_list[103].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.3", 37);
	sv_list[104].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.1", 37);
	sv_list[105].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.15.8", 37);
	sv_list[106].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.4", 37);
	sv_list[107].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.3", 37);
	sv_list[108].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.2", 37);
	sv_list[109].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.1", 37);
	sv_list[110].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.0", 37);
	sv_list[111].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.5", 37);
	sv_list[112].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.4", 37);
	sv_list[113].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.10.1", 37);
	sv_list[114].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.9", 36);
	sv_list[115].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.8", 36);
	sv_list[116].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.5", 36);
	sv_list[117].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.4", 36);
	sv_list[118].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.6.2", 36);
	sv_list[119].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl", 30);
	sv_list[120].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[57];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(63 * sizeof(SV*));
	#else
		svp = (SV**)malloc(63 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=58; gcount<121; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvHV(PL_incgv) = (HV*)&sv_list[56];
	GvAV(PL_incgv) = (AV*)&sv_list[57];
	PL_curpad = AvARRAY((AV*)&sv_list[51]);
	PL_comppad = (AV*)&sv_list[51];
	PL_stack_sp = PL_stack_base;
	PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = &padnamelist_list[5]; /* namepad */
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)(AV*)&sv_list[51]; /* curpad */
	
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
static void perl_init2_aaaa(pTHX)
{
	unopaux_item0[2].sv = (SV*)gv_list[0];
	Gv_AMG(hv1); /* init AMG overload for %main:: */
	Gv_AMG(hv2); /* init AMG overload for main::2 */
	unopaux_item1[2].sv = (SV*)gv_list[0];
	
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
