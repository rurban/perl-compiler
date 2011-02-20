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

typedef struct magic* B__MAGIC;

static int
my_runops(pTHX)
{
    HV* regexp_hv = get_hv( "B::C::REGEXP", 0 );
    SV* key = newSViv( 0 );

    do {
	PERL_ASYNC_CHECK();

        if( PL_op->op_type == OP_QR ) {
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

MODULE=B__C 	PACKAGE=B::C

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
    PL_runops = my_runops;
