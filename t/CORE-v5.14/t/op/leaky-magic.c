/* created at Thu Oct 22 01:29:25 2015 with B::C 1.52_06 -2850-g341501a for /usr/local/bin/perl5.22.0-nt */
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

#define XPVCVIX0	Nullhv, {0}, 2, 3, Nullhv, {(OP*)&cop_list[7]}, {(OP*)&unop_list[17]}, 0, NULL, &padlist_list[0], (CV*)0, 6802, 0x90, 0
#define CVIX65	(XPVCV*)&xpvcv_list[0], 2, 0x4440d, {0}
#define XPVCVIX1	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[10]}, {(OP*)&unop_list[26]}, 0, NULL, &padlist_list[1], (CV*)0, 6804, 0x90, 0
#define CVIX75	(XPVCV*)&xpvcv_list[1], 2, 0x4000d, {0}
#define XPVCVIX2	Nullhv, {0}, 3, 4, Nullhv, {(OP*)&cop_list[61]}, {(OP*)&unop_list[134]}, 0, NULL, &padlist_list[2], (CV*)0, 6806, 0x90, 0
#define CVIX173	(XPVCV*)&xpvcv_list[2], 2, 0x4440d, {0}
#define XPVCVIX3	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[86]}, {(OP*)&unop_list[189]}, 0, NULL, &padlist_list[3], (CV*)&PL_main_cv, 6813, 0x0, 0
#define CVIX213	(XPVCV*)&xpvcv_list[3], 1, 0xd, {0}
#define XPVCVIX4	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[87]}, {(OP*)&unop_list[191]}, 0, NULL, &padlist_list[4], (CV*)&PL_main_cv, 6809, 0x100, 0
#define CVIX221	(XPVCV*)&xpvcv_list[4], 1, 0x100000d, {0}
#define XPVCVIX5	Nullhv, {0}, 0, 0, Nullhv, {(OP*)&cop_list[89]}, {(OP*)&unop_list[194]}, 0, NULL, &padlist_list[5], (CV*)&PL_main_cv, 6898, 0xb0, 0
#define CVIX270	(XPVCV*)&xpvcv_list[5], 1, 0xd, {0}

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

Static COP cop_list[90];
Static OP op_list[107];
Static UNOP unop_list[195];
Static BINOP binop_list[63];
Static LOGOP logop_list[19];
Static LISTOP listop_list[51];
Static PMOP pmop_list[5];
Static SVOP svop_list[196];
Static LOOP loop_list[12];
Static UNOP_AUX unopaux_list[5];
Static XPV xpv_list[197];
Static XPVAV xpvav_list[14];
Static XPVHV xpvhv_list[2];
Static XPVCV_or_similar xpvcv_list[6];
Static PADLIST padlist_list[6];
Static MyPADNAME padname_list[10];
Static PADNAMELIST padnamelist_list[7];
Static XPVIV xpviv_list[5];
Static XPVMG xpvmg_list[3];
Static XPVIO xpvio_list[1];
Static SV sv_list[299];
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
Static const char pv1[] = "t/CORE/op/leaky-magic.t";
Static HEK *hek0;
Static HEK *hek1;
Static UNOP_AUX_item unopaux_item0[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* PL_incgv */
	,{.sv=&sv_list[63]}
};
Static HEK *hek2;
Static HV *hv1;
Static HEK *hek3;
Static UNOP_AUX_item unopaux_item1[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* PL_incgv */
	,{.sv=&sv_list[68]}
};
Static const char pv2[] = "";
Static HEK *hek4;
Static UNOP_AUX_item unopaux_item2[] = {
	{.uv=2} 	/* length prefix */
	,{.uv=0x58} 	/* action: 88 */
	,{.sv=&sv_list[153]}
};
Static UNOP_AUX_item unopaux_item3[] = {
	{.uv=2} 	/* length prefix */
	,{.uv=0x58} 	/* action: 88 */
	,{.sv=&sv_list[157]}
};
Static HEK *hek5;
Static HEK *hek6;
Static UNOP_AUX_item unopaux_item4[] = {
	{.uv=3} 	/* length prefix */
	,{.uv=0x5d} 	/* action: 93 */
	,{.sv=Nullsv} 	/* gv_list[10] */
	,{.sv=&sv_list[169]}
};
Static HEK *hek7;
Static char pv3[] = "t/CORE/op/leaky-magic.c";
Static HV *hv2;
Static HEK *hek8;
Static HEK *hek9;
Static HEK *hek10;

Static COP cop_list[90] = {
	{ &op_list[100], &op_list[100], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 132, Nullhv, Nullgv, 0, 6937, pWARN_STD, NULL }, /* cop_list[0]  */
	{ &op_list[2], (OP*)&unop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 22, Nullhv, Nullgv, 256, 6815, pWARN_STD, NULL }, /* cop_list[1]  */
	{ &op_list[3], (OP*)&logop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 25, Nullhv, Nullgv, 256, 6816, pWARN_STD, NULL }, /* cop_list[2]  */
	{ &op_list[5], (OP*)&unop_list[9], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 25, Nullhv, Nullgv, 0, 6817, pWARN_STD, NULL }, /* cop_list[3]  */
	{ (OP*)&loop_list[1], (OP*)&binop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 27, Nullhv, Nullgv, 256, 6818, pWARN_STD, NULL }, /* cop_list[4]  */
	{ (OP*)&svop_list[8], (OP*)&binop_list[3], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 27, Nullhv, Nullgv, 256, 6819, pWARN_STD, NULL }, /* cop_list[5]  */
	{ &op_list[6], (OP*)&unop_list[11], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 28, Nullhv, Nullgv, 256, 6819, pWARN_STD, NULL }, /* cop_list[6]  */
	{ (OP*)&unop_list[17], 0, INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0, 9, Nullhv, Nullgv, 0, 6802, pWARN_STD, NULL }, /* cop_list[7]  */
	{ &op_list[8], (OP*)&unop_list[18], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 30, Nullhv, Nullgv, 256, 6820, pWARN_STD, NULL }, /* cop_list[8]  */
	{ &op_list[10], (OP*)&unop_list[23], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 34, Nullhv, Nullgv, 256, 6821, pWARN_STD, NULL }, /* cop_list[9]  */
	{ (OP*)&unop_list[26], 0, INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0, 10, Nullhv, Nullgv, 0, 6804, pWARN_STD, NULL }, /* cop_list[10]  */
	{ &op_list[12], (OP*)&unop_list[27], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 41, Nullhv, Nullgv, 256, 6822, pWARN_STD, NULL }, /* cop_list[11]  */
	{ &op_list[16], (OP*)&binop_list[4], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 44, Nullhv, Nullgv, 256, 6823, pWARN_STD, NULL }, /* cop_list[12]  */
	{ (OP*)&pmop_list[1], (OP*)&binop_list[5], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 45, Nullhv, Nullgv, 256, 6825, pWARN_STD, NULL }, /* cop_list[13]  */
	{ &op_list[17], (OP*)&unop_list[38], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 45, Nullhv, Nullgv, 0, 6826, pWARN_STD, NULL }, /* cop_list[14]  */
	{ (OP*)&svop_list[31], (OP*)&binop_list[8], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 46, Nullhv, Nullgv, 256, 6828, pWARN_STD, NULL }, /* cop_list[15]  */
	{ (OP*)&svop_list[32], (OP*)&unop_list[41], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 49, Nullhv, Nullgv, 256, 6828, pWARN_STD, NULL }, /* cop_list[16]  */
	{ &op_list[20], (OP*)&unop_list[42], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 49, Nullhv, Nullgv, 0, 6829, pWARN_STD, NULL }, /* cop_list[17]  */
	{ &op_list[22], (OP*)&unop_list[43], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 51, Nullhv, Nullgv, 256, 6830, pWARN_STD, NULL }, /* cop_list[18]  */
	{ &op_list[23], (OP*)&unop_list[48], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 51, Nullhv, Nullgv, 0, 6831, pWARN_STD, NULL }, /* cop_list[19]  */
	{ &op_list[29], (OP*)&binop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 55, Nullhv, Nullgv, 256, 6835, pWARN_STD, NULL }, /* cop_list[20]  */
	{ &op_list[30], (OP*)&unop_list[54], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 56, Nullhv, Nullgv, 256, 6837, pWARN_STD, NULL }, /* cop_list[21]  */
	{ &op_list[32], (OP*)&unop_list[59], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 56, Nullhv, Nullgv, 0, 6840, pWARN_STD, NULL }, /* cop_list[22]  */
	{ (OP*)&svop_list[44], (OP*)&binop_list[13], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 56, Nullhv, Nullgv, 256, 6838, pWARN_STD, NULL }, /* cop_list[23]  */
	{ (OP*)&svop_list[45], (OP*)&binop_list[14], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 56, Nullhv, Nullgv, 256, 6839, pWARN_STD, NULL }, /* cop_list[24]  */
	{ &op_list[37], (OP*)&binop_list[18], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 60, Nullhv, Nullgv, 256, 6846, pWARN_STD, NULL }, /* cop_list[25]  */
	{ &op_list[38], (OP*)&unop_list[66], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 61, Nullhv, Nullgv, 256, 6848, pWARN_STD, NULL }, /* cop_list[26]  */
	{ &op_list[39], (OP*)&unop_list[69], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 61, Nullhv, Nullgv, 0, 6850, pWARN_STD, NULL }, /* cop_list[27]  */
	{ (OP*)&svop_list[68], (OP*)&binop_list[19], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 61, Nullhv, Nullgv, 256, 6849, pWARN_STD, NULL }, /* cop_list[28]  */
	{ &op_list[44], (OP*)&binop_list[22], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 65, Nullhv, Nullgv, 256, 6855, pWARN_STD, NULL }, /* cop_list[29]  */
	{ &op_list[45], (OP*)&unop_list[76], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 66, Nullhv, Nullgv, 256, 6857, pWARN_STD, NULL }, /* cop_list[30]  */
	{ &op_list[46], (OP*)&unop_list[79], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 66, Nullhv, Nullgv, 0, 6859, pWARN_STD, NULL }, /* cop_list[31]  */
	{ (OP*)&svop_list[80], (OP*)&binop_list[23], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 66, Nullhv, Nullgv, 256, 6858, pWARN_STD, NULL }, /* cop_list[32]  */
	{ (OP*)&loop_list[6], (OP*)&binop_list[26], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 73, Nullhv, Nullgv, 256, 6864, pWARN_STD, NULL }, /* cop_list[33]  */
	{ &op_list[51], (OP*)&listop_list[21], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 73, Nullhv, Nullgv, 0, 6865, pWARN_STD, NULL }, /* cop_list[34]  */
	{ (OP*)&svop_list[103], (OP*)&binop_list[28], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 77, Nullhv, Nullgv, 256, 6868, pWARN_STD, NULL }, /* cop_list[35]  */
	{ &op_list[53], (OP*)&unop_list[86], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 74, Nullhv, Nullgv, 0, 6866, pWARN_STD, NULL }, /* cop_list[36]  */
	{ &op_list[54], (OP*)&binop_list[27], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 76, Nullhv, Nullgv, 256, 6866, pWARN_STD, NULL }, /* cop_list[37]  */
	{ (OP*)&svop_list[105], (OP*)&unop_list[90], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 78, Nullhv, Nullgv, 256, 6868, pWARN_STD, NULL }, /* cop_list[38]  */
	{ &op_list[55], (OP*)&unop_list[91], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 78, Nullhv, Nullgv, 0, 6869, pWARN_STD, NULL }, /* cop_list[39]  */
	{ &op_list[56], (OP*)&unop_list[93], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 79, Nullhv, Nullgv, 256, 6870, pWARN_STD, NULL }, /* cop_list[40]  */
	{ &op_list[57], (OP*)&unop_list[98], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 79, Nullhv, Nullgv, 0, 6871, pWARN_STD, NULL }, /* cop_list[41]  */
	{ &op_list[59], (OP*)&unop_list[103], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 84, Nullhv, Nullgv, 256, 6876, pWARN_STD, NULL }, /* cop_list[42]  */
	{ (OP*)&svop_list[112], (OP*)&svop_list[112], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 84, Nullhv, Nullgv, 0, 6877, pWARN_STD, NULL }, /* cop_list[43]  */
	{ &op_list[60], (OP*)&unop_list[109], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 87, Nullhv, Nullgv, 256, 6879, pWARN_STD, NULL }, /* cop_list[44]  */
	{ (OP*)&svop_list[117], (OP*)&svop_list[117], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 87, Nullhv, Nullgv, 0, 6881, pWARN_STD, NULL }, /* cop_list[45]  */
	{ (OP*)&svop_list[116], (OP*)&binop_list[33], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 87, Nullhv, Nullgv, 0, 6880, pWARN_STD, NULL }, /* cop_list[46]  */
	{ &op_list[61], (OP*)&unop_list[114], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 88, Nullhv, Nullgv, 256, 6883, pWARN_STD, NULL }, /* cop_list[47]  */
	{ (OP*)&svop_list[121], (OP*)&svop_list[121], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 88, Nullhv, Nullgv, 0, 6885, pWARN_STD, NULL }, /* cop_list[48]  */
	{ (OP*)&svop_list[120], (OP*)&binop_list[34], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 88, Nullhv, Nullgv, 0, 6884, pWARN_STD, NULL }, /* cop_list[49]  */
	{ &op_list[62], (OP*)&unop_list[119], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 89, Nullhv, Nullgv, 256, 6887, pWARN_STD, NULL }, /* cop_list[50]  */
	{ (OP*)&svop_list[125], (OP*)&svop_list[125], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 89, Nullhv, Nullgv, 0, 6889, pWARN_STD, NULL }, /* cop_list[51]  */
	{ (OP*)&svop_list[124], (OP*)&binop_list[35], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 89, Nullhv, Nullgv, 0, 6888, pWARN_STD, NULL }, /* cop_list[52]  */
	{ &op_list[63], (OP*)&unop_list[123], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 90, Nullhv, Nullgv, 256, 6891, pWARN_STD, NULL }, /* cop_list[53]  */
	{ (OP*)&svop_list[130], (OP*)&svop_list[130], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 90, Nullhv, Nullgv, 0, 6893, pWARN_STD, NULL }, /* cop_list[54]  */
	{ (OP*)&svop_list[129], (OP*)&binop_list[37], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 90, Nullhv, Nullgv, 0, 6892, pWARN_STD, NULL }, /* cop_list[55]  */
	{ (OP*)&loop_list[8], (OP*)&binop_list[39], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 94, Nullhv, Nullgv, 256, 6896, pWARN_STD, NULL }, /* cop_list[56]  */
	{ (OP*)&svop_list[134], (OP*)&binop_list[40], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 94, Nullhv, Nullgv, 0, 6897, pWARN_STD, NULL }, /* cop_list[57]  */
	{ (OP*)&svop_list[135], (OP*)&binop_list[41], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 95, Nullhv, Nullgv, 256, 6898, pWARN_STD, NULL }, /* cop_list[58]  */
	{ (OP*)&svop_list[136], (OP*)&unop_list[132], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 96, Nullhv, Nullgv, 256, 6900, pWARN_STD, NULL }, /* cop_list[59]  */
	{ &op_list[64], (OP*)&unop_list[127], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 97, Nullhv, Nullgv, 256, 6900, pWARN_STD, NULL }, /* cop_list[60]  */
	{ (OP*)&unop_list[134], 0, INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x8, 0x0, 11, Nullhv, Nullgv, 256, 6806, pWARN_STD, NULL }, /* cop_list[61]  */
	{ &op_list[71], (OP*)&binop_list[42], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 101, Nullhv, Nullgv, 256, 6902, pWARN_STD, NULL }, /* cop_list[62]  */
	{ (OP*)&svop_list[152], (OP*)&binop_list[43], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 102, Nullhv, Nullgv, 256, 6904, pWARN_STD, NULL }, /* cop_list[63]  */
	{ (OP*)&svop_list[155], (OP*)&binop_list[46], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 103, Nullhv, Nullgv, 256, 6905, pWARN_STD, NULL }, /* cop_list[64]  */
	{ (OP*)&svop_list[156], (OP*)&unop_list[141], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 105, Nullhv, Nullgv, 256, 6905, pWARN_STD, NULL }, /* cop_list[65]  */
	{ &op_list[75], (OP*)&unop_list[142], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 105, Nullhv, Nullgv, 0, 6906, pWARN_STD, NULL }, /* cop_list[66]  */
	{ &op_list[77], (OP*)&unop_list[143], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 106, Nullhv, Nullgv, 256, 6907, pWARN_STD, NULL }, /* cop_list[67]  */
	{ &op_list[78], (OP*)&unop_list[148], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 106, Nullhv, Nullgv, 0, 6908, pWARN_STD, NULL }, /* cop_list[68]  */
	{ &op_list[84], (OP*)&binop_list[50], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 110, Nullhv, Nullgv, 256, 6912, pWARN_STD, NULL }, /* cop_list[69]  */
	{ (OP*)&svop_list[164], (OP*)&binop_list[51], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 111, Nullhv, Nullgv, 256, 6914, pWARN_STD, NULL }, /* cop_list[70]  */
	{ &op_list[87], (OP*)&unop_list[157], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 112, Nullhv, Nullgv, 256, 6915, pWARN_STD, NULL }, /* cop_list[71]  */
	{ &op_list[88], (OP*)&unop_list[160], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 112, Nullhv, Nullgv, 0, 6917, pWARN_STD, NULL }, /* cop_list[72]  */
	{ (OP*)&svop_list[167], (OP*)&binop_list[54], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 112, Nullhv, Nullgv, 256, 6916, pWARN_STD, NULL }, /* cop_list[73]  */
	{ (OP*)&svop_list[172], (OP*)&unop_list[164], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 117, Nullhv, Nullgv, 256, 6922, pWARN_STD, NULL }, /* cop_list[74]  */
	{ (OP*)&svop_list[172], (OP*)&svop_list[172], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 117, Nullhv, Nullgv, 0, 6923, pWARN_STD, NULL }, /* cop_list[75]  */
	{ &op_list[91], (OP*)&unop_list[165], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 118, Nullhv, Nullgv, 256, 6924, pWARN_STD, NULL }, /* cop_list[76]  */
	{ (OP*)&svop_list[173], (OP*)&svop_list[173], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 118, Nullhv, Nullgv, 0, 6925, pWARN_STD, NULL }, /* cop_list[77]  */
	{ &op_list[95], (OP*)&binop_list[57], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 123, Nullhv, Nullgv, 256, 6927, pWARN_STD, NULL }, /* cop_list[78]  */
	{ (OP*)&svop_list[181], (OP*)&unop_list[173], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 124, Nullhv, Nullgv, 0, 6929, pWARN_STD, NULL }, /* cop_list[79]  */
	{ &op_list[96], (OP*)&unop_list[174], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 124, Nullhv, Nullgv, 0, 6930, pWARN_STD, NULL }, /* cop_list[80]  */
	{ &op_list[97], (OP*)&unop_list[176], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 125, Nullhv, Nullgv, 0, 6931, pWARN_STD, NULL }, /* cop_list[81]  */
	{ &op_list[98], (OP*)&unop_list[181], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 125, Nullhv, Nullgv, 0, 6932, pWARN_STD, NULL }, /* cop_list[82]  */
	{ (OP*)&loop_list[0], (OP*)&binop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 132, Nullhv, Nullgv, 256, 6936, pWARN_STD, NULL }, /* cop_list[83]  */
	{ (OP*)&svop_list[189], (OP*)&pmop_list[4], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 133, Nullhv, Nullgv, 256, 6938, pWARN_STD, NULL }, /* cop_list[84]  */
	{ &op_list[1], (OP*)&unop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 134, Nullhv, Nullgv, 256, 6942, pWARN_STD, NULL }, /* cop_list[85]  */
	{ (OP*)&svop_list[192], (OP*)&binop_list[61], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 21, Nullhv, Nullgv, 256, 6814, pWARN_STD, NULL }, /* cop_list[86]  */
	{ (OP*)&svop_list[194], (OP*)&unop_list[192], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 15, Nullhv, Nullgv, 0, 6810, pWARN_STD, NULL }, /* cop_list[87]  */
	{ &op_list[104], (OP*)&listop_list[49], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 16, Nullhv, Nullgv, 0, 6810, pWARN_STD, NULL }, /* cop_list[88]  */
	{ &op_list[105], (OP*)&binop_list[62], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 95, Nullhv, Nullgv, 0, 6899, pWARN_STD, NULL }, /* cop_list[89]  */
};

Static OP op_list[107] = {
	{ (OP*)&cop_list[1], (OP*)&cop_list[1], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0 }, /* op_list[0]  */
	{ &op_list[102], (OP*)&unop_list[186], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[1]  */
	{ (OP*)&svop_list[0], (OP*)&svop_list[0], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[2]  */
	{ (OP*)&svop_list[5], (OP*)&unop_list[7], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[3]  */
	{ (OP*)&svop_list[5], (OP*)&svop_list[5], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[4]  */
	{ (OP*)&svop_list[3], (OP*)&binop_list[1], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[5]  */
	{ (OP*)&unopaux_list[0], (OP*)&unop_list[14], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[6]  */
	{ (OP*)&unopaux_list[0], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[7]  */
	{ (OP*)&unopaux_list[1], (OP*)&unop_list[20], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[8]  */
	{ (OP*)&unopaux_list[1], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[9]  */
	{ (OP*)&svop_list[14], (OP*)&svop_list[14], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[10]  */
	{ (OP*)&svop_list[17], (OP*)&svop_list[17], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[11]  */
	{ (OP*)&svop_list[20], (OP*)&unop_list[29], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[12]  */
	{ &op_list[16], (OP*)&unop_list[35], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[13]  */
	{ &op_list[15], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[14]  */
	{ (OP*)&logop_list[1], (OP*)&listop_list[6], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[15]  */
	{ (OP*)&svop_list[24], (OP*)&svop_list[24], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[16]  */
	{ (OP*)&svop_list[28], (OP*)&binop_list[6], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[17]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_PADSV), 6, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[18]  */
	{ (OP*)&unop_list[40], 0, INT2PTR(void*,OP_PADSV), 6, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x30 }, /* op_list[19]  */
	{ (OP*)&svop_list[32], (OP*)&binop_list[9], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[20]  */
	{ (OP*)&binop_list[9], 0, INT2PTR(void*,OP_PADSV), 6, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[21]  */
	{ (OP*)&svop_list[33], (OP*)&unop_list[45], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[22]  */
	{ (OP*)&svop_list[33], (OP*)&binop_list[10], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[23]  */
	{ (OP*)&binop_list[10], 0, INT2PTR(void*,OP_PADSV), 6, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[24]  */
	{ (OP*)&svop_list[34], (OP*)&binop_list[11], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[25]  */
	{ &op_list[29], (OP*)&unop_list[53], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[26]  */
	{ &op_list[28], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[27]  */
	{ (OP*)&logop_list[3], (OP*)&listop_list[10], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[28]  */
	{ (OP*)&svop_list[38], (OP*)&svop_list[38], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[29]  */
	{ (OP*)&logop_list[4], (OP*)&listop_list[11], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[30]  */
	{ (OP*)&cop_list[24], (OP*)&cop_list[24], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[31]  */
	{ (OP*)&svop_list[46], (OP*)&binop_list[15], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[32]  */
	{ (OP*)&svop_list[49], (OP*)&binop_list[17], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[33]  */
	{ &op_list[37], (OP*)&unop_list[65], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[34]  */
	{ &op_list[36], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[35]  */
	{ (OP*)&logop_list[6], (OP*)&listop_list[14], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[36]  */
	{ (OP*)&svop_list[53], (OP*)&svop_list[53], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[37]  */
	{ (OP*)&logop_list[7], (OP*)&listop_list[15], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[38]  */
	{ (OP*)&svop_list[69], (OP*)&binop_list[20], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[39]  */
	{ (OP*)&svop_list[71], (OP*)&binop_list[21], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[40]  */
	{ &op_list[44], (OP*)&unop_list[75], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[41]  */
	{ &op_list[43], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[42]  */
	{ (OP*)&logop_list[8], (OP*)&listop_list[17], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[43]  */
	{ (OP*)&svop_list[75], (OP*)&svop_list[75], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[44]  */
	{ (OP*)&logop_list[9], (OP*)&listop_list[18], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[45]  */
	{ (OP*)&svop_list[81], (OP*)&binop_list[24], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[46]  */
	{ (OP*)&svop_list[83], (OP*)&binop_list[25], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[47]  */
	{ &op_list[54], (OP*)&unop_list[87], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[48]  */
	{ &op_list[50], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[49]  */
	{ (OP*)&logop_list[10], (OP*)&listop_list[22], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[50]  */
	{ &op_list[52], (OP*)&unop_list[85], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[51]  */
	{ (OP*)&unop_list[85], 0, INT2PTR(void*,OP_PADSV), 30, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x80 }, /* op_list[52]  */
	{ (OP*)&unop_list[86], 0, INT2PTR(void*,OP_PADSV), 30, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[53]  */
	{ (OP*)&svop_list[89], (OP*)&svop_list[89], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[54]  */
	{ (OP*)&svop_list[105], (OP*)&binop_list[29], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[55]  */
	{ (OP*)&svop_list[107], (OP*)&unop_list[95], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[56]  */
	{ (OP*)&svop_list[107], (OP*)&binop_list[30], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[57]  */
	{ (OP*)&svop_list[109], (OP*)&binop_list[31], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[58]  */
	{ (OP*)&svop_list[112], (OP*)&binop_list[32], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[59]  */
	{ (OP*)&logop_list[11], (OP*)&listop_list[26], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[60]  */
	{ (OP*)&logop_list[12], (OP*)&listop_list[28], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[61]  */
	{ (OP*)&logop_list[13], (OP*)&listop_list[30], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[62]  */
	{ (OP*)&logop_list[14], (OP*)&listop_list[32], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[63]  */
	{ &op_list[67], &op_list[67], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[64]  */
	{ (OP*)&binop_list[40], 0, INT2PTR(void*,OP_PADSV), 41, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[65]  */
	{ (OP*)&unopaux_list[4], 0, INT2PTR(void*,OP_NULL), 7, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[66]  */
	{ (OP*)&svop_list[137], (OP*)&svop_list[137], INT2PTR(void*,OP_PADSV), 41, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[67]  */
	{ &op_list[71], (OP*)&unop_list[136], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[68]  */
	{ &op_list[70], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[69]  */
	{ (OP*)&logop_list[15], (OP*)&listop_list[35], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[70]  */
	{ (OP*)&svop_list[141], (OP*)&svop_list[141], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[71]  */
	{ (OP*)&svop_list[152], (OP*)&binop_list[44], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[72]  */
	{ (OP*)&binop_list[43], 0, INT2PTR(void*,OP_PADSV), 43, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[73]  */
	{ (OP*)&unop_list[140], 0, INT2PTR(void*,OP_PADSV), 43, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x30 }, /* op_list[74]  */
	{ (OP*)&svop_list[156], (OP*)&binop_list[47], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[75]  */
	{ (OP*)&binop_list[47], 0, INT2PTR(void*,OP_PADSV), 43, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[76]  */
	{ (OP*)&svop_list[157], (OP*)&unop_list[145], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[77]  */
	{ (OP*)&svop_list[157], (OP*)&binop_list[48], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[78]  */
	{ (OP*)&binop_list[48], 0, INT2PTR(void*,OP_PADSV), 43, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[79]  */
	{ (OP*)&svop_list[158], (OP*)&binop_list[49], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[80]  */
	{ &op_list[84], (OP*)&unop_list[153], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[81]  */
	{ &op_list[83], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[82]  */
	{ (OP*)&logop_list[16], (OP*)&listop_list[38], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[83]  */
	{ (OP*)&svop_list[162], (OP*)&svop_list[162], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[84]  */
	{ (OP*)&svop_list[164], (OP*)&binop_list[52], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[85]  */
	{ (OP*)&binop_list[51], 0, INT2PTR(void*,OP_PADSV), 53, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[86]  */
	{ (OP*)&logop_list[17], (OP*)&listop_list[39], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[87]  */
	{ (OP*)&svop_list[168], (OP*)&binop_list[55], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[88]  */
	{ (OP*)&binop_list[55], 0, INT2PTR(void*,OP_PADSV), 53, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[89]  */
	{ (OP*)&svop_list[169], (OP*)&binop_list[56], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[90]  */
	{ (OP*)&svop_list[173], (OP*)&unop_list[167], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[91]  */
	{ &op_list[95], (OP*)&unop_list[172], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[92]  */
	{ &op_list[94], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[93]  */
	{ (OP*)&logop_list[18], (OP*)&listop_list[43], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[94]  */
	{ (OP*)&svop_list[177], (OP*)&svop_list[177], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[95]  */
	{ (OP*)&svop_list[181], (OP*)&binop_list[58], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[96]  */
	{ (OP*)&svop_list[183], (OP*)&unop_list[178], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[97]  */
	{ (OP*)&svop_list[183], (OP*)&binop_list[59], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[98]  */
	{ (OP*)&svop_list[185], (OP*)&binop_list[60], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[99]  */
	{ (OP*)&cop_list[84], (OP*)&cop_list[84], INT2PTR(void*,OP_PADSV), 67, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[100]  */
	{ 0, 0, INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[101] s\_7fb6bb10ef40 */
	{ (OP*)&unop_list[187], 0, INT2PTR(void*,OP_PADSV), 67, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[102]  */
	{ (OP*)&binop_list[61], 0, INT2PTR(void*,OP_POP), 0, 164, 0, 0, 0, 1, 0, 0, 0, 0x82, 0x0 }, /* op_list[103]  */
	{ (OP*)&svop_list[195], (OP*)&unop_list[193], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[104]  */
	{ &op_list[106], &op_list[106], INT2PTR(void*,OP_SHIFT), 0, 165, 0, 0, 0, 1, 0, 0, 0, 0x82, 0x0 }, /* op_list[105]  */
	{ (OP*)&binop_list[62], 0, INT2PTR(void*,OP_PADSV), 1, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[106]  */
};

Static UNOP unop_list[195] = {
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[1] }, /* unop_list[0]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[1] }, /* unop_list[1]  */
	{ (OP*)&cop_list[2], (OP*)&cop_list[2], INT2PTR(void*,OP_ENTERSUB), 1, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x4, (OP*)&unop_list[3] }, /* unop_list[2]  */
	{ (OP*)&unop_list[2], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[2] }, /* unop_list[3]  */
	{ (OP*)&svop_list[2], (OP*)&unop_list[5], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&svop_list[1] }, /* unop_list[4]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[2] }, /* unop_list[5]  */
	{ (OP*)&listop_list[2], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[4] }, /* unop_list[6]  */
	{ &op_list[4], (OP*)&unop_list[6], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&unop_list[8] }, /* unop_list[7]  */
	{ (OP*)&logop_list[0], 0, INT2PTR(void*,OP_RV2HV), 0, 149, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x1, (OP*)&listop_list[3] }, /* unop_list[8]  */
	{ (OP*)&listop_list[3], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[5] }, /* unop_list[9]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[4] }, /* unop_list[10]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[12] }, /* unop_list[11]  */
	{ (OP*)&unop_list[11], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[6] }, /* unop_list[12]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x81, (OP*)&svop_list[9] }, /* unop_list[13]  */
	{ (OP*)&svop_list[10], (OP*)&svop_list[10], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[15] }, /* unop_list[14]  */
	{ (OP*)&unop_list[14], 0, INT2PTR(void*,OP_NULL), 148, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unopaux_list[0] }, /* unop_list[15]  */
	{ (OP*)&unop_list[12], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[11] }, /* unop_list[16]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&cop_list[7] }, /* unop_list[17]  */
	{ (OP*)&cop_list[9], (OP*)&cop_list[9], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[19] }, /* unop_list[18]  */
	{ (OP*)&unop_list[18], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[8] }, /* unop_list[19]  */
	{ (OP*)&svop_list[12], (OP*)&svop_list[12], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[21] }, /* unop_list[20]  */
	{ (OP*)&unop_list[20], 0, INT2PTR(void*,OP_NULL), 148, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unopaux_list[1] }, /* unop_list[21]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[13] }, /* unop_list[22]  */
	{ (OP*)&cop_list[11], (OP*)&cop_list[11], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[24] }, /* unop_list[23]  */
	{ (OP*)&unop_list[23], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[10] }, /* unop_list[24]  */
	{ (OP*)&unop_list[24], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[19] }, /* unop_list[25]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&cop_list[10] }, /* unop_list[26]  */
	{ (OP*)&cop_list[12], (OP*)&cop_list[12], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[28] }, /* unop_list[27]  */
	{ (OP*)&unop_list[27], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[12] }, /* unop_list[28]  */
	{ (OP*)&svop_list[21], (OP*)&svop_list[21], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[30] }, /* unop_list[29]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[31] }, /* unop_list[30]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_KEYS), 5, 146, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[32] }, /* unop_list[31]  */
	{ (OP*)&unop_list[31], 0, INT2PTR(void*,OP_RV2HV), 0, 149, 0, 0, 0, 1, 0, 0, 0, 0x37, 0x1, (OP*)&svop_list[20] }, /* unop_list[32]  */
	{ (OP*)&unop_list[28], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[22] }, /* unop_list[33]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[1] }, /* unop_list[34]  */
	{ (OP*)&svop_list[23], (OP*)&svop_list[23], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[16] }, /* unop_list[35]  */
	{ (OP*)&logop_list[2], 0, INT2PTR(void*,OP_ENTEREVAL), 256, 342, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[37] }, /* unop_list[36]  */
	{ (OP*)&unop_list[36], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[7] }, /* unop_list[37]  */
	{ (OP*)&listop_list[7], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[17] }, /* unop_list[38]  */
	{ (OP*)&binop_list[7], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[29] }, /* unop_list[39]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x81, &op_list[19] }, /* unop_list[40]  */
	{ (OP*)&cop_list[18], (OP*)&cop_list[18], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&listop_list[8] }, /* unop_list[41]  */
	{ (OP*)&listop_list[8], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[20] }, /* unop_list[42]  */
	{ &op_list[14], &op_list[14], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[44] }, /* unop_list[43]  */
	{ (OP*)&unop_list[43], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[22] }, /* unop_list[44]  */
	{ (OP*)&svop_list[34], (OP*)&unop_list[49], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[46] }, /* unop_list[45]  */
	{ (OP*)&unop_list[45], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[47] }, /* unop_list[46]  */
	{ (OP*)&unop_list[46], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[9] }, /* unop_list[47]  */
	{ (OP*)&listop_list[9], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[23] }, /* unop_list[48]  */
	{ (OP*)&svop_list[36], (OP*)&unop_list[51], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[25] }, /* unop_list[49]  */
	{ (OP*)&binop_list[11], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[35] }, /* unop_list[50]  */
	{ (OP*)&unop_list[44], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[36] }, /* unop_list[51]  */
	{ (OP*)&binop_list[12], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[3] }, /* unop_list[52]  */
	{ (OP*)&svop_list[37], (OP*)&svop_list[37], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[29] }, /* unop_list[53]  */
	{ &op_list[27], &op_list[27], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[55] }, /* unop_list[54]  */
	{ (OP*)&unop_list[54], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[30] }, /* unop_list[55]  */
	{ (OP*)&binop_list[13], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&listop_list[12] }, /* unop_list[56]  */
	{ (OP*)&logop_list[5], 0, INT2PTR(void*,OP_ENTEREVAL), 256, 342, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[58] }, /* unop_list[57]  */
	{ (OP*)&unop_list[57], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[13] }, /* unop_list[58]  */
	{ (OP*)&listop_list[13], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[32] }, /* unop_list[59]  */
	{ (OP*)&binop_list[16], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[47] }, /* unop_list[60]  */
	{ (OP*)&svop_list[51], (OP*)&unop_list[63], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[33] }, /* unop_list[61]  */
	{ (OP*)&binop_list[17], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[50] }, /* unop_list[62]  */
	{ (OP*)&unop_list[55], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[51] }, /* unop_list[63]  */
	{ (OP*)&binop_list[18], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[6] }, /* unop_list[64]  */
	{ (OP*)&svop_list[52], (OP*)&svop_list[52], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[37] }, /* unop_list[65]  */
	{ &op_list[35], &op_list[35], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[67] }, /* unop_list[66]  */
	{ (OP*)&unop_list[66], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[38] }, /* unop_list[67]  */
	{ (OP*)&binop_list[19], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&listop_list[16] }, /* unop_list[68]  */
	{ (OP*)&listop_list[16], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[39] }, /* unop_list[69]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[70] }, /* unop_list[70]  */
	{ (OP*)&svop_list[73], (OP*)&unop_list[73], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[40] }, /* unop_list[71]  */
	{ (OP*)&binop_list[21], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[72] }, /* unop_list[72]  */
	{ (OP*)&unop_list[67], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[73] }, /* unop_list[73]  */
	{ (OP*)&binop_list[22], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[8] }, /* unop_list[74]  */
	{ (OP*)&svop_list[74], (OP*)&svop_list[74], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[44] }, /* unop_list[75]  */
	{ &op_list[42], &op_list[42], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[77] }, /* unop_list[76]  */
	{ (OP*)&unop_list[76], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[45] }, /* unop_list[77]  */
	{ (OP*)&binop_list[23], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&listop_list[19] }, /* unop_list[78]  */
	{ (OP*)&listop_list[19], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[46] }, /* unop_list[79]  */
	{ (OP*)&binop_list[24], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[82] }, /* unop_list[80]  */
	{ (OP*)&svop_list[85], (OP*)&unop_list[83], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[47] }, /* unop_list[81]  */
	{ (OP*)&binop_list[25], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[84] }, /* unop_list[82]  */
	{ (OP*)&unop_list[77], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[85] }, /* unop_list[83]  */
	{ (OP*)&binop_list[27], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[10] }, /* unop_list[84]  */
	{ (OP*)&svop_list[88], (OP*)&svop_list[88], INT2PTR(void*,OP_RV2GV), 31, 14, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x31, &op_list[52] }, /* unop_list[85]  */
	{ (OP*)&cop_list[37], (OP*)&cop_list[37], INT2PTR(void*,OP_READLINE), 33, 26, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[53] }, /* unop_list[86]  */
	{ (OP*)&svop_list[86], (OP*)&svop_list[86], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[54] }, /* unop_list[87]  */
	{ (OP*)&binop_list[28], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x81, (OP*)&unop_list[89] }, /* unop_list[88]  */
	{ (OP*)&unop_list[88], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x31, (OP*)&svop_list[104] }, /* unop_list[89]  */
	{ (OP*)&cop_list[40], (OP*)&cop_list[40], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&listop_list[23] }, /* unop_list[90]  */
	{ (OP*)&listop_list[23], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[55] }, /* unop_list[91]  */
	{ (OP*)&binop_list[29], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[106] }, /* unop_list[92]  */
	{ &op_list[49], &op_list[49], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[94] }, /* unop_list[93]  */
	{ (OP*)&unop_list[93], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[56] }, /* unop_list[94]  */
	{ (OP*)&svop_list[109], (OP*)&unop_list[100], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[96] }, /* unop_list[95]  */
	{ (OP*)&unop_list[95], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[97] }, /* unop_list[96]  */
	{ (OP*)&unop_list[96], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[24] }, /* unop_list[97]  */
	{ (OP*)&listop_list[24], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[57] }, /* unop_list[98]  */
	{ (OP*)&binop_list[30], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[108] }, /* unop_list[99]  */
	{ (OP*)&svop_list[111], (OP*)&unop_list[102], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[58] }, /* unop_list[100]  */
	{ (OP*)&binop_list[31], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[110] }, /* unop_list[101]  */
	{ (OP*)&unop_list[94], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[111] }, /* unop_list[102]  */
	{ (OP*)&cop_list[44], (OP*)&cop_list[44], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[104] }, /* unop_list[103]  */
	{ (OP*)&unop_list[103], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[59] }, /* unop_list[104]  */
	{ (OP*)&svop_list[113], (OP*)&svop_list[113], INT2PTR(void*,OP_SCALAR), 0, 2, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[106] }, /* unop_list[105]  */
	{ (OP*)&svop_list[113], 0, INT2PTR(void*,OP_KEYS), 40, 146, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[107] }, /* unop_list[106]  */
	{ (OP*)&unop_list[106], 0, INT2PTR(void*,OP_RV2HV), 0, 149, 0, 0, 0, 1, 0, 0, 0, 0x37, 0x1, (OP*)&listop_list[25] }, /* unop_list[107]  */
	{ (OP*)&unop_list[104], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[115] }, /* unop_list[108]  */
	{ (OP*)&cop_list[47], (OP*)&cop_list[47], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[110] }, /* unop_list[109]  */
	{ (OP*)&unop_list[109], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[60] }, /* unop_list[110]  */
	{ (OP*)&binop_list[33], 0, INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unopaux_list[2] }, /* unop_list[111]  */
	{ (OP*)&unopaux_list[2], 0, INT2PTR(void*,OP_NULL), 149, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&listop_list[27] }, /* unop_list[112]  */
	{ (OP*)&unop_list[110], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[119] }, /* unop_list[113]  */
	{ (OP*)&cop_list[50], (OP*)&cop_list[50], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[115] }, /* unop_list[114]  */
	{ (OP*)&unop_list[114], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[61] }, /* unop_list[115]  */
	{ (OP*)&binop_list[34], 0, INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unopaux_list[3] }, /* unop_list[116]  */
	{ (OP*)&unopaux_list[3], 0, INT2PTR(void*,OP_NULL), 149, 0, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&listop_list[29] }, /* unop_list[117]  */
	{ (OP*)&unop_list[115], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[123] }, /* unop_list[118]  */
	{ (OP*)&cop_list[53], (OP*)&cop_list[53], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[120] }, /* unop_list[119]  */
	{ (OP*)&unop_list[119], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[62] }, /* unop_list[120]  */
	{ (OP*)&svop_list[126], (OP*)&svop_list[126], INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&listop_list[31] }, /* unop_list[121]  */
	{ (OP*)&unop_list[120], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[128] }, /* unop_list[122]  */
	{ (OP*)&cop_list[56], (OP*)&cop_list[56], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[124] }, /* unop_list[123]  */
	{ (OP*)&unop_list[123], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[63] }, /* unop_list[124]  */
	{ (OP*)&svop_list[131], (OP*)&svop_list[131], INT2PTR(void*,OP_RV2AV), 0, 135, 0, 0, 0, 1, 0, 0, 0, 0x16, 0x1, (OP*)&listop_list[33] }, /* unop_list[125]  */
	{ (OP*)&unop_list[124], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[133] }, /* unop_list[126]  */
	{ (OP*)&binop_list[39], 0, INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[128] }, /* unop_list[127]  */
	{ (OP*)&unop_list[127], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[64] }, /* unop_list[128]  */
	{ (OP*)&unopaux_list[4], (OP*)&unop_list[131], INT2PTR(void*,OP_SREFGEN), 0, 21, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[130] }, /* unop_list[129]  */
	{ (OP*)&unop_list[129], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x37, 0x0, (OP*)&svop_list[135] }, /* unop_list[130]  */
	{ (OP*)&binop_list[41], 0, INT2PTR(void*,OP_NULL), 150, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x82, (OP*)&unopaux_list[4] }, /* unop_list[131]  */
	{ (OP*)&cop_list[60], (OP*)&cop_list[60], INT2PTR(void*,OP_ENTEREVAL), 256, 342, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&svop_list[136] }, /* unop_list[132]  */
	{ (OP*)&unop_list[128], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[139] }, /* unop_list[133]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&cop_list[61] }, /* unop_list[134]  */
	{ (OP*)&binop_list[42], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[15] }, /* unop_list[135]  */
	{ (OP*)&svop_list[140], (OP*)&svop_list[140], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[71] }, /* unop_list[136]  */
	{ &op_list[73], &op_list[73], INT2PTR(void*,OP_ENTEREVAL), 256, 342, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[138] }, /* unop_list[137]  */
	{ (OP*)&unop_list[137], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[72] }, /* unop_list[138]  */
	{ (OP*)&binop_list[45], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[153] }, /* unop_list[139]  */
	{ (OP*)&binop_list[46], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x81, &op_list[74] }, /* unop_list[140]  */
	{ (OP*)&cop_list[67], (OP*)&cop_list[67], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&listop_list[36] }, /* unop_list[141]  */
	{ (OP*)&listop_list[36], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[75] }, /* unop_list[142]  */
	{ &op_list[69], &op_list[69], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[144] }, /* unop_list[143]  */
	{ (OP*)&unop_list[143], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[77] }, /* unop_list[144]  */
	{ (OP*)&svop_list[158], (OP*)&unop_list[149], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[146] }, /* unop_list[145]  */
	{ (OP*)&unop_list[145], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[147] }, /* unop_list[146]  */
	{ (OP*)&unop_list[146], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[37] }, /* unop_list[147]  */
	{ (OP*)&listop_list[37], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[78] }, /* unop_list[148]  */
	{ (OP*)&svop_list[160], (OP*)&unop_list[151], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[80] }, /* unop_list[149]  */
	{ (OP*)&binop_list[49], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[159] }, /* unop_list[150]  */
	{ (OP*)&unop_list[144], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[160] }, /* unop_list[151]  */
	{ (OP*)&binop_list[50], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[16] }, /* unop_list[152]  */
	{ (OP*)&svop_list[161], (OP*)&svop_list[161], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[84] }, /* unop_list[153]  */
	{ &op_list[86], &op_list[86], INT2PTR(void*,OP_ENTEREVAL), 256, 342, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[155] }, /* unop_list[154]  */
	{ (OP*)&unop_list[154], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[85] }, /* unop_list[155]  */
	{ (OP*)&binop_list[53], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[165] }, /* unop_list[156]  */
	{ &op_list[82], &op_list[82], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[158] }, /* unop_list[157]  */
	{ (OP*)&unop_list[157], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[87] }, /* unop_list[158]  */
	{ (OP*)&binop_list[54], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x1, (OP*)&listop_list[40] }, /* unop_list[159]  */
	{ (OP*)&listop_list[40], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[88] }, /* unop_list[160]  */
	{ (OP*)&svop_list[171], (OP*)&unop_list[163], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[90] }, /* unop_list[161]  */
	{ (OP*)&binop_list[56], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[170] }, /* unop_list[162]  */
	{ (OP*)&unop_list[158], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[171] }, /* unop_list[163]  */
	{ (OP*)&cop_list[76], (OP*)&cop_list[76], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&listop_list[41] }, /* unop_list[164]  */
	{ (OP*)&cop_list[78], (OP*)&cop_list[78], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[166] }, /* unop_list[165]  */
	{ (OP*)&unop_list[165], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[91] }, /* unop_list[166]  */
	{ (OP*)&svop_list[174], (OP*)&svop_list[174], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[168] }, /* unop_list[167]  */
	{ (OP*)&unop_list[167], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[169] }, /* unop_list[168]  */
	{ (OP*)&unop_list[168], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[42] }, /* unop_list[169]  */
	{ (OP*)&unop_list[166], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[175] }, /* unop_list[170]  */
	{ (OP*)&binop_list[57], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[18] }, /* unop_list[171]  */
	{ (OP*)&svop_list[176], (OP*)&svop_list[176], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x2f, 0x0, &op_list[95] }, /* unop_list[172]  */
	{ (OP*)&cop_list[81], (OP*)&cop_list[81], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&listop_list[44] }, /* unop_list[173]  */
	{ (OP*)&listop_list[44], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[96] }, /* unop_list[174]  */
	{ (OP*)&binop_list[58], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[182] }, /* unop_list[175]  */
	{ &op_list[93], &op_list[93], INT2PTR(void*,OP_ENTERSUB), 0, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x0, (OP*)&unop_list[177] }, /* unop_list[176]  */
	{ (OP*)&unop_list[176], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[97] }, /* unop_list[177]  */
	{ (OP*)&svop_list[185], (OP*)&unop_list[183], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[179] }, /* unop_list[178]  */
	{ (OP*)&unop_list[178], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[180] }, /* unop_list[179]  */
	{ (OP*)&unop_list[179], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[45] }, /* unop_list[180]  */
	{ (OP*)&listop_list[45], 0, INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[98] }, /* unop_list[181]  */
	{ (OP*)&binop_list[59], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[184] }, /* unop_list[182]  */
	{ (OP*)&svop_list[187], (OP*)&unop_list[185], INT2PTR(void*,OP_NULL), 68, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, &op_list[99] }, /* unop_list[183]  */
	{ (OP*)&binop_list[60], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[186] }, /* unop_list[184]  */
	{ (OP*)&unop_list[177], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[187] }, /* unop_list[185]  */
	{ (OP*)&svop_list[190], (OP*)&svop_list[190], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[187] }, /* unop_list[186]  */
	{ (OP*)&unop_list[186], 0, INT2PTR(void*,OP_DEFINED), 0, 43, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, &op_list[102] }, /* unop_list[187]  */
	{ (OP*)&unop_list[1], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0xa1, (OP*)&svop_list[191] }, /* unop_list[188]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[47] }, /* unop_list[189]  */
	{ &op_list[103], &op_list[103], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x36, 0x1, (OP*)&svop_list[192] }, /* unop_list[190]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[48] }, /* unop_list[191]  */
	{ (OP*)&cop_list[88], (OP*)&cop_list[88], INT2PTR(void*,OP_REQUIRE), 0, 339, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[194] }, /* unop_list[192]  */
	{ (OP*)&svop_list[193], (OP*)&svop_list[193], INT2PTR(void*,OP_RV2AV), 1, 135, 0, 0, 0, 1, 0, 0, 0, 0x37, 0x1, (OP*)&svop_list[195] }, /* unop_list[193]  */
	{ 0, 0, INT2PTR(void*,OP_LEAVESUB), 1, 186, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x41, (OP*)&listop_list[50] }, /* unop_list[194]  */
};

Static BINOP binop_list[63] = {
	{ (OP*)&listop_list[0], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[0], (OP*)&listop_list[1] }, /* binop_list[0]  */
	{ (OP*)&unop_list[8], 0, INT2PTR(void*,OP_CONCAT), 2, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[3], (OP*)&unop_list[10] }, /* binop_list[1]  */
	{ (OP*)&cop_list[8], (OP*)&cop_list[8], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[1], (OP*)&listop_list[4] }, /* binop_list[2]  */
	{ (OP*)&cop_list[6], (OP*)&cop_list[6], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[8], (OP*)&unop_list[13] }, /* binop_list[3]  */
	{ (OP*)&cop_list[20], (OP*)&cop_list[20], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[2], (OP*)&unop_list[34] }, /* binop_list[4]  */
	{ (OP*)&cop_list[15], (OP*)&cop_list[15], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&pmop_list[1], &op_list[18] }, /* binop_list[5]  */
	{ (OP*)&unop_list[36], 0, INT2PTR(void*,OP_CONCAT), 8, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[7], (OP*)&svop_list[30] }, /* binop_list[6]  */
	{ (OP*)&svop_list[30], (OP*)&svop_list[30], INT2PTR(void*,OP_CONCAT), 7, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[28], (OP*)&unop_list[39] }, /* binop_list[7]  */
	{ (OP*)&cop_list[16], (OP*)&cop_list[16], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[31], (OP*)&unop_list[40] }, /* binop_list[8]  */
	{ (OP*)&unop_list[41], 0, INT2PTR(void*,OP_CONCAT), 10, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[32], &op_list[21] }, /* binop_list[9]  */
	{ (OP*)&unop_list[47], 0, INT2PTR(void*,OP_CONCAT), 12, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[33], &op_list[24] }, /* binop_list[10]  */
	{ (OP*)&svop_list[36], 0, INT2PTR(void*,OP_CONCAT), 14, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[34], (OP*)&unop_list[50] }, /* binop_list[11]  */
	{ (OP*)&cop_list[25], (OP*)&cop_list[25], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[3], (OP*)&unop_list[52] }, /* binop_list[12]  */
	{ (OP*)&listop_list[11], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[44], (OP*)&unop_list[56] }, /* binop_list[13]  */
	{ (OP*)&listop_list[12], 0, INT2PTR(void*,OP_CONCAT), 19, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[45], (OP*)&pmop_list[3] }, /* binop_list[14]  */
	{ (OP*)&unop_list[57], 0, INT2PTR(void*,OP_CONCAT), 17, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[16], (OP*)&svop_list[48] }, /* binop_list[15]  */
	{ (OP*)&svop_list[48], (OP*)&svop_list[48], INT2PTR(void*,OP_CONCAT), 16, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[46], (OP*)&unop_list[60] }, /* binop_list[16]  */
	{ (OP*)&svop_list[51], 0, INT2PTR(void*,OP_CONCAT), 20, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[49], (OP*)&unop_list[62] }, /* binop_list[17]  */
	{ (OP*)&cop_list[29], (OP*)&cop_list[29], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[4], (OP*)&unop_list[64] }, /* binop_list[18]  */
	{ (OP*)&listop_list[15], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[68], (OP*)&unop_list[68] }, /* binop_list[19]  */
	{ (OP*)&unop_list[68], 0, INT2PTR(void*,OP_CONCAT), 22, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[69], (OP*)&unop_list[70] }, /* binop_list[20]  */
	{ (OP*)&svop_list[73], 0, INT2PTR(void*,OP_CONCAT), 24, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[71], (OP*)&unop_list[72] }, /* binop_list[21]  */
	{ (OP*)&cop_list[33], (OP*)&cop_list[33], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[5], (OP*)&unop_list[74] }, /* binop_list[22]  */
	{ (OP*)&listop_list[18], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[80], (OP*)&unop_list[78] }, /* binop_list[23]  */
	{ (OP*)&unop_list[78], 0, INT2PTR(void*,OP_CONCAT), 26, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[81], (OP*)&unop_list[80] }, /* binop_list[24]  */
	{ (OP*)&svop_list[85], 0, INT2PTR(void*,OP_CONCAT), 28, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[83], (OP*)&unop_list[82] }, /* binop_list[25]  */
	{ (OP*)&cop_list[42], (OP*)&cop_list[42], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[6], (OP*)&listop_list[20] }, /* binop_list[26]  */
	{ (OP*)&binop_list[26], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[7], (OP*)&unop_list[84] }, /* binop_list[27]  */
	{ (OP*)&cop_list[38], (OP*)&cop_list[38], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[103], (OP*)&unop_list[88] }, /* binop_list[28]  */
	{ (OP*)&unop_list[90], 0, INT2PTR(void*,OP_CONCAT), 34, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[105], (OP*)&unop_list[92] }, /* binop_list[29]  */
	{ (OP*)&unop_list[97], 0, INT2PTR(void*,OP_CONCAT), 36, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[107], (OP*)&unop_list[99] }, /* binop_list[30]  */
	{ (OP*)&svop_list[111], 0, INT2PTR(void*,OP_CONCAT), 38, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[109], (OP*)&unop_list[101] }, /* binop_list[31]  */
	{ (OP*)&svop_list[114], (OP*)&svop_list[114], INT2PTR(void*,OP_EQ), 0, 79, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[105], (OP*)&svop_list[113] }, /* binop_list[32]  */
	{ (OP*)&listop_list[26], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[116], (OP*)&unop_list[111] }, /* binop_list[33]  */
	{ (OP*)&listop_list[28], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[120], (OP*)&unop_list[116] }, /* binop_list[34]  */
	{ (OP*)&listop_list[30], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[124], (OP*)&binop_list[36] }, /* binop_list[35]  */
	{ (OP*)&binop_list[35], 0, INT2PTR(void*,OP_AELEM), 0, 138, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unop_list[121], (OP*)&svop_list[126] }, /* binop_list[36]  */
	{ (OP*)&listop_list[32], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[129], (OP*)&binop_list[38] }, /* binop_list[37]  */
	{ (OP*)&binop_list[37], 0, INT2PTR(void*,OP_AELEM), 0, 138, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x2, (OP*)&unop_list[125], (OP*)&svop_list[131] }, /* binop_list[38]  */
	{ (OP*)&cop_list[62], (OP*)&cop_list[62], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[8], (OP*)&listop_list[34] }, /* binop_list[39]  */
	{ (OP*)&cop_list[58], (OP*)&cop_list[58], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[134], &op_list[65] }, /* binop_list[40]  */
	{ (OP*)&cop_list[59], (OP*)&cop_list[59], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[129], (OP*)&unop_list[131] }, /* binop_list[41]  */
	{ (OP*)&cop_list[69], (OP*)&cop_list[69], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[9], (OP*)&unop_list[135] }, /* binop_list[42]  */
	{ (OP*)&cop_list[64], (OP*)&cop_list[64], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[137], &op_list[73] }, /* binop_list[43]  */
	{ (OP*)&unop_list[137], 0, INT2PTR(void*,OP_CONCAT), 45, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[45], (OP*)&svop_list[154] }, /* binop_list[44]  */
	{ (OP*)&svop_list[154], (OP*)&svop_list[154], INT2PTR(void*,OP_CONCAT), 44, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[152], (OP*)&unop_list[139] }, /* binop_list[45]  */
	{ (OP*)&cop_list[65], (OP*)&cop_list[65], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[155], (OP*)&unop_list[140] }, /* binop_list[46]  */
	{ (OP*)&unop_list[141], 0, INT2PTR(void*,OP_CONCAT), 47, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[156], &op_list[76] }, /* binop_list[47]  */
	{ (OP*)&unop_list[147], 0, INT2PTR(void*,OP_CONCAT), 49, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[157], &op_list[79] }, /* binop_list[48]  */
	{ (OP*)&svop_list[160], 0, INT2PTR(void*,OP_CONCAT), 51, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[158], (OP*)&unop_list[150] }, /* binop_list[49]  */
	{ (OP*)&cop_list[74], (OP*)&cop_list[74], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[10], (OP*)&unop_list[152] }, /* binop_list[50]  */
	{ (OP*)&cop_list[71], (OP*)&cop_list[71], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[154], &op_list[86] }, /* binop_list[51]  */
	{ (OP*)&unop_list[154], 0, INT2PTR(void*,OP_CONCAT), 55, 67, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&binop_list[53], (OP*)&svop_list[166] }, /* binop_list[52]  */
	{ (OP*)&svop_list[166], (OP*)&svop_list[166], INT2PTR(void*,OP_CONCAT), 54, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[164], (OP*)&unop_list[156] }, /* binop_list[53]  */
	{ (OP*)&listop_list[39], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[167], (OP*)&unop_list[159] }, /* binop_list[54]  */
	{ (OP*)&unop_list[159], 0, INT2PTR(void*,OP_CONCAT), 57, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[168], &op_list[89] }, /* binop_list[55]  */
	{ (OP*)&svop_list[171], 0, INT2PTR(void*,OP_CONCAT), 59, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[169], (OP*)&unop_list[162] }, /* binop_list[56]  */
	{ (OP*)&cop_list[83], (OP*)&cop_list[83], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x2, (OP*)&loop_list[11], (OP*)&unop_list[171] }, /* binop_list[57]  */
	{ (OP*)&unop_list[173], 0, INT2PTR(void*,OP_CONCAT), 61, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[181], (OP*)&unop_list[175] }, /* binop_list[58]  */
	{ (OP*)&unop_list[180], 0, INT2PTR(void*,OP_CONCAT), 63, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[183], (OP*)&unop_list[182] }, /* binop_list[59]  */
	{ (OP*)&svop_list[187], 0, INT2PTR(void*,OP_CONCAT), 65, 67, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, (OP*)&svop_list[185], (OP*)&unop_list[184] }, /* binop_list[60]  */
	{ (OP*)&unop_list[189], 0, INT2PTR(void*,OP_ADD), 1, 63, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&unop_list[190], &op_list[103] }, /* binop_list[61]  */
	{ (OP*)&unop_list[194], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, &op_list[105], &op_list[106] }, /* binop_list[62]  */
};

Static LOGOP logop_list[19] = {
	{ (OP*)&cop_list[4], (OP*)&cop_list[4], INT2PTR(void*,OP_MAPWHILE), 4, 172, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&listop_list[2], (OP*)&svop_list[3] }, /* logop_list[0]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[15], (OP*)&cop_list[13] }, /* logop_list[1]  */
	{ 0, 0, INT2PTR(void*,OP_SUBSTCONT), 0, 34, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[36], (OP*)&pmop_list[1] }, /* logop_list[2]  */
	{ (OP*)&binop_list[12], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[28], (OP*)&cop_list[21] }, /* logop_list[3]  */
	{ (OP*)&cop_list[23], (OP*)&cop_list[23], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[11] }, /* logop_list[4]  */
	{ 0, 0, INT2PTR(void*,OP_SUBSTCONT), 0, 34, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&unop_list[57], (OP*)&pmop_list[3] }, /* logop_list[5]  */
	{ (OP*)&binop_list[18], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[36], (OP*)&cop_list[26] }, /* logop_list[6]  */
	{ (OP*)&cop_list[28], (OP*)&cop_list[28], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[15] }, /* logop_list[7]  */
	{ (OP*)&binop_list[22], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[43], (OP*)&cop_list[30] }, /* logop_list[8]  */
	{ (OP*)&cop_list[32], (OP*)&cop_list[32], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[18] }, /* logop_list[9]  */
	{ (OP*)&binop_list[27], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[50], (OP*)&cop_list[35] }, /* logop_list[10]  */
	{ (OP*)&cop_list[46], (OP*)&cop_list[46], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[26] }, /* logop_list[11]  */
	{ (OP*)&cop_list[49], (OP*)&cop_list[49], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[28] }, /* logop_list[12]  */
	{ (OP*)&cop_list[52], (OP*)&cop_list[52], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[30] }, /* logop_list[13]  */
	{ (OP*)&cop_list[55], (OP*)&cop_list[55], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[32] }, /* logop_list[14]  */
	{ (OP*)&binop_list[42], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[70], (OP*)&cop_list[63] }, /* logop_list[15]  */
	{ (OP*)&binop_list[50], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[83], (OP*)&cop_list[70] }, /* logop_list[16]  */
	{ (OP*)&cop_list[73], (OP*)&cop_list[73], INT2PTR(void*,OP_ENTERTRY), 0, 344, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, 0, (OP*)&listop_list[39] }, /* logop_list[17]  */
	{ (OP*)&binop_list[57], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[94], (OP*)&cop_list[79] }, /* logop_list[18]  */
};

Static LISTOP listop_list[51] = {
	{ 0, 0, INT2PTR(void*,OP_LEAVE), 1, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x40, &op_list[0], (OP*)&binop_list[0] }, /* listop_list[0]  */
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[0], (OP*)&unop_list[0] }, /* listop_list[1]  */
	{ (OP*)&logop_list[0], 0, INT2PTR(void*,OP_MAPSTART), 0, 171, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[3], (OP*)&unop_list[6] }, /* listop_list[2]  */
	{ (OP*)&unop_list[8], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[3], (OP*)&unop_list[9] }, /* listop_list[3]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[5], (OP*)&unop_list[11] }, /* listop_list[4]  */
	{ (OP*)&svop_list[18], (OP*)&svop_list[18], INT2PTR(void*,OP_ANONHASH), 0, 161, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x1, &op_list[11], (OP*)&svop_list[16] }, /* listop_list[5]  */
	{ (OP*)&unop_list[34], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[13], &op_list[14] }, /* listop_list[6]  */
	{ (OP*)&unop_list[37], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[14], (OP*)&unop_list[38] }, /* listop_list[7]  */
	{ (OP*)&unop_list[41], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[17], (OP*)&unop_list[42] }, /* listop_list[8]  */
	{ (OP*)&unop_list[47], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[19], (OP*)&unop_list[48] }, /* listop_list[9]  */
	{ (OP*)&unop_list[52], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[21], &op_list[27] }, /* listop_list[10]  */
	{ (OP*)&svop_list[49], (OP*)&unop_list[61], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x2e, 0x0, (OP*)&logop_list[4], (OP*)&binop_list[13] }, /* listop_list[11]  */
	{ (OP*)&unop_list[56], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xe, 0x0, &op_list[31], (OP*)&binop_list[14] }, /* listop_list[12]  */
	{ (OP*)&unop_list[58], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[22], (OP*)&unop_list[59] }, /* listop_list[13]  */
	{ (OP*)&unop_list[64], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[26], &op_list[35] }, /* listop_list[14]  */
	{ (OP*)&svop_list[71], (OP*)&unop_list[71], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x2e, 0x0, (OP*)&logop_list[7], (OP*)&binop_list[19] }, /* listop_list[15]  */
	{ (OP*)&unop_list[68], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[27], (OP*)&unop_list[69] }, /* listop_list[16]  */
	{ (OP*)&unop_list[74], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[30], &op_list[42] }, /* listop_list[17]  */
	{ (OP*)&svop_list[83], (OP*)&unop_list[81], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x2e, 0x0, (OP*)&logop_list[9], (OP*)&binop_list[23] }, /* listop_list[18]  */
	{ (OP*)&unop_list[78], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[31], (OP*)&unop_list[79] }, /* listop_list[19]  */
	{ (OP*)&binop_list[26], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[34], (OP*)&binop_list[27] }, /* listop_list[20]  */
	{ (OP*)&cop_list[36], (OP*)&cop_list[36], INT2PTR(void*,OP_OPEN), 32, 220, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x3, &op_list[51], (OP*)&svop_list[87] }, /* listop_list[21]  */
	{ (OP*)&unop_list[84], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[35], &op_list[49] }, /* listop_list[22]  */
	{ (OP*)&unop_list[90], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[39], (OP*)&unop_list[91] }, /* listop_list[23]  */
	{ (OP*)&unop_list[97], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[41], (OP*)&unop_list[98] }, /* listop_list[24]  */
	{ (OP*)&unop_list[107], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[43], (OP*)&svop_list[112] }, /* listop_list[25]  */
	{ (OP*)&svop_list[118], (OP*)&svop_list[118], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&logop_list[11], (OP*)&binop_list[33] }, /* listop_list[26]  */
	{ (OP*)&unop_list[112], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[45], (OP*)&svop_list[117] }, /* listop_list[27]  */
	{ (OP*)&svop_list[122], (OP*)&svop_list[122], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&logop_list[12], (OP*)&binop_list[34] }, /* listop_list[28]  */
	{ (OP*)&unop_list[117], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[48], (OP*)&svop_list[121] }, /* listop_list[29]  */
	{ (OP*)&svop_list[127], (OP*)&svop_list[127], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&logop_list[13], (OP*)&binop_list[35] }, /* listop_list[30]  */
	{ (OP*)&unop_list[121], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[51], (OP*)&svop_list[125] }, /* listop_list[31]  */
	{ (OP*)&svop_list[132], (OP*)&svop_list[132], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&logop_list[14], (OP*)&binop_list[37] }, /* listop_list[32]  */
	{ (OP*)&unop_list[125], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[54], (OP*)&svop_list[130] }, /* listop_list[33]  */
	{ (OP*)&binop_list[39], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[57], (OP*)&unop_list[127] }, /* listop_list[34]  */
	{ (OP*)&unop_list[135], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[63], &op_list[69] }, /* listop_list[35]  */
	{ (OP*)&unop_list[141], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[66], (OP*)&unop_list[142] }, /* listop_list[36]  */
	{ (OP*)&unop_list[147], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[68], (OP*)&unop_list[148] }, /* listop_list[37]  */
	{ (OP*)&unop_list[152], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[70], &op_list[82] }, /* listop_list[38]  */
	{ (OP*)&svop_list[169], (OP*)&unop_list[161], INT2PTR(void*,OP_LEAVETRY), 0, 345, 0, 0, 0, 1, 0, 0, 0, 0x2e, 0x0, (OP*)&logop_list[17], (OP*)&binop_list[54] }, /* listop_list[39]  */
	{ (OP*)&unop_list[159], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[72], (OP*)&unop_list[160] }, /* listop_list[40]  */
	{ (OP*)&unop_list[164], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[75], (OP*)&svop_list[172] }, /* listop_list[41]  */
	{ (OP*)&unop_list[169], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[77], (OP*)&svop_list[173] }, /* listop_list[42]  */
	{ (OP*)&unop_list[171], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[79], &op_list[93] }, /* listop_list[43]  */
	{ (OP*)&unop_list[173], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[80], (OP*)&unop_list[174] }, /* listop_list[44]  */
	{ (OP*)&unop_list[180], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x0, (OP*)&cop_list[82], (OP*)&unop_list[181] }, /* listop_list[45]  */
	{ &op_list[101], 0, INT2PTR(void*,OP_LIST), 0, 158, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[101], (OP*)&svop_list[188] }, /* listop_list[46]  */
	{ (OP*)&unop_list[189], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[86], (OP*)&binop_list[61] }, /* listop_list[47]  */
	{ (OP*)&unop_list[191], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[87], (OP*)&listop_list[49] }, /* listop_list[48]  */
	{ (OP*)&unop_list[191], 0, INT2PTR(void*,OP_UNSHIFT), 2, 166, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x2, &op_list[104], (OP*)&svop_list[193] }, /* listop_list[49]  */
	{ (OP*)&unop_list[194], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xc, 0x0, (OP*)&cop_list[89], (OP*)&binop_list[62] }, /* listop_list[50]  */
};

Static PMOP pmop_list[5] = {
	{ &op_list[18], &op_list[18], INT2PTR(void*,OP_SUBST), 0, 33, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, 0, 0, 0, 0xc000000, {(OP*)&logop_list[2]}, {NULL} }, /* pmop_list[0]  */
	{ &op_list[18], &op_list[18], INT2PTR(void*,OP_SUBST), 0, 33, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, 0, 0, 0, 0xc000000, {(OP*)&logop_list[2]}, {NULL} }, /* pmop_list[1]  */
	{ (OP*)&binop_list[14], 0, INT2PTR(void*,OP_SUBST), 0, 33, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, 0, 0, 0, 0xc000000, {(OP*)&logop_list[5]}, {NULL} }, /* pmop_list[2]  */
	{ (OP*)&binop_list[14], 0, INT2PTR(void*,OP_SUBST), 0, 33, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, 0, 0, 0, 0xc000000, {(OP*)&logop_list[5]}, {NULL} }, /* pmop_list[3]  */
	{ (OP*)&cop_list[85], (OP*)&cop_list[85], INT2PTR(void*,OP_MATCH), 0, 31, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x40, (OP*)&svop_list[189], (OP*)&svop_list[189], 0, 0x0, {0}, {NULL} }, /* pmop_list[4]  */
};

Static SVOP svop_list[196] = {
	{ (OP*)&svop_list[1], (OP*)&unop_list[4], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, &sv_list[1] }, /* svop_list[0]  */
	{ (OP*)&svop_list[2], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[0] */ }, /* svop_list[1]  */
	{ (OP*)&unop_list[2], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[2]  */
	{ (OP*)&svop_list[4], (OP*)&unop_list[10], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[3] }, /* svop_list[3]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[4]  */
	{ (OP*)&svop_list[6], (OP*)&svop_list[6], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[4] }, /* svop_list[5]  */
	{ (OP*)&svop_list[7], (OP*)&svop_list[7], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[5] }, /* svop_list[6]  */
	{ (OP*)&listop_list[2], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[6] }, /* svop_list[7]  */
	{ (OP*)&svop_list[9], (OP*)&unop_list[13], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[7] }, /* svop_list[8]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x80, Nullsv /* (SV*)gv_list[3] */ }, /* svop_list[9]  */
	{ (OP*)&svop_list[11], (OP*)&unop_list[16], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[64] }, /* svop_list[10]  */
	{ (OP*)&unop_list[11], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[11]  */
	{ (OP*)&svop_list[13], (OP*)&unop_list[22], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[69] }, /* svop_list[12]  */
	{ (OP*)&unop_list[18], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[13]  */
	{ (OP*)&svop_list[15], (OP*)&svop_list[15], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[70] }, /* svop_list[14]  */
	{ &op_list[11], (OP*)&listop_list[5], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[71] }, /* svop_list[15]  */
	{ (OP*)&listop_list[5], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[72] }, /* svop_list[16]  */
	{ (OP*)&svop_list[16], (OP*)&svop_list[16], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x40, &sv_list[73] }, /* svop_list[17]  */
	{ (OP*)&svop_list[19], (OP*)&unop_list[25], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[74] }, /* svop_list[18]  */
	{ (OP*)&unop_list[23], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[19]  */
	{ (OP*)&unop_list[32], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[20]  */
	{ (OP*)&svop_list[22], (OP*)&unop_list[33], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[79] }, /* svop_list[21]  */
	{ (OP*)&unop_list[27], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[22]  */
	{ (OP*)&loop_list[2], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[23]  */
	{ (OP*)&svop_list[25], (OP*)&svop_list[25], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[80] }, /* svop_list[24]  */
	{ (OP*)&svop_list[26], (OP*)&svop_list[26], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[81] }, /* svop_list[25]  */
	{ (OP*)&svop_list[27], (OP*)&svop_list[27], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[82] }, /* svop_list[26]  */
	{ (OP*)&svop_list[23], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[83] }, /* svop_list[27]  */
	{ (OP*)&svop_list[29], (OP*)&unop_list[39], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[84] }, /* svop_list[28]  */
	{ (OP*)&binop_list[7], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[29]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[86] }, /* svop_list[30]  */
	{ &op_list[19], (OP*)&unop_list[40], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[87] }, /* svop_list[31]  */
	{ &op_list[21], &op_list[21], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[88] }, /* svop_list[32]  */
	{ &op_list[24], &op_list[24], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[89] }, /* svop_list[33]  */
	{ (OP*)&svop_list[35], (OP*)&unop_list[50], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[90] }, /* svop_list[34]  */
	{ (OP*)&binop_list[11], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[35]  */
	{ (OP*)&unop_list[43], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[36]  */
	{ (OP*)&loop_list[3], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[37]  */
	{ (OP*)&svop_list[39], (OP*)&svop_list[39], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[91] }, /* svop_list[38]  */
	{ (OP*)&svop_list[40], (OP*)&svop_list[40], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[92] }, /* svop_list[39]  */
	{ (OP*)&svop_list[41], (OP*)&svop_list[41], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[93] }, /* svop_list[40]  */
	{ (OP*)&svop_list[42], (OP*)&svop_list[42], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[94] }, /* svop_list[41]  */
	{ (OP*)&svop_list[43], (OP*)&svop_list[43], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[95] }, /* svop_list[42]  */
	{ (OP*)&svop_list[37], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[96] }, /* svop_list[43]  */
	{ &op_list[31], (OP*)&unop_list[56], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[97] }, /* svop_list[44]  */
	{ (OP*)&pmop_list[3], (OP*)&pmop_list[3], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[98] }, /* svop_list[45]  */
	{ (OP*)&svop_list[47], (OP*)&unop_list[60], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[99] }, /* svop_list[46]  */
	{ (OP*)&binop_list[16], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[47]  */
	{ (OP*)&binop_list[15], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[100] }, /* svop_list[48]  */
	{ (OP*)&svop_list[50], (OP*)&unop_list[62], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[101] }, /* svop_list[49]  */
	{ (OP*)&binop_list[17], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[50]  */
	{ (OP*)&unop_list[54], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[51]  */
	{ (OP*)&loop_list[4], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[52]  */
	{ (OP*)&svop_list[54], (OP*)&svop_list[54], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[102] }, /* svop_list[53]  */
	{ (OP*)&svop_list[55], (OP*)&svop_list[55], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[103] }, /* svop_list[54]  */
	{ (OP*)&svop_list[56], (OP*)&svop_list[56], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[104] }, /* svop_list[55]  */
	{ (OP*)&svop_list[57], (OP*)&svop_list[57], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[105] }, /* svop_list[56]  */
	{ (OP*)&svop_list[58], (OP*)&svop_list[58], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[106] }, /* svop_list[57]  */
	{ (OP*)&svop_list[59], (OP*)&svop_list[59], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[107] }, /* svop_list[58]  */
	{ (OP*)&svop_list[60], (OP*)&svop_list[60], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[108] }, /* svop_list[59]  */
	{ (OP*)&svop_list[61], (OP*)&svop_list[61], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[109] }, /* svop_list[60]  */
	{ (OP*)&svop_list[62], (OP*)&svop_list[62], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[110] }, /* svop_list[61]  */
	{ (OP*)&svop_list[63], (OP*)&svop_list[63], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[111] }, /* svop_list[62]  */
	{ (OP*)&svop_list[64], (OP*)&svop_list[64], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[112] }, /* svop_list[63]  */
	{ (OP*)&svop_list[65], (OP*)&svop_list[65], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[113] }, /* svop_list[64]  */
	{ (OP*)&svop_list[66], (OP*)&svop_list[66], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[114] }, /* svop_list[65]  */
	{ (OP*)&svop_list[67], (OP*)&svop_list[67], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[115] }, /* svop_list[66]  */
	{ (OP*)&svop_list[52], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[116] }, /* svop_list[67]  */
	{ (OP*)&svop_list[69], (OP*)&unop_list[68], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[117] }, /* svop_list[68]  */
	{ (OP*)&svop_list[70], (OP*)&unop_list[70], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[118] }, /* svop_list[69]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[70]  */
	{ (OP*)&svop_list[72], (OP*)&unop_list[72], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[119] }, /* svop_list[71]  */
	{ (OP*)&binop_list[21], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[72]  */
	{ (OP*)&unop_list[66], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[73]  */
	{ (OP*)&loop_list[5], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[74]  */
	{ (OP*)&svop_list[76], (OP*)&svop_list[76], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[120] }, /* svop_list[75]  */
	{ (OP*)&svop_list[77], (OP*)&svop_list[77], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[121] }, /* svop_list[76]  */
	{ (OP*)&svop_list[78], (OP*)&svop_list[78], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[122] }, /* svop_list[77]  */
	{ (OP*)&svop_list[79], (OP*)&svop_list[79], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[123] }, /* svop_list[78]  */
	{ (OP*)&svop_list[74], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[124] }, /* svop_list[79]  */
	{ (OP*)&svop_list[81], (OP*)&unop_list[78], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[125] }, /* svop_list[80]  */
	{ (OP*)&svop_list[82], (OP*)&unop_list[80], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[126] }, /* svop_list[81]  */
	{ (OP*)&binop_list[24], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[82]  */
	{ (OP*)&svop_list[84], (OP*)&unop_list[82], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[127] }, /* svop_list[83]  */
	{ (OP*)&binop_list[25], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[84]  */
	{ (OP*)&unop_list[76], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[85]  */
	{ (OP*)&loop_list[7], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[86]  */
	{ (OP*)&listop_list[21], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[129] }, /* svop_list[87]  */
	{ (OP*)&svop_list[87], (OP*)&svop_list[87], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[130] }, /* svop_list[88]  */
	{ (OP*)&svop_list[90], (OP*)&svop_list[90], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[131] }, /* svop_list[89]  */
	{ (OP*)&svop_list[91], (OP*)&svop_list[91], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[132] }, /* svop_list[90]  */
	{ (OP*)&svop_list[92], (OP*)&svop_list[92], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[133] }, /* svop_list[91]  */
	{ (OP*)&svop_list[93], (OP*)&svop_list[93], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[134] }, /* svop_list[92]  */
	{ (OP*)&svop_list[94], (OP*)&svop_list[94], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[135] }, /* svop_list[93]  */
	{ (OP*)&svop_list[95], (OP*)&svop_list[95], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[136] }, /* svop_list[94]  */
	{ (OP*)&svop_list[96], (OP*)&svop_list[96], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[137] }, /* svop_list[95]  */
	{ (OP*)&svop_list[97], (OP*)&svop_list[97], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[138] }, /* svop_list[96]  */
	{ (OP*)&svop_list[98], (OP*)&svop_list[98], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[139] }, /* svop_list[97]  */
	{ (OP*)&svop_list[99], (OP*)&svop_list[99], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[140] }, /* svop_list[98]  */
	{ (OP*)&svop_list[100], (OP*)&svop_list[100], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[141] }, /* svop_list[99]  */
	{ (OP*)&svop_list[101], (OP*)&svop_list[101], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[142] }, /* svop_list[100]  */
	{ (OP*)&svop_list[102], (OP*)&svop_list[102], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[143] }, /* svop_list[101]  */
	{ (OP*)&svop_list[86], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[144] }, /* svop_list[102]  */
	{ (OP*)&svop_list[104], (OP*)&unop_list[88], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[145] }, /* svop_list[103]  */
	{ (OP*)&unop_list[89], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[104]  */
	{ (OP*)&svop_list[106], (OP*)&unop_list[92], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[146] }, /* svop_list[105]  */
	{ (OP*)&binop_list[29], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[106]  */
	{ (OP*)&svop_list[108], (OP*)&unop_list[99], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[147] }, /* svop_list[107]  */
	{ (OP*)&binop_list[30], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[108]  */
	{ (OP*)&svop_list[110], (OP*)&unop_list[101], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[148] }, /* svop_list[109]  */
	{ (OP*)&binop_list[31], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[110]  */
	{ (OP*)&unop_list[93], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[111]  */
	{ (OP*)&unop_list[107], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[149] }, /* svop_list[112]  */
	{ (OP*)&binop_list[32], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[150] }, /* svop_list[113]  */
	{ (OP*)&svop_list[115], (OP*)&unop_list[108], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[151] }, /* svop_list[114]  */
	{ (OP*)&unop_list[103], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[115]  */
	{ (OP*)&svop_list[117], (OP*)&unop_list[111], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[152] }, /* svop_list[116]  */
	{ (OP*)&unopaux_list[2], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[154] }, /* svop_list[117]  */
	{ (OP*)&svop_list[119], (OP*)&unop_list[113], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[155] }, /* svop_list[118]  */
	{ (OP*)&unop_list[109], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[119]  */
	{ (OP*)&svop_list[121], (OP*)&unop_list[116], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[156] }, /* svop_list[120]  */
	{ (OP*)&unopaux_list[3], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[158] }, /* svop_list[121]  */
	{ (OP*)&svop_list[123], (OP*)&unop_list[118], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[159] }, /* svop_list[122]  */
	{ (OP*)&unop_list[114], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[123]  */
	{ (OP*)&svop_list[125], (OP*)&binop_list[36], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[160] }, /* svop_list[124]  */
	{ (OP*)&unop_list[121], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[161] }, /* svop_list[125]  */
	{ (OP*)&binop_list[36], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[162] }, /* svop_list[126]  */
	{ (OP*)&svop_list[128], (OP*)&unop_list[122], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[163] }, /* svop_list[127]  */
	{ (OP*)&unop_list[119], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[128]  */
	{ (OP*)&svop_list[130], (OP*)&binop_list[38], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[164] }, /* svop_list[129]  */
	{ (OP*)&unop_list[125], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[165] }, /* svop_list[130]  */
	{ (OP*)&binop_list[38], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[166] }, /* svop_list[131]  */
	{ (OP*)&svop_list[133], (OP*)&unop_list[126], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[167] }, /* svop_list[132]  */
	{ (OP*)&unop_list[123], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[133]  */
	{ &op_list[65], &op_list[65], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[168] }, /* svop_list[134]  */
	{ (OP*)&unop_list[129], 0, INT2PTR(void*,OP_ANONCODE), 42, 18, 0, 0, 0, 1, 0, 0, 0, 0x32, 0x0, Nullsv }, /* svop_list[135]  */
	{ (OP*)&unop_list[132], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[170] }, /* svop_list[136]  */
	{ (OP*)&svop_list[138], (OP*)&svop_list[138], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[171] }, /* svop_list[137]  */
	{ (OP*)&svop_list[139], (OP*)&unop_list[133], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[172] }, /* svop_list[138]  */
	{ (OP*)&unop_list[127], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[139]  */
	{ (OP*)&loop_list[9], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[140]  */
	{ (OP*)&svop_list[142], (OP*)&svop_list[142], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[176] }, /* svop_list[141]  */
	{ (OP*)&svop_list[143], (OP*)&svop_list[143], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[177] }, /* svop_list[142]  */
	{ (OP*)&svop_list[144], (OP*)&svop_list[144], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[178] }, /* svop_list[143]  */
	{ (OP*)&svop_list[145], (OP*)&svop_list[145], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[179] }, /* svop_list[144]  */
	{ (OP*)&svop_list[146], (OP*)&svop_list[146], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[180] }, /* svop_list[145]  */
	{ (OP*)&svop_list[147], (OP*)&svop_list[147], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[181] }, /* svop_list[146]  */
	{ (OP*)&svop_list[148], (OP*)&svop_list[148], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[182] }, /* svop_list[147]  */
	{ (OP*)&svop_list[149], (OP*)&svop_list[149], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[183] }, /* svop_list[148]  */
	{ (OP*)&svop_list[150], (OP*)&svop_list[150], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[184] }, /* svop_list[149]  */
	{ (OP*)&svop_list[151], (OP*)&svop_list[151], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[185] }, /* svop_list[150]  */
	{ (OP*)&svop_list[140], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[186] }, /* svop_list[151]  */
	{ (OP*)&svop_list[153], (OP*)&unop_list[139], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[187] }, /* svop_list[152]  */
	{ (OP*)&binop_list[45], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[153]  */
	{ (OP*)&binop_list[44], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[188] }, /* svop_list[154]  */
	{ &op_list[74], (OP*)&unop_list[140], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[189] }, /* svop_list[155]  */
	{ &op_list[76], &op_list[76], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[190] }, /* svop_list[156]  */
	{ &op_list[79], &op_list[79], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[191] }, /* svop_list[157]  */
	{ (OP*)&svop_list[159], (OP*)&unop_list[150], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[192] }, /* svop_list[158]  */
	{ (OP*)&binop_list[49], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[159]  */
	{ (OP*)&unop_list[143], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[160]  */
	{ (OP*)&loop_list[10], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[161]  */
	{ (OP*)&svop_list[163], (OP*)&svop_list[163], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[193] }, /* svop_list[162]  */
	{ (OP*)&svop_list[161], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[194] }, /* svop_list[163]  */
	{ (OP*)&svop_list[165], (OP*)&unop_list[156], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[195] }, /* svop_list[164]  */
	{ (OP*)&binop_list[53], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[165]  */
	{ (OP*)&binop_list[52], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[196] }, /* svop_list[166]  */
	{ (OP*)&svop_list[168], (OP*)&unop_list[159], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[197] }, /* svop_list[167]  */
	{ &op_list[89], &op_list[89], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[198] }, /* svop_list[168]  */
	{ (OP*)&svop_list[170], (OP*)&unop_list[162], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[199] }, /* svop_list[169]  */
	{ (OP*)&binop_list[56], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[170]  */
	{ (OP*)&unop_list[157], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[171]  */
	{ (OP*)&unop_list[164], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[200] }, /* svop_list[172]  */
	{ (OP*)&unop_list[169], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[201] }, /* svop_list[173]  */
	{ (OP*)&svop_list[175], (OP*)&unop_list[170], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[202] }, /* svop_list[174]  */
	{ (OP*)&unop_list[165], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[175]  */
	{ (OP*)&loop_list[11], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[176]  */
	{ (OP*)&svop_list[178], (OP*)&svop_list[178], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[203] }, /* svop_list[177]  */
	{ (OP*)&svop_list[179], (OP*)&svop_list[179], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[204] }, /* svop_list[178]  */
	{ (OP*)&svop_list[180], (OP*)&svop_list[180], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[205] }, /* svop_list[179]  */
	{ (OP*)&svop_list[176], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[206] }, /* svop_list[180]  */
	{ (OP*)&svop_list[182], (OP*)&unop_list[175], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[207] }, /* svop_list[181]  */
	{ (OP*)&binop_list[58], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[182]  */
	{ (OP*)&svop_list[184], (OP*)&unop_list[182], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[208] }, /* svop_list[183]  */
	{ (OP*)&binop_list[59], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[184]  */
	{ (OP*)&svop_list[186], (OP*)&unop_list[184], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[209] }, /* svop_list[185]  */
	{ (OP*)&binop_list[60], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[186]  */
	{ (OP*)&unop_list[176], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[187]  */
	{ (OP*)&listop_list[46], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[210] }, /* svop_list[188]  */
	{ (OP*)&pmop_list[4], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[211] }, /* svop_list[189]  */
	{ (OP*)&svop_list[191], (OP*)&unop_list[188], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[212] }, /* svop_list[190]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[5] */ }, /* svop_list[191]  */
	{ &op_list[103], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[0] */ }, /* svop_list[192]  */
	{ (OP*)&listop_list[49], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[222] }, /* svop_list[193]  */
	{ (OP*)&unop_list[192], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[223] }, /* svop_list[194]  */
	{ (OP*)&unop_list[193], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_incgv */ }, /* svop_list[195]  */
};

Static LOOP loop_list[12] = {
	{ (OP*)&cop_list[0], (OP*)&listop_list[1], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[0], (OP*)&binop_list[0], (OP*)&binop_list[0] }, /* loop_list[0]  */
	{ (OP*)&cop_list[5], (OP*)&listop_list[4], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[5], (OP*)&binop_list[2], (OP*)&binop_list[2] }, /* loop_list[1]  */
	{ &op_list[15], (OP*)&unop_list[34], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[13], (OP*)&svop_list[23], (OP*)&cop_list[13], &op_list[14], (OP*)&binop_list[4] }, /* loop_list[2]  */
	{ &op_list[28], (OP*)&unop_list[52], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[26], (OP*)&svop_list[37], (OP*)&cop_list[21], &op_list[27], (OP*)&binop_list[12] }, /* loop_list[3]  */
	{ &op_list[36], (OP*)&unop_list[64], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[34], (OP*)&svop_list[52], (OP*)&cop_list[26], &op_list[35], (OP*)&binop_list[18] }, /* loop_list[4]  */
	{ &op_list[43], (OP*)&unop_list[74], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[41], (OP*)&svop_list[74], (OP*)&cop_list[30], &op_list[42], (OP*)&binop_list[22] }, /* loop_list[5]  */
	{ (OP*)&cop_list[34], (OP*)&listop_list[20], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[34], (OP*)&binop_list[26], (OP*)&binop_list[26] }, /* loop_list[6]  */
	{ &op_list[50], (OP*)&unop_list[84], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[48], (OP*)&svop_list[86], (OP*)&cop_list[35], &op_list[49], (OP*)&binop_list[27] }, /* loop_list[7]  */
	{ (OP*)&cop_list[57], (OP*)&listop_list[34], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[57], (OP*)&binop_list[39], (OP*)&binop_list[39] }, /* loop_list[8]  */
	{ &op_list[70], (OP*)&unop_list[135], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[68], (OP*)&svop_list[140], (OP*)&cop_list[63], &op_list[69], (OP*)&binop_list[42] }, /* loop_list[9]  */
	{ &op_list[83], (OP*)&unop_list[152], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[81], (OP*)&svop_list[161], (OP*)&cop_list[70], &op_list[82], (OP*)&binop_list[50] }, /* loop_list[10]  */
	{ &op_list[94], (OP*)&unop_list[171], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[92], (OP*)&svop_list[176], (OP*)&cop_list[79], &op_list[93], (OP*)&binop_list[57] }, /* loop_list[11]  */
};

Static UNOP_AUX unopaux_list[5] = {
	{ (OP*)&unop_list[14], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x10, &op_list[7], unopaux_item0+1 }, /* unopaux_list[0]  */
	{ (OP*)&unop_list[20], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x10, &op_list[9], unopaux_item1+1 }, /* unopaux_list[1]  */
	{ (OP*)&binop_list[33], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x0, (OP*)&unop_list[112], unopaux_item2+1 }, /* unopaux_list[2]  */
	{ (OP*)&binop_list[34], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x0, (OP*)&unop_list[117], unopaux_item3+1 }, /* unopaux_list[3]  */
	{ (OP*)&binop_list[41], 0, INT2PTR(void*,OP_MULTIDEREF), 0, 153, 0, 0, 0, 1, 0, 0, 0, 0xa6, 0x80, &op_list[66], unopaux_item4+1 }, /* unopaux_list[4]  */
};

Static XPV xpv_list[197] = {
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[9]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[10]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[11]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[12]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[13]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[14]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[15]  */
	{ Nullhv, {0}, 44, 48 }, /* xpv_list[16]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[17]  */
	{ Nullhv, {0}, 34, 40 }, /* xpv_list[18]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[19]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[20]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[21]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[22]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[23]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[24]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[25]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[26]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[27]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[28]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[29]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[30]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[31]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[32]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[33]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[34]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[35]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[36]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[37]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[38]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[39]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[40]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[41]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[42]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[43]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[44]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[45]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[46]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[47]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[48]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[49]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[50]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[51]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[52]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[53]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[54]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[55]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[56]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[57]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[58]  */
	{ Nullhv, {0}, 8, 0 }, /* xpv_list[59]  */
	{ Nullhv, {0}, 29, 32 }, /* xpv_list[60]  */
	{ Nullhv, {0}, 24, 0 }, /* xpv_list[61]  */
	{ Nullhv, {0}, 55, 64 }, /* xpv_list[62]  */
	{ Nullhv, {0}, 51, 56 }, /* xpv_list[63]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[64]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[65]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[66]  */
	{ Nullhv, {0}, 42, 48 }, /* xpv_list[67]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[68]  */
	{ Nullhv, {0}, 18, 24 }, /* xpv_list[69]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[70]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[71]  */
	{ Nullhv, {0}, 12, 16 }, /* xpv_list[72]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[73]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[74]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[75]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[76]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[77]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[78]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[79]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[80]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[81]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[82]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[83]  */
	{ Nullhv, {0}, 10, 16 }, /* xpv_list[84]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[85]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[86]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[87]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[88]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[89]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[90]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[91]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[92]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[93]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[94]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[95]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[96]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[97]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[98]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[99]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[100]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[101]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[102]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[103]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[104]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[105]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[106]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[107]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[108]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[109]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[110]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[111]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[112]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[113]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[114]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[115]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[116]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[117]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[118]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[119]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[120]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[121]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[122]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[123]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[124]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[125]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[126]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[127]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[128]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[129]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[130]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[131]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[132]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[133]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[134]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[135]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[136]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[137]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[138]  */
	{ Nullhv, {0}, 5, 0 }, /* xpv_list[139]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[140]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[141]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[142]  */
	{ Nullhv, {0}, 5, 0 }, /* xpv_list[143]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[144]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[145]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[146]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[147]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[148]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[149]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[150]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[151]  */
	{ Nullhv, {0}, 0, 8 }, /* xpv_list[152]  */
	{ Nullhv, {0}, 8, 0 }, /* xpv_list[153]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[154]  */
	{ Nullhv, {0}, 0, 8 }, /* xpv_list[155]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[156]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[157]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[158]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[159]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[160]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[161]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[162]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[163]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[164]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[165]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[166]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[167]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[168]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[169]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[170]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[171]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[172]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[173]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[174]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[175]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[176]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[177]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[178]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[179]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[180]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[181]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[182]  */
	{ Nullhv, {0}, 7, 16 }, /* xpv_list[183]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[184]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[185]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[186]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[187]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[188]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[189]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[190]  */
	{ Nullhv, {0}, 29, 32 }, /* xpv_list[191]  */
	{ Nullhv, {0}, 4, 8 }, /* xpv_list[192]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[193]  */
	{ Nullhv, {0}, 10, 16 }, /* xpv_list[194]  */
	{ Nullhv, {0}, 14, 0 }, /* xpv_list[195]  */
	{ Nullhv, {0}, 3, 8 }, /* xpv_list[196]  */
};

Static XPVAV xpvav_list[14] = {
	{ Nullhv, {0}, 52, 52, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[1]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[2]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[3]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[4]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[5]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[6]  */
	{ Nullhv, {0}, 1, 1, 0 }, /* xpvav_list[7]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[8]  */
	{ Nullhv, {0}, 0, 0, 0 }, /* xpvav_list[9]  */
	{ Nullhv, {0}, 2, 2, 0 }, /* xpvav_list[10]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[11]  */
	{ Nullhv, {0}, 68, 68, 0 }, /* xpvav_list[12]  */
	{ Nullhv, {0}, 1, 1, 0 }, /* xpvav_list[13]  */
};

Static XPVHV xpvhv_list[2] = {
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[0]  */
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[1]  */
};

Static XPVCV_or_similar xpvcv_list[6] = {
	{ XPVCVIX0 }, /* xpvcv_list[0]  */
	{ XPVCVIX1 }, /* xpvcv_list[1]  */
	{ XPVCVIX2 }, /* xpvcv_list[2]  */
	{ XPVCVIX3 }, /* xpvcv_list[3]  */
	{ XPVCVIX4 }, /* xpvcv_list[4]  */
	{ XPVCVIX5 }, /* xpvcv_list[5]  */
};

Static PADLIST padlist_list[6] = {
	{ 1, NULL, 535, 534 }, /* padlist_list[0]  */
	{ 1, NULL, 536, 534 }, /* padlist_list[1]  */
	{ 1, NULL, 537, 534 }, /* padlist_list[2]  */
	{ 1, NULL, 540, 1 }, /* padlist_list[3]  */
	{ 1, NULL, 538, 1 }, /* padlist_list[4]  */
	{ 1, NULL, 552, 1 }, /* padlist_list[5]  */
};

Static MyPADNAME padname_list[10] = {
	{ NULL, (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 0xffffff45, 0, 0, 0x0, 0 }, /* padname_list[0]  */
	{ ((char*)&padname_list[1])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6827, 6832, 2 /* +1 */, 0, 5, 0x0, "$name" }, /* padname_list[1]  */
	{ ((char*)&padname_list[2])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6865, 6874, 2 /* +1 */, 0, 3, 0x0, "$fh" }, /* padname_list[2]  */
	{ ((char*)&padname_list[3])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 1 /* +1 */, 0, 0, 0x0, "" }, /* padname_list[3]  */
	{ ((char*)&padname_list[4])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6897, 6900, 3 /* +1 */, 0, 2, 0x4, "$w" }, /* padname_list[4]  */
	{ ((char*)&padname_list[5])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 2 /* +1 */, 0, 1, 0x0, "&" }, /* padname_list[5]  */
	{ ((char*)&padname_list[6])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6904, 6909, 2 /* +1 */, 0, 5, 0x0, "$name" }, /* padname_list[6]  */
	{ ((char*)&padname_list[7])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6914, 6919, 2 /* +1 */, 0, 5, 0x0, "$name" }, /* padname_list[7]  */
	{ ((char*)&padname_list[8])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6937, 6942, 2 /* +1 */, 0, 6, 0x4, "$thing" }, /* padname_list[8]  */
	{ ((char*)&padname_list[9])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 41, 0, 2 /* +1 */, 0, 2, 0x5, "$w" }, /* padname_list[9]  */
};

Static PADNAMELIST padnamelist_list[7] = {
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[0]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[1]  */
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[2]  */
	{ 1, NULL, 1, 0, 2 /* +1 */ }, /* padnamelist_list[3]  */
	{ 2, NULL, 2, 0, 2 /* +1 */ }, /* padnamelist_list[4]  */
	{ 67, NULL, 67, 67, 2 /* +1 */ }, /* padnamelist_list[5]  */
	{ 1, NULL, 1, 1, 2 /* +1 */ }, /* padnamelist_list[6]  */
};

Static XPVIV xpviv_list[5] = {
	{ Nullhv, {0}, 0, 0, {73} }, /* xpviv_list[0]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[1]  */
	{ Nullhv, {0}, 0, 0, {47} }, /* xpviv_list[2]  */
	{ Nullhv, {0}, 0, 0, {63} }, /* xpviv_list[3]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[4]  */
};

Static XPVMG xpvmg_list[3] = {
	{ Nullhv, {0}, 0, 1, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 23, 32, {0}, {0.00} }, /* xpvmg_list[1]  */
	{ Nullhv, {0}, 4, 5, {10}, {0.00} }, /* xpvmg_list[2]  */
};

Static XPVIO xpvio_list[1] = {
	{ Nullhv,{0},0,0,{0},0,{0},0,60,60,NULL,Nullgv,NULL,Nullgv,NULL,Nullgv,'>',0x0 }, /* xpvio_list[0]  */
};

Static SV sv_list[299] = {
	{ 0, 299, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */
	{ &xpv_list[0], 2147483647, 0x18014403, {0} }, /* sv_list[1]  */
	{ &xpviv_list[0], 1, 0x1101, {.svu_pv=NULL} }, /* sv_list[2]  */
	{ &xpv_list[1], 2147483647, 0x18014403, {0} }, /* sv_list[3]  */
	{ &xpv_list[2], 2147483647, 0x18014403, {0} }, /* sv_list[4]  */
	{ &xpv_list[3], 2147483647, 0x18014403, {0} }, /* sv_list[5]  */
	{ &xpv_list[4], 2147483647, 0x18014403, {0} }, /* sv_list[6]  */
	{ &xpv_list[5], 2147483647, 0x18014403, {0} }, /* sv_list[7]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[8]  */
	{ &xpvav_list[0], 1, 0x4000000b, {0} }, /* sv_list[9]  */
	{ &xpv_list[6], 1, 0x4403, {0} }, /* sv_list[10]  */
	{ &xpv_list[7], 1, 0x4403, {0} }, /* sv_list[11]  */
	{ &xpv_list[8], 1, 0x4403, {0} }, /* sv_list[12]  */
	{ &xpv_list[9], 1, 0x4403, {0} }, /* sv_list[13]  */
	{ &xpv_list[10], 1, 0x4403, {0} }, /* sv_list[14]  */
	{ &xpv_list[11], 1, 0x4403, {0} }, /* sv_list[15]  */
	{ &xpv_list[12], 1, 0x4403, {0} }, /* sv_list[16]  */
	{ &xpv_list[13], 1, 0x4403, {0} }, /* sv_list[17]  */
	{ &xpv_list[14], 1, 0x4403, {0} }, /* sv_list[18]  */
	{ &xpv_list[15], 1, 0x4403, {0} }, /* sv_list[19]  */
	{ &xpv_list[16], 1, 0x4403, {0} }, /* sv_list[20]  */
	{ &xpv_list[17], 1, 0x4403, {0} }, /* sv_list[21]  */
	{ &xpv_list[18], 1, 0x4403, {0} }, /* sv_list[22]  */
	{ &xpv_list[19], 1, 0x4403, {0} }, /* sv_list[23]  */
	{ &xpv_list[20], 1, 0x4403, {0} }, /* sv_list[24]  */
	{ &xpv_list[21], 1, 0x4403, {0} }, /* sv_list[25]  */
	{ &xpv_list[22], 1, 0x4403, {0} }, /* sv_list[26]  */
	{ &xpv_list[23], 1, 0x4403, {0} }, /* sv_list[27]  */
	{ &xpv_list[24], 1, 0x4403, {0} }, /* sv_list[28]  */
	{ &xpv_list[25], 1, 0x4403, {0} }, /* sv_list[29]  */
	{ &xpv_list[26], 1, 0x4403, {0} }, /* sv_list[30]  */
	{ &xpv_list[27], 1, 0x4403, {0} }, /* sv_list[31]  */
	{ &xpv_list[28], 1, 0x4403, {0} }, /* sv_list[32]  */
	{ &xpv_list[29], 1, 0x4403, {0} }, /* sv_list[33]  */
	{ &xpv_list[30], 1, 0x4403, {0} }, /* sv_list[34]  */
	{ &xpv_list[31], 1, 0x4403, {0} }, /* sv_list[35]  */
	{ &xpv_list[32], 1, 0x4403, {0} }, /* sv_list[36]  */
	{ &xpv_list[33], 1, 0x4403, {0} }, /* sv_list[37]  */
	{ &xpv_list[34], 1, 0x4403, {0} }, /* sv_list[38]  */
	{ &xpv_list[35], 1, 0x4403, {0} }, /* sv_list[39]  */
	{ &xpv_list[36], 1, 0x4403, {0} }, /* sv_list[40]  */
	{ &xpv_list[37], 1, 0x4403, {0} }, /* sv_list[41]  */
	{ &xpv_list[38], 1, 0x4403, {0} }, /* sv_list[42]  */
	{ &xpv_list[39], 1, 0x4403, {0} }, /* sv_list[43]  */
	{ &xpv_list[40], 1, 0x4403, {0} }, /* sv_list[44]  */
	{ &xpv_list[41], 1, 0x4403, {0} }, /* sv_list[45]  */
	{ &xpv_list[42], 1, 0x4403, {0} }, /* sv_list[46]  */
	{ &xpv_list[43], 1, 0x4403, {0} }, /* sv_list[47]  */
	{ &xpv_list[44], 1, 0x4403, {0} }, /* sv_list[48]  */
	{ &xpv_list[45], 1, 0x4403, {0} }, /* sv_list[49]  */
	{ &xpv_list[46], 1, 0x4403, {0} }, /* sv_list[50]  */
	{ &xpv_list[47], 1, 0x4403, {0} }, /* sv_list[51]  */
	{ &xpv_list[48], 1, 0x4403, {0} }, /* sv_list[52]  */
	{ &xpv_list[49], 1, 0x4403, {0} }, /* sv_list[53]  */
	{ &xpv_list[50], 1, 0x4403, {0} }, /* sv_list[54]  */
	{ &xpv_list[51], 1, 0x4403, {0} }, /* sv_list[55]  */
	{ &xpv_list[52], 1, 0x4403, {0} }, /* sv_list[56]  */
	{ &xpv_list[53], 1, 0x4403, {0} }, /* sv_list[57]  */
	{ &xpv_list[54], 1, 0x4403, {0} }, /* sv_list[58]  */
	{ &xpv_list[55], 1, 0x4403, {0} }, /* sv_list[59]  */
	{ &xpv_list[56], 1, 0x4403, {0} }, /* sv_list[60]  */
	{ &xpv_list[57], 1, 0x4403, {0} }, /* sv_list[61]  */
	{ &xpv_list[58], 1, 0x4403, {0} }, /* sv_list[62]  */
	{ &xpv_list[59], 1, 0x10004403, {0} }, /* sv_list[63]  */
	{ &xpv_list[60], 2147483647, 0x18014403, {0} }, /* sv_list[64]  */
	{ CVIX65 }, /* sv_list[65]  */
	{ &xpvav_list[1], 1, 0x4000000b, {0} }, /* sv_list[66]  */
	{ &xpvav_list[2], 1, 0x8000000b, {0} }, /* sv_list[67]  */
	{ &xpv_list[61], 1, 0x10004403, {0} }, /* sv_list[68]  */
	{ &xpv_list[62], 2147483647, 0x18014403, {0} }, /* sv_list[69]  */
	{ &xpv_list[63], 2147483647, 0x18014403, {0} }, /* sv_list[70]  */
	{ &xpv_list[64], 2147483647, 0x18014403, {0} }, /* sv_list[71]  */
	{ &xpv_list[65], 2147483647, 0x18014403, {0} }, /* sv_list[72]  */
	{ &xpv_list[66], 2147483647, 0x18014403, {0} }, /* sv_list[73]  */
	{ &xpv_list[67], 2147483647, 0x18014403, {0} }, /* sv_list[74]  */
	{ CVIX75 }, /* sv_list[75]  */
	{ &xpvav_list[3], 1, 0x4000000b, {0} }, /* sv_list[76]  */
	{ &xpvav_list[4], 1, 0x8000000b, {0} }, /* sv_list[77]  */
	{ &xpvhv_list[0], 1, 0x2000000c, {0} }, /* sv_list[78]  */
	{ &xpv_list[68], 2147483647, 0x18014403, {0} }, /* sv_list[79]  */
	{ &xpv_list[69], 2147483647, 0x18014403, {0} }, /* sv_list[80]  */
	{ &xpv_list[70], 2147483647, 0x18014403, {0} }, /* sv_list[81]  */
	{ &xpv_list[71], 2147483647, 0x18014403, {0} }, /* sv_list[82]  */
	{ &xpv_list[72], 2147483647, 0x18014403, {0} }, /* sv_list[83]  */
	{ &xpv_list[73], 2147483647, 0x8014403, {0} }, /* sv_list[84]  */
	{ &xpvmg_list[0], 1, 0x600007, {.svu_pv=(char*)pv2} }, /* sv_list[85]  */
	{ &xpv_list[74], 2147483647, 0x8014403, {0} }, /* sv_list[86]  */
	{ &xpv_list[75], 2147483647, 0x18014403, {0} }, /* sv_list[87]  */
	{ &xpv_list[76], 2147483647, 0x8014403, {0} }, /* sv_list[88]  */
	{ &xpv_list[77], 2147483647, 0x8014403, {0} }, /* sv_list[89]  */
	{ &xpv_list[78], 2147483647, 0x18014403, {0} }, /* sv_list[90]  */
	{ &xpv_list[79], 2147483647, 0x18014403, {0} }, /* sv_list[91]  */
	{ &xpv_list[80], 2147483647, 0x18014403, {0} }, /* sv_list[92]  */
	{ &xpv_list[81], 2147483647, 0x18014403, {0} }, /* sv_list[93]  */
	{ &xpv_list[82], 2147483647, 0x18014403, {0} }, /* sv_list[94]  */
	{ &xpv_list[83], 2147483647, 0x18014403, {0} }, /* sv_list[95]  */
	{ &xpv_list[84], 2147483647, 0x18014403, {0} }, /* sv_list[96]  */
	{ &xpv_list[85], 2147483647, 0x18014403, {0} }, /* sv_list[97]  */
	{ &xpv_list[86], 2147483647, 0x18014403, {0} }, /* sv_list[98]  */
	{ &xpv_list[87], 2147483647, 0x8014403, {0} }, /* sv_list[99]  */
	{ &xpv_list[88], 2147483647, 0x8014403, {0} }, /* sv_list[100]  */
	{ &xpv_list[89], 2147483647, 0x18014403, {0} }, /* sv_list[101]  */
	{ &xpv_list[90], 2147483647, 0x18014403, {0} }, /* sv_list[102]  */
	{ &xpv_list[91], 2147483647, 0x18014403, {0} }, /* sv_list[103]  */
	{ &xpv_list[92], 2147483647, 0x18014403, {0} }, /* sv_list[104]  */
	{ &xpv_list[93], 2147483647, 0x18014403, {0} }, /* sv_list[105]  */
	{ &xpv_list[94], 2147483647, 0x18014403, {0} }, /* sv_list[106]  */
	{ &xpv_list[95], 2147483647, 0x18014403, {0} }, /* sv_list[107]  */
	{ &xpv_list[96], 2147483647, 0x18014403, {0} }, /* sv_list[108]  */
	{ &xpv_list[97], 2147483647, 0x18014403, {0} }, /* sv_list[109]  */
	{ &xpv_list[98], 2147483647, 0x18014403, {0} }, /* sv_list[110]  */
	{ &xpv_list[99], 2147483647, 0x18014403, {0} }, /* sv_list[111]  */
	{ &xpv_list[100], 2147483647, 0x18014403, {0} }, /* sv_list[112]  */
	{ &xpv_list[101], 2147483647, 0x18014403, {0} }, /* sv_list[113]  */
	{ &xpv_list[102], 2147483647, 0x18014403, {0} }, /* sv_list[114]  */
	{ &xpv_list[103], 2147483647, 0x18014403, {0} }, /* sv_list[115]  */
	{ &xpv_list[104], 2147483647, 0x18014403, {0} }, /* sv_list[116]  */
	{ &xpv_list[105], 2147483647, 0x18014403, {0} }, /* sv_list[117]  */
	{ &xpv_list[106], 2147483647, 0x18014403, {0} }, /* sv_list[118]  */
	{ &xpv_list[107], 2147483647, 0x18014403, {0} }, /* sv_list[119]  */
	{ &xpv_list[108], 2147483647, 0x18014403, {0} }, /* sv_list[120]  */
	{ &xpv_list[109], 2147483647, 0x18014403, {0} }, /* sv_list[121]  */
	{ &xpv_list[110], 2147483647, 0x18014403, {0} }, /* sv_list[122]  */
	{ &xpv_list[111], 2147483647, 0x18014403, {0} }, /* sv_list[123]  */
	{ &xpv_list[112], 2147483647, 0x18014403, {0} }, /* sv_list[124]  */
	{ &xpv_list[113], 2147483647, 0x18014403, {0} }, /* sv_list[125]  */
	{ &xpv_list[114], 2147483647, 0x18014403, {0} }, /* sv_list[126]  */
	{ &xpv_list[115], 2147483647, 0x18014403, {0} }, /* sv_list[127]  */
	{ &xpv_list[116], 2147483647, 0x18014403, {0} }, /* sv_list[128]  */
	{ ptr_undef, 1, 0x801, {.svu_rv=&sv_list[128]} }, /* sv_list[129]  */
	{ &xpv_list[117], 2147483647, 0x18014403, {0} }, /* sv_list[130]  */
	{ &xpv_list[118], 2147483647, 0x18014403, {0} }, /* sv_list[131]  */
	{ &xpv_list[119], 2147483647, 0x18014403, {0} }, /* sv_list[132]  */
	{ &xpv_list[120], 2147483647, 0x18014403, {0} }, /* sv_list[133]  */
	{ &xpv_list[121], 2147483647, 0x18014403, {0} }, /* sv_list[134]  */
	{ &xpv_list[122], 2147483647, 0x18014403, {0} }, /* sv_list[135]  */
	{ &xpv_list[123], 2147483647, 0x18014403, {0} }, /* sv_list[136]  */
	{ &xpv_list[124], 2147483647, 0x18014403, {0} }, /* sv_list[137]  */
	{ &xpv_list[125], 2147483647, 0x18014403, {0} }, /* sv_list[138]  */
	{ &xpv_list[126], 2147483647, 0x18014403, {0} }, /* sv_list[139]  */
	{ &xpv_list[127], 2147483647, 0x18014403, {0} }, /* sv_list[140]  */
	{ &xpv_list[128], 2147483647, 0x18014403, {0} }, /* sv_list[141]  */
	{ &xpv_list[129], 2147483647, 0x18014403, {0} }, /* sv_list[142]  */
	{ &xpv_list[130], 2147483647, 0x18014403, {0} }, /* sv_list[143]  */
	{ &xpv_list[131], 2147483647, 0x18014403, {0} }, /* sv_list[144]  */
	{ &xpv_list[132], 2147483647, 0x18014403, {0} }, /* sv_list[145]  */
	{ &xpv_list[133], 2147483647, 0x18014403, {0} }, /* sv_list[146]  */
	{ &xpv_list[134], 2147483647, 0x18014403, {0} }, /* sv_list[147]  */
	{ &xpv_list[135], 2147483647, 0x18014403, {0} }, /* sv_list[148]  */
	{ &xpv_list[136], 2147483647, 0x18014403, {0} }, /* sv_list[149]  */
	{ &xpviv_list[1], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[150]  */
	{ &xpv_list[137], 2147483647, 0x18014403, {0} }, /* sv_list[151]  */
	{ &xpv_list[138], 2147483647, 0x18014403, {0} }, /* sv_list[152]  */
	{ &xpv_list[139], 1, 0x10004403, {0} }, /* sv_list[153]  */
	{ &xpv_list[140], 2147483647, 0x18014403, {0} }, /* sv_list[154]  */
	{ &xpv_list[141], 2147483647, 0x18014403, {0} }, /* sv_list[155]  */
	{ &xpv_list[142], 2147483647, 0x18014403, {0} }, /* sv_list[156]  */
	{ &xpv_list[143], 1, 0x10004403, {0} }, /* sv_list[157]  */
	{ &xpv_list[144], 2147483647, 0x18014403, {0} }, /* sv_list[158]  */
	{ &xpv_list[145], 2147483647, 0x18014403, {0} }, /* sv_list[159]  */
	{ &xpv_list[146], 2147483647, 0x18014403, {0} }, /* sv_list[160]  */
	{ &xpv_list[147], 2147483647, 0x18014403, {0} }, /* sv_list[161]  */
	{ &xpviv_list[2], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[162]  */
	{ &xpv_list[148], 2147483647, 0x18014403, {0} }, /* sv_list[163]  */
	{ &xpv_list[149], 2147483647, 0x18014403, {0} }, /* sv_list[164]  */
	{ &xpv_list[150], 2147483647, 0x18014403, {0} }, /* sv_list[165]  */
	{ &xpviv_list[3], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[166]  */
	{ &xpv_list[151], 2147483647, 0x18014403, {0} }, /* sv_list[167]  */
	{ &xpv_list[152], 2147483647, 0x18014403, {0} }, /* sv_list[168]  */
	{ &xpv_list[153], 1, 0x10004403, {0} }, /* sv_list[169]  */
	{ &xpv_list[154], 2147483647, 0x18014403, {0} }, /* sv_list[170]  */
	{ &xpv_list[155], 2147483647, 0x18014403, {0} }, /* sv_list[171]  */
	{ &xpv_list[156], 2147483647, 0x18014403, {0} }, /* sv_list[172]  */
	{ CVIX173 }, /* sv_list[173]  */
	{ &xpvav_list[5], 1, 0x4000000b, {0} }, /* sv_list[174]  */
	{ &xpvav_list[6], 1, 0x8000000b, {0} }, /* sv_list[175]  */
	{ &xpv_list[157], 2147483647, 0x18014403, {0} }, /* sv_list[176]  */
	{ &xpv_list[158], 2147483647, 0x18014403, {0} }, /* sv_list[177]  */
	{ &xpv_list[159], 2147483647, 0x18014403, {0} }, /* sv_list[178]  */
	{ &xpv_list[160], 2147483647, 0x18014403, {0} }, /* sv_list[179]  */
	{ &xpv_list[161], 2147483647, 0x18014403, {0} }, /* sv_list[180]  */
	{ &xpv_list[162], 2147483647, 0x18014403, {0} }, /* sv_list[181]  */
	{ &xpv_list[163], 2147483647, 0x18014403, {0} }, /* sv_list[182]  */
	{ &xpv_list[164], 2147483647, 0x18014403, {0} }, /* sv_list[183]  */
	{ &xpv_list[165], 2147483647, 0x18014403, {0} }, /* sv_list[184]  */
	{ &xpv_list[166], 2147483647, 0x18014403, {0} }, /* sv_list[185]  */
	{ &xpv_list[167], 2147483647, 0x18014403, {0} }, /* sv_list[186]  */
	{ &xpv_list[168], 2147483647, 0x8014403, {0} }, /* sv_list[187]  */
	{ &xpv_list[169], 2147483647, 0x8014403, {0} }, /* sv_list[188]  */
	{ &xpv_list[170], 2147483647, 0x18014403, {0} }, /* sv_list[189]  */
	{ &xpv_list[171], 2147483647, 0x8014403, {0} }, /* sv_list[190]  */
	{ &xpv_list[172], 2147483647, 0x8014403, {0} }, /* sv_list[191]  */
	{ &xpv_list[173], 2147483647, 0x18014403, {0} }, /* sv_list[192]  */
	{ &xpv_list[174], 2147483647, 0x18014403, {0} }, /* sv_list[193]  */
	{ &xpv_list[175], 2147483647, 0x18014403, {0} }, /* sv_list[194]  */
	{ &xpv_list[176], 2147483647, 0x8014403, {0} }, /* sv_list[195]  */
	{ &xpv_list[177], 2147483647, 0x8014403, {0} }, /* sv_list[196]  */
	{ &xpv_list[178], 2147483647, 0x18014403, {0} }, /* sv_list[197]  */
	{ &xpv_list[179], 2147483647, 0x8014403, {0} }, /* sv_list[198]  */
	{ &xpv_list[180], 2147483647, 0x18014403, {0} }, /* sv_list[199]  */
	{ &xpv_list[181], 2147483647, 0x18014403, {0} }, /* sv_list[200]  */
	{ &xpv_list[182], 2147483647, 0x18014403, {0} }, /* sv_list[201]  */
	{ &xpv_list[183], 2147483647, 0x18014403, {0} }, /* sv_list[202]  */
	{ &xpv_list[184], 2147483647, 0x18014403, {0} }, /* sv_list[203]  */
	{ &xpv_list[185], 2147483647, 0x18014403, {0} }, /* sv_list[204]  */
	{ &xpv_list[186], 2147483647, 0x18014403, {0} }, /* sv_list[205]  */
	{ &xpv_list[187], 2147483647, 0x18014403, {0} }, /* sv_list[206]  */
	{ &xpv_list[188], 2147483647, 0x18014403, {0} }, /* sv_list[207]  */
	{ &xpv_list[189], 2147483647, 0x18014403, {0} }, /* sv_list[208]  */
	{ &xpv_list[190], 2147483647, 0x18014403, {0} }, /* sv_list[209]  */
	{ &xpv_list[191], 2147483647, 0x18014403, {0} }, /* sv_list[210]  */
	{ &xpv_list[192], 2147483647, 0x18014403, {0} }, /* sv_list[211]  */
	{ &xpv_list[193], 2147483647, 0x18014403, {0} }, /* sv_list[212]  */
	{ CVIX213 }, /* sv_list[213]  */
	{ &xpvav_list[7], 1, 0x4000000b, {0} }, /* sv_list[214]  */
	{ &xpvav_list[8], 1, 0x8000000b, {0} }, /* sv_list[215]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[216]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[217]  */
	{ &xpvmg_list[1], 1, 0x10604407, {.svu_pv=(char*)pv3} }, /* sv_list[218]  */
	{ &xpvmg_list[2], 1, 0x604407, {.svu_pv=(char*)pv0} }, /* sv_list[219]  */
	{ &xpvav_list[9], 1, 0x4000000b, {0} }, /* sv_list[220]  */
	{ CVIX221 }, /* sv_list[221]  */
	{ &xpv_list[194], 2147483647, 0x18014403, {0} }, /* sv_list[222]  */
	{ &xpv_list[195], 2147483647, 0x18014403, {0} }, /* sv_list[223]  */
	{ &xpvav_list[10], 1, 0x4000000b, {0} }, /* sv_list[224]  */
	{ &xpvav_list[11], 1, 0x8000000b, {0} }, /* sv_list[225]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[226]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[227]  */
	{ &xpvav_list[12], 1, 0x4000000b, {0} }, /* sv_list[228]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[229]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[230]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[231]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[232]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[233]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[234]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[235]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[236]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[237]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[238]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[239]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[240]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[241]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[242]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[243]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[244]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[245]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[246]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[247]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[248]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[249]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[250]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[251]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[252]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[253]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[254]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[255]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[256]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[257]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[258]  */
	{ &xpv_list[196], 1, 0x20024403, {0} }, /* sv_list[259]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[260]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[261]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[262]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[263]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[264]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[265]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[266]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[267]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[268]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[269]  */
	{ CVIX270 }, /* sv_list[270]  */
	{ &xpvav_list[13], 1, 0x4000000b, {0} }, /* sv_list[271]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[272]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[273]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[274]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[275]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[276]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[277]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[278]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[279]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[280]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[281]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[282]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[283]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[284]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[285]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[286]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[287]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[288]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[289]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[290]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[291]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[292]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[293]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[294]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[295]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[296]  */
	{ &xpvhv_list[1], 1, 0x2200000c, {0} }, /* sv_list[297]  */
	{ &xpviv_list[4], 1, 0x1101, {.svu_pv=NULL} }, /* sv_list[298]  */
};

static void perl_init0(pTHX) /* fixup_ppaddr */
{
	register int i;
	for (i = 0; i < 63; ++i) {
		binop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(binop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 90; ++i) {
		cop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(cop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 51; ++i) {
		listop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(listop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 19; ++i) {
		logop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(logop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 12; ++i) {
		loop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(loop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 107; ++i) {
		op_list[i].op_ppaddr = PL_ppaddr[PTR2IV(op_list[i].op_ppaddr)];
	}
	for (i = 0; i < 5; ++i) {
		pmop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(pmop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 196; ++i) {
		svop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(svop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 195; ++i) {
		unop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(unop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 5; ++i) {
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
	gv_list[0] = gv_fetchpvn_flags("tests", 5, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[0]) = 0x8009;
	GvFLAGS(gv_list[0]) = 0x2; 
	GvLINE(gv_list[0]) = 21;
	SvREFCNT(gv_list[0]) = 3;
	GvSVn(gv_list[0]) = (SV*)&sv_list[2];
	hek0 = share_hek("t/CORE/op/leaky-magic.t", 23, 0);
	GvFILE_HEK(gv_list[0]) = hek0;
	
	svop_list[1].op_sv = (SV*)gv_list[0];
	gv_list[1] = gv_fetchpvn_flags("plan", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[1]) = 0x8009;
	GvFLAGS(gv_list[1]) = 0x2; 
	GvLINE(gv_list[1]) = 22;
	SvREFCNT(gv_list[1]) = 2;
	GvFILE_HEK(gv_list[1]) = share_hek_hek(hek0);
	
	svop_list[2].op_sv = (SV*)gv_list[1];
	CopSTASH_set(&cop_list[2], hv0);
	CopFILE_set(&cop_list[2], pv1);
	sv_list[3].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	CopSTASH_set(&cop_list[3], hv0);
	CopFILE_set(&cop_list[3], pv1);
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x2; 
	GvLINE(PL_defgv) = 0;
	SvREFCNT(PL_defgv) = 536;
	svop_list[4].op_sv = (SV*)PL_defgv;
	sv_list[4].sv_u.svu_pv = savepvn("!\000\001", 3);
	sv_list[5].sv_u.svu_pv = savepvn("-\000\001", 3);
	sv_list[6].sv_u.svu_pv = savepvn("+\000\001", 3);
	Perl_cop_store_label(aTHX_ &cop_list[4], "TODO", 4, 0);
	CopSTASH_set(&cop_list[4], hv0);
	CopFILE_set(&cop_list[4], pv1);
	CopSTASH_set(&cop_list[5], hv0);
	CopFILE_set(&cop_list[5], pv1);
	sv_list[7].sv_u.svu_pv = savepvn("with perlcc\000\001", 13);
	gv_list[3] = gv_fetchpvn_flags("TODO", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[3]) = 0x8009;
	GvFLAGS(gv_list[3]) = 0x2; 
	GvLINE(gv_list[3]) = 27;
	SvREFCNT(gv_list[3]) = 2;
	GvSVn(gv_list[3]) = (SV*)&sv_list[8];
	GvFILE_HEK(gv_list[3]) = share_hek_hek(hek0);
	
	svop_list[9].op_sv = (SV*)gv_list[3];
	CopSTASH_set(&cop_list[6], hv0);
	CopFILE_set(&cop_list[6], pv1);
	SvFLAGS(PL_incgv) = 0x8009;
	GvFLAGS(PL_incgv) = 0x2; 
	GvLINE(PL_incgv) = 0;
	SvREFCNT(PL_incgv) = 44;
	sv_list[10].sv_u.svu_pv = savepvn("blib/arch", 9);
	sv_list[11].sv_u.svu_pv = savepvn("blib/lib", 8);
	sv_list[12].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[13].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[14].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[15].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[16].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[17].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[18].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[19].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[20].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0/darwin", 44);
	sv_list[21].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0", 37);
	sv_list[22].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0/darwin", 34);
	sv_list[23].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0", 27);
	sv_list[24].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.11", 38);
	sv_list[25].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.10", 38);
	sv_list[26].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.9", 37);
	sv_list[27].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.8", 37);
	sv_list[28].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.5", 37);
	sv_list[29].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.4", 37);
	sv_list[30].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.3", 37);
	sv_list[31].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.2", 37);
	sv_list[32].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.1", 37);
	sv_list[33].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.2", 37);
	sv_list[34].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.1", 37);
	sv_list[35].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.0", 37);
	sv_list[36].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.9", 37);
	sv_list[37].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.8", 37);
	sv_list[38].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.6", 37);
	sv_list[39].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.4", 37);
	sv_list[40].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.2", 37);
	sv_list[41].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.4", 37);
	sv_list[42].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.2", 37);
	sv_list[43].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.1", 37);
	sv_list[44].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.0", 37);
	sv_list[45].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.3", 37);
	sv_list[46].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.1", 37);
	sv_list[47].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.15.8", 37);
	sv_list[48].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.4", 37);
	sv_list[49].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.3", 37);
	sv_list[50].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.2", 37);
	sv_list[51].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.1", 37);
	sv_list[52].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.0", 37);
	sv_list[53].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.5", 37);
	sv_list[54].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.4", 37);
	sv_list[55].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.10.1", 37);
	sv_list[56].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.9", 36);
	sv_list[57].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.8", 36);
	sv_list[58].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.5", 36);
	sv_list[59].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.4", 36);
	sv_list[60].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.6.2", 36);
	sv_list[61].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl", 30);
	sv_list[62].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[9];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(53 * sizeof(SV*));
	#else
		svp = (SV**)malloc(53 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=10; gcount<63; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvAV(PL_incgv) = (AV*)&sv_list[9];
	hek1 = share_hek("Errno.pm", 8, 0);
	sv_list[63].sv_u.svu_pv = HEK_KEY(hek1);
	sv_list[64].sv_u.svu_pv = savepvn("$swext::! does not load Errno\000\001", 31);
	gv_list[5] = gv_fetchpvn_flags("ok", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[5]) = 0x8009;
	GvFLAGS(gv_list[5]) = 0x6; 
	GvLINE(gv_list[5]) = 9;
	SvREFCNT(gv_list[5]) = 20;
	CopSTASH_set(&cop_list[7], hv0);
	CopFILE_set(&cop_list[7], pv1);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[0];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[66];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[67];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[0];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[0];
		*svp++ = (PAD*)(AV*)&sv_list[66];
	}
	{ /* &main::__ANON__ needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[0], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[65]) = pad;
	}
	hek2 = share_hek("$@", 2, 0);
	GvXPVGV(&sv_list[65])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[65]) = (CV*)0;
	gv_list[6] = gv_fetchpvn_flags("__ANON__", 8, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[6]) = 0x8009;
	GvFLAGS(gv_list[6]) = 0x2; 
	GvLINE(gv_list[6]) = 9;
	SvREFCNT(gv_list[6]) = 5;
	GvFILE_HEK(gv_list[6]) = share_hek_hek(hek0);
	
	CvGV_set((CV*)&sv_list[65], (GV*)gv_list[6]);
	CvSTART(&sv_list[65]) = (OP*)&cop_list[7];
	CvFILE(&sv_list[65]) = "t/CORE/op/leaky-magic.t";
	hv1 = gv_stashpvn("main", 4, GV_ADD);
	CvSTASH_set((CV*)&sv_list[65], hv1);
	SvPVX(&sv_list[65]) = HEK_KEY(hek2);
	GvCV_set(gv_list[5], (CV*)(&sv_list[65]));
	GvFILE_HEK(gv_list[5]) = share_hek_hek(hek0);
	
	svop_list[11].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[8], hv0);
	CopFILE_set(&cop_list[8], pv1);
	hek3 = share_hek("Tie/Hash/NamedCapture.pm", 24, 0);
	sv_list[68].sv_u.svu_pv = HEK_KEY(hek3);
	sv_list[69].sv_u.svu_pv = savepvn("$foo::+ and $foo::- do not load Tie::Hash::NamedCapture\000\001", 57);
	svop_list[13].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[9], hv0);
	CopFILE_set(&cop_list[9], pv1);
	sv_list[70].sv_u.svu_pv = savepvn("$count=0; ++$count while(<foo::ARGV>); print $count\000\001", 53);
	sv_list[71].sv_u.svu_pv = savepvn("0\000\001", 3);
	sv_list[72].sv_u.svu_pv = savepvn("swext\\n\000\001", 9);
	sv_list[73].sv_u.svu_pv = savepvn("stdin\000\001", 7);
	sv_list[74].sv_u.svu_pv = savepvn("<foo::ARGV> does not iterate through STDIN\000\001", 44);
	gv_list[7] = gv_fetchpvn_flags("fresh_perl_is", 13, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[7]) = 0x8009;
	GvFLAGS(gv_list[7]) = 0x6; 
	GvLINE(gv_list[7]) = 10;
	SvREFCNT(gv_list[7]) = 3;
	CopSTASH_set(&cop_list[10], hv0);
	CopFILE_set(&cop_list[10], pv1);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[1];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[76];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[77];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[1];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[1];
		*svp++ = (PAD*)(AV*)&sv_list[76];
	}
	{ /* &main::__ANON__ needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[1], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[75]) = pad;
	}
	GvXPVGV(&sv_list[75])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[75]) = (CV*)0;
	CvGV_set((CV*)&sv_list[75], (GV*)gv_list[6]);
	CvSTART(&sv_list[75]) = (OP*)&cop_list[10];
	CvFILE(&sv_list[75]) = "t/CORE/op/leaky-magic.t";
	CvSTASH_set((CV*)&sv_list[75], hv1);
	GvCV_set(gv_list[7], (CV*)(&sv_list[75]));
	GvFILE_HEK(gv_list[7]) = share_hek_hek(hek0);
	
	svop_list[19].op_sv = (SV*)gv_list[7];
	CopSTASH_set(&cop_list[11], hv0);
	CopFILE_set(&cop_list[11], pv1);
	gv_list[8] = gv_fetchpvn_flags("foo::SIG", 8, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[8]) = 0x8009;
	GvFLAGS(gv_list[8]) = 0x2; 
	GvLINE(gv_list[8]) = 41;
	SvREFCNT(gv_list[8]) = 2;
	HvTOTALKEYS((HV*)&sv_list[78]) = 0;
	GvHV(gv_list[8]) = (HV*)&sv_list[78];
	GvFILE_HEK(gv_list[8]) = share_hek_hek(hek0);
	
	svop_list[20].op_sv = (SV*)gv_list[8];
	sv_list[79].sv_u.svu_pv = savepvn("%foo::SIG\000\001", 11);
	svop_list[22].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[12], hv0);
	CopFILE_set(&cop_list[12], pv1);
	svop_list[23].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[13], hv0);
	CopFILE_set(&cop_list[13], pv1);
	sv_list[80].sv_u.svu_pv = savepvn("CHILD_ERROR_NATIVE\000\001", 20);
	sv_list[81].sv_u.svu_pv = savepvn("ENCODING\000\001", 10);
	sv_list[82].sv_u.svu_pv = savepvn("UTF8CACHE\000\001", 11);
	sv_list[83].sv_u.svu_pv = savepvn("WARNING_BITS\000\001", 14);
	CopSTASH_set(&cop_list[14], hv0);
	CopFILE_set(&cop_list[14], pv1);
	sv_list[84].sv_u.svu_pv = savepvn("qq|\\c", 5);
	gv_list[9] = gv_fetchpvn_flags("&", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[9]) = 0x8009;
	GvFLAGS(gv_list[9]) = 0x2; 
	GvLINE(gv_list[9]) = 45;
	SvREFCNT(gv_list[9]) = 3;
	sv_list[85].sv_u.svu_pv = savepvn("", 0);
	sv_magic((SV*)&sv_list[85], (SV*)gv_list[9], '\000', 0, 0);
	GvSVn(gv_list[9]) = (SV*)&sv_list[85];
	GvFILE_HEK(gv_list[9]) = share_hek_hek(hek0);
	
	svop_list[29].op_sv = (SV*)gv_list[9];
	sv_list[86].sv_u.svu_pv = savepvn("|", 1);
	pmop_list[0].op_pmstashstartu.op_pmreplstart = (OP*)(OP*)&svop_list[28];
	PM_SETRE(&pmop_list[0], CALLREGCOMP(newSVpvn_flags(".", 1, SVs_TEMP|0), 0xc000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[0])) = 0x0;
	pmop_list[1].op_pmstashstartu.op_pmreplstart = (OP*)(OP*)&svop_list[28];
	PM_SETRE(&pmop_list[1], CALLREGCOMP(newSVpvn_flags(".", 1, SVs_TEMP|0), 0xc000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[1])) = 0x0;
	CopSTASH_set(&cop_list[15], hv0);
	CopFILE_set(&cop_list[15], pv1);
	sv_list[87].sv_u.svu_pv = savepvn("swit\000\001", 6);
	CopSTASH_set(&cop_list[16], hv0);
	CopFILE_set(&cop_list[16], pv1);
	CopSTASH_set(&cop_list[17], hv0);
	CopFILE_set(&cop_list[17], pv1);
	sv_list[88].sv_u.svu_pv = savepvn("foo::", 5);
	CopSTASH_set(&cop_list[18], hv0);
	CopFILE_set(&cop_list[18], pv1);
	CopSTASH_set(&cop_list[19], hv0);
	CopFILE_set(&cop_list[19], pv1);
	sv_list[89].sv_u.svu_pv = savepvn("foo::", 5);
	sv_list[90].sv_u.svu_pv = savepvn("$foo::^\000\001", 9);
	svop_list[35].op_sv = (SV*)PL_defgv;
	svop_list[36].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[20], hv0);
	CopFILE_set(&cop_list[20], pv1);
	svop_list[37].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[21], hv0);
	CopFILE_set(&cop_list[21], pv1);
	sv_list[91].sv_u.svu_pv = savepvn("MATCH\000\001", 7);
	sv_list[92].sv_u.svu_pv = savepvn("PREMATCH\000\001", 10);
	sv_list[93].sv_u.svu_pv = savepvn("POSTMATCH\000\001", 11);
	sv_list[94].sv_u.svu_pv = savepvn("TAINT\000\001", 7);
	sv_list[95].sv_u.svu_pv = savepvn("UNICODE\000\001", 9);
	sv_list[96].sv_u.svu_pv = savepvn("UTF8LOCALE\000\001", 12);
	sv_list[97].sv_u.svu_pv = savepvn("prile\000\001", 7);
	sv_list[98].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	CopSTASH_set(&cop_list[22], hv0);
	CopFILE_set(&cop_list[22], pv1);
	sv_list[99].sv_u.svu_pv = savepvn("qq|\\c", 5);
	svop_list[47].op_sv = (SV*)gv_list[9];
	sv_list[100].sv_u.svu_pv = savepvn("|", 1);
	pmop_list[2].op_pmstashstartu.op_pmreplstart = (OP*)(OP*)&svop_list[46];
	PM_SETRE(&pmop_list[2], CALLREGCOMP(newSVpvn_flags(".", 1, SVs_TEMP|0), 0xc000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[2])) = 0x0;
	pmop_list[3].op_pmstashstartu.op_pmreplstart = (OP*)(OP*)&svop_list[46];
	PM_SETRE(&pmop_list[3], CALLREGCOMP(newSVpvn_flags(".", 1, SVs_TEMP|0), 0xc000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[3])) = 0x0;
	CopSTASH_set(&cop_list[23], hv0);
	CopFILE_set(&cop_list[23], pv1);
	CopSTASH_set(&cop_list[24], hv0);
	CopFILE_set(&cop_list[24], pv1);
	sv_list[101].sv_u.svu_pv = savepvn("$foo::^\000\001", 9);
	svop_list[50].op_sv = (SV*)PL_defgv;
	svop_list[51].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[25], hv0);
	CopFILE_set(&cop_list[25], pv1);
	svop_list[52].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[26], hv0);
	CopFILE_set(&cop_list[26], pv1);
	sv_list[102].sv_u.svu_pv = savepvn("1\000\001", 3);
	sv_list[103].sv_u.svu_pv = savepvn("2\000\001", 3);
	sv_list[104].sv_u.svu_pv = savepvn("3\000\001", 3);
	sv_list[105].sv_u.svu_pv = savepvn("4\000\001", 3);
	sv_list[106].sv_u.svu_pv = savepvn("5\000\001", 3);
	sv_list[107].sv_u.svu_pv = savepvn("6\000\001", 3);
	sv_list[108].sv_u.svu_pv = savepvn("7\000\001", 3);
	sv_list[109].sv_u.svu_pv = savepvn("8\000\001", 3);
	sv_list[110].sv_u.svu_pv = savepvn("9\000\001", 3);
	sv_list[111].sv_u.svu_pv = savepvn("324897\000\001", 8);
	sv_list[112].sv_u.svu_pv = savepvn("237\000\001", 5);
	sv_list[113].sv_u.svu_pv = savepvn("635\000\001", 5);
	sv_list[114].sv_u.svu_pv = savepvn("6780\000\001", 6);
	sv_list[115].sv_u.svu_pv = savepvn("42\000\001", 4);
	sv_list[116].sv_u.svu_pv = savepvn("14\000\001", 4);
	sv_list[117].sv_u.svu_pv = savepvn("prile\000\001", 7);
	CopSTASH_set(&cop_list[27], hv0);
	CopFILE_set(&cop_list[27], pv1);
	CopSTASH_set(&cop_list[28], hv0);
	CopFILE_set(&cop_list[28], pv1);
	sv_list[118].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[70].op_sv = (SV*)PL_defgv;
	sv_list[119].sv_u.svu_pv = savepvn("$foo::\000\001", 8);
	svop_list[72].op_sv = (SV*)PL_defgv;
	svop_list[73].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[29], hv0);
	CopFILE_set(&cop_list[29], pv1);
	svop_list[74].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[30], hv0);
	CopFILE_set(&cop_list[30], pv1);
	sv_list[120].sv_u.svu_pv = savepvn("&\000\001", 3);
	sv_list[121].sv_u.svu_pv = savepvn("`\000\001", 3);
	sv_list[122].sv_u.svu_pv = savepvn("'\000\001", 3);
	sv_list[123].sv_u.svu_pv = savepvn("+\000\001", 3);
	sv_list[124].sv_u.svu_pv = savepvn("]\000\001", 3);
	sv_list[125].sv_u.svu_pv = savepvn("twor\000\001", 6);
	CopSTASH_set(&cop_list[31], hv0);
	CopFILE_set(&cop_list[31], pv1);
	CopSTASH_set(&cop_list[32], hv0);
	CopFILE_set(&cop_list[32], pv1);
	sv_list[126].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[82].op_sv = (SV*)PL_defgv;
	sv_list[127].sv_u.svu_pv = savepvn("$foo::\000\001", 8);
	svop_list[84].op_sv = (SV*)PL_defgv;
	svop_list[85].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[33], hv0);
	CopFILE_set(&cop_list[33], pv1);
	CopSTASH_set(&cop_list[34], hv0);
	CopFILE_set(&cop_list[34], pv1);
	svop_list[86].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[35], hv0);
	CopFILE_set(&cop_list[35], pv1);
	sv_list[128].sv_u.svu_pv = savepvn("freen\000\001", 7);
	sv_list[130].sv_u.svu_pv = savepvn("<\000\001", 3);
	CopSTASH_set(&cop_list[36], hv0);
	CopFILE_set(&cop_list[36], pv1);
	CopSTASH_set(&cop_list[37], hv0);
	CopFILE_set(&cop_list[37], pv1);
	sv_list[131].sv_u.svu_pv = savepvn(":\000\001", 3);
	sv_list[132].sv_u.svu_pv = savepvn("?\000\001", 3);
	sv_list[133].sv_u.svu_pv = savepvn("!\000\001", 3);
	sv_list[134].sv_u.svu_pv = savepvn("-\000\001", 3);
	sv_list[135].sv_u.svu_pv = savepvn("|\000\001", 3);
	sv_list[136].sv_u.svu_pv = savepvn("^\000\001", 3);
	sv_list[137].sv_u.svu_pv = savepvn("~\000\001", 3);
	sv_list[138].sv_u.svu_pv = savepvn("=\000\001", 3);
	sv_list[139].sv_u.svu_pv = savepvn("%\000\001", 3);
	sv_list[140].sv_u.svu_pv = savepvn(".\000\001", 3);
	sv_list[141].sv_u.svu_pv = savepvn("\\\000\001", 3);
	sv_list[142].sv_u.svu_pv = savepvn("/\000\001", 3);
	sv_list[143].sv_u.svu_pv = savepvn(";\000\001", 3);
	sv_list[144].sv_u.svu_pv = savepvn("0\000\001", 3);
	sv_list[145].sv_u.svu_pv = savepvn("thew\000\001", 6);
	svop_list[104].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[38], hv0);
	CopFILE_set(&cop_list[38], pv1);
	CopSTASH_set(&cop_list[39], hv0);
	CopFILE_set(&cop_list[39], pv1);
	sv_list[146].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[106].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[40], hv0);
	CopFILE_set(&cop_list[40], pv1);
	CopSTASH_set(&cop_list[41], hv0);
	CopFILE_set(&cop_list[41], pv1);
	sv_list[147].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[108].op_sv = (SV*)PL_defgv;
	sv_list[148].sv_u.svu_pv = savepvn("$foo::\000\001", 8);
	svop_list[110].op_sv = (SV*)PL_defgv;
	svop_list[111].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[42], hv0);
	CopFILE_set(&cop_list[42], pv1);
	CopSTASH_set(&cop_list[43], hv0);
	CopFILE_set(&cop_list[43], pv1);
	sv_list[149].sv_u.svu_pv = savepvn("foo::!\000\001", 8);
	sv_list[151].sv_u.svu_pv = savepvn("%foo::!\000\001", 9);
	svop_list[115].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[44], hv0);
	CopFILE_set(&cop_list[44], pv1);
	sv_list[152].sv_u.svu_pv = savepvn("quin\000\001", 6);
	hek4 = share_hek("strat", 5, 0);
	sv_list[153].sv_u.svu_pv = HEK_KEY(hek4);
	CopSTASH_set(&cop_list[45], hv0);
	CopFILE_set(&cop_list[45], pv1);
	sv_list[154].sv_u.svu_pv = savepvn("foo::+\000\001", 8);
	CopSTASH_set(&cop_list[46], hv0);
	CopFILE_set(&cop_list[46], pv1);
	sv_list[155].sv_u.svu_pv = savepvn("%foo::+\000\001", 9);
	svop_list[119].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[47], hv0);
	CopFILE_set(&cop_list[47], pv1);
	sv_list[156].sv_u.svu_pv = savepvn("quin\000\001", 6);
	sv_list[157].sv_u.svu_pv = HEK_KEY(share_hek_hek(hek4));
	CopSTASH_set(&cop_list[48], hv0);
	CopFILE_set(&cop_list[48], pv1);
	sv_list[158].sv_u.svu_pv = savepvn("foo::-\000\001", 8);
	CopSTASH_set(&cop_list[49], hv0);
	CopFILE_set(&cop_list[49], pv1);
	sv_list[159].sv_u.svu_pv = savepvn("%foo::-\000\001", 9);
	svop_list[123].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[50], hv0);
	CopFILE_set(&cop_list[50], pv1);
	sv_list[160].sv_u.svu_pv = savepvn("quin\000\001", 6);
	CopSTASH_set(&cop_list[51], hv0);
	CopFILE_set(&cop_list[51], pv1);
	sv_list[161].sv_u.svu_pv = savepvn("foo::+\000\001", 8);
	CopSTASH_set(&cop_list[52], hv0);
	CopFILE_set(&cop_list[52], pv1);
	sv_list[163].sv_u.svu_pv = savepvn("@foo::+\000\001", 9);
	svop_list[128].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[53], hv0);
	CopFILE_set(&cop_list[53], pv1);
	sv_list[164].sv_u.svu_pv = savepvn("quin\000\001", 6);
	CopSTASH_set(&cop_list[54], hv0);
	CopFILE_set(&cop_list[54], pv1);
	sv_list[165].sv_u.svu_pv = savepvn("foo::-\000\001", 8);
	CopSTASH_set(&cop_list[55], hv0);
	CopFILE_set(&cop_list[55], pv1);
	sv_list[167].sv_u.svu_pv = savepvn("@foo::-\000\001", 9);
	svop_list[133].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[56], hv0);
	CopFILE_set(&cop_list[56], pv1);
	CopSTASH_set(&cop_list[57], hv0);
	CopFILE_set(&cop_list[57], pv1);
	sv_list[168].sv_u.svu_pv = savepvn("\000\001", 2);
	CopSTASH_set(&cop_list[58], hv0);
	CopFILE_set(&cop_list[58], pv1);
	gv_list[10] = gv_fetchpvn_flags("SIG", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[10]) = 0x8009;
	GvFLAGS(gv_list[10]) = 0x2; 
	GvLINE(gv_list[10]) = 63;
	SvREFCNT(gv_list[10]) = 17;
	hek5 = share_hek("/usr/local/lib/perl5/5.22.0/Exporter.pm", 39, 0);
	GvFILE_HEK(gv_list[10]) = hek5;
	
	hek6 = share_hek("__WARN__", 8, 0);
	sv_list[169].sv_u.svu_pv = HEK_KEY(hek6);
	CopSTASH_set(&cop_list[59], hv0);
	CopFILE_set(&cop_list[59], pv1);
	sv_list[170].sv_u.svu_pv = savepvn("${\"foo::#\"}\000\001", 13);
	CopSTASH_set(&cop_list[60], hv0);
	CopFILE_set(&cop_list[60], pv1);
	sv_list[171].sv_u.svu_pv = savepvn("\000\001", 2);
	sv_list[172].sv_u.svu_pv = savepvn("$foo::#\000\001", 9);
	gv_list[11] = gv_fetchpvn_flags("is", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[11]) = 0x8009;
	GvFLAGS(gv_list[11]) = 0x6; 
	GvLINE(gv_list[11]) = 11;
	SvREFCNT(gv_list[11]) = 3;
	CopSTASH_set(&cop_list[61], hv0);
	CopFILE_set(&cop_list[61], pv1);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[2];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[174];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[175];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[2];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[2];
		*svp++ = (PAD*)(AV*)&sv_list[174];
	}
	{ /* &main::__ANON__ needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[2], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[173]) = pad;
	}
	hek7 = share_hek("$$@", 3, 0);
	GvXPVGV(&sv_list[173])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[173]) = (CV*)0;
	CvGV_set((CV*)&sv_list[173], (GV*)gv_list[6]);
	CvSTART(&sv_list[173]) = (OP*)&cop_list[61];
	CvFILE(&sv_list[173]) = "t/CORE/op/leaky-magic.t";
	CvSTASH_set((CV*)&sv_list[173], hv1);
	SvPVX(&sv_list[173]) = HEK_KEY(hek7);
	GvCV_set(gv_list[11], (CV*)(&sv_list[173]));
	GvFILE_HEK(gv_list[11]) = share_hek_hek(hek0);
	
	svop_list[139].op_sv = (SV*)gv_list[11];
	CopSTASH_set(&cop_list[62], hv0);
	CopFILE_set(&cop_list[62], pv1);
	svop_list[140].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[63], hv0);
	CopFILE_set(&cop_list[63], pv1);
	sv_list[176].sv_u.svu_pv = savepvn("C\000\001", 3);
	sv_list[177].sv_u.svu_pv = savepvn("O\000\001", 3);
	sv_list[178].sv_u.svu_pv = savepvn("I\000\001", 3);
	sv_list[179].sv_u.svu_pv = savepvn("L\000\001", 3);
	sv_list[180].sv_u.svu_pv = savepvn("H\000\001", 3);
	sv_list[181].sv_u.svu_pv = savepvn("A\000\001", 3);
	sv_list[182].sv_u.svu_pv = savepvn("D\000\001", 3);
	sv_list[183].sv_u.svu_pv = savepvn("W\000\001", 3);
	sv_list[184].sv_u.svu_pv = savepvn("E\000\001", 3);
	sv_list[185].sv_u.svu_pv = savepvn("P\000\001", 3);
	sv_list[186].sv_u.svu_pv = savepvn("T\000\001", 3);
	sv_list[187].sv_u.svu_pv = savepvn("qq|\\c", 5);
	svop_list[153].op_sv = (SV*)PL_defgv;
	sv_list[188].sv_u.svu_pv = savepvn("|", 1);
	CopSTASH_set(&cop_list[64], hv0);
	CopFILE_set(&cop_list[64], pv1);
	sv_list[189].sv_u.svu_pv = savepvn("poof\000\001", 6);
	CopSTASH_set(&cop_list[65], hv0);
	CopFILE_set(&cop_list[65], pv1);
	CopSTASH_set(&cop_list[66], hv0);
	CopFILE_set(&cop_list[66], pv1);
	sv_list[190].sv_u.svu_pv = savepvn("foo::", 5);
	CopSTASH_set(&cop_list[67], hv0);
	CopFILE_set(&cop_list[67], pv1);
	CopSTASH_set(&cop_list[68], hv0);
	CopFILE_set(&cop_list[68], pv1);
	sv_list[191].sv_u.svu_pv = savepvn("foo::", 5);
	sv_list[192].sv_u.svu_pv = savepvn("$foo::^\000\001", 9);
	svop_list[159].op_sv = (SV*)PL_defgv;
	svop_list[160].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[69], hv0);
	CopFILE_set(&cop_list[69], pv1);
	svop_list[161].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[70], hv0);
	CopFILE_set(&cop_list[70], pv1);
	sv_list[193].sv_u.svu_pv = savepvn("S\000\001", 3);
	sv_list[194].sv_u.svu_pv = savepvn("V\000\001", 3);
	sv_list[195].sv_u.svu_pv = savepvn("qq|\\c", 5);
	svop_list[165].op_sv = (SV*)PL_defgv;
	sv_list[196].sv_u.svu_pv = savepvn("|", 1);
	CopSTASH_set(&cop_list[71], hv0);
	CopFILE_set(&cop_list[71], pv1);
	sv_list[197].sv_u.svu_pv = savepvn("twor\000\001", 6);
	CopSTASH_set(&cop_list[72], hv0);
	CopFILE_set(&cop_list[72], pv1);
	CopSTASH_set(&cop_list[73], hv0);
	CopFILE_set(&cop_list[73], pv1);
	sv_list[198].sv_u.svu_pv = savepvn("foo::", 5);
	sv_list[199].sv_u.svu_pv = savepvn("$foo::^\000\001", 9);
	svop_list[170].op_sv = (SV*)PL_defgv;
	svop_list[171].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[74], hv0);
	CopFILE_set(&cop_list[74], pv1);
	CopSTASH_set(&cop_list[75], hv0);
	CopFILE_set(&cop_list[75], pv1);
	sv_list[200].sv_u.svu_pv = savepvn("foo::[\000\001", 8);
	CopSTASH_set(&cop_list[76], hv0);
	CopFILE_set(&cop_list[76], pv1);
	CopSTASH_set(&cop_list[77], hv0);
	CopFILE_set(&cop_list[77], pv1);
	sv_list[201].sv_u.svu_pv = savepvn("foo::[\000\001", 8);
	sv_list[202].sv_u.svu_pv = savepvn("$foo::[\000\001", 9);
	svop_list[175].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[78], hv0);
	CopFILE_set(&cop_list[78], pv1);
	svop_list[176].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[79], hv0);
	CopFILE_set(&cop_list[79], pv1);
	sv_list[203].sv_u.svu_pv = savepvn("<\000\001", 3);
	sv_list[204].sv_u.svu_pv = savepvn(">\000\001", 3);
	sv_list[205].sv_u.svu_pv = savepvn("(\000\001", 3);
	sv_list[206].sv_u.svu_pv = savepvn(")\000\001", 3);
	CopSTASH_set(&cop_list[80], hv0);
	CopFILE_set(&cop_list[80], pv1);
	sv_list[207].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[182].op_sv = (SV*)PL_defgv;
	CopSTASH_set(&cop_list[81], hv0);
	CopFILE_set(&cop_list[81], pv1);
	CopSTASH_set(&cop_list[82], hv0);
	CopFILE_set(&cop_list[82], pv1);
	sv_list[208].sv_u.svu_pv = savepvn("foo::\000\001", 7);
	svop_list[184].op_sv = (SV*)PL_defgv;
	sv_list[209].sv_u.svu_pv = savepvn("$foo::\000\001", 8);
	svop_list[186].op_sv = (SV*)PL_defgv;
	svop_list[187].op_sv = (SV*)gv_list[5];
	CopSTASH_set(&cop_list[83], hv0);
	CopFILE_set(&cop_list[83], pv1);
	CopSTASH_set(&cop_list[84], hv0);
	CopFILE_set(&cop_list[84], pv1);
	pmop_list[4].op_pmstashstartu.op_pmreplstart = (OP*)0;
	sv_list[210].sv_u.svu_pv = savepvn("(?{ $thing = ${\"foo::\\cN\"} })\000\001", 31);
	pmop_list[4].op_code_list = (OP*)&listop_list[46];
	{
	  U32 hints_sav = PL_hints;
	  PL_hints |= HINT_RE_EVAL;
	PM_SETRE(&pmop_list[4], CALLREGCOMP(newSVpvn_flags("(.)(?{ $thing = ${\"foo::\\cN\"} })", 32, SVs_TEMP|0), 0x4000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[4])) = 0x20000;
	  PL_hints = hints_sav;
	}
	sv_list[211].sv_u.svu_pv = savepvn("felp\000\001", 6);
	CopSTASH_set(&cop_list[85], hv0);
	CopFILE_set(&cop_list[85], pv1);
	sv_list[212].sv_u.svu_pv = savepvn("$foo::^N\000\001", 10);
	svop_list[191].op_sv = (SV*)gv_list[5];
	
	/* done main optree, extra subs which might be unused */
	gv_list[12] = gv_fetchpvn_flags("tests::import", 13, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[12]) = 0x8009;
	GvFLAGS(gv_list[12]) = 0x2; 
	GvLINE(gv_list[12]) = 24;
	SvREFCNT(gv_list[12]) = 2;
	GvREFCNT(gv_list[12]) += 1;
	GvFILE_HEK(gv_list[12]) = share_hek_hek(hek0);
	
	gv_list[13] = gv_fetchpvn_flags("tests::VERSION", 14, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[13]) = 0x808009;
	GvFLAGS(gv_list[13]) = 0x2; 
	GvLINE(gv_list[13]) = 21;
	SvREFCNT(gv_list[13]) = 2;
	GvREFCNT(gv_list[13]) += 1;
	CopSTASH_set(&cop_list[86], hv0);
	CopFILE_set(&cop_list[86], pv1);
	svop_list[192].op_sv = (SV*)gv_list[0];
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[3];
		Newxz(svp, 2, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
	}
	av_extend((AV*)&sv_list[215], 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[214];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[215];
		*svp++ = (SV*)&sv_list[216];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[3];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[3];
		*svp++ = (PAD*)(AV*)&sv_list[214];
	}
	{ /* &tests::VERSION needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[3], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[213]) = pad;
	}
	GvXPVGV(&sv_list[213])->xnv_u.xgv_stash = 0;
	CvOUTSIDE(&sv_list[213]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[213])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[213], (GV*)gv_list[13]);
	CvSTART(&sv_list[213]) = (OP*)&cop_list[86];
	CvFILE(&sv_list[213]) = "t/CORE/op/leaky-magic.t";
	CvSTASH_set((CV*)&sv_list[213], hv1);
	GvCV_set(gv_list[13], (CV*)(&sv_list[213]));
	sv_magic((SV*)gv_list[13], (SV*)&sv_list[213], '<', 0, 0);
	CvCVGV_RC_off(&sv_list[213]);
	GvFILE_HEK(gv_list[13]) = share_hek_hek(hek0);
	
	gv_list[14] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[14]) = 2;
	gv_list[15] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[15]) = 2;
	gv_list[16] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[16]) = 2;
	gv_list[17] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[17]) = 0x8009;
	GvFLAGS(gv_list[17]) = 0x2; 
	GvLINE(gv_list[17]) = 0;
	SvREFCNT(gv_list[17]) = 23;
	GvREFCNT(gv_list[17]) += 1;
	GvFILE_HEK(gv_list[17]) = share_hek_hek(hek0);
	IoIFP((IO*)&sv_list[217]) = IoOFP((IO*)&sv_list[217]) = PerlIO_stdout();
	GvIOp(gv_list[17]) = (IO*)&sv_list[217];
	
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
	gv_list[20] = gv_fetchpvn_flags("INIT", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[20]) = 0x808009;
	GvFLAGS(gv_list[20]) = 0x2; 
	GvLINE(gv_list[20]) = 17;
	SvREFCNT(gv_list[20]) = 2;
	GvREFCNT(gv_list[20]) += 1;
	GvFILE_HEK(gv_list[20]) = share_hek_hek(hek0);
	
	gv_list[21] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[21]) = 0x8009;
	GvFLAGS(gv_list[21]) = 0x2; 
	GvLINE(gv_list[21]) = 363;
	SvREFCNT(gv_list[21]) = 9;
	GvREFCNT(gv_list[21]) += 1;
	sv_list[218].sv_u.svu_pv = savepvn("t/CORE/op/leaky-magic.c\000\001", 25);
	hv2 = gv_stashpvn("main::2", 7, GV_ADD);
	sv_magic((SV*)&sv_list[218], (SV*)gv_list[21], '\000', 0, 2);
	GvSVn(gv_list[21]) = (SV*)&sv_list[218];
	hek8 = share_hek("/usr/local/lib/perl5/5.22.0/Carp.pm", 35, 0);
	GvFILE_HEK(gv_list[21]) = hek8;
	
	gv_list[22] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[22]) = 0x8009;
	GvFLAGS(gv_list[22]) = 0x2; 
	GvLINE(gv_list[22]) = 102;
	SvREFCNT(gv_list[22]) = 48;
	GvREFCNT(gv_list[22]) += 1;
	sv_list[219].sv_u.svu_pv = savepvn("main", 4);
	sv_magic((SV*)&sv_list[219], (SV*)gv_list[22], '\000', 0, 1);
	GvSVn(gv_list[22]) = (SV*)&sv_list[219];
	hek9 = share_hek("/usr/local/lib/perl5/5.22.0/darwin/B.pm", 39, 0);
	GvFILE_HEK(gv_list[22]) = hek9;
	
	gv_list[23] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[23]) = 3;
	/* done extras */
	/* honor -w */
	PL_dowarn = ( 0 ) ? G_WARN_ON : G_WARN_OFF;
	CopSTASH_set(&cop_list[87], hv1);
	CopFILE_set(&cop_list[87], "t/CORE/op/leaky-magic.t");
	sv_list[222].sv_u.svu_pv = savepvn("t/CORE/lib\000\001", 12);
	hek10 = share_hek("t/CORE/test.pl", 14, 0);
	sv_list[223].sv_u.svu_pv = HEK_KEY(hek10);
	CopSTASH_set(&cop_list[88], hv1);
	CopFILE_set(&cop_list[88], "t/CORE/op/leaky-magic.t");
	svop_list[195].op_sv = (SV*)PL_incgv;
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[4];
		Newxz(svp, 3, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[0];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[224];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)(AV*)&sv_list[225];
		*svp++ = (SV*)&sv_list[226];
		*svp++ = (SV*)&sv_list[227];
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[4];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[4];
		*svp++ = (PAD*)(AV*)&sv_list[224];
	}
	{ /* &main::INIT needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[4], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[221]) = pad;
	}
	GvXPVGV(&sv_list[221])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[221]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[221])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[221], (GV*)gv_list[20]);
	CvSTART(&sv_list[221]) = (OP*)&cop_list[87];
	CvFILE(&sv_list[221]) = "t/CORE/op/leaky-magic.t";
	CvSTASH_set((CV*)&sv_list[221], hv1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[220];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)&sv_list[221];
	}
	/* END block */
	/* startpoints */
	PL_main_root = (OP*)&listop_list[0];
	PL_main_start = &op_list[0];
	PL_initav = (AV*)&sv_list[220];
	PL_endav = (AV*)Nullsv;
	/* curpad names */
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[5];
		Newxz(svp, 68, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[1];
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
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[4];
		*svp++ = (PADNAME*)&padname_list[5];
		*svp++ = (PADNAME*)&padname_list[6];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
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
		*svp++ = (PADNAME*)&padname_list[8];
	}
	/* curpad syms */
	sv_list[259].sv_u.svu_pv = savepvn("$fh", 3);
	CopSTASH_set(&cop_list[89], hv1);
	CopFILE_set(&cop_list[89], "t/CORE/op/leaky-magic.t");
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[6];
		Newxz(svp, 2, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)&padname_list[9];
	}
	{
		SV **svp;
		AV *av = (AV*)&sv_list[271];
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(3 * sizeof(SV*));
	#else
		svp = (SV**)malloc(3 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)Nullsv;
	}
	{
		PAD **svp;
		PADLIST *padl = &padlist_list[5];
		Newxz(svp, 2, PAD *);
		PadlistARRAY(padl) = svp;
		*svp++ = (PAD*)&padnamelist_list[6];
		*svp++ = (PAD*)(AV*)&sv_list[271];
	}
	{ /* &main::__ANON__ needs a dynamic padlist */
	  PADLIST *pad;
	  Newxz(pad, sizeof(PADLIST), PADLIST);
	  Copy(&padlist_list[5], pad, sizeof(PADLIST), char);
	  CvPADLIST(&sv_list[270]) = pad;
	}
	GvXPVGV(&sv_list[270])->xnv_u.xgv_stash = hv1;
	CvOUTSIDE(&sv_list[270]) = PL_main_cv;
	SvREFCNT_inc(PL_main_cv);
	CvPADLIST(&sv_list[270])->xpadl_outid = CvPADLIST(PL_main_cv)->xpadl_id;
	CvGV_set((CV*)&sv_list[270], (GV*)gv_list[6]);
	CvSTART(&sv_list[270]) = (OP*)&cop_list[89];
	CvFILE(&sv_list[270]) = "t/CORE/op/leaky-magic.t";
	CvSTASH_set((CV*)&sv_list[270], hv1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[228];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(69 * sizeof(SV*));
	#else
		svp = (SV**)malloc(69 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		for (gcount=229; gcount<271; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		for (gcount=272; gcount<297; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[297]) = a;
		HvRITER_set(&sv_list[297], -1);
	}
	{
		HV *hv = (HV*)&sv_list[297];
		hv_store(hv, "tests.pm", 8, &sv_list[298], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[297]) = 1;
	/* @INC */
	GvHV(PL_incgv) = (HV*)&sv_list[297];
	GvAV(PL_incgv) = (AV*)&sv_list[9];
	PL_curpad = AvARRAY((AV*)&sv_list[228]);
	PL_comppad = (AV*)&sv_list[228];
	PL_stack_sp = PL_stack_base;
	PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = &padnamelist_list[5]; /* namepad */
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)(AV*)&sv_list[228]; /* curpad */
	
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
static void perl_init2_aaaa(pTHX)
{
	unopaux_item0[2].sv = (SV*)PL_incgv;
	Gv_AMG(hv1); /* init AMG overload for %main:: */
	unopaux_item1[2].sv = (SV*)PL_incgv;
	unopaux_item4[2].sv = (SV*)gv_list[10];
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
