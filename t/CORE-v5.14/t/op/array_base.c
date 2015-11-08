/* created at Thu Oct 22 00:48:35 2015 with B::C 1.52_06 -2850-g341501a for /usr/local/bin/perl5.22.0-nt */
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
Static GV *gv_list[30];
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );

Static COP cop_list[52];
Static OP op_list[53];
Static UNOP unop_list[131];
Static BINOP binop_list[26];
Static LOGOP logop_list[3];
Static LISTOP listop_list[10];
Static PMOP pmop_list[3];
Static SVOP svop_list[136];
Static LOOP loop_list[5];
Static XPV xpv_list[103];
Static XPVAV xpvav_list[2];
Static XPVHV xpvhv_list[4];
Static MyPADNAME padname_list[15];
Static PADNAMELIST padnamelist_list[1];
Static XPVIV xpviv_list[28];
Static XPVNV xpvnv_list[2];
Static XPVMG xpvmg_list[15];
Static XPVIO xpvio_list[1];
Static SV sv_list[207];
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
Static const char lexwarn0[] = "\022\000\000\000\000\000\000\000DUUUUUUUUUUUUUUUU\001";
Static const char pv1[] = "main";
Static HV *hv0;
Static const char pv2[] = "t/CORE/op/array_base.t";
Static HEK *hek0;
Static HEK *hek1;
Static HEK *hek2;
Static const char pv3[] = "";
Static HV *hv1;
Static HEK *hek3;
Static const char lexwarn4[] = "\022\000\000\000\000\000\000\000DUUUUUUUUUQUUUUUU\001";
Static HV *hv2;
Static HV *hv3;
Static char pv5[] = "t/CORE/op/array_base.c";
Static HV *hv4;
Static HEK *hek4;
Static const char pv6[] = "arybase";
Static HEK *hek5;
Static HV *hv5;

Static COP cop_list[52] = {
	{ (OP*)&svop_list[83], (OP*)&binop_list[20], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 63, Nullhv, Nullgv, 133090, 6833, NULL, NULL }, /* cop_list[0]  */
	{ (OP*)&svop_list[0], (OP*)&unop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 4, Nullhv, Nullgv, 2018, 6802, pWARN_STD, NULL }, /* cop_list[1]  */
	{ &op_list[2], (OP*)&unop_list[3], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 6, Nullhv, Nullgv, 2018, 6802, pWARN_STD, NULL }, /* cop_list[2]  */
	{ (OP*)&loop_list[1], (OP*)&binop_list[1], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 20, Nullhv, Nullgv, 2018, 6803, NULL, NULL }, /* cop_list[3]  */
	{ &op_list[3], &op_list[3], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 12, Nullhv, Nullgv, 1762, 6804, NULL, NULL }, /* cop_list[4]  */
	{ &op_list[4], (OP*)&listop_list[3], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 13, Nullhv, Nullgv, 133090, 6805, NULL, NULL }, /* cop_list[5]  */
	{ &op_list[7], (OP*)&unop_list[9], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 14, Nullhv, Nullgv, 133090, 6805, NULL, NULL }, /* cop_list[6]  */
	{ (OP*)&svop_list[4], (OP*)&binop_list[2], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 15, Nullhv, Nullgv, 133090, 6805, NULL, NULL }, /* cop_list[7]  */
	{ (OP*)&loop_list[2], (OP*)&binop_list[4], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 42, Nullhv, Nullgv, 2018, 6806, NULL, NULL }, /* cop_list[8]  */
	{ &op_list[9], &op_list[9], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 20, Nullhv, Nullgv, 1762, 6807, NULL, NULL }, /* cop_list[9]  */
	{ &op_list[13], (OP*)&binop_list[5], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 21, Nullhv, Nullgv, 133090, 6808, NULL, NULL }, /* cop_list[10]  */
	{ &op_list[17], (OP*)&unop_list[19], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 22, Nullhv, Nullgv, 133090, 6808, NULL, NULL }, /* cop_list[11]  */
	{ (OP*)&svop_list[16], (OP*)&unop_list[22], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 23, Nullhv, Nullgv, 133090, 6808, NULL, NULL }, /* cop_list[12]  */
	{ (OP*)&svop_list[18], (OP*)&binop_list[9], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 23, Nullhv, Nullgv, 132834, 6810, NULL, NULL }, /* cop_list[13]  */
	{ &op_list[19], (OP*)&unop_list[24], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 24, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[14]  */
	{ (OP*)&svop_list[21], (OP*)&binop_list[10], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 25, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[15]  */
	{ &op_list[21], (OP*)&unop_list[28], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 26, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[16]  */
	{ &op_list[23], (OP*)&binop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 27, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[17]  */
	{ &op_list[26], (OP*)&unop_list[34], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 28, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[18]  */
	{ (OP*)&svop_list[31], (OP*)&binop_list[14], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 29, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[19]  */
	{ &op_list[29], (OP*)&unop_list[38], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 30, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[20]  */
	{ (OP*)&svop_list[36], (OP*)&unop_list[42], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 32, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[21]  */
	{ &op_list[30], (OP*)&unop_list[43], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 33, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[22]  */
	{ (OP*)&svop_list[41], (OP*)&unop_list[47], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 35, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[23]  */
	{ &op_list[8], (OP*)&unop_list[12], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 36, Nullhv, Nullgv, 133090, 6812, NULL, NULL }, /* cop_list[24]  */
	{ (OP*)&loop_list[4], (OP*)&binop_list[15], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 63, Nullhv, Nullgv, 2018, 6813, NULL, NULL }, /* cop_list[25]  */
	{ (OP*)&svop_list[46], (OP*)&binop_list[16], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 42, Nullhv, Nullgv, 133090, 6814, NULL, NULL }, /* cop_list[26]  */
	{ &op_list[32], (OP*)&unop_list[53], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 43, Nullhv, Nullgv, 133090, 6814, NULL, NULL }, /* cop_list[27]  */
	{ (OP*)&cop_list[29], (OP*)&unop_list[57], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 44, Nullhv, Nullgv, 133090, 6814, NULL, NULL }, /* cop_list[28]  */
	{ &op_list[33], (OP*)&unop_list[58], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 45, Nullhv, Nullgv, 133090, 6817, NULL, NULL }, /* cop_list[29]  */
	{ &op_list[34], (OP*)&unop_list[62], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 48, Nullhv, Nullgv, 133090, 6819, NULL, NULL }, /* cop_list[30]  */
	{ (OP*)&cop_list[32], (OP*)&unop_list[66], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 49, Nullhv, Nullgv, 133090, 6819, NULL, NULL }, /* cop_list[31]  */
	{ &op_list[35], (OP*)&unop_list[67], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 50, Nullhv, Nullgv, 133090, 6822, NULL, NULL }, /* cop_list[32]  */
	{ &op_list[36], (OP*)&binop_list[19], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 53, Nullhv, Nullgv, 133090, 6824, NULL, NULL }, /* cop_list[33]  */
	{ (OP*)&svop_list[72], (OP*)&unop_list[72], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 55, Nullhv, Nullgv, 133090, 6826, NULL, NULL }, /* cop_list[34]  */
	{ &op_list[38], (OP*)&unop_list[73], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 57, Nullhv, Nullgv, 133090, 6828, NULL, NULL }, /* cop_list[35]  */
	{ (OP*)&cop_list[37], (OP*)&unop_list[76], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 58, Nullhv, Nullgv, 133090, 6828, NULL, NULL }, /* cop_list[36]  */
	{ &op_list[31], (OP*)&unop_list[50], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 59, Nullhv, Nullgv, 133090, 6831, NULL, NULL }, /* cop_list[37]  */
	{ (OP*)&loop_list[0], (OP*)&binop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 63, Nullhv, Nullgv, 2018, 6832, NULL, NULL }, /* cop_list[38]  */
	{ (OP*)&unop_list[80], (OP*)&unop_list[80], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 66, Nullhv, Nullgv, 67241954, 6835, NULL, NULL }, /* cop_list[39]  */
	{ &op_list[41], (OP*)&unop_list[83], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 67, Nullhv, Nullgv, 67241954, 6838, NULL, NULL }, /* cop_list[40]  */
	{ &op_list[42], (OP*)&unop_list[87], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 68, Nullhv, Nullgv, 67241954, 6838, NULL, NULL }, /* cop_list[41]  */
	{ &op_list[43], (OP*)&unop_list[91], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 69, Nullhv, Nullgv, 67241954, 6838, NULL, NULL }, /* cop_list[42]  */
	{ (OP*)&unop_list[95], (OP*)&unop_list[95], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 71, Nullhv, Nullgv, 67241954, 6838, NULL, NULL }, /* cop_list[43]  */
	{ &op_list[45], (OP*)&unop_list[100], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 73, Nullhv, Nullgv, 67241954, 6846, NULL, NULL }, /* cop_list[44]  */
	{ &op_list[46], (OP*)&unop_list[104], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 74, Nullhv, Nullgv, 67241954, 6846, NULL, NULL }, /* cop_list[45]  */
	{ &op_list[47], (OP*)&unop_list[109], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 75, Nullhv, Nullgv, 67241954, 6846, NULL, NULL }, /* cop_list[46]  */
	{ &op_list[49], (OP*)&unop_list[113], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 76, Nullhv, Nullgv, 67241954, 6846, NULL, NULL }, /* cop_list[47]  */
	{ (OP*)&unop_list[118], (OP*)&unop_list[118], INT2PTR(void*,OP_NULL), 193, 0, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 78, Nullhv, Nullgv, 67241954, 6846, NULL, NULL }, /* cop_list[48]  */
	{ &op_list[51], (OP*)&unop_list[121], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 79, Nullhv, Nullgv, 67241954, 6849, NULL, NULL }, /* cop_list[49]  */
	{ &op_list[52], (OP*)&unop_list[125], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 80, Nullhv, Nullgv, 67241954, 6849, NULL, NULL }, /* cop_list[50]  */
	{ &op_list[1], (OP*)&unop_list[0], INT2PTR(void*,OP_NEXTSTATE), 0, 193, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 81, Nullhv, Nullgv, 67241954, 6849, NULL, NULL }, /* cop_list[51]  */
};

Static OP op_list[53] = {
	{ (OP*)&cop_list[1], (OP*)&cop_list[1], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x0, 0x0 }, /* op_list[0]  */
	{ (OP*)&svop_list[132], (OP*)&unop_list[129], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[1]  */
	{ (OP*)&svop_list[1], (OP*)&svop_list[1], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[2]  */
	{ (OP*)&cop_list[5], (OP*)&cop_list[5], INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[3]  */
	{ &op_list[5], (OP*)&unop_list[7], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[4]  */
	{ (OP*)&logop_list[0], (OP*)&listop_list[4], INT2PTR(void*,OP_PADSV), 2, 9, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[5]  */
	{ &op_list[5], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[6]  */
	{ (OP*)&svop_list[8], (OP*)&svop_list[8], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[7]  */
	{ (OP*)&svop_list[43], (OP*)&unop_list[48], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[8]  */
	{ (OP*)&cop_list[10], (OP*)&cop_list[10], INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[9]  */
	{ &op_list[13], (OP*)&unop_list[15], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[10]  */
	{ &op_list[12], 0, INT2PTR(void*,OP_UNSTACK), 0, 195, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0 }, /* op_list[11]  */
	{ (OP*)&logop_list[1], (OP*)&listop_list[6], INT2PTR(void*,OP_ITER), 0, 200, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[12]  */
	{ &op_list[14], (OP*)&binop_list[6], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[13]  */
	{ (OP*)&svop_list[12], (OP*)&svop_list[12], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[14]  */
	{ (OP*)&svop_list[13], (OP*)&unop_list[18], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[15]  */
	{ (OP*)&binop_list[7], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[16]  */
	{ (OP*)&svop_list[14], (OP*)&svop_list[14], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[17]  */
	{ (OP*)&binop_list[9], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[18]  */
	{ (OP*)&svop_list[19], (OP*)&svop_list[19], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[19]  */
	{ (OP*)&binop_list[10], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[20]  */
	{ &op_list[22], &op_list[22], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[21]  */
	{ (OP*)&svop_list[23], (OP*)&svop_list[23], INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[22]  */
	{ (OP*)&svop_list[26], (OP*)&svop_list[26], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[23]  */
	{ (OP*)&svop_list[27], (OP*)&unop_list[33], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[24]  */
	{ (OP*)&binop_list[12], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[25]  */
	{ &op_list[27], &op_list[27], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[26]  */
	{ (OP*)&svop_list[28], (OP*)&svop_list[28], INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[27]  */
	{ (OP*)&binop_list[14], 0, INT2PTR(void*,OP_PADSV), 4, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x0 }, /* op_list[28]  */
	{ (OP*)&svop_list[33], (OP*)&unop_list[40], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[29]  */
	{ (OP*)&svop_list[38], (OP*)&unop_list[45], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[30]  */
	{ (OP*)&svop_list[78], (OP*)&unop_list[77], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[31]  */
	{ (OP*)&svop_list[48], (OP*)&binop_list[17], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[32]  */
	{ (OP*)&svop_list[55], (OP*)&unop_list[60], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[33]  */
	{ (OP*)&svop_list[60], (OP*)&binop_list[18], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[34]  */
	{ (OP*)&svop_list[67], (OP*)&unop_list[69], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[35]  */
	{ (OP*)&cop_list[34], (OP*)&cop_list[34], INT2PTR(void*,OP_ENTER), 0, 196, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[36]  */
	{ (OP*)&binop_list[19], 0, INT2PTR(void*,OP_PADSV), 22, 9, 0, 0, 0, 1, 0, 0, 0, 0xb2, 0x80 }, /* op_list[37]  */
	{ &op_list[39], &op_list[39], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[38]  */
	{ (OP*)&svop_list[73], (OP*)&svop_list[73], INT2PTR(void*,OP_PADSV), 22, 9, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0 }, /* op_list[39]  */
	{ (OP*)&svop_list[85], (OP*)&unop_list[81], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[40]  */
	{ (OP*)&svop_list[87], (OP*)&binop_list[21], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[41]  */
	{ (OP*)&svop_list[93], (OP*)&binop_list[22], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[42]  */
	{ (OP*)&svop_list[97], (OP*)&unop_list[93], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[43]  */
	{ (OP*)&svop_list[101], (OP*)&unop_list[96], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[44]  */
	{ (OP*)&svop_list[105], (OP*)&unop_list[102], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[45]  */
	{ (OP*)&svop_list[110], (OP*)&unop_list[106], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[46]  */
	{ (OP*)&svop_list[114], (OP*)&unop_list[111], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[47]  */
	{ (OP*)&svop_list[115], (OP*)&svop_list[115], INT2PTR(void*,OP_UNDEF), 0, 44, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[48]  */
	{ (OP*)&svop_list[117], (OP*)&unop_list[115], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[49]  */
	{ (OP*)&svop_list[120], (OP*)&unop_list[119], INT2PTR(void*,OP_NULL), 3, 0, 0, 0, 0, 1, 0, 0, 0, 0x21, 0x80 }, /* op_list[50]  */
	{ (OP*)&svop_list[122], (OP*)&binop_list[24], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[51]  */
	{ (OP*)&svop_list[128], (OP*)&binop_list[25], INT2PTR(void*,OP_PUSHMARK), 0, 3, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0 }, /* op_list[52]  */
};

Static UNOP unop_list[131] = {
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_ENTERSUB), 48, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[1] }, /* unop_list[0]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[1] }, /* unop_list[1]  */
	{ (OP*)&cop_list[2], (OP*)&cop_list[2], INT2PTR(void*,OP_REQUIRE), 0, 339, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x1, (OP*)&svop_list[0] }, /* unop_list[2]  */
	{ (OP*)&cop_list[3], (OP*)&cop_list[3], INT2PTR(void*,OP_ENTERSUB), 1, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[4] }, /* unop_list[3]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[2] }, /* unop_list[4]  */
	{ (OP*)&unop_list[4], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[3] }, /* unop_list[5]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[5] }, /* unop_list[6]  */
	{ (OP*)&listop_list[3], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[0] }, /* unop_list[7]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[7] }, /* unop_list[8]  */
	{ (OP*)&cop_list[7], (OP*)&cop_list[7], INT2PTR(void*,OP_ENTERSUB), 3, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[10] }, /* unop_list[9]  */
	{ (OP*)&unop_list[9], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[7] }, /* unop_list[10]  */
	{ (OP*)&unop_list[10], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[9] }, /* unop_list[11]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_ENTERSUB), 13, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[13] }, /* unop_list[12]  */
	{ (OP*)&unop_list[12], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[8] }, /* unop_list[13]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&logop_list[1] }, /* unop_list[14]  */
	{ (OP*)&svop_list[10], (OP*)&svop_list[10], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x27, 0x0, &op_list[13] }, /* unop_list[15]  */
	{ &op_list[15], (OP*)&unop_list[17], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[14] }, /* unop_list[16]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[15] }, /* unop_list[17]  */
	{ (OP*)&unop_list[17], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xbe, 0x3, (OP*)&svop_list[13] }, /* unop_list[18]  */
	{ (OP*)&cop_list[12], (OP*)&cop_list[12], INT2PTR(void*,OP_ENTERSUB), 6, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[20] }, /* unop_list[19]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[17] }, /* unop_list[20]  */
	{ (OP*)&unop_list[20], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[15] }, /* unop_list[21]  */
	{ (OP*)&cop_list[14], (OP*)&cop_list[14], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x1, (OP*)&logop_list[2] }, /* unop_list[22]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[17] }, /* unop_list[23]  */
	{ (OP*)&cop_list[15], (OP*)&cop_list[15], INT2PTR(void*,OP_ENTERSUB), 7, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[25] }, /* unop_list[24]  */
	{ (OP*)&unop_list[24], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[19] }, /* unop_list[25]  */
	{ (OP*)&unop_list[25], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[20] }, /* unop_list[26]  */
	{ (OP*)&binop_list[11], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[22] }, /* unop_list[27]  */
	{ (OP*)&cop_list[17], (OP*)&cop_list[17], INT2PTR(void*,OP_ENTERSUB), 8, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[29] }, /* unop_list[28]  */
	{ (OP*)&unop_list[28], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[21] }, /* unop_list[29]  */
	{ (OP*)&unop_list[29], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[25] }, /* unop_list[30]  */
	{ &op_list[24], (OP*)&unop_list[32], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[23] }, /* unop_list[31]  */
	{ (OP*)&binop_list[13], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x7, 0x0, &op_list[24] }, /* unop_list[32]  */
	{ (OP*)&unop_list[32], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xbe, 0x3, (OP*)&svop_list[27] }, /* unop_list[33]  */
	{ (OP*)&cop_list[19], (OP*)&cop_list[19], INT2PTR(void*,OP_ENTERSUB), 10, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[35] }, /* unop_list[34]  */
	{ (OP*)&unop_list[34], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[26] }, /* unop_list[35]  */
	{ (OP*)&unop_list[35], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[30] }, /* unop_list[36]  */
	{ &op_list[28], &op_list[28], INT2PTR(void*,OP_ENTEREVAL), 133090, 342, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[31] }, /* unop_list[37]  */
	{ (OP*)&cop_list[21], (OP*)&cop_list[21], INT2PTR(void*,OP_ENTERSUB), 11, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[39] }, /* unop_list[38]  */
	{ (OP*)&unop_list[38], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[29] }, /* unop_list[39]  */
	{ (OP*)&pmop_list[0], (OP*)&pmop_list[0], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[33] }, /* unop_list[40]  */
	{ (OP*)&unop_list[39], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[35] }, /* unop_list[41]  */
	{ (OP*)&cop_list[22], (OP*)&cop_list[22], INT2PTR(void*,OP_ENTEREVAL), 133090, 342, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x3, (OP*)&svop_list[36] }, /* unop_list[42]  */
	{ (OP*)&cop_list[23], (OP*)&cop_list[23], INT2PTR(void*,OP_ENTERSUB), 12, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[44] }, /* unop_list[43]  */
	{ (OP*)&unop_list[43], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[30] }, /* unop_list[44]  */
	{ (OP*)&pmop_list[1], (OP*)&pmop_list[1], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[38] }, /* unop_list[45]  */
	{ (OP*)&unop_list[44], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[40] }, /* unop_list[46]  */
	{ (OP*)&cop_list[24], (OP*)&cop_list[24], INT2PTR(void*,OP_ENTEREVAL), 133090, 342, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x3, (OP*)&svop_list[41] }, /* unop_list[47]  */
	{ (OP*)&pmop_list[2], (OP*)&pmop_list[2], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[43] }, /* unop_list[48]  */
	{ (OP*)&unop_list[13], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[45] }, /* unop_list[49]  */
	{ (OP*)&binop_list[15], 0, INT2PTR(void*,OP_ENTERSUB), 25, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[51] }, /* unop_list[50]  */
	{ (OP*)&unop_list[50], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[31] }, /* unop_list[51]  */
	{ (OP*)&binop_list[16], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[47] }, /* unop_list[52]  */
	{ (OP*)&cop_list[29], (OP*)&cop_list[28], INT2PTR(void*,OP_ENTERSUB), 15, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[54] }, /* unop_list[53]  */
	{ (OP*)&unop_list[53], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[32] }, /* unop_list[54]  */
	{ (OP*)&svop_list[49], (OP*)&svop_list[49], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[48] }, /* unop_list[55]  */
	{ (OP*)&unop_list[54], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[53] }, /* unop_list[56]  */
	{ (OP*)&cop_list[29], (OP*)&cop_list[29], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[54] }, /* unop_list[57]  */
	{ (OP*)&cop_list[30], (OP*)&cop_list[30], INT2PTR(void*,OP_ENTERSUB), 17, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[59] }, /* unop_list[58]  */
	{ (OP*)&unop_list[58], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[33] }, /* unop_list[59]  */
	{ (OP*)&svop_list[56], (OP*)&svop_list[56], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[55] }, /* unop_list[60]  */
	{ (OP*)&unop_list[59], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[59] }, /* unop_list[61]  */
	{ (OP*)&cop_list[32], (OP*)&cop_list[31], INT2PTR(void*,OP_ENTERSUB), 19, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[63] }, /* unop_list[62]  */
	{ (OP*)&unop_list[62], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[34] }, /* unop_list[63]  */
	{ (OP*)&svop_list[61], (OP*)&svop_list[61], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[60] }, /* unop_list[64]  */
	{ (OP*)&unop_list[63], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[65] }, /* unop_list[65]  */
	{ (OP*)&cop_list[32], (OP*)&cop_list[32], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[66] }, /* unop_list[66]  */
	{ (OP*)&cop_list[33], (OP*)&cop_list[33], INT2PTR(void*,OP_ENTERSUB), 21, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[68] }, /* unop_list[67]  */
	{ (OP*)&unop_list[67], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[35] }, /* unop_list[68]  */
	{ (OP*)&svop_list[68], (OP*)&svop_list[68], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[67] }, /* unop_list[69]  */
	{ (OP*)&unop_list[68], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[71] }, /* unop_list[70]  */
	{ &op_list[37], &op_list[37], INT2PTR(void*,OP_NULL), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0x86, 0x1, (OP*)&listop_list[9] }, /* unop_list[71]  */
	{ (OP*)&listop_list[9], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[72] }, /* unop_list[72]  */
	{ (OP*)&cop_list[37], (OP*)&cop_list[36], INT2PTR(void*,OP_ENTERSUB), 23, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[74] }, /* unop_list[73]  */
	{ (OP*)&unop_list[73], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[38] }, /* unop_list[74]  */
	{ (OP*)&unop_list[74], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[76] }, /* unop_list[75]  */
	{ (OP*)&cop_list[37], (OP*)&cop_list[37], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[77] }, /* unop_list[76]  */
	{ (OP*)&svop_list[79], (OP*)&svop_list[79], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[78] }, /* unop_list[77]  */
	{ (OP*)&unop_list[51], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[82] }, /* unop_list[78]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0xb6, 0x3, (OP*)&svop_list[84] }, /* unop_list[79]  */
	{ (OP*)&cop_list[40], (OP*)&cop_list[40], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[40] }, /* unop_list[80]  */
	{ (OP*)&svop_list[86], (OP*)&unop_list[82], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[85] }, /* unop_list[81]  */
	{ (OP*)&unop_list[80], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[86] }, /* unop_list[82]  */
	{ (OP*)&cop_list[41], (OP*)&cop_list[41], INT2PTR(void*,OP_ENTERSUB), 29, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[84] }, /* unop_list[83]  */
	{ (OP*)&unop_list[83], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[41] }, /* unop_list[84]  */
	{ (OP*)&svop_list[88], (OP*)&svop_list[88], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[87] }, /* unop_list[85]  */
	{ (OP*)&unop_list[84], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[92] }, /* unop_list[86]  */
	{ (OP*)&cop_list[42], (OP*)&cop_list[42], INT2PTR(void*,OP_ENTERSUB), 31, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[88] }, /* unop_list[87]  */
	{ (OP*)&unop_list[87], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[42] }, /* unop_list[88]  */
	{ (OP*)&svop_list[94], (OP*)&svop_list[94], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[93] }, /* unop_list[89]  */
	{ (OP*)&unop_list[88], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[96] }, /* unop_list[90]  */
	{ (OP*)&cop_list[44], (OP*)&cop_list[43], INT2PTR(void*,OP_ENTERSUB), 32, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[92] }, /* unop_list[91]  */
	{ (OP*)&unop_list[91], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[43] }, /* unop_list[92]  */
	{ (OP*)&svop_list[98], (OP*)&svop_list[98], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[97] }, /* unop_list[93]  */
	{ (OP*)&unop_list[92], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[100] }, /* unop_list[94]  */
	{ (OP*)&cop_list[44], (OP*)&cop_list[44], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[44] }, /* unop_list[95]  */
	{ (OP*)&svop_list[102], (OP*)&unop_list[97], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[101] }, /* unop_list[96]  */
	{ (OP*)&svop_list[103], (OP*)&unop_list[98], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[102] }, /* unop_list[97]  */
	{ (OP*)&svop_list[104], (OP*)&unop_list[99], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[103] }, /* unop_list[98]  */
	{ (OP*)&unop_list[95], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[104] }, /* unop_list[99]  */
	{ (OP*)&cop_list[45], (OP*)&cop_list[45], INT2PTR(void*,OP_ENTERSUB), 37, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[101] }, /* unop_list[100]  */
	{ (OP*)&unop_list[100], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[45] }, /* unop_list[101]  */
	{ (OP*)&svop_list[106], (OP*)&svop_list[106], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[105] }, /* unop_list[102]  */
	{ (OP*)&unop_list[101], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[109] }, /* unop_list[103]  */
	{ (OP*)&cop_list[46], (OP*)&cop_list[46], INT2PTR(void*,OP_ENTERSUB), 39, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[105] }, /* unop_list[104]  */
	{ (OP*)&unop_list[104], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[46] }, /* unop_list[105]  */
	{ (OP*)&svop_list[112], (OP*)&svop_list[112], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&binop_list[23] }, /* unop_list[106]  */
	{ (OP*)&svop_list[111], (OP*)&svop_list[111], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[110] }, /* unop_list[107]  */
	{ (OP*)&unop_list[105], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[113] }, /* unop_list[108]  */
	{ (OP*)&cop_list[47], (OP*)&cop_list[47], INT2PTR(void*,OP_ENTERSUB), 40, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[110] }, /* unop_list[109]  */
	{ (OP*)&unop_list[109], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[47] }, /* unop_list[110]  */
	{ &op_list[48], &op_list[48], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[114] }, /* unop_list[111]  */
	{ (OP*)&unop_list[110], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[116] }, /* unop_list[112]  */
	{ (OP*)&cop_list[49], (OP*)&cop_list[48], INT2PTR(void*,OP_ENTERSUB), 41, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[114] }, /* unop_list[113]  */
	{ (OP*)&unop_list[113], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[49] }, /* unop_list[114]  */
	{ (OP*)&svop_list[118], (OP*)&svop_list[118], INT2PTR(void*,OP_NOT), 0, 103, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x1, (OP*)&unop_list[116] }, /* unop_list[115]  */
	{ (OP*)&unop_list[115], 0, INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[117] }, /* unop_list[116]  */
	{ (OP*)&unop_list[114], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[119] }, /* unop_list[117]  */
	{ (OP*)&cop_list[49], (OP*)&cop_list[49], INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, &op_list[50] }, /* unop_list[118]  */
	{ (OP*)&svop_list[121], (OP*)&unop_list[120], INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[120] }, /* unop_list[119]  */
	{ (OP*)&unop_list[118], 0, INT2PTR(void*,OP_RV2SV), 0, 15, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x43, (OP*)&svop_list[121] }, /* unop_list[120]  */
	{ (OP*)&cop_list[50], (OP*)&cop_list[50], INT2PTR(void*,OP_ENTERSUB), 45, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[122] }, /* unop_list[121]  */
	{ (OP*)&unop_list[121], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[51] }, /* unop_list[122]  */
	{ (OP*)&svop_list[123], (OP*)&svop_list[123], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[122] }, /* unop_list[123]  */
	{ (OP*)&unop_list[122], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[127] }, /* unop_list[124]  */
	{ (OP*)&cop_list[51], (OP*)&cop_list[51], INT2PTR(void*,OP_ENTERSUB), 47, 185, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x6, (OP*)&unop_list[126] }, /* unop_list[125]  */
	{ (OP*)&unop_list[125], 0, INT2PTR(void*,OP_NULL), 158, 0, 0, 0, 0, 1, 0, 0, 0, 0x4, 0x0, &op_list[52] }, /* unop_list[126]  */
	{ (OP*)&svop_list[129], (OP*)&svop_list[129], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[128] }, /* unop_list[127]  */
	{ (OP*)&unop_list[126], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[131] }, /* unop_list[128]  */
	{ (OP*)&svop_list[133], (OP*)&svop_list[133], INT2PTR(void*,OP_NULL), 15, 0, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x3, (OP*)&svop_list[132] }, /* unop_list[129]  */
	{ (OP*)&unop_list[1], 0, INT2PTR(void*,OP_NULL), 17, 0, 0, 0, 0, 1, 0, 0, 0, 0x6, 0x3, (OP*)&svop_list[135] }, /* unop_list[130]  */
};

Static BINOP binop_list[26] = {
	{ (OP*)&listop_list[0], 0, INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[0], (OP*)&listop_list[1] }, /* binop_list[0]  */
	{ (OP*)&cop_list[8], (OP*)&cop_list[8], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[1], (OP*)&listop_list[2] }, /* binop_list[1]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[4], (OP*)&unop_list[6] }, /* binop_list[2]  */
	{ &op_list[6], &op_list[6], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[6], (OP*)&unop_list[8] }, /* binop_list[3]  */
	{ (OP*)&cop_list[25], (OP*)&cop_list[25], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[2], (OP*)&listop_list[5] }, /* binop_list[4]  */
	{ (OP*)&cop_list[11], (OP*)&cop_list[11], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[3], (OP*)&unop_list[14] }, /* binop_list[5]  */
	{ (OP*)&svop_list[10], 0, INT2PTR(void*,OP_AASSIGN), 5, 38, 0, 0, 0, 1, 0, 0, 0, 0x67, 0x0, (OP*)&unop_list[16], (OP*)&unop_list[17] }, /* binop_list[6]  */
	{ &op_list[11], &op_list[11], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[11], &op_list[16] }, /* binop_list[7]  */
	{ (OP*)&logop_list[2], (OP*)&listop_list[7], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x46, 0x2, (OP*)&svop_list[16], (OP*)&unop_list[23] }, /* binop_list[8]  */
	{ (OP*)&cop_list[14], 0, INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[18], &op_list[18] }, /* binop_list[9]  */
	{ (OP*)&cop_list[16], (OP*)&cop_list[16], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&binop_list[11], &op_list[20] }, /* binop_list[10]  */
	{ &op_list[20], &op_list[20], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x4e, 0x2, (OP*)&svop_list[21], (OP*)&unop_list[27] }, /* binop_list[11]  */
	{ (OP*)&cop_list[18], (OP*)&cop_list[18], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&binop_list[13], &op_list[25] }, /* binop_list[12]  */
	{ &op_list[25], &op_list[25], INT2PTR(void*,OP_AASSIGN), 9, 38, 0, 0, 0, 1, 0, 0, 0, 0x4e, 0x0, (OP*)&unop_list[31], (OP*)&unop_list[32] }, /* binop_list[13]  */
	{ (OP*)&cop_list[20], (OP*)&cop_list[20], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[37], &op_list[28] }, /* binop_list[14]  */
	{ (OP*)&cop_list[38], (OP*)&cop_list[38], INT2PTR(void*,OP_LEAVELOOP), 0, 202, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x2, (OP*)&loop_list[4], (OP*)&listop_list[8] }, /* binop_list[15]  */
	{ (OP*)&cop_list[27], (OP*)&cop_list[27], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[46], (OP*)&unop_list[52] }, /* binop_list[16]  */
	{ (OP*)&svop_list[50], (OP*)&svop_list[50], INT2PTR(void*,OP_ADD), 14, 63, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[55], (OP*)&svop_list[49] }, /* binop_list[17]  */
	{ (OP*)&svop_list[62], (OP*)&svop_list[62], INT2PTR(void*,OP_ADD), 18, 63, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[64], (OP*)&svop_list[61] }, /* binop_list[18]  */
	{ (OP*)&cop_list[35], (OP*)&cop_list[35], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&unop_list[71], &op_list[37] }, /* binop_list[19]  */
	{ (OP*)&cop_list[40], (OP*)&cop_list[39], INT2PTR(void*,OP_SASSIGN), 0, 37, 0, 0, 0, 1, 0, 0, 0, 0x45, 0x2, (OP*)&svop_list[83], (OP*)&unop_list[79] }, /* binop_list[20]  */
	{ (OP*)&svop_list[89], (OP*)&svop_list[89], INT2PTR(void*,OP_ADD), 28, 63, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[85], (OP*)&svop_list[88] }, /* binop_list[21]  */
	{ (OP*)&svop_list[95], (OP*)&svop_list[95], INT2PTR(void*,OP_BIT_AND), 30, 92, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&unop_list[89], (OP*)&svop_list[94] }, /* binop_list[22]  */
	{ (OP*)&unop_list[106], 0, INT2PTR(void*,OP_BIT_AND), 38, 92, 0, 0, 0, 1, 0, 0, 0, 0xe, 0x0, (OP*)&unop_list[107], (OP*)&svop_list[111] }, /* binop_list[23]  */
	{ (OP*)&svop_list[124], (OP*)&svop_list[124], INT2PTR(void*,OP_ADD), 44, 63, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x2, (OP*)&unop_list[123], (OP*)&svop_list[123] }, /* binop_list[24]  */
	{ (OP*)&svop_list[130], (OP*)&svop_list[130], INT2PTR(void*,OP_BIT_AND), 46, 92, 0, 0, 0, 1, 0, 0, 0, 0x26, 0x0, (OP*)&unop_list[127], (OP*)&svop_list[129] }, /* binop_list[25]  */
};

Static LOGOP logop_list[3] = {
	{ (OP*)&listop_list[3], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[5], (OP*)&svop_list[6] }, /* logop_list[0]  */
	{ (OP*)&binop_list[5], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, &op_list[12], (OP*)&svop_list[11] }, /* logop_list[1]  */
	{ (OP*)&cop_list[14], 0, INT2PTR(void*,OP_AND), 0, 176, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x1, (OP*)&binop_list[8], (OP*)&svop_list[18] }, /* logop_list[2]  */
};

Static LISTOP listop_list[10] = {
	{ 0, 0, INT2PTR(void*,OP_LEAVE), 1, 197, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x40, &op_list[0], (OP*)&binop_list[0] }, /* listop_list[0]  */
	{ (OP*)&binop_list[0], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[0], (OP*)&unop_list[0] }, /* listop_list[1]  */
	{ (OP*)&binop_list[1], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[4], (OP*)&binop_list[2] }, /* listop_list[2]  */
	{ (OP*)&cop_list[6], (OP*)&cop_list[6], INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0x85, 0x0, &op_list[4], (OP*)&unop_list[7] }, /* listop_list[3]  */
	{ (OP*)&unop_list[7], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&binop_list[3], &op_list[6] }, /* listop_list[4]  */
	{ (OP*)&binop_list[4], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[9], (OP*)&unop_list[12] }, /* listop_list[5]  */
	{ (OP*)&unop_list[14], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&binop_list[7], &op_list[11] }, /* listop_list[6]  */
	{ (OP*)&unop_list[22], 0, INT2PTR(void*,OP_SCOPE), 0, 198, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x0, (OP*)&cop_list[13], (OP*)&binop_list[9] }, /* listop_list[7]  */
	{ (OP*)&binop_list[15], 0, INT2PTR(void*,OP_LINESEQ), 0, 192, 0, 0, 0, 1, 0, 0, 0, 0xd, 0x0, (OP*)&cop_list[26], (OP*)&unop_list[50] }, /* listop_list[8]  */
	{ &op_list[37], 0, INT2PTR(void*,OP_LEAVE), 0, 197, 0, 0, 0, 1, 0, 0, 0, 0xe, 0x0, &op_list[36], (OP*)&unop_list[72] }, /* listop_list[9]  */
};

Static PMOP pmop_list[3] = {
	{ (OP*)&svop_list[34], (OP*)&svop_list[34], INT2PTR(void*,OP_QR), 0, 32, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, 0, 0, 0, 0x40000000, {0}, {NULL} }, /* pmop_list[0]  */
	{ (OP*)&svop_list[39], (OP*)&svop_list[39], INT2PTR(void*,OP_QR), 0, 32, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, 0, 0, 0, 0x40000000, {0}, {NULL} }, /* pmop_list[1]  */
	{ (OP*)&svop_list[44], (OP*)&svop_list[44], INT2PTR(void*,OP_QR), 0, 32, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, 0, 0, 0, 0x40000000, {0}, {NULL} }, /* pmop_list[2]  */
};

Static SVOP svop_list[136] = {
	{ (OP*)&unop_list[2], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[1] }, /* svop_list[0]  */
	{ (OP*)&svop_list[2], (OP*)&svop_list[2], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x40, &sv_list[2] }, /* svop_list[1]  */
	{ (OP*)&svop_list[3], (OP*)&unop_list[5], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[3] }, /* svop_list[2]  */
	{ (OP*)&unop_list[3], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[0] */ }, /* svop_list[3]  */
	{ (OP*)&svop_list[5], (OP*)&unop_list[6], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[4] }, /* svop_list[4]  */
	{ (OP*)&binop_list[2], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[5]  */
	{ (OP*)&svop_list[7], (OP*)&unop_list[8], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[5] }, /* svop_list[6]  */
	{ (OP*)&binop_list[3], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[7]  */
	{ (OP*)&svop_list[9], (OP*)&unop_list[11], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[6] }, /* svop_list[8]  */
	{ (OP*)&unop_list[9], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[9]  */
	{ (OP*)&loop_list[3], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_defgv */ }, /* svop_list[10]  */
	{ &op_list[16], &op_list[16], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[7] }, /* svop_list[11]  */
	{ &op_list[15], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[8] }, /* svop_list[12]  */
	{ (OP*)&binop_list[6], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[13]  */
	{ (OP*)&svop_list[15], (OP*)&unop_list[21], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[9] }, /* svop_list[14]  */
	{ (OP*)&unop_list[19], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[15]  */
	{ (OP*)&svop_list[17], (OP*)&unop_list[23], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[10] }, /* svop_list[16]  */
	{ (OP*)&binop_list[8], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[17]  */
	{ &op_list[18], &op_list[18], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[11] }, /* svop_list[18]  */
	{ (OP*)&svop_list[20], (OP*)&unop_list[26], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[12] }, /* svop_list[19]  */
	{ (OP*)&unop_list[24], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[2] */ }, /* svop_list[20]  */
	{ (OP*)&svop_list[22], (OP*)&unop_list[27], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[13] }, /* svop_list[21]  */
	{ (OP*)&binop_list[11], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[22]  */
	{ (OP*)&svop_list[24], (OP*)&svop_list[24], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[14] }, /* svop_list[23]  */
	{ (OP*)&svop_list[25], (OP*)&unop_list[30], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[15] }, /* svop_list[24]  */
	{ (OP*)&unop_list[28], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[25]  */
	{ &op_list[24], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[16] }, /* svop_list[26]  */
	{ (OP*)&binop_list[13], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[27]  */
	{ (OP*)&svop_list[29], (OP*)&svop_list[29], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[17] }, /* svop_list[28]  */
	{ (OP*)&svop_list[30], (OP*)&unop_list[36], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[18] }, /* svop_list[29]  */
	{ (OP*)&unop_list[34], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[30]  */
	{ (OP*)&svop_list[32], (OP*)&svop_list[32], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[19] }, /* svop_list[31]  */
	{ (OP*)&unop_list[37], 0, INT2PTR(void*,OP_HINTSEVAL), 0, 341, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[20] }, /* svop_list[32]  */
	{ (OP*)&pmop_list[0], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_errgv */ }, /* svop_list[33]  */
	{ (OP*)&svop_list[35], (OP*)&unop_list[41], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[23] }, /* svop_list[34]  */
	{ (OP*)&unop_list[38], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[35]  */
	{ (OP*)&svop_list[37], (OP*)&svop_list[37], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[24] }, /* svop_list[36]  */
	{ (OP*)&unop_list[42], 0, INT2PTR(void*,OP_HINTSEVAL), 0, 341, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[25] }, /* svop_list[37]  */
	{ (OP*)&pmop_list[1], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_errgv */ }, /* svop_list[38]  */
	{ (OP*)&svop_list[40], (OP*)&unop_list[46], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[28] }, /* svop_list[39]  */
	{ (OP*)&unop_list[43], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[40]  */
	{ (OP*)&svop_list[42], (OP*)&svop_list[42], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[29] }, /* svop_list[41]  */
	{ (OP*)&unop_list[47], 0, INT2PTR(void*,OP_HINTSEVAL), 0, 341, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[30] }, /* svop_list[42]  */
	{ (OP*)&pmop_list[2], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)PL_errgv */ }, /* svop_list[43]  */
	{ (OP*)&svop_list[45], (OP*)&unop_list[49], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[33] }, /* svop_list[44]  */
	{ (OP*)&unop_list[12], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[6] */ }, /* svop_list[45]  */
	{ (OP*)&svop_list[47], (OP*)&unop_list[52], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[34] }, /* svop_list[46]  */
	{ (OP*)&binop_list[16], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[47]  */
	{ (OP*)&svop_list[49], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[48]  */
	{ (OP*)&binop_list[17], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[38] }, /* svop_list[49]  */
	{ (OP*)&svop_list[51], (OP*)&svop_list[51], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[39] }, /* svop_list[50]  */
	{ (OP*)&svop_list[52], (OP*)&svop_list[52], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[40] }, /* svop_list[51]  */
	{ (OP*)&svop_list[53], (OP*)&unop_list[56], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[41] }, /* svop_list[52]  */
	{ (OP*)&unop_list[53], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[53]  */
	{ (OP*)&unop_list[57], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[54]  */
	{ (OP*)&svop_list[56], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[9] */ }, /* svop_list[55]  */
	{ (OP*)&svop_list[57], (OP*)&svop_list[57], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[43] }, /* svop_list[56]  */
	{ (OP*)&svop_list[58], (OP*)&svop_list[58], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[44] }, /* svop_list[57]  */
	{ (OP*)&svop_list[59], (OP*)&unop_list[61], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[45] }, /* svop_list[58]  */
	{ (OP*)&unop_list[58], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[59]  */
	{ (OP*)&svop_list[61], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[60]  */
	{ (OP*)&binop_list[18], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[46] }, /* svop_list[61]  */
	{ (OP*)&svop_list[63], (OP*)&svop_list[63], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[47] }, /* svop_list[62]  */
	{ (OP*)&svop_list[64], (OP*)&svop_list[64], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[48] }, /* svop_list[63]  */
	{ (OP*)&svop_list[65], (OP*)&unop_list[65], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[49] }, /* svop_list[64]  */
	{ (OP*)&unop_list[62], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[65]  */
	{ (OP*)&unop_list[66], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[66]  */
	{ (OP*)&svop_list[68], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[10] */ }, /* svop_list[67]  */
	{ (OP*)&svop_list[69], (OP*)&svop_list[69], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[51] }, /* svop_list[68]  */
	{ (OP*)&svop_list[70], (OP*)&svop_list[70], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[52] }, /* svop_list[69]  */
	{ (OP*)&svop_list[71], (OP*)&unop_list[70], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[53] }, /* svop_list[70]  */
	{ (OP*)&unop_list[67], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[71]  */
	{ (OP*)&listop_list[9], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[72]  */
	{ (OP*)&svop_list[74], (OP*)&svop_list[74], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[54] }, /* svop_list[73]  */
	{ (OP*)&svop_list[75], (OP*)&svop_list[75], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[55] }, /* svop_list[74]  */
	{ (OP*)&svop_list[76], (OP*)&unop_list[75], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[56] }, /* svop_list[75]  */
	{ (OP*)&unop_list[73], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[76]  */
	{ (OP*)&unop_list[76], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[77]  */
	{ (OP*)&svop_list[79], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[11] */ }, /* svop_list[78]  */
	{ (OP*)&svop_list[80], (OP*)&svop_list[80], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[58] }, /* svop_list[79]  */
	{ (OP*)&svop_list[81], (OP*)&svop_list[81], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[59] }, /* svop_list[80]  */
	{ (OP*)&svop_list[82], (OP*)&unop_list[78], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[60] }, /* svop_list[81]  */
	{ (OP*)&unop_list[50], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[82]  */
	{ (OP*)&svop_list[84], (OP*)&unop_list[79], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[61] }, /* svop_list[83]  */
	{ (OP*)&binop_list[20], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[1] */ }, /* svop_list[84]  */
	{ (OP*)&unop_list[81], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[12] */ }, /* svop_list[85]  */
	{ (OP*)&unop_list[82], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[13] */ }, /* svop_list[86]  */
	{ (OP*)&svop_list[88], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[87]  */
	{ (OP*)&binop_list[21], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[64] }, /* svop_list[88]  */
	{ (OP*)&svop_list[90], (OP*)&svop_list[90], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[65] }, /* svop_list[89]  */
	{ (OP*)&svop_list[91], (OP*)&svop_list[91], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[66] }, /* svop_list[90]  */
	{ (OP*)&svop_list[92], (OP*)&unop_list[86], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[67] }, /* svop_list[91]  */
	{ (OP*)&unop_list[83], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[92]  */
	{ (OP*)&svop_list[94], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[12] */ }, /* svop_list[93]  */
	{ (OP*)&binop_list[22], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[68] }, /* svop_list[94]  */
	{ (OP*)&svop_list[96], (OP*)&unop_list[90], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[69] }, /* svop_list[95]  */
	{ (OP*)&unop_list[87], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[14] */ }, /* svop_list[96]  */
	{ (OP*)&svop_list[98], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[13] */ }, /* svop_list[97]  */
	{ (OP*)&svop_list[99], (OP*)&svop_list[99], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[70] }, /* svop_list[98]  */
	{ (OP*)&svop_list[100], (OP*)&unop_list[94], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[71] }, /* svop_list[99]  */
	{ (OP*)&unop_list[91], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[100]  */
	{ (OP*)&unop_list[96], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[15] */ }, /* svop_list[101]  */
	{ (OP*)&unop_list[97], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[16] */ }, /* svop_list[102]  */
	{ (OP*)&unop_list[98], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[17] */ }, /* svop_list[103]  */
	{ (OP*)&unop_list[99], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[18] */ }, /* svop_list[104]  */
	{ (OP*)&svop_list[106], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[15] */ }, /* svop_list[105]  */
	{ (OP*)&svop_list[107], (OP*)&svop_list[107], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[76] }, /* svop_list[106]  */
	{ (OP*)&svop_list[108], (OP*)&svop_list[108], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[77] }, /* svop_list[107]  */
	{ (OP*)&svop_list[109], (OP*)&unop_list[103], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[78] }, /* svop_list[108]  */
	{ (OP*)&unop_list[100], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[109]  */
	{ (OP*)&svop_list[111], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[16] */ }, /* svop_list[110]  */
	{ (OP*)&binop_list[23], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[79] }, /* svop_list[111]  */
	{ (OP*)&svop_list[113], (OP*)&unop_list[108], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[80] }, /* svop_list[112]  */
	{ (OP*)&unop_list[104], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[14] */ }, /* svop_list[113]  */
	{ &op_list[48], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[17] */ }, /* svop_list[114]  */
	{ (OP*)&svop_list[116], (OP*)&unop_list[112], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[81] }, /* svop_list[115]  */
	{ (OP*)&unop_list[109], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[116]  */
	{ (OP*)&unop_list[115], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[18] */ }, /* svop_list[117]  */
	{ (OP*)&svop_list[119], (OP*)&unop_list[117], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[82] }, /* svop_list[118]  */
	{ (OP*)&unop_list[113], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[14] */ }, /* svop_list[119]  */
	{ (OP*)&unop_list[119], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[19] */ }, /* svop_list[120]  */
	{ (OP*)&unop_list[120], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[20] */ }, /* svop_list[121]  */
	{ (OP*)&svop_list[123], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[7] */ }, /* svop_list[122]  */
	{ (OP*)&binop_list[24], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[85] }, /* svop_list[123]  */
	{ (OP*)&svop_list[125], (OP*)&svop_list[125], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[86] }, /* svop_list[124]  */
	{ (OP*)&svop_list[126], (OP*)&svop_list[126], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[87] }, /* svop_list[125]  */
	{ (OP*)&svop_list[127], (OP*)&unop_list[124], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[88] }, /* svop_list[126]  */
	{ (OP*)&unop_list[121], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[8] */ }, /* svop_list[127]  */
	{ (OP*)&svop_list[129], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[19] */ }, /* svop_list[128]  */
	{ (OP*)&binop_list[25], 0, INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, &sv_list[89] }, /* svop_list[129]  */
	{ (OP*)&svop_list[131], (OP*)&unop_list[128], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[90] }, /* svop_list[130]  */
	{ (OP*)&unop_list[125], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[14] */ }, /* svop_list[131]  */
	{ (OP*)&svop_list[133], 0, INT2PTR(void*,OP_GVSV), 0, 6, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x0, Nullsv /* (SV*)gv_list[20] */ }, /* svop_list[132]  */
	{ (OP*)&svop_list[134], (OP*)&svop_list[134], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[91] }, /* svop_list[133]  */
	{ (OP*)&svop_list[135], (OP*)&unop_list[130], INT2PTR(void*,OP_CONST), 0, 5, 0, 0, 0, 1, 0, 0, 0, 0x22, 0x0, &sv_list[92] }, /* svop_list[134]  */
	{ (OP*)&unop_list[0], 0, INT2PTR(void*,OP_GV), 0, 7, 0, 0, 0, 1, 0, 0, 0, 0x2, 0x20, Nullsv /* (SV*)gv_list[4] */ }, /* svop_list[135]  */
};

Static LOOP loop_list[5] = {
	{ (OP*)&cop_list[0], (OP*)&listop_list[1], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[0], (OP*)&binop_list[0], (OP*)&binop_list[0] }, /* loop_list[0]  */
	{ (OP*)&cop_list[4], (OP*)&listop_list[2], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[4], (OP*)&binop_list[1], (OP*)&binop_list[1] }, /* loop_list[1]  */
	{ (OP*)&cop_list[9], (OP*)&listop_list[5], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[9], (OP*)&binop_list[4], (OP*)&binop_list[4] }, /* loop_list[2]  */
	{ &op_list[12], (OP*)&unop_list[14], INT2PTR(void*,OP_ENTERITER), 0, 199, 0, 0, 0, 1, 0, 0, 0, 0x5, 0x8, &op_list[10], (OP*)&svop_list[10], (OP*)&svop_list[11], &op_list[11], (OP*)&binop_list[5] }, /* loop_list[3]  */
	{ (OP*)&cop_list[26], (OP*)&listop_list[8], INT2PTR(void*,OP_ENTERLOOP), 0, 201, 0, 0, 0, 1, 0, 0, 0, 0x1, 0x0, 0, 0, (OP*)&cop_list[26], (OP*)&binop_list[15], (OP*)&binop_list[15] }, /* loop_list[4]  */
};

Static XPV xpv_list[103] = {
	{ Nullhv, {0}, 14, 0 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 5, 8 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 6, 8 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 59, 64 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 61, 64 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 52, 56 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 50, 56 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 16, 24 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 2, 0 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 29, 32 }, /* xpv_list[9]  */
	{ Nullhv, {0}, 15, 24 }, /* xpv_list[10]  */
	{ Nullhv, {0}, 2, 0 }, /* xpv_list[11]  */
	{ Nullhv, {0}, 39, 48 }, /* xpv_list[12]  */
	{ Nullhv, {0}, 11, 16 }, /* xpv_list[13]  */
	{ Nullhv, {0}, 2, 0 }, /* xpv_list[14]  */
	{ Nullhv, {0}, 39, 48 }, /* xpv_list[15]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[16]  */
	{ Nullhv, {0}, 21, 24 }, /* xpv_list[17]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[18]  */
	{ Nullhv, {0}, 28, 32 }, /* xpv_list[19]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[20]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[21]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[22]  */
	{ Nullhv, {0}, 35, 40 }, /* xpv_list[23]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[24]  */
	{ Nullhv, {0}, 23, 32 }, /* xpv_list[25]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[26]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[27]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[28]  */
	{ Nullhv, {0}, 25, 32 }, /* xpv_list[29]  */
	{ Nullhv, {0}, 26, 32 }, /* xpv_list[30]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[31]  */
	{ Nullhv, {0}, 31, 40 }, /* xpv_list[32]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[33]  */
	{ Nullhv, {0}, 22, 24 }, /* xpv_list[34]  */
	{ Nullhv, {0}, 23, 32 }, /* xpv_list[35]  */
	{ Nullhv, {0}, 28, 32 }, /* xpv_list[36]  */
	{ Nullhv, {0}, 28, 32 }, /* xpv_list[37]  */
	{ Nullhv, {0}, 2, 8 }, /* xpv_list[38]  */
	{ Nullhv, {0}, 24, 32 }, /* xpv_list[39]  */
	{ Nullhv, {0}, 25, 32 }, /* xpv_list[40]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[41]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[42]  */
	{ Nullhv, {0}, 24, 32 }, /* xpv_list[43]  */
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[44]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[45]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[46]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[47]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[48]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[49]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[50]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[51]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[52]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[53]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[54]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[55]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[56]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[57]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[58]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[59]  */
	{ Nullhv, {0}, 44, 48 }, /* xpv_list[60]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[61]  */
	{ Nullhv, {0}, 34, 40 }, /* xpv_list[62]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[63]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[64]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[65]  */
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
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[77]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[78]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[79]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[80]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[81]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[82]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[83]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[84]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[85]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[86]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[87]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[88]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[89]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[90]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[91]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[92]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[93]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[94]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[95]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[96]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[97]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[98]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[99]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[100]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[101]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[102]  */
};

Static XPVAV xpvav_list[2] = {
	{ Nullhv, {0}, 48, 48, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, 58, 58, 0 }, /* xpvav_list[1]  */
};

Static XPVHV xpvhv_list[4] = {
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[0]  */
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[1]  */
	{ Nullhv, {0}, 7, 0 }, /* xpvhv_list[2]  */
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[3]  */
};

Static MyPADNAME padname_list[15] = {
	{ NULL, (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 0xffffff44, 0, 0, 0x0, 0 }, /* padname_list[0]  */
	{ ((char*)&padname_list[1])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6804, 6805, 2 /* +1 */, 0, 2, 0x0, "$x" }, /* padname_list[1]  */
	{ ((char*)&padname_list[2])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6807, 6812, 2 /* +1 */, 0, 2, 0x4, "$x" }, /* padname_list[2]  */
	{ ((char*)&padname_list[3])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6814, 6831, 3 /* +1 */, 0, 4, 0x10, "$t11" }, /* padname_list[3]  */
	{ ((char*)&padname_list[4])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6819, 6831, 3 /* +1 */, 0, 4, 0x10, "$t22" }, /* padname_list[4]  */
	{ ((char*)&padname_list[5])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), (HV*)Nullsv, {(HV*)Nullsv}, 6827, 6831, 2 /* +1 */, 0, 4, 0x4, "$val" }, /* padname_list[5]  */
	{ ((char*)&padname_list[6])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6828, 6831, 3 /* +1 */, 0, 3, 0x10, "$t0" }, /* padname_list[6]  */
	{ ((char*)&padname_list[7])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6835, 6849, 3 /* +1 */, 0, 4, 0x10, "$ri0" }, /* padname_list[7]  */
	{ ((char*)&padname_list[8])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6835, 6849, 3 /* +1 */, 0, 4, 0x10, "$rf0" }, /* padname_list[8]  */
	{ ((char*)&padname_list[9])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6838, 6849, 2 /* +1 */, 0, 4, 0x10, "$ra1" }, /* padname_list[9]  */
	{ ((char*)&padname_list[10])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6838, 6849, 2 /* +1 */, 0, 4, 0x10, "$ri1" }, /* padname_list[10]  */
	{ ((char*)&padname_list[11])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6838, 6849, 2 /* +1 */, 0, 4, 0x10, "$rf1" }, /* padname_list[11]  */
	{ ((char*)&padname_list[12])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6838, 6849, 2 /* +1 */, 0, 5, 0x10, "$rfe1" }, /* padname_list[12]  */
	{ ((char*)&padname_list[13])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6846, 6849, 3 /* +1 */, 0, 4, 0x10, "$ri2" }, /* padname_list[13]  */
	{ ((char*)&padname_list[14])+STRUCT_OFFSET(struct padname_with_str, xpadn_str[0]), Nullhv, {(HV*)Nullsv}, 6846, 6849, 3 /* +1 */, 0, 4, 0x10, "$rf2" }, /* padname_list[14]  */
};

Static PADNAMELIST padnamelist_list[1] = {
	{ 43, NULL, 43, 43, 2 /* +1 */ }, /* padnamelist_list[0]  */
};

Static XPVIV xpviv_list[28] = {
	{ Nullhv, {0}, 0, 0, {24} }, /* xpviv_list[0]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[1]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[2]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[3]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[4]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[5]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[6]  */
	{ Nullhv, {0}, 0, 0, {2} }, /* xpviv_list[7]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[8]  */
	{ Nullhv, {0}, 0, 0, {1} }, /* xpviv_list[9]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[10]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[11]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[12]  */
	{ Nullhv, {0}, 0, 0, {11} }, /* xpviv_list[13]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[14]  */
	{ Nullhv, {0}, 0, 0, {22} }, /* xpviv_list[15]  */
	{ Nullhv, {0}, 0, 0, {22} }, /* xpviv_list[16]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[17]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[18]  */
	{ Nullhv, {0}, 0, 0, {13} }, /* xpviv_list[19]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[20]  */
	{ Nullhv, {0}, 0, 0, {13} }, /* xpviv_list[21]  */
	{ Nullhv, {0}, 0, 0, {67108864} }, /* xpviv_list[22]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[23]  */
	{ Nullhv, {0}, 0, 0, {67108864} }, /* xpviv_list[24]  */
	{ Nullhv, {0}, 0, 0, {0} }, /* xpviv_list[25]  */
	{ Nullhv, {0}, 0, 0, {13} }, /* xpviv_list[26]  */
	{ Nullhv, {0}, 0, 0, {67108864} }, /* xpviv_list[27]  */
};

Static XPVNV xpvnv_list[2] = {
	{ Nullhv, {0}, 0, 0, {2}, {2.4} }, /* xpvnv_list[0]  */
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvnv_list[1]  */
};

Static XPVMG xpvmg_list[15] = {
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvmg_list[1]  */
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvmg_list[2]  */
	{ Nullhv, {0}, 0, 1, {0}, {0.00} }, /* xpvmg_list[3]  */
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvmg_list[4]  */
	{ Nullhv, {0}, 0, 0, {11}, {0.00} }, /* xpvmg_list[5]  */
	{ Nullhv, {0}, 0, 0, {22}, {0.00} }, /* xpvmg_list[6]  */
	{ Nullhv, {0}, 0, 0, {67241954}, {0.00} }, /* xpvmg_list[7]  */
	{ Nullhv, {0}, 1, 8, {0}, {0.00} }, /* xpvmg_list[8]  */
	{ Nullhv, {0}, 0, 0, {0}, {0.00} }, /* xpvmg_list[9]  */
	{ Nullhv, {0}, 0, 0, {256}, {0.00} }, /* xpvmg_list[10]  */
	{ Nullhv, {0}, 0, 0, {67241954}, {0.00} }, /* xpvmg_list[11]  */
	{ Nullhv, {0}, 1, 8, {0}, {0.00} }, /* xpvmg_list[12]  */
	{ Nullhv, {0}, 22, 24, {0}, {0.00} }, /* xpvmg_list[13]  */
	{ Nullhv, {0}, 7, 8, {0}, {0.00} }, /* xpvmg_list[14]  */
};

Static XPVIO xpvio_list[1] = {
	{ Nullhv,{0},0,0,{0},0,{0},0,60,60,NULL,Nullgv,NULL,Nullgv,NULL,Nullgv,'>',0x0 }, /* xpvio_list[0]  */
};

Static SV sv_list[207] = {
	{ 0, 207, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */
	{ &xpv_list[0], 2147483647, 0x18014403, {0} }, /* sv_list[1]  */
	{ &xpv_list[1], 2147483647, 0x18014403, {0} }, /* sv_list[2]  */
	{ &xpviv_list[0], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[3]  */
	{ &xpviv_list[1], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[4]  */
	{ &xpviv_list[2], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[5]  */
	{ &xpv_list[2], 2147483647, 0x18014403, {0} }, /* sv_list[6]  */
	{ &xpviv_list[3], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[7]  */
	{ &xpviv_list[4], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[8]  */
	{ &xpv_list[3], 2147483647, 0x18014403, {0} }, /* sv_list[9]  */
	{ &xpviv_list[5], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[10]  */
	{ &xpviv_list[6], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[11]  */
	{ &xpv_list[4], 2147483647, 0x18014403, {0} }, /* sv_list[12]  */
	{ &xpvnv_list[0], 1, 0x8013206 , {.svu_pv=(char*)NULL} }, /* sv_list[13]  */
	{ &xpviv_list[7], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[14]  */
	{ &xpv_list[5], 2147483647, 0x18014403, {0} }, /* sv_list[15]  */
	{ &xpviv_list[8], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[16]  */
	{ &xpviv_list[9], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[17]  */
	{ &xpv_list[6], 2147483647, 0x18014403, {0} }, /* sv_list[18]  */
	{ &xpv_list[7], 2147483647, 0x18014403, {0} }, /* sv_list[19]  */
	{ &xpvhv_list[0], 1, 0x2081000c, {0} }, /* sv_list[20]  */
	{ &xpvmg_list[0], 1, 0xc01107, {0} }, /* sv_list[21]  */
	{ &xpv_list[8], 1, 0x10004403, {0} }, /* sv_list[22]  */
	{ &xpv_list[9], 2147483647, 0x18014403, {0} }, /* sv_list[23]  */
	{ &xpv_list[10], 2147483647, 0x18014403, {0} }, /* sv_list[24]  */
	{ &xpvhv_list[1], 1, 0x2081000c, {0} }, /* sv_list[25]  */
	{ &xpvmg_list[1], 1, 0xc01107, {0} }, /* sv_list[26]  */
	{ &xpv_list[11], 1, 0x10004403, {0} }, /* sv_list[27]  */
	{ &xpv_list[12], 2147483647, 0x18014403, {0} }, /* sv_list[28]  */
	{ &xpv_list[13], 2147483647, 0x18014403, {0} }, /* sv_list[29]  */
	{ &xpvhv_list[2], 1, 0x2081000c, {0} }, /* sv_list[30]  */
	{ &xpvmg_list[2], 1, 0xc01107, {0} }, /* sv_list[31]  */
	{ &xpv_list[14], 1, 0x10004403, {0} }, /* sv_list[32]  */
	{ &xpv_list[15], 2147483647, 0x18014403, {0} }, /* sv_list[33]  */
	{ &xpviv_list[10], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[34]  */
	{ &xpvmg_list[3], 1, 0xe01107, {.svu_pv=(char*)pv3} }, /* sv_list[35]  */
	{ &xpvmg_list[4], 1, 0x100007, {0} }, /* sv_list[36]  */
	{ ptr_undef, 1, 0x801, {.svu_rv=&sv_list[36]} }, /* sv_list[37]  */
	{ &xpviv_list[11], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[38]  */
	{ &xpv_list[16], 2147483647, 0x18014403, {0} }, /* sv_list[39]  */
	{ &xpviv_list[12], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[40]  */
	{ &xpv_list[17], 2147483647, 0x18014403, {0} }, /* sv_list[41]  */
	{ &xpvmg_list[5], 1, 0x1107, {0} }, /* sv_list[42]  */
	{ &xpv_list[18], 2147483647, 0x18014403, {0} }, /* sv_list[43]  */
	{ &xpviv_list[13], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[44]  */
	{ &xpv_list[19], 2147483647, 0x18014403, {0} }, /* sv_list[45]  */
	{ &xpviv_list[14], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[46]  */
	{ &xpv_list[20], 2147483647, 0x18014403, {0} }, /* sv_list[47]  */
	{ &xpviv_list[15], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[48]  */
	{ &xpv_list[21], 2147483647, 0x18014403, {0} }, /* sv_list[49]  */
	{ &xpvmg_list[6], 1, 0x1107, {0} }, /* sv_list[50]  */
	{ &xpv_list[22], 2147483647, 0x18014403, {0} }, /* sv_list[51]  */
	{ &xpviv_list[16], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[52]  */
	{ &xpv_list[23], 2147483647, 0x18014403, {0} }, /* sv_list[53]  */
	{ &xpv_list[24], 2147483647, 0x18014403, {0} }, /* sv_list[54]  */
	{ &xpviv_list[17], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[55]  */
	{ &xpv_list[25], 2147483647, 0x18014403, {0} }, /* sv_list[56]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[57]  */
	{ &xpv_list[26], 2147483647, 0x18014403, {0} }, /* sv_list[58]  */
	{ &xpviv_list[18], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[59]  */
	{ &xpv_list[27], 2147483647, 0x18014403, {0} }, /* sv_list[60]  */
	{ &xpviv_list[19], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[61]  */
	{ &xpvmg_list[7], 1, 0x1107, {0} }, /* sv_list[62]  */
	{ &xpvmg_list[8], 1, 0x10004407, {0} }, /* sv_list[63]  */
	{ &xpviv_list[20], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[64]  */
	{ &xpv_list[28], 2147483647, 0x18014403, {0} }, /* sv_list[65]  */
	{ &xpviv_list[21], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[66]  */
	{ &xpv_list[29], 2147483647, 0x18014403, {0} }, /* sv_list[67]  */
	{ &xpviv_list[22], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[68]  */
	{ &xpv_list[30], 2147483647, 0x18014403, {0} }, /* sv_list[69]  */
	{ &xpv_list[31], 2147483647, 0x18014403, {0} }, /* sv_list[70]  */
	{ &xpv_list[32], 2147483647, 0x18014403, {0} }, /* sv_list[71]  */
	{ &xpvmg_list[9], 1, 0x1107, {0} }, /* sv_list[72]  */
	{ &xpvmg_list[10], 1, 0x1107, {0} }, /* sv_list[73]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[74]  */
	{ &xpvnv_list[1], 1, 0x7706 , {.svu_pv=(char*)pv3} }, /* sv_list[75]  */
	{ &xpv_list[33], 2147483647, 0x18014403, {0} }, /* sv_list[76]  */
	{ &xpviv_list[23], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[77]  */
	{ &xpv_list[34], 2147483647, 0x18014403, {0} }, /* sv_list[78]  */
	{ &xpviv_list[24], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[79]  */
	{ &xpv_list[35], 2147483647, 0x18014403, {0} }, /* sv_list[80]  */
	{ &xpv_list[36], 2147483647, 0x18014403, {0} }, /* sv_list[81]  */
	{ &xpv_list[37], 2147483647, 0x18014403, {0} }, /* sv_list[82]  */
	{ &xpvmg_list[11], 1, 0x1107, {0} }, /* sv_list[83]  */
	{ &xpvmg_list[12], 1, 0x10004407, {0} }, /* sv_list[84]  */
	{ &xpviv_list[25], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[85]  */
	{ &xpv_list[38], 2147483647, 0x18014403, {0} }, /* sv_list[86]  */
	{ &xpviv_list[26], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[87]  */
	{ &xpv_list[39], 2147483647, 0x18014403, {0} }, /* sv_list[88]  */
	{ &xpviv_list[27], 1, 0x8011101, {.svu_pv=NULL} }, /* sv_list[89]  */
	{ &xpv_list[40], 2147483647, 0x18014403, {0} }, /* sv_list[90]  */
	{ &xpv_list[41], 2147483647, 0x18014403, {0} }, /* sv_list[91]  */
	{ &xpv_list[42], 2147483647, 0x18014403, {0} }, /* sv_list[92]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[93]  */
	{ &xpvmg_list[13], 1, 0x10604407, {.svu_pv=(char*)pv5} }, /* sv_list[94]  */
	{ &xpvmg_list[14], 1, 0x604407, {.svu_pv=(char*)pv6} }, /* sv_list[95]  */
	{ &xpvav_list[0], 1, 0x4000000b, {0} }, /* sv_list[96]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[97]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[98]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[99]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[100]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[101]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[102]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[103]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[104]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[105]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[106]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[107]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[108]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[109]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[110]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[111]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[112]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[113]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[114]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[115]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[116]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[117]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[118]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[119]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[120]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[121]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[122]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[123]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[124]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[125]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[126]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[127]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[128]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[129]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[130]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[131]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[132]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[133]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[134]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[135]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[136]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[137]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[138]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[139]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[140]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[141]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[142]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[143]  */
	{ 0, 1, 0x20000, {0} }, /* sv_list[144]  */
	{ &xpvhv_list[3], 1, 0x2200000c, {0} }, /* sv_list[145]  */
	{ &xpv_list[43], 1, 0x10004403, {0} }, /* sv_list[146]  */
	{ &xpvav_list[1], 1, 0x4000000b, {0} }, /* sv_list[147]  */
	{ &xpv_list[44], 1, 0x4403, {0} }, /* sv_list[148]  */
	{ &xpv_list[45], 1, 0x4403, {0} }, /* sv_list[149]  */
	{ &xpv_list[46], 1, 0x4403, {0} }, /* sv_list[150]  */
	{ &xpv_list[47], 1, 0x4403, {0} }, /* sv_list[151]  */
	{ &xpv_list[48], 1, 0x4403, {0} }, /* sv_list[152]  */
	{ &xpv_list[49], 1, 0x4403, {0} }, /* sv_list[153]  */
	{ &xpv_list[50], 1, 0x4403, {0} }, /* sv_list[154]  */
	{ &xpv_list[51], 1, 0x4403, {0} }, /* sv_list[155]  */
	{ &xpv_list[52], 1, 0x4403, {0} }, /* sv_list[156]  */
	{ &xpv_list[53], 1, 0x4403, {0} }, /* sv_list[157]  */
	{ &xpv_list[54], 1, 0x4403, {0} }, /* sv_list[158]  */
	{ &xpv_list[55], 1, 0x4403, {0} }, /* sv_list[159]  */
	{ &xpv_list[56], 1, 0x4403, {0} }, /* sv_list[160]  */
	{ &xpv_list[57], 1, 0x4403, {0} }, /* sv_list[161]  */
	{ &xpv_list[58], 1, 0x4403, {0} }, /* sv_list[162]  */
	{ &xpv_list[59], 1, 0x4403, {0} }, /* sv_list[163]  */
	{ &xpv_list[60], 1, 0x4403, {0} }, /* sv_list[164]  */
	{ &xpv_list[61], 1, 0x4403, {0} }, /* sv_list[165]  */
	{ &xpv_list[62], 1, 0x4403, {0} }, /* sv_list[166]  */
	{ &xpv_list[63], 1, 0x4403, {0} }, /* sv_list[167]  */
	{ &xpv_list[64], 1, 0x4403, {0} }, /* sv_list[168]  */
	{ &xpv_list[65], 1, 0x4403, {0} }, /* sv_list[169]  */
	{ &xpv_list[66], 1, 0x4403, {0} }, /* sv_list[170]  */
	{ &xpv_list[67], 1, 0x4403, {0} }, /* sv_list[171]  */
	{ &xpv_list[68], 1, 0x4403, {0} }, /* sv_list[172]  */
	{ &xpv_list[69], 1, 0x4403, {0} }, /* sv_list[173]  */
	{ &xpv_list[70], 1, 0x4403, {0} }, /* sv_list[174]  */
	{ &xpv_list[71], 1, 0x4403, {0} }, /* sv_list[175]  */
	{ &xpv_list[72], 1, 0x4403, {0} }, /* sv_list[176]  */
	{ &xpv_list[73], 1, 0x4403, {0} }, /* sv_list[177]  */
	{ &xpv_list[74], 1, 0x4403, {0} }, /* sv_list[178]  */
	{ &xpv_list[75], 1, 0x4403, {0} }, /* sv_list[179]  */
	{ &xpv_list[76], 1, 0x4403, {0} }, /* sv_list[180]  */
	{ &xpv_list[77], 1, 0x4403, {0} }, /* sv_list[181]  */
	{ &xpv_list[78], 1, 0x4403, {0} }, /* sv_list[182]  */
	{ &xpv_list[79], 1, 0x4403, {0} }, /* sv_list[183]  */
	{ &xpv_list[80], 1, 0x4403, {0} }, /* sv_list[184]  */
	{ &xpv_list[81], 1, 0x4403, {0} }, /* sv_list[185]  */
	{ &xpv_list[82], 1, 0x4403, {0} }, /* sv_list[186]  */
	{ &xpv_list[83], 1, 0x4403, {0} }, /* sv_list[187]  */
	{ &xpv_list[84], 1, 0x4403, {0} }, /* sv_list[188]  */
	{ &xpv_list[85], 1, 0x4403, {0} }, /* sv_list[189]  */
	{ &xpv_list[86], 1, 0x4403, {0} }, /* sv_list[190]  */
	{ &xpv_list[87], 1, 0x4403, {0} }, /* sv_list[191]  */
	{ &xpv_list[88], 1, 0x4403, {0} }, /* sv_list[192]  */
	{ &xpv_list[89], 1, 0x4403, {0} }, /* sv_list[193]  */
	{ &xpv_list[90], 1, 0x4403, {0} }, /* sv_list[194]  */
	{ &xpv_list[91], 1, 0x4403, {0} }, /* sv_list[195]  */
	{ &xpv_list[92], 1, 0x4403, {0} }, /* sv_list[196]  */
	{ &xpv_list[93], 1, 0x4403, {0} }, /* sv_list[197]  */
	{ &xpv_list[94], 1, 0x4403, {0} }, /* sv_list[198]  */
	{ &xpv_list[95], 1, 0x4403, {0} }, /* sv_list[199]  */
	{ &xpv_list[96], 1, 0x4403, {0} }, /* sv_list[200]  */
	{ &xpv_list[97], 1, 0x4403, {0} }, /* sv_list[201]  */
	{ &xpv_list[98], 1, 0x4403, {0} }, /* sv_list[202]  */
	{ &xpv_list[99], 1, 0x4403, {0} }, /* sv_list[203]  */
	{ &xpv_list[100], 1, 0x4403, {0} }, /* sv_list[204]  */
	{ &xpv_list[101], 1, 0x4403, {0} }, /* sv_list[205]  */
	{ &xpv_list[102], 1, 0x4403, {0} }, /* sv_list[206]  */
};

static void perl_init0(pTHX) /* fixup_ppaddr */
{
	register int i;
	for (i = 0; i < 26; ++i) {
		binop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(binop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 52; ++i) {
		cop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(cop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 10; ++i) {
		listop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(listop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 3; ++i) {
		logop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(logop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 5; ++i) {
		loop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(loop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 53; ++i) {
		op_list[i].op_ppaddr = PL_ppaddr[PTR2IV(op_list[i].op_ppaddr)];
	}
	for (i = 0; i < 3; ++i) {
		pmop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(pmop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 136; ++i) {
		svop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(svop_list[i].op_ppaddr)];
	}
	for (i = 0; i < 131; ++i) {
		unop_list[i].op_ppaddr = PL_ppaddr[PTR2IV(unop_list[i].op_ppaddr)];
	}
};

static void perl_init_aaaa(pTHX)
{
	if (lexwarn0) cop_list[0].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	hv0 = gv_stashpvn(pv1, 4, 4|GV_ADD);
	CopSTASH_set(&cop_list[0], hv0);
	CopFILE_set(&cop_list[0], pv2);
	CopSTASH_set(&cop_list[1], hv0);
	CopFILE_set(&cop_list[1], pv2);
	hek0 = share_hek("t/CORE/test.pl", 14, 0);
	sv_list[1].sv_u.svu_pv = HEK_KEY(hek0);
	CopSTASH_set(&cop_list[2], hv0);
	CopFILE_set(&cop_list[2], pv2);
	sv_list[2].sv_u.svu_pv = savepvn("tests\000\001", 7);
	gv_list[0] = gv_fetchpvn_flags("plan", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[0]) = 0x8009;
	GvFLAGS(gv_list[0]) = 0x2; 
	GvLINE(gv_list[0]) = 6;
	SvREFCNT(gv_list[0]) = 2;
	hek1 = share_hek("t/CORE/op/array_base.t", 22, 0);
	GvFILE_HEK(gv_list[0]) = hek1;
	
	svop_list[3].op_sv = (SV*)gv_list[0];
	if (lexwarn0) cop_list[3].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[3], hv0);
	CopFILE_set(&cop_list[3], pv2);
	if (lexwarn0) cop_list[4].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[4], hv0);
	CopFILE_set(&cop_list[4], pv2);
	gv_list[1] = gv_fetchpvn_flags("arybase::leftbrack", 18, GV_ADD, SVt_PV);
	SvFLAGS(gv_list[1]) = 0x8009;
	GvFLAGS(gv_list[1]) = 0x2; 
	GvLINE(gv_list[1]) = 13;
	SvREFCNT(gv_list[1]) = 9;
	GvFILE_HEK(gv_list[1]) = share_hek_hek(hek1);
	
	svop_list[5].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[5].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[5], hv0);
	CopFILE_set(&cop_list[5], pv2);
	svop_list[7].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[6].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[6], hv0);
	CopFILE_set(&cop_list[6], pv2);
	sv_list[6].sv_u.svu_pv = savepvn("#27204\000\001", 8);
	gv_list[2] = gv_fetchpvn_flags("pass", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[2]) = 0x8009;
	GvFLAGS(gv_list[2]) = 0x2; 
	GvLINE(gv_list[2]) = 14;
	SvREFCNT(gv_list[2]) = 4;
	GvFILE_HEK(gv_list[2]) = share_hek_hek(hek1);
	
	svop_list[9].op_sv = (SV*)gv_list[2];
	if (lexwarn0) cop_list[7].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[7], hv0);
	CopFILE_set(&cop_list[7], pv2);
	if (lexwarn0) cop_list[8].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[8], hv0);
	CopFILE_set(&cop_list[8], pv2);
	if (lexwarn0) cop_list[9].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[9], hv0);
	CopFILE_set(&cop_list[9], pv2);
	if (lexwarn0) cop_list[10].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[10], hv0);
	CopFILE_set(&cop_list[10], pv2);
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x2; 
	GvLINE(PL_defgv) = 0;
	SvREFCNT(PL_defgv) = 511;
	svop_list[10].op_sv = (SV*)PL_defgv;
	svop_list[13].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[11].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[11], hv0);
	CopFILE_set(&cop_list[11], pv2);
	sv_list[9].sv_u.svu_pv = savepvn("optimized assignment to $[ used to segfault in list context\000\001", 61);
	svop_list[15].op_sv = (SV*)gv_list[2];
	if (lexwarn0) cop_list[12].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[12], hv0);
	CopFILE_set(&cop_list[12], pv2);
	svop_list[17].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[13].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[13], hv0);
	CopFILE_set(&cop_list[13], pv2);
	if (lexwarn0) cop_list[14].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[14], hv0);
	CopFILE_set(&cop_list[14], pv2);
	sv_list[12].sv_u.svu_pv = savepvn("optimized assignment to $[ used to segfault in scalar context\000\001", 63);
	svop_list[20].op_sv = (SV*)gv_list[2];
	if (lexwarn0) cop_list[15].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[15], hv0);
	CopFILE_set(&cop_list[15], pv2);
	svop_list[22].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[16].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[16], hv0);
	CopFILE_set(&cop_list[16], pv2);
	sv_list[15].sv_u.svu_pv = savepvn("scalar assignment to $[ behaves like other variables\000\001", 54);
	gv_list[4] = gv_fetchpvn_flags("is", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[4]) = 0x8009;
	GvFLAGS(gv_list[4]) = 0x2; 
	GvLINE(gv_list[4]) = 26;
	SvREFCNT(gv_list[4]) = 6;
	GvFILE_HEK(gv_list[4]) = share_hek_hek(hek1);
	
	svop_list[25].op_sv = (SV*)gv_list[4];
	if (lexwarn0) cop_list[17].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[17], hv0);
	CopFILE_set(&cop_list[17], pv2);
	svop_list[27].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[18].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[18], hv0);
	CopFILE_set(&cop_list[18], pv2);
	sv_list[18].sv_u.svu_pv = savepvn("list assignment to $[ behaves like other variables\000\001", 52);
	svop_list[30].op_sv = (SV*)gv_list[4];
	if (lexwarn0) cop_list[19].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[19], hv0);
	CopFILE_set(&cop_list[19], pv2);
	sv_list[19].sv_u.svu_pv = savepvn(" ($[, $x) = (0) \000\001", 18);
	sv_list[21].sv_u.svu_pv = savepvn("", 0);
	hek2 = share_hek("$[", 2, 0);
	sv_list[22].sv_u.svu_pv = HEK_KEY(hek2);
	sv_magic((SV*)&sv_list[21], (SV*)0, 'h', (char *)&sv_list[22], -2);
	{
		HV *hv = (HV*)&sv_list[20];
		hv_store(hv, "$[", 2, &sv_list[21], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[20]) = 1;
	SvREADONLY_off((SV*)(HV*)&sv_list[20]);
	sv_magic((SV*)(HV*)&sv_list[20], (SV*)0, 'H', 0, 0);
	SvREADONLY_on((SV*)(HV*)&sv_list[20]);
	SvREADONLY_on((HV*)&sv_list[20]);
	if (lexwarn0) cop_list[20].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[20], hv0);
	CopFILE_set(&cop_list[20], pv2);
	SvFLAGS(PL_errgv) = 0x8009;
	GvFLAGS(PL_errgv) = 0x2; 
	GvLINE(PL_errgv) = 0;
	SvREFCNT(PL_errgv) = 27;
	svop_list[33].op_sv = (SV*)PL_errgv;
	pmop_list[0].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[0], CALLREGCOMP(newSVpvn_flags("That use of \\$\\[ is unsupported", 31, SVs_TEMP|0), 0x40000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[0])) = 0x680000;
	sv_list[23].sv_u.svu_pv = savepvn("cannot assign to $[ in a list\000\001", 31);
	gv_list[6] = gv_fetchpvn_flags("like", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[6]) = 0x8009;
	GvFLAGS(gv_list[6]) = 0x2; 
	GvLINE(gv_list[6]) = 30;
	SvREFCNT(gv_list[6]) = 4;
	GvFILE_HEK(gv_list[6]) = share_hek_hek(hek1);
	
	svop_list[35].op_sv = (SV*)gv_list[6];
	if (lexwarn0) cop_list[21].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[21], hv0);
	CopFILE_set(&cop_list[21], pv2);
	sv_list[24].sv_u.svu_pv = savepvn(" ($[) = (0, 1) \000\001", 17);
	sv_list[26].sv_u.svu_pv = savepvn("", 0);
	sv_list[27].sv_u.svu_pv = HEK_KEY(share_hek_hek(hek2));
	sv_magic((SV*)&sv_list[26], (SV*)0, 'h', (char *)&sv_list[27], -2);
	{
		HV *hv = (HV*)&sv_list[25];
		hv_store(hv, "$[", 2, &sv_list[26], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[25]) = 1;
	SvREADONLY_off((SV*)(HV*)&sv_list[25]);
	sv_magic((SV*)(HV*)&sv_list[25], (SV*)0, 'H', 0, 0);
	SvREADONLY_on((SV*)(HV*)&sv_list[25]);
	SvREADONLY_on((HV*)&sv_list[25]);
	if (lexwarn0) cop_list[22].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[22], hv0);
	CopFILE_set(&cop_list[22], pv2);
	svop_list[38].op_sv = (SV*)PL_errgv;
	pmop_list[1].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[1], CALLREGCOMP(newSVpvn_flags("That use of \\$\\[ is unsupported", 31, SVs_TEMP|0), 0x40000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[1])) = 0x680000;
	sv_list[28].sv_u.svu_pv = savepvn("cannot assign list of >1 elements to $[\000\001", 41);
	svop_list[40].op_sv = (SV*)gv_list[6];
	if (lexwarn0) cop_list[23].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[23], hv0);
	CopFILE_set(&cop_list[23], pv2);
	sv_list[29].sv_u.svu_pv = savepvn(" ($[) = () \000\001", 13);
	sv_list[31].sv_u.svu_pv = savepvn("", 0);
	sv_list[32].sv_u.svu_pv = HEK_KEY(share_hek_hek(hek2));
	sv_magic((SV*)&sv_list[31], (SV*)0, 'h', (char *)&sv_list[32], -2);
	{
		HV *hv = (HV*)&sv_list[30];
		hv_store(hv, "$[", 2, &sv_list[31], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[30]) = 1;
	SvREADONLY_off((SV*)(HV*)&sv_list[30]);
	sv_magic((SV*)(HV*)&sv_list[30], (SV*)0, 'H', 0, 0);
	SvREADONLY_on((SV*)(HV*)&sv_list[30]);
	SvREADONLY_on((HV*)&sv_list[30]);
	if (lexwarn0) cop_list[24].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[24], hv0);
	CopFILE_set(&cop_list[24], pv2);
	svop_list[43].op_sv = (SV*)PL_errgv;
	pmop_list[2].op_pmstashstartu.op_pmreplstart = (OP*)0;
	PM_SETRE(&pmop_list[2], CALLREGCOMP(newSVpvn_flags("That use of \\$\\[ is unsupported", 31, SVs_TEMP|0), 0x40000000));
	RX_EXTFLAGS(PM_GETRE(&pmop_list[2])) = 0x680000;
	sv_list[33].sv_u.svu_pv = savepvn("cannot assign list of <1 elements to $[\000\001", 41);
	svop_list[45].op_sv = (SV*)gv_list[6];
	if (lexwarn0) cop_list[25].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[25], hv0);
	CopFILE_set(&cop_list[25], pv2);
	if (lexwarn0) cop_list[26].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[26], hv0);
	CopFILE_set(&cop_list[26], pv2);
	svop_list[47].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[27].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[27], hv0);
	CopFILE_set(&cop_list[27], pv2);
	gv_list[7] = gv_fetchpvn_flags("[", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[7]) = 0x8009;
	GvFLAGS(gv_list[7]) = 0x2; 
	GvLINE(gv_list[7]) = 6648;
	SvREFCNT(gv_list[7]) = 8;
	sv_list[35].sv_u.svu_pv = savepvn("", 0);
	sv_list[36].sv_u.svu_pv = savepvn("", 0);
	hv1 = gv_stashpvn("arybase", 7, GV_ADD);
	SvSTASH_set(&sv_list[36], (HV*)hv1);
	SvREFCNT((SV*)hv1) += 1;
	++PL_sv_objcount;
	sv_magic((SV*)&sv_list[35], (SV*)&sv_list[37], 'q', 0, 0);
	GvSVn(gv_list[7]) = (SV*)&sv_list[35];
	hek3 = share_hek("blib/lib/B/C.pm", 15, 0);
	GvFILE_HEK(gv_list[7]) = hek3;
	
	svop_list[48].op_sv = (SV*)gv_list[7];
	sv_list[39].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[41].sv_u.svu_pv = savepvn("setting $[ affects $[\000\001", 23);
	gv_list[8] = gv_fetchpvn_flags("cmp_ok", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[8]) = 0x8009;
	GvFLAGS(gv_list[8]) = 0x2; 
	GvLINE(gv_list[8]) = 43;
	SvREFCNT(gv_list[8]) = 10;
	GvFILE_HEK(gv_list[8]) = share_hek_hek(hek1);
	
	svop_list[53].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[28].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[28], hv0);
	CopFILE_set(&cop_list[28], pv2);
	gv_list[9] = gv_fetchpvn_flags("t11", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[9]) = 0x8009;
	GvFLAGS(gv_list[9]) = 0x2; 
	GvLINE(gv_list[9]) = 44;
	SvREFCNT(gv_list[9]) = 4;
	sv_list[42].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[9]) = (SV*)&sv_list[42];
	GvFILE_HEK(gv_list[9]) = share_hek_hek(hek1);
	
	svop_list[54].op_sv = (SV*)gv_list[9];
	if (lexwarn0) cop_list[29].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[29], hv0);
	CopFILE_set(&cop_list[29], pv2);
	svop_list[55].op_sv = (SV*)gv_list[9];
	sv_list[43].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[45].sv_u.svu_pv = savepvn("setting $[ affects $^H{'$['}\000\001", 30);
	svop_list[59].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[30].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[30], hv0);
	CopFILE_set(&cop_list[30], pv2);
	svop_list[60].op_sv = (SV*)gv_list[7];
	sv_list[47].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[49].sv_u.svu_pv = savepvn("setting $^H{'$'} affects $[\000\001", 29);
	svop_list[65].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[31].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[31], hv0);
	CopFILE_set(&cop_list[31], pv2);
	gv_list[10] = gv_fetchpvn_flags("t22", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[10]) = 0x8009;
	GvFLAGS(gv_list[10]) = 0x2; 
	GvLINE(gv_list[10]) = 49;
	SvREFCNT(gv_list[10]) = 4;
	sv_list[50].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[10]) = (SV*)&sv_list[50];
	GvFILE_HEK(gv_list[10]) = share_hek_hek(hek1);
	
	svop_list[66].op_sv = (SV*)gv_list[10];
	if (lexwarn0) cop_list[32].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[32], hv0);
	CopFILE_set(&cop_list[32], pv2);
	svop_list[67].op_sv = (SV*)gv_list[10];
	sv_list[51].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[53].sv_u.svu_pv = savepvn("setting $^H{'$['} affects $^H{'$['}\000\001", 37);
	svop_list[71].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[33].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[33], hv0);
	CopFILE_set(&cop_list[33], pv2);
	svop_list[72].op_sv = (SV*)gv_list[7];
	if (lexwarn4) cop_list[34].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn4, sizeof(lexwarn4));
	CopSTASH_set(&cop_list[34], hv0);
	CopFILE_set(&cop_list[34], pv2);
	if (lexwarn0) cop_list[35].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[35], hv0);
	CopFILE_set(&cop_list[35], pv2);
	sv_list[54].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[56].sv_u.svu_pv = savepvn("clearing %^H affects $[\000\001", 25);
	svop_list[76].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[36].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[36], hv0);
	CopFILE_set(&cop_list[36], pv2);
	gv_list[11] = gv_fetchpvn_flags("t0", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[11]) = 0x8009;
	GvFLAGS(gv_list[11]) = 0x2; 
	GvLINE(gv_list[11]) = 58;
	SvREFCNT(gv_list[11]) = 4;
	GvSVn(gv_list[11]) = (SV*)&sv_list[57];
	GvFILE_HEK(gv_list[11]) = share_hek_hek(hek1);
	
	svop_list[77].op_sv = (SV*)gv_list[11];
	if (lexwarn0) cop_list[37].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[37], hv0);
	CopFILE_set(&cop_list[37], pv2);
	svop_list[78].op_sv = (SV*)gv_list[11];
	sv_list[58].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[60].sv_u.svu_pv = savepvn("clearing %^H affects $^H{'$['}\000\001", 32);
	svop_list[82].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[38].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[38], hv0);
	CopFILE_set(&cop_list[38], pv2);
	svop_list[84].op_sv = (SV*)gv_list[1];
	if (lexwarn0) cop_list[39].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[39], hv0);
	CopFILE_set(&cop_list[39], pv2);
	gv_list[12] = gv_fetchpvn_flags("ri0", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[12]) = 0x8009;
	GvFLAGS(gv_list[12]) = 0x2; 
	GvLINE(gv_list[12]) = 66;
	SvREFCNT(gv_list[12]) = 4;
	sv_list[62].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[12]) = (SV*)&sv_list[62];
	GvFILE_HEK(gv_list[12]) = share_hek_hek(hek1);
	
	svop_list[85].op_sv = (SV*)gv_list[12];
	gv_list[13] = gv_fetchpvn_flags("rf0", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[13]) = 0x8009;
	GvFLAGS(gv_list[13]) = 0x2; 
	GvLINE(gv_list[13]) = 66;
	SvREFCNT(gv_list[13]) = 4;
	sv_list[63].sv_u.svu_pv = savepvn("z\000\001", 3);
	hv2 = gv_stashpvn("main::rf0", 9, GV_ADD);
	GvSVn(gv_list[13]) = (SV*)&sv_list[63];
	GvFILE_HEK(gv_list[13]) = share_hek_hek(hek1);
	
	svop_list[86].op_sv = (SV*)gv_list[13];
	if (lexwarn0) cop_list[40].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[40], hv0);
	CopFILE_set(&cop_list[40], pv2);
	svop_list[87].op_sv = (SV*)gv_list[7];
	sv_list[65].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[67].sv_u.svu_pv = savepvn("$[ correct before require\000\001", 27);
	svop_list[92].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[41].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[41], hv0);
	CopFILE_set(&cop_list[41], pv2);
	svop_list[93].op_sv = (SV*)gv_list[12];
	sv_list[69].sv_u.svu_pv = savepvn("$^H correct before require\000\001", 28);
	gv_list[14] = gv_fetchpvn_flags("ok", 2, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[14]) = 0x8009;
	GvFLAGS(gv_list[14]) = 0x2; 
	GvLINE(gv_list[14]) = 68;
	SvREFCNT(gv_list[14]) = 5;
	GvFILE_HEK(gv_list[14]) = share_hek_hek(hek1);
	
	svop_list[96].op_sv = (SV*)gv_list[14];
	if (lexwarn0) cop_list[42].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[42], hv0);
	CopFILE_set(&cop_list[42], pv2);
	svop_list[97].op_sv = (SV*)gv_list[13];
	sv_list[70].sv_u.svu_pv = savepvn("z\000\001", 3);
	sv_list[71].sv_u.svu_pv = savepvn("$^H{foo} correct before require\000\001", 33);
	svop_list[100].op_sv = (SV*)gv_list[4];
	if (lexwarn0) cop_list[43].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[43], hv0);
	CopFILE_set(&cop_list[43], pv2);
	gv_list[15] = gv_fetchpvn_flags("ra1", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[15]) = 0x8009;
	GvFLAGS(gv_list[15]) = 0x2; 
	GvLINE(gv_list[15]) = 71;
	SvREFCNT(gv_list[15]) = 3;
	sv_list[72].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[15]) = (SV*)&sv_list[72];
	GvFILE_HEK(gv_list[15]) = share_hek_hek(hek1);
	
	svop_list[101].op_sv = (SV*)gv_list[15];
	gv_list[16] = gv_fetchpvn_flags("ri1", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[16]) = 0x8009;
	GvFLAGS(gv_list[16]) = 0x2; 
	GvLINE(gv_list[16]) = 71;
	SvREFCNT(gv_list[16]) = 4;
	sv_list[73].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[16]) = (SV*)&sv_list[73];
	GvFILE_HEK(gv_list[16]) = share_hek_hek(hek1);
	
	svop_list[102].op_sv = (SV*)gv_list[16];
	gv_list[17] = gv_fetchpvn_flags("rf1", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[17]) = 0x8009;
	GvFLAGS(gv_list[17]) = 0x2; 
	GvLINE(gv_list[17]) = 71;
	SvREFCNT(gv_list[17]) = 4;
	GvSVn(gv_list[17]) = (SV*)&sv_list[74];
	GvFILE_HEK(gv_list[17]) = share_hek_hek(hek1);
	
	svop_list[103].op_sv = (SV*)gv_list[17];
	gv_list[18] = gv_fetchpvn_flags("rfe1", 4, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[18]) = 0x8009;
	GvFLAGS(gv_list[18]) = 0x2; 
	GvLINE(gv_list[18]) = 71;
	SvREFCNT(gv_list[18]) = 4;
	GvSVn(gv_list[18]) = (SV*)&sv_list[75];
	GvFILE_HEK(gv_list[18]) = share_hek_hek(hek1);
	
	svop_list[104].op_sv = (SV*)gv_list[18];
	if (lexwarn0) cop_list[44].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[44], hv0);
	CopFILE_set(&cop_list[44], pv2);
	svop_list[105].op_sv = (SV*)gv_list[15];
	sv_list[76].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[78].sv_u.svu_pv = savepvn("$[ cleared for require\000\001", 24);
	svop_list[109].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[45].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[45], hv0);
	CopFILE_set(&cop_list[45], pv2);
	svop_list[110].op_sv = (SV*)gv_list[16];
	sv_list[80].sv_u.svu_pv = savepvn("$^H cleared for require\000\001", 25);
	svop_list[113].op_sv = (SV*)gv_list[14];
	if (lexwarn0) cop_list[46].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[46], hv0);
	CopFILE_set(&cop_list[46], pv2);
	svop_list[114].op_sv = (SV*)gv_list[17];
	sv_list[81].sv_u.svu_pv = savepvn("$^H{foo} cleared for require\000\001", 30);
	svop_list[116].op_sv = (SV*)gv_list[4];
	if (lexwarn0) cop_list[47].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[47], hv0);
	CopFILE_set(&cop_list[47], pv2);
	svop_list[117].op_sv = (SV*)gv_list[18];
	sv_list[82].sv_u.svu_pv = savepvn("$^H{foo} cleared for require\000\001", 30);
	svop_list[119].op_sv = (SV*)gv_list[14];
	if (lexwarn0) cop_list[48].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[48], hv0);
	CopFILE_set(&cop_list[48], pv2);
	gv_list[19] = gv_fetchpvn_flags("ri2", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[19]) = 0x8009;
	GvFLAGS(gv_list[19]) = 0x2; 
	GvLINE(gv_list[19]) = 78;
	SvREFCNT(gv_list[19]) = 4;
	sv_list[83].sv_u.svu_pv = savepvn("", 0);
	GvSVn(gv_list[19]) = (SV*)&sv_list[83];
	GvFILE_HEK(gv_list[19]) = share_hek_hek(hek1);
	
	svop_list[120].op_sv = (SV*)gv_list[19];
	gv_list[20] = gv_fetchpvn_flags("rf2", 3, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[20]) = 0x8009;
	GvFLAGS(gv_list[20]) = 0x2; 
	GvLINE(gv_list[20]) = 78;
	SvREFCNT(gv_list[20]) = 4;
	sv_list[84].sv_u.svu_pv = savepvn("z\000\001", 3);
	hv3 = gv_stashpvn("main::rf2", 9, GV_ADD);
	GvSVn(gv_list[20]) = (SV*)&sv_list[84];
	GvFILE_HEK(gv_list[20]) = share_hek_hek(hek1);
	
	svop_list[121].op_sv = (SV*)gv_list[20];
	if (lexwarn0) cop_list[49].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[49], hv0);
	CopFILE_set(&cop_list[49], pv2);
	svop_list[122].op_sv = (SV*)gv_list[7];
	sv_list[86].sv_u.svu_pv = savepvn("==\000\001", 4);
	sv_list[88].sv_u.svu_pv = savepvn("$[ correct after require\000\001", 26);
	svop_list[127].op_sv = (SV*)gv_list[8];
	if (lexwarn0) cop_list[50].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[50], hv0);
	CopFILE_set(&cop_list[50], pv2);
	svop_list[128].op_sv = (SV*)gv_list[19];
	sv_list[90].sv_u.svu_pv = savepvn("$^H correct after require\000\001", 27);
	svop_list[131].op_sv = (SV*)gv_list[14];
	if (lexwarn0) cop_list[51].cop_warnings = (STRLEN*)savesharedpvn((const char*)lexwarn0, sizeof(lexwarn0));
	CopSTASH_set(&cop_list[51], hv0);
	CopFILE_set(&cop_list[51], pv2);
	svop_list[132].op_sv = (SV*)gv_list[20];
	sv_list[91].sv_u.svu_pv = savepvn("z\000\001", 3);
	sv_list[92].sv_u.svu_pv = savepvn("$^H{foo} correct after require\000\001", 32);
	svop_list[135].op_sv = (SV*)gv_list[4];
	
	/* done main optree, extra subs which might be unused */
	gv_list[21] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[21]) = 2;
	gv_list[22] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[22]) = 2;
	gv_list[23] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[23]) = 2;
	gv_list[24] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[24]) = 0x8009;
	GvFLAGS(gv_list[24]) = 0x2; 
	GvLINE(gv_list[24]) = 0;
	SvREFCNT(gv_list[24]) = 23;
	GvREFCNT(gv_list[24]) += 1;
	GvFILE_HEK(gv_list[24]) = share_hek_hek(hek1);
	IoIFP((IO*)&sv_list[93]) = IoOFP((IO*)&sv_list[93]) = PerlIO_stdout();
	GvIOp(gv_list[24]) = (IO*)&sv_list[93];
	
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
	gv_list[27] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[27]) = 0x8009;
	GvFLAGS(gv_list[27]) = 0x2; 
	GvLINE(gv_list[27]) = 363;
	SvREFCNT(gv_list[27]) = 9;
	GvREFCNT(gv_list[27]) += 1;
	sv_list[94].sv_u.svu_pv = savepvn("t/CORE/op/array_base.c\000\001", 24);
	hv4 = gv_stashpvn("main::2", 7, GV_ADD);
	sv_magic((SV*)&sv_list[94], (SV*)gv_list[27], '\000', 0, 2);
	GvSVn(gv_list[27]) = (SV*)&sv_list[94];
	hek4 = share_hek("/usr/local/lib/perl5/5.22.0/Carp.pm", 35, 0);
	GvFILE_HEK(gv_list[27]) = hek4;
	
	gv_list[28] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[28]) = 0x8009;
	GvFLAGS(gv_list[28]) = 0x2; 
	GvLINE(gv_list[28]) = 102;
	SvREFCNT(gv_list[28]) = 48;
	GvREFCNT(gv_list[28]) += 1;
	sv_list[95].sv_u.svu_pv = savepvn("arybase", 7);
	sv_magic((SV*)&sv_list[95], (SV*)gv_list[28], '\000', 0, 1);
	GvSVn(gv_list[28]) = (SV*)&sv_list[95];
	hek5 = share_hek("/usr/local/lib/perl5/5.22.0/darwin/B.pm", 39, 0);
	GvFILE_HEK(gv_list[28]) = hek5;
	
	gv_list[29] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[29]) = 3;
	/* done extras */
	/* honor -w */
	PL_dowarn = ( 1 ) ? G_WARN_ON : G_WARN_OFF;
	/* END block */
	/* startpoints */
	PL_main_root = (OP*)&listop_list[0];
	PL_main_start = &op_list[0];
	PL_initav = (AV*)Nullsv;
	PL_endav = (AV*)Nullsv;
	/* curpad names */
	hv5 = gv_stashpvn("main", 4, GV_ADD);
	SvOURSTASH_set(&padname_list[3], hv5);
	SvOURSTASH_set(&padname_list[4], hv5);
	SvOURSTASH_set(&padname_list[6], hv5);
	SvOURSTASH_set(&padname_list[7], hv5);
	SvOURSTASH_set(&padname_list[8], hv5);
	SvOURSTASH_set(&padname_list[9], hv5);
	SvOURSTASH_set(&padname_list[10], hv5);
	SvOURSTASH_set(&padname_list[11], hv5);
	SvOURSTASH_set(&padname_list[12], hv5);
	SvOURSTASH_set(&padname_list[13], hv5);
	SvOURSTASH_set(&padname_list[14], hv5);
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[0];
		Newxz(svp, 44, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[1];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[2];
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
		*svp++ = (PADNAME*)&padname_list[3];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[4];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[5];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[6];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[7];
		*svp++ = (PADNAME*)&padname_list[8];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[9];
		*svp++ = (PADNAME*)&padname_list[10];
		*svp++ = (PADNAME*)&padname_list[11];
		*svp++ = (PADNAME*)&padname_list[12];
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)Nullsv;
		*svp++ = (PADNAME*)&padname_list[13];
		*svp++ = (PADNAME*)&padname_list[14];
	}
	/* curpad syms */
	{
		SV **svp;
		AV *av = (AV*)&sv_list[96];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(49 * sizeof(SV*));
	#else
		svp = (SV**)malloc(49 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		for (gcount=97; gcount<145; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[145]) = a;
		HvRITER_set(&sv_list[145], -1);
	}
	sv_list[146].sv_u.svu_pv = savepvn("t/CORE/op/array_base.aux\000\001", 26);
	{
		HV *hv = (HV*)&sv_list[145];
		hv_store(hv, "t/CORE/op/array_base.aux", 24, &sv_list[146], 0);
	}
	HvTOTALKEYS((HV*)&sv_list[145]) = 1;
	/* @INC */
	sv_list[148].sv_u.svu_pv = savepvn("blib/arch", 9);
	sv_list[149].sv_u.svu_pv = savepvn("blib/lib", 8);
	sv_list[150].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[151].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[152].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[153].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[154].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[155].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[156].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[157].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[158].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[159].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[160].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[161].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[162].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[163].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[164].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0/darwin", 44);
	sv_list[165].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0", 37);
	sv_list[166].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0/darwin", 34);
	sv_list[167].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0", 27);
	sv_list[168].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.11", 38);
	sv_list[169].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.10", 38);
	sv_list[170].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.9", 37);
	sv_list[171].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.8", 37);
	sv_list[172].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.5", 37);
	sv_list[173].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.4", 37);
	sv_list[174].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.3", 37);
	sv_list[175].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.2", 37);
	sv_list[176].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.1", 37);
	sv_list[177].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.2", 37);
	sv_list[178].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.1", 37);
	sv_list[179].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.0", 37);
	sv_list[180].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.9", 37);
	sv_list[181].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.8", 37);
	sv_list[182].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.6", 37);
	sv_list[183].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.4", 37);
	sv_list[184].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.2", 37);
	sv_list[185].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.4", 37);
	sv_list[186].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.2", 37);
	sv_list[187].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.1", 37);
	sv_list[188].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.0", 37);
	sv_list[189].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.3", 37);
	sv_list[190].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.1", 37);
	sv_list[191].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.15.8", 37);
	sv_list[192].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.4", 37);
	sv_list[193].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.3", 37);
	sv_list[194].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.2", 37);
	sv_list[195].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.1", 37);
	sv_list[196].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.0", 37);
	sv_list[197].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.5", 37);
	sv_list[198].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.4", 37);
	sv_list[199].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.10.1", 37);
	sv_list[200].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.9", 36);
	sv_list[201].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.8", 36);
	sv_list[202].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.5", 36);
	sv_list[203].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.4", 36);
	sv_list[204].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.6.2", 36);
	sv_list[205].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl", 30);
	sv_list[206].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[147];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(59 * sizeof(SV*));
	#else
		svp = (SV**)malloc(59 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=148; gcount<207; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvHV(PL_incgv) = (HV*)&sv_list[145];
	GvAV(PL_incgv) = (AV*)&sv_list[147];
	PL_curpad = AvARRAY((AV*)&sv_list[96]);
	PL_comppad = (AV*)&sv_list[96];
	PL_stack_sp = PL_stack_base;
	PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = &padnamelist_list[0]; /* namepad */
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)(AV*)&sv_list[96]; /* curpad */
	
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
static void perl_init2_aaaa(pTHX)
{
	Gv_AMG(hv1); /* init AMG overload for %arybase:: */
	Gv_AMG(hv2); /* init AMG overload for main::rf0 */
	Gv_AMG(hv3); /* init AMG overload for main::rf2 */
	Gv_AMG(hv4); /* init AMG overload for main::2 */
	Gv_AMG(hv5); /* init AMG overload for %main:: */
	
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
