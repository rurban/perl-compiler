#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifndef PM_GETRE
# if defined(USE_ITHREADS) && (PERL_VERSION > 8)
#  define PM_GETRE(o)     (INT2PTR(REGEXP*,SvIVX(PL_regex_pad[(o)->op_pmoffset])))
# else
#  define PM_GETRE(o)     ((o)->op_pmregexp)
# endif
#endif
/* hack for 5.6.2: just want to know if PMf_ONCE or 0 */
#ifndef PmopSTASHPV
# define PmopSTASHPV(o) ((o)->op_pmflags & PMf_ONCE)
#endif
#ifndef RX_EXTFLAGS
# define RX_EXTFLAGS(prog) ((prog)->extflags)
#endif

#if PERL_VERSION > 17 && (PERL_VERSION < 19 || (PERL_VERSION == 19 && PERL_SUBVERSION < 4))
#define need_op_slabbed
#endif
#if PERL_VERSION == 19 && (PERL_SUBVERSION > 2 && PERL_SUBVERSION <= 4)
#define need_op_folded
#endif

typedef struct magic  *B__MAGIC;
#if PERL_VERSION >= 11
typedef struct p5rx  *B__REGEXP;
#endif
typedef COP  *B__COP;
typedef OP   *B__OP;
typedef HV   *B__HV;

STATIC U32 a_hash = 0;

typedef struct {
  U32 bits;
  IV  require_tag;
} a_hint_t;

#if PERL_VERSION >= 10

static const char* const svclassnames[] = {
    "B::NULL",
#if PERL_VERSION < 19
    "B::BIND",
#endif
    "B::IV",
    "B::NV",
#if PERL_VERSION <= 10
    "B::RV",
#endif
    "B::PV",
#if PERL_VERSION >= 19
    "B::INVLIST",
#endif
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
#if PERL_VERSION >= 11
    "B::REGEXP",
#endif
    "B::GV",
    "B::PVLV",
    "B::AV",
    "B::HV",
    "B::CV",
    "B::FM",
    "B::IO",
};

#define MY_CXT_KEY "B::C::_guts" XS_VERSION

typedef struct {
    int		x_walkoptree_debug;	/* Flag for walkoptree debug hook */
    SV *	x_specialsv_list[7];
} my_cxt_t;

START_MY_CXT

#define walkoptree_debug	(MY_CXT.x_walkoptree_debug)
#define specialsv_list		(MY_CXT.x_specialsv_list)

static SV *
make_sv_object(pTHX_ SV *sv)
{
    SV *const arg = sv_newmortal();
    const char *type = 0;
    IV iv;
    dMY_CXT;

    for (iv = 0; iv < (IV)(sizeof(specialsv_list)/sizeof(SV*)); iv++) {
	if (sv == specialsv_list[iv]) {
	    type = "B::SPECIAL";
	    break;
	}
    }
    if (!type) {
	type = svclassnames[SvTYPE(sv)];
	iv = PTR2IV(sv);
    }
    sv_setiv(newSVrv(arg, type), iv);
    return arg;
}

#endif

static int
my_runops(pTHX)
{
    HV* regexp_hv = get_hv( "B::C::Regexp", GV_ADD );
    SV* key = newSViv( 0 );

    DEBUG_l(Perl_deb(aTHX_ "Entering new RUNOPS level (B::C)\n"));
    do {
#if (PERL_VERSION < 13) || ((PERL_VERSION == 13) && (PERL_SUBVERSION < 2))
	PERL_ASYNC_CHECK();
#endif

	if (PL_debug) {
	    if (PL_watchaddr && (*PL_watchaddr != PL_watchok))
		PerlIO_printf(Perl_debug_log,
			      "WARNING: %"UVxf" changed from %"UVxf" to %"UVxf"\n",
			      PTR2UV(PL_watchaddr), PTR2UV(PL_watchok),
			      PTR2UV(*PL_watchaddr));
#if defined(DEBUGGING) \
   && !(defined(_WIN32) || (defined(__CYGWIN__) && (__GNUC__ > 3)) || defined(AIX))
# if (PERL_VERSION > 7)
	    if (DEBUG_s_TEST_) debstack();
	    if (DEBUG_t_TEST_) debop(PL_op);
# else
	    DEBUG_s(debstack());
	    DEBUG_t(debop(PL_op));
# endif
#endif
	}

        /* Need to store the rx all for QR PMOPs in a global %Regexp hash. MATCH once also */
#if 1
        if ((PL_op->op_type == OP_QR)
        || ((PL_op->op_type == OP_MATCH) && PmopSTASHPV((PMOP*)PL_op)))
#else
        if ((PL_op->op_type == OP_QR)
         || (PL_op->op_type == OP_MATCH)
         || (PL_op->op_type == OP_PUSHRE)
         || (PL_op->op_type == OP_SUBST))
#endif
        {
            PMOP* op;
            REGEXP* rx = PM_GETRE( (PMOP*)PL_op );
            SV* rv = newSViv( 0 );

            New(0, op, 1, PMOP );
            Copy( PL_op, op, 1, PMOP );
            /* we need just the flags */
            op->op_next = NULL;
            op->op_sibling = NULL;
            op->op_first = NULL;
            op->op_last = NULL;

#if PERL_VERSION < 10
            op->op_pmreplroot = NULL;
            op->op_pmreplstart = NULL;
            op->op_pmnext = NULL;
#endif
#if defined(USE_ITHREADS) && (PERL_VERSION > 7)
            op->op_pmoffset = 0;
#else
            op->op_pmregexp = 0;
#endif

            sv_setiv( key, PTR2IV( rx ) );
            sv_setref_iv( rv, "B::PMOP", PTR2IV( op ) );
#if defined(DEBUGGING) && (PERL_VERSION > 7)
	    if (DEBUG_D_TEST_) fprintf(stderr, "pmop %p => rx %p\n", op, rx);
#endif
            hv_store_ent( regexp_hv, key, rv, 0 );
        }
    } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));

    SvREFCNT_dec( key );

    TAINT_NOT;
    return 0;
}

MODULE = B__MAGIC	PACKAGE = B::MAGIC

#if PERL_VERSION < 7

SV*
precomp(mg)
        B::MAGIC        mg
    CODE:
        if (mg->mg_type == 'r') {
            REGEXP* rx = (REGEXP*)mg->mg_obj;
            RETVAL = Nullsv;
            if (rx)
                RETVAL = newSVpvn( rx->precomp, rx->prelen );
        }
        else {
            croak( "precomp is only meaningful on r-magic" );
        }
    OUTPUT:
        RETVAL

#endif

MODULE = B	PACKAGE = B::PMOP

#if defined(RX_UTF8) && PERL_VERSION < 20

SV*
precomp(o)
          B::OP o
PPCODE:
  {
    if (SvROK(ST(0))) {
      IV tmp = SvIV((SV*)SvRV(ST(0)));
      o = INT2PTR(B__OP,tmp);
    }
    else
      croak("precomp(o) argument is not a reference");
    if (o) {
      REGEXP *rx = PM_GETRE(cPMOPo);
      if (!rx)
        XSRETURN_UNDEF;
      ST(0) = sv_2mortal(newSVpvn_flags(RX_PRECOMP(rx), RX_PRELEN(rx), RX_UTF8(rx) ? SVf_UTF8 : 0));
      XSRETURN(1);
    } else {
      XSRETURN_UNDEF;
    }
  }

#endif

MODULE = B	PACKAGE = B::UNOP_AUX

SV*
aux(o)
          B::OP o
CODE:
    UNOP_AUX_item *items = cUNOP_AUXo->op_aux;
    UV len = items[-1].uv;
    RETVAL = newSVpvn_flags((char*)&items[-1], (1+len) * sizeof(UNOP_AUX_item), 0);
OUTPUT:
    RETVAL
          
MODULE = B	PACKAGE = B::REGEXP	PREFIX = RX_

#if PERL_VERSION > 10

U32
RX_EXTFLAGS(rx)
	  B::REGEXP rx

#endif

MODULE = B	PACKAGE = B::COP	PREFIX = COP_

#if (PERL_VERSION >= 15) && defined(USE_ITHREADS) && defined(CopSTASH_flags)

#define COP_stashflags(o)	CopSTASH_flags(o)

U32
COP_stashflags(o)
	B::COP	o

#endif

MODULE = B__CC	PACKAGE = B::CC

PROTOTYPES: DISABLE

# Perl_ck_null is not exported on Windows, so disable autovivification optimizations there

U32
_autovivification(cop)
	B::COP	cop
CODE:
    {
      SV *hint;
      IV h;

      RETVAL = 1;
      if (PL_check[OP_PADSV] != PL_check[0]) {
	char *package = CopSTASHPV(cop);
#ifdef cop_hints_fetch_pvn
	hint = cop_hints_fetch_pvn(cop, "autovivification", strlen("autovivification"), a_hash, 0);
#elif PERL_VERSION > 9
	hint = Perl_refcounted_he_fetch(aTHX_ cop->cop_hints_hash,
					NULL, "autovivification", strlen("autovivification"), 0, a_hash);
#else
	SV **val = hv_fetch(GvHV(PL_hintgv), "autovivification", strlen("autovivification"), 0);
	if (!val)
	  return;
	hint = *val;
#endif
	if (!(hint && SvIOK(hint)))
	  return;
	h = SvIVX(hint);
	if (h & 4)  /* A_HINT_FETCH  4 */
	  RETVAL = 0;
      }
    }
OUTPUT:
  RETVAL


MODULE = B__OP	PACKAGE = B::OP		PREFIX = op_

#ifdef need_op_slabbed

I32
op_slabbed(op)
        B::OP        op
    PPCODE:
	PUSHi(op->op_slabbed);

I32
op_savefree(op)
        B::OP        op
    PPCODE:
	PUSHi(op->op_savefree);

I32
op_static(op)
        B::OP        op
    PPCODE:
	PUSHi(op->op_static);

#endif

#ifdef need_op_folded

I32
op_folded(op)
        B::OP        op
    PPCODE:
	PUSHi(op->op_folded);

#endif

MODULE = B	PACKAGE = B::HV		PREFIX = Hv

#if PERL_VERSION >= 10

void
HvARRAY_utf8(hv)
	B::HV	hv
    PPCODE:
	if (HvKEYS(hv) > 0) {
	    HE *he;
	    (void)hv_iterinit(hv);
	    EXTEND(sp, HvKEYS(hv) * 2);
	    while ((he = hv_iternext(hv))) {
                if (HeSVKEY(he)) {
                    mPUSHs(HeSVKEY(he));
                } else if (HeKUTF8(he)) {
                    PUSHs(newSVpvn_flags(HeKEY(he), HeKLEN(he), SVf_UTF8|SVs_TEMP));
                } else {
                    PUSHs(newSVpvn_flags(HeKEY(he), HeKLEN(he), SVs_TEMP));
                }
		PUSHs(make_sv_object(aTHX_ HeVAL(he)));
	    }
	}

#endif

MODULE = B__C	PACKAGE = B::C

PROTOTYPES: DISABLE

#if PERL_VERSION >= 11

CV*
method_cv(meth, packname)
        SV* meth;
	char *packname;
   CODE:
	U32 hash;
    	HV* stash; /* XXX from op before, also on the run-time stack */
        GV* gv;
	hash = SvSHARED_HASH(meth);
        stash = gv_stashpv(packname, TRUE);
	if (hash) {
          const HE* const he = hv_fetch_ent(stash, meth, 0, hash);
          if (he) {
	    gv = MUTABLE_GV(HeVAL(he));
	    if (isGV(gv) && GvCV(gv) &&
		(!GvCVGEN(gv) || GvCVGEN(gv)
                 == (PL_sub_generation + HvMROMETA(stash)->cache_gen)))
              RETVAL = (CV*)MUTABLE_SV(GvCV(gv));
              return;
          }
        }
        /* public API since 5.11 */
	gv = gv_fetchmethod_flags(stash,
			      SvPV_nolen_const(meth),
			      GV_AUTOLOAD | GV_CROAK);
    	assert(gv);
    	RETVAL = isGV(gv) ? (CV*)MUTABLE_SV(GvCV(gv)) : (CV*)MUTABLE_SV(gv);
    OUTPUT:
        RETVAL

#endif

BOOT:
#if PERL_VERSION >= 10
{
    MY_CXT_INIT;
#endif
    PL_runops = my_runops;
#if PERL_VERSION >= 10
    {
      dMY_CXT;
      specialsv_list[0] = Nullsv;
      specialsv_list[1] = &PL_sv_undef;
      specialsv_list[2] = &PL_sv_yes;
      specialsv_list[3] = &PL_sv_no;
      specialsv_list[4] = (SV *) pWARN_ALL;
      specialsv_list[5] = (SV *) pWARN_NONE;
      specialsv_list[6] = (SV *) pWARN_STD;
    }
}
#endif
