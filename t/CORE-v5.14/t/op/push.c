/* created at Thu Oct 22 01:33:32 2015 with B::C 1.52_06 -2850-g341501a for /usr/local/bin/perl5.22.0-nt */
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
Static GV *gv_list[12];
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );

Static XPV xpv_list[47];
Static XPVAV xpvav_list[4];
Static XPVHV xpvhv_list[1];
Static MyPADNAME padname_list[1];
Static PADNAMELIST padnamelist_list[1];
Static XPVMG xpvmg_list[2];
Static XPVIO xpvio_list[1];
Static SV sv_list[78];
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
Static HEK *hek0;
Static char pv0[] = "t/CORE/op/push.c";
Static HV *hv0;
Static HEK *hek1;
Static const char pv1[] = "o";
Static HEK *hek2;

Static XPV xpv_list[47] = {
	{ Nullhv, {0}, 9, 16 }, /* xpv_list[0]  */
	{ Nullhv, {0}, 8, 16 }, /* xpv_list[1]  */
	{ Nullhv, {0}, 31, 32 }, /* xpv_list[2]  */
	{ Nullhv, {0}, 32, 40 }, /* xpv_list[3]  */
	{ Nullhv, {0}, 44, 48 }, /* xpv_list[4]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[5]  */
	{ Nullhv, {0}, 34, 40 }, /* xpv_list[6]  */
	{ Nullhv, {0}, 27, 32 }, /* xpv_list[7]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[8]  */
	{ Nullhv, {0}, 38, 40 }, /* xpv_list[9]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[10]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[11]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[12]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[13]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[14]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[15]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[16]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[17]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[18]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[19]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[20]  */
	{ Nullhv, {0}, 37, 40 }, /* xpv_list[21]  */
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
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[40]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[41]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[42]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[43]  */
	{ Nullhv, {0}, 36, 40 }, /* xpv_list[44]  */
	{ Nullhv, {0}, 30, 32 }, /* xpv_list[45]  */
	{ Nullhv, {0}, 1, 8 }, /* xpv_list[46]  */
};

Static XPVAV xpvav_list[4] = {
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[0]  */
	{ Nullhv, {0}, -1, -1, 0 }, /* xpvav_list[1]  */
	{ Nullhv, {0}, 27, 27, 0 }, /* xpvav_list[2]  */
	{ Nullhv, {0}, 46, 46, 0 }, /* xpvav_list[3]  */
};

Static XPVHV xpvhv_list[1] = {
	{ Nullhv, {0}, 31, 0 }, /* xpvhv_list[0]  */
};

Static MyPADNAME padname_list[1] = {
	{ NULL, (HV*)Nullsv, {(HV*)Nullsv}, 0, 0, 0xffffff43, 0, 0, 0x0, 0 }, /* padname_list[0]  */
};

Static PADNAMELIST padnamelist_list[1] = {
	{ 0, NULL, 0, 0, 2 /* +1 */ }, /* padnamelist_list[0]  */
};

Static XPVMG xpvmg_list[2] = {
	{ Nullhv, {0}, 16, 24, {0}, {0.00} }, /* xpvmg_list[0]  */
	{ Nullhv, {0}, 1, 2, {0}, {0.00} }, /* xpvmg_list[1]  */
};

Static XPVIO xpvio_list[1] = {
	{ Nullhv,{0},0,0,{0},0,{0},0,60,60,NULL,Nullgv,NULL,Nullgv,NULL,Nullgv,'>',0x0 }, /* xpvio_list[0]  */
};

Static SV sv_list[78] = {
	{ 0, 78, SVTYPEMASK|0x01000000, {0} }, /* sv_list[0]  */
	{ &xpvav_list[0], 1, 0x4000000b, {0} }, /* sv_list[1]  */
	{ &xpvav_list[1], 1, 0x4000000b, {0} }, /* sv_list[2]  */
	{ &xpvio_list[0], 2, 0x10000f, {0} }, /* sv_list[3]  */
	{ &xpvmg_list[0], 1, 0x10604407, {.svu_pv=(char*)pv0} }, /* sv_list[4]  */
	{ &xpvmg_list[1], 1, 0x604407, {.svu_pv=(char*)pv1} }, /* sv_list[5]  */
	{ &xpvav_list[2], 1, 0x4000000b, {0} }, /* sv_list[6]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[7]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[8]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[9]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[10]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[11]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[12]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[13]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[14]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[15]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[16]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[17]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[18]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[19]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[20]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[21]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[22]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[23]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[24]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[25]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[26]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[27]  */
	{ 0, 1, 0x0, {0} }, /* sv_list[28]  */
	{ &xpvhv_list[0], 1, 0x2200000c, {0} }, /* sv_list[29]  */
	{ &xpvav_list[3], 1, 0x4000000b, {0} }, /* sv_list[30]  */
	{ &xpv_list[0], 1, 0x4403, {0} }, /* sv_list[31]  */
	{ &xpv_list[1], 1, 0x4403, {0} }, /* sv_list[32]  */
	{ &xpv_list[2], 1, 0x4403, {0} }, /* sv_list[33]  */
	{ &xpv_list[3], 1, 0x4403, {0} }, /* sv_list[34]  */
	{ &xpv_list[4], 1, 0x4403, {0} }, /* sv_list[35]  */
	{ &xpv_list[5], 1, 0x4403, {0} }, /* sv_list[36]  */
	{ &xpv_list[6], 1, 0x4403, {0} }, /* sv_list[37]  */
	{ &xpv_list[7], 1, 0x4403, {0} }, /* sv_list[38]  */
	{ &xpv_list[8], 1, 0x4403, {0} }, /* sv_list[39]  */
	{ &xpv_list[9], 1, 0x4403, {0} }, /* sv_list[40]  */
	{ &xpv_list[10], 1, 0x4403, {0} }, /* sv_list[41]  */
	{ &xpv_list[11], 1, 0x4403, {0} }, /* sv_list[42]  */
	{ &xpv_list[12], 1, 0x4403, {0} }, /* sv_list[43]  */
	{ &xpv_list[13], 1, 0x4403, {0} }, /* sv_list[44]  */
	{ &xpv_list[14], 1, 0x4403, {0} }, /* sv_list[45]  */
	{ &xpv_list[15], 1, 0x4403, {0} }, /* sv_list[46]  */
	{ &xpv_list[16], 1, 0x4403, {0} }, /* sv_list[47]  */
	{ &xpv_list[17], 1, 0x4403, {0} }, /* sv_list[48]  */
	{ &xpv_list[18], 1, 0x4403, {0} }, /* sv_list[49]  */
	{ &xpv_list[19], 1, 0x4403, {0} }, /* sv_list[50]  */
	{ &xpv_list[20], 1, 0x4403, {0} }, /* sv_list[51]  */
	{ &xpv_list[21], 1, 0x4403, {0} }, /* sv_list[52]  */
	{ &xpv_list[22], 1, 0x4403, {0} }, /* sv_list[53]  */
	{ &xpv_list[23], 1, 0x4403, {0} }, /* sv_list[54]  */
	{ &xpv_list[24], 1, 0x4403, {0} }, /* sv_list[55]  */
	{ &xpv_list[25], 1, 0x4403, {0} }, /* sv_list[56]  */
	{ &xpv_list[26], 1, 0x4403, {0} }, /* sv_list[57]  */
	{ &xpv_list[27], 1, 0x4403, {0} }, /* sv_list[58]  */
	{ &xpv_list[28], 1, 0x4403, {0} }, /* sv_list[59]  */
	{ &xpv_list[29], 1, 0x4403, {0} }, /* sv_list[60]  */
	{ &xpv_list[30], 1, 0x4403, {0} }, /* sv_list[61]  */
	{ &xpv_list[31], 1, 0x4403, {0} }, /* sv_list[62]  */
	{ &xpv_list[32], 1, 0x4403, {0} }, /* sv_list[63]  */
	{ &xpv_list[33], 1, 0x4403, {0} }, /* sv_list[64]  */
	{ &xpv_list[34], 1, 0x4403, {0} }, /* sv_list[65]  */
	{ &xpv_list[35], 1, 0x4403, {0} }, /* sv_list[66]  */
	{ &xpv_list[36], 1, 0x4403, {0} }, /* sv_list[67]  */
	{ &xpv_list[37], 1, 0x4403, {0} }, /* sv_list[68]  */
	{ &xpv_list[38], 1, 0x4403, {0} }, /* sv_list[69]  */
	{ &xpv_list[39], 1, 0x4403, {0} }, /* sv_list[70]  */
	{ &xpv_list[40], 1, 0x4403, {0} }, /* sv_list[71]  */
	{ &xpv_list[41], 1, 0x4403, {0} }, /* sv_list[72]  */
	{ &xpv_list[42], 1, 0x4403, {0} }, /* sv_list[73]  */
	{ &xpv_list[43], 1, 0x4403, {0} }, /* sv_list[74]  */
	{ &xpv_list[44], 1, 0x4403, {0} }, /* sv_list[75]  */
	{ &xpv_list[45], 1, 0x4403, {0} }, /* sv_list[76]  */
	{ &xpv_list[46], 1, 0x4403, {0} }, /* sv_list[77]  */
};

static void perl_init0(pTHX) /* fixup_ppaddr */
{
	register int i;
};

static void perl_init_aaaa(pTHX)
{
	
	/* done main optree, extra subs which might be unused */
	gv_list[0] = gv_fetchpvn_flags("x", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[0]) = 0x8009;
	GvFLAGS(gv_list[0]) = 0x2; 
	GvLINE(gv_list[0]) = 20;
	SvREFCNT(gv_list[0]) = 2;
	GvREFCNT(gv_list[0]) += 1;
	GvAV(gv_list[0]) = (AV*)&sv_list[1];
	hek0 = share_hek("t/CORE/op/push.t", 16, 0);
	GvFILE_HEK(gv_list[0]) = hek0;
	
	gv_list[1] = gv_fetchpvn_flags("tests", 5, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[1]) = 0x8009;
	GvFLAGS(gv_list[1]) = 0x2; 
	GvLINE(gv_list[1]) = 3;
	SvREFCNT(gv_list[1]) = 2;
	GvREFCNT(gv_list[1]) += 1;
	GvAV(gv_list[1]) = (AV*)&sv_list[2];
	GvFILE_HEK(gv_list[1]) = share_hek_hek(hek0);
	
	gv_list[2] = gv_fetchpv("stdout", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[2]) = 2;
	gv_list[3] = gv_fetchpv("stdin", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[3]) = 2;
	gv_list[4] = gv_fetchpv("stderr", GV_NOTQUAL, SVt_PVGV);
	SvREFCNT(gv_list[4]) = 2;
	SvFLAGS(PL_defgv) = 0x8009;
	GvFLAGS(PL_defgv) = 0x2; 
	GvLINE(PL_defgv) = 0;
	SvREFCNT(PL_defgv) = 511;
	GvREFCNT(PL_defgv) += 1;
	gv_list[6] = gv_fetchpvn_flags("STDOUT", 6, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[6]) = 0x8009;
	GvFLAGS(gv_list[6]) = 0x2; 
	GvLINE(gv_list[6]) = 0;
	SvREFCNT(gv_list[6]) = 23;
	GvREFCNT(gv_list[6]) += 1;
	GvFILE_HEK(gv_list[6]) = share_hek_hek(hek0);
	IoIFP((IO*)&sv_list[3]) = IoOFP((IO*)&sv_list[3]) = PerlIO_stdout();
	GvIOp(gv_list[6]) = (IO*)&sv_list[3];
	
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
	gv_list[9] = gv_fetchpvn_flags("2", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[9]) = 0x8009;
	GvFLAGS(gv_list[9]) = 0x2; 
	GvLINE(gv_list[9]) = 363;
	SvREFCNT(gv_list[9]) = 9;
	GvREFCNT(gv_list[9]) += 1;
	sv_list[4].sv_u.svu_pv = savepvn("t/CORE/op/push.c\000\001", 18);
	hv0 = gv_stashpvn("main::2", 7, GV_ADD);
	sv_magic((SV*)&sv_list[4], (SV*)gv_list[9], '\000', 0, 2);
	GvSVn(gv_list[9]) = (SV*)&sv_list[4];
	hek1 = share_hek("/usr/local/lib/perl5/5.22.0/Carp.pm", 35, 0);
	GvFILE_HEK(gv_list[9]) = hek1;
	
	gv_list[10] = gv_fetchpvn_flags("1", 1, GV_NOTQUAL|GV_ADD, SVt_PV);
	SvFLAGS(gv_list[10]) = 0x8009;
	GvFLAGS(gv_list[10]) = 0x2; 
	GvLINE(gv_list[10]) = 102;
	SvREFCNT(gv_list[10]) = 48;
	GvREFCNT(gv_list[10]) += 1;
	sv_list[5].sv_u.svu_pv = savepvn("o", 1);
	sv_magic((SV*)&sv_list[5], (SV*)gv_list[10], '\000', 0, 1);
	GvSVn(gv_list[10]) = (SV*)&sv_list[5];
	hek2 = share_hek("/usr/local/lib/perl5/5.22.0/darwin/B.pm", 39, 0);
	GvFILE_HEK(gv_list[10]) = hek2;
	
	gv_list[11] = gv_fetchpv("0", GV_NOTQUAL, SVt_PV);
	SvREFCNT(gv_list[11]) = 3;
	/* done extras */
	/* honor -w */
	PL_dowarn = ( 0 ) ? G_WARN_ON : G_WARN_OFF;
	/* END block */
	/* startpoints */
	PL_main_root = (void*)Nullsv;
	PL_main_start = (void*)Nullsv;
	PL_initav = (AV*)Nullsv;
	PL_endav = (AV*)Nullsv;
	/* curpad names */
	{
		PADNAME **svp;
		PADNAMELIST *padnl = &padnamelist_list[0];
		Newxz(svp, 1, PADNAME *);
		PadnamelistARRAY(padnl) = svp;
		*svp++ = (PADNAME*)&padname_list[0];
	}
	/* curpad syms */
	{
		SV **svp;
		AV *av = (AV*)&sv_list[6];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(28 * sizeof(SV*));
	#else
		svp = (SV**)malloc(28 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		*svp++ = (SV*)Nullsv;
		for (gcount=7; gcount<11; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
		for (gcount=11; gcount<20; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)Nullsv;
		for (gcount=20; gcount<24; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
		*svp++ = (SV*)Nullsv;
		*svp++ = (SV*)Nullsv;
		for (gcount=24; gcount<29; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	/* %INC */
	{	HE **a; struct xpvhv_aux *aux;
	#ifdef PERL_USE_LARGE_HV_ALLOC
		Newxz(a, PERL_HV_ARRAY_ALLOC_BYTES(32) + sizeof(struct xpvhv_aux), HE*);
	#else
		Newxz(a, 32 + sizeof(struct xpvhv_aux), HE*);
	#endif
		HvARRAY(&sv_list[29]) = a;
		HvRITER_set(&sv_list[29], -1);
	}
	HvTOTALKEYS((HV*)&sv_list[29]) = 0;
	/* @INC */
	sv_list[31].sv_u.svu_pv = savepvn("blib/arch", 9);
	sv_list[32].sv_u.svu_pv = savepvn("blib/lib", 8);
	sv_list[33].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/lib", 31);
	sv_list[34].sv_u.svu_pv = savepvn("/Users/rurban/Perl/B-C/blib/arch", 32);
	sv_list[35].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0/darwin", 44);
	sv_list[36].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.22.0", 37);
	sv_list[37].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0/darwin", 34);
	sv_list[38].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/5.22.0", 27);
	sv_list[39].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.11", 38);
	sv_list[40].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.10", 38);
	sv_list[41].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.9", 37);
	sv_list[42].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.8", 37);
	sv_list[43].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.5", 37);
	sv_list[44].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.4", 37);
	sv_list[45].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.3", 37);
	sv_list[46].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.2", 37);
	sv_list[47].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.21.1", 37);
	sv_list[48].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.2", 37);
	sv_list[49].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.1", 37);
	sv_list[50].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.20.0", 37);
	sv_list[51].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.9", 37);
	sv_list[52].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.8", 37);
	sv_list[53].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.6", 37);
	sv_list[54].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.4", 37);
	sv_list[55].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.19.2", 37);
	sv_list[56].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.4", 37);
	sv_list[57].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.2", 37);
	sv_list[58].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.1", 37);
	sv_list[59].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.18.0", 37);
	sv_list[60].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.3", 37);
	sv_list[61].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.16.1", 37);
	sv_list[62].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.15.8", 37);
	sv_list[63].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.4", 37);
	sv_list[64].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.3", 37);
	sv_list[65].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.2", 37);
	sv_list[66].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.1", 37);
	sv_list[67].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.14.0", 37);
	sv_list[68].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.5", 37);
	sv_list[69].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.12.4", 37);
	sv_list[70].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.10.1", 37);
	sv_list[71].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.9", 36);
	sv_list[72].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.8", 36);
	sv_list[73].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.5", 36);
	sv_list[74].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.8.4", 36);
	sv_list[75].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl/5.6.2", 36);
	sv_list[76].sv_u.svu_pv = savepvn("/usr/local/lib/perl5/site_perl", 30);
	sv_list[77].sv_u.svu_pv = savepvn(".", 1);
	{
		SV **svp;
		AV *av = (AV*)&sv_list[30];
		register int gcount;
	#ifdef PERL_TRACK_MEMPOOL
		svp = (SV**)Perl_safesysmalloc(47 * sizeof(SV*));
	#else
		svp = (SV**)malloc(47 * sizeof(SV*));
	#endif
		AvALLOC(av) = svp;
		AvARRAY(av) = svp;
		for (gcount=31; gcount<78; gcount++) { *svp++ = (SV*)&sv_list[gcount]; };
	}
	GvHV(PL_incgv) = (HV*)&sv_list[29];
	GvAV(PL_incgv) = (AV*)&sv_list[30];
	PL_curpad = AvARRAY((AV*)&sv_list[6]);
	PL_comppad = (AV*)&sv_list[6];
	PL_stack_sp = PL_stack_base;
	PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = &padnamelist_list[0]; /* namepad */
	PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)(AV*)&sv_list[6]; /* curpad */
	
}
static int perl_init(pTHX)
{
	perl_init0(aTHX);
	perl_init_aaaa(aTHX);
	return 0;
}
static void perl_init2_aaaa(pTHX)
{
	Gv_AMG(hv0); /* init AMG overload for main::2 */
	
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
