#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifndef PM_GETRE
# if defined(USE_ITHREADS)
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

typedef struct magic  *B__MAGIC;
typedef PADNAME       *B__PADNAME;
typedef PADLIST       *B__PADLIST;
typedef PADNAMELIST   *B__PADNAMELIST;
typedef struct p5rx  *B__REGEXP;
typedef COP  *B__COP;
typedef OP   *B__OP;
typedef HV   *B__HV;

STATIC U32 a_hash = 0;

typedef struct {
  U32 bits;
  IV  require_tag;
} a_hint_t;

static const char* const svclassnames[] = {
    "B::NULL",
    "B::IV",
    "B::NV",
    "B::PV",
    "B::INVLIST",
    "B::PVIV",
    "B::PVNV",
    "B::PVMG",
    "B::REGEXP",
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

static int
my_runops(pTHX)
{
    HV* regexp_hv = get_hv( "B::C::Regexp", GV_ADD );
    SV* key = newSViv( 0 );
    int type;

    DEBUG_l(Perl_deb(aTHX_ "Entering new RUNOPS level (B::C)\n"));
    do {

	if (PL_debug) {
	    if (PL_watchaddr && (*PL_watchaddr != PL_watchok))
		PerlIO_printf(Perl_debug_log,
			      "WARNING: %"UVxf" changed from %"UVxf" to %"UVxf"\n",
			      PTR2UV(PL_watchaddr), PTR2UV(PL_watchok),
			      PTR2UV(*PL_watchaddr));
#if defined(DEBUGGING) \
   && !(defined(_WIN32) || (defined(__CYGWIN__) && (__GNUC__ > 3)) || defined(AIX))
	    if (DEBUG_s_TEST_) debstack();
	    if (DEBUG_t_TEST_) debop(PL_op);
#endif
	}

        /* Need to store the rx all for QR PMOPs in a global %Regexp hash. MATCH once also */
        type = PL_op->op_type;
        if (type == OP_QR
        || (type == OP_MATCH
            && PmopSTASH((PMOP*)PL_op)
            ))
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

#if defined(USE_ITHREADS)
            op->op_pmoffset = 0;
#else
            op->op_pmregexp = 0;
#endif

            sv_setiv( key, PTR2IV( rx ) );
            sv_setref_iv( rv, "B::PMOP", PTR2IV( op ) );
#if defined(DEBUGGING)
	    if (DEBUG_D_TEST_) fprintf(stderr, "pmop %p => rx %s %p 0x%x %s\n",
                                       op, PL_op_name[type], rx, (unsigned)op->op_pmflags,
                                       RX_WRAPPED(rx));
#endif
            hv_store_ent( regexp_hv, key, rv, 0 );
        }
    } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));

    SvREFCNT_dec( key );

    TAINT_NOT;
    return 0;
}

MODULE = B__MAGIC	PACKAGE = B::MAGIC

MODULE = B      PACKAGE = B::HV

# returns a single or multiple ENAME(s), since 5.14
void
ENAMES(hv)
    B::HV hv
PPCODE:
    if (SvOOK(hv)) {
      if (HvENAME_HEK(hv)) {
        I32 i = 0;
        const I32 count = HvAUX(hv)->xhv_name_count;
        if (count) {
          HEK** names = HvAUX(hv)->xhv_name_u.xhvnameu_names;
          HEK *const *hekp = names + (count < 0 ? 1 : 0);
          HEK *const *const endp = names + (count < 0 ? -count : count);
          while (hekp < endp) {
            assert(*hekp);
            PUSHs(newSVpvn_flags(HEK_KEY(*hekp), HEK_LEN(*hekp),
                                 HEK_UTF8(*hekp) ? SVf_UTF8|SVs_TEMP : SVs_TEMP));
            ++hekp;
            i++;
          }
          XSRETURN(i);
        }
        else {
          HEK *const hek = HvENAME_HEK_NN(hv);
          ST(0) = newSVpvn_flags(HEK_KEY(hek), HEK_LEN(hek),
                                 HEK_UTF8(hek) ? SVf_UTF8|SVs_TEMP : SVs_TEMP);
          XSRETURN(1);
        }
      }
    }
    XSRETURN_UNDEF;

I32
name_count(hv)
    B::HV hv
PPCODE:
    PERL_UNUSED_VAR(RETVAL);
    if (SvOOK(hv))
      PUSHi(HvAUX(hv)->xhv_name_count);
    else
      PUSHi(0);

MODULE = B	PACKAGE = B::UNOP_AUX

SV*
aux(o)
          B::OP o
CODE:
  {
    UNOP_AUX_item *items = cUNOP_AUXo->op_aux;
    UV len = items[-1].uv;
    RETVAL = newSVpvn_flags((char*)&items[-1], (1+len) * sizeof(UNOP_AUX_item), 0);
  }
OUTPUT:
    RETVAL

# Return the contents of the op_aux array as a list of IV/SV/GV/PADOFFSET objects.
# This version here returns the padoffset of SV/GV under ithreads, and not the
# SV/GV itself. It also uses simplified mPUSH macros.
# The design of the upstream aux_list method deviates significantly from proper B design.

void
aux_list_thr(o)
	B::OP  o
    PPCODE:
        PERL_UNUSED_VAR(cv); /* not needed on unthreaded builds */
        switch (o->op_type) {
        default:
            XSRETURN(0); /* by default, an empty list */

        case OP_MULTIDEREF:
#ifdef USE_ITHREADS
#  define PUSH_SV(item) mPUSHu((item)->pad_offset)
#else
#  define PUSH_SV(item) PUSHs(make_sv_object(aTHX_ (item)->sv))
#endif
            {
                UNOP_AUX_item *items = cUNOP_AUXo->op_aux;
                UV actions = items->uv;
                UV len = items[-1].uv;
                bool last = 0;
                bool is_hash = FALSE;

                assert(len <= SSize_t_MAX);
                EXTEND(SP, (SSize_t)len);
                mPUSHu(actions);

                while (!last) {
                    switch (actions & MDEREF_ACTION_MASK) {

                    case MDEREF_reload:
                        actions = (++items)->uv;
                        mPUSHu(actions);
                        continue;
                        NOT_REACHED; /* NOTREACHED */

                    case MDEREF_HV_padhv_helem:
                        is_hash = TRUE;
                        /* FALLTHROUGH */
                    case MDEREF_AV_padav_aelem:
                        mPUSHu((++items)->pad_offset);
                        goto do_elem;
                        NOT_REACHED; /* NOTREACHED */

                    case MDEREF_HV_gvhv_helem:
                        is_hash = TRUE;
                        /* FALLTHROUGH */
                    case MDEREF_AV_gvav_aelem:
                        PUSH_SV(++items);
                        goto do_elem;
                        NOT_REACHED; /* NOTREACHED */

                    case MDEREF_HV_gvsv_vivify_rv2hv_helem:
                        is_hash = TRUE;
                        /* FALLTHROUGH */
                    case MDEREF_AV_gvsv_vivify_rv2av_aelem:
                        PUSH_SV(++items);
                        goto do_vivify_rv2xv_elem;
                        NOT_REACHED; /* NOTREACHED */

                    case MDEREF_HV_padsv_vivify_rv2hv_helem:
                        is_hash = TRUE;
                        /* FALLTHROUGH */
                    case MDEREF_AV_padsv_vivify_rv2av_aelem:
                        mPUSHu((++items)->pad_offset);
                        goto do_vivify_rv2xv_elem;
                        NOT_REACHED; /* NOTREACHED */

                    case MDEREF_HV_pop_rv2hv_helem:
                    case MDEREF_HV_vivify_rv2hv_helem:
                        is_hash = TRUE;
                        /* FALLTHROUGH */
                    do_vivify_rv2xv_elem:
                    case MDEREF_AV_pop_rv2av_aelem:
                    case MDEREF_AV_vivify_rv2av_aelem:
                    do_elem:
                        switch (actions & MDEREF_INDEX_MASK) {
                        case MDEREF_INDEX_none:
                            last = 1;
                            break;
                        case MDEREF_INDEX_const:
                            if (is_hash)
                              PUSH_SV(++items);
                            else
                              mPUSHi((++items)->iv);
                            break;
                        case MDEREF_INDEX_padsv:
                            mPUSHu((++items)->pad_offset);
                            break;
                        case MDEREF_INDEX_gvsv:
                            PUSH_SV(++items);
                            break;
                        }
                        if (actions & MDEREF_FLAG_last)
                            last = 1;
                        is_hash = FALSE;

                        break;
                    } /* switch */

                    actions >>= MDEREF_SHIFT;
                } /* while */
                XSRETURN(len);

            } /* OP_MULTIDEREF */
#if PERL_VERSION > 23 && defined(OP_SIGNATURE) /* cperl */
        case OP_SIGNATURE:
            {
                UNOP_AUX_item *items = cUNOP_AUXo->op_aux;
                UV len = items[-1].uv;
                UV actions = items[1].uv;

                assert(len <= SSize_t_MAX);
                EXTEND(SP, (SSize_t)len);
                mPUSHu(items[0].uv);
                mPUSHu(actions);
                items++;

                while (1) {
                    switch (actions & SIGNATURE_ACTION_MASK) {

                    case SIGNATURE_reload:
                        actions = (++items)->uv;
                        mPUSHu(actions);
                        continue;

                    case SIGNATURE_end:
                        goto finish;

                    case SIGNATURE_padintro:
                        mPUSHu((++items)->uv);
                        break;

                    case SIGNATURE_arg:
                    case SIGNATURE_arg_default_none:
                    case SIGNATURE_arg_default_undef:
                    case SIGNATURE_arg_default_0:
                    case SIGNATURE_arg_default_1:
                    case SIGNATURE_arg_default_op:
                    case SIGNATURE_array:
                    case SIGNATURE_hash:
                        break;

                    case SIGNATURE_arg_default_iv:
                        mPUSHu((++items)->iv);
                        break;

                    case SIGNATURE_arg_default_const:
                        PUSH_SV(++items);
                        break;

                    case SIGNATURE_arg_default_padsv:
                        mPUSHu((++items)->pad_offset);
                        break;

                    case SIGNATURE_arg_default_gvsv:
                        PUSH_SV(++items);
                        break;

                    } /* switch */

                    actions >>= SIGNATURE_SHIFT;
                } /* while */
              finish:
                XSRETURN(len);

            } /* OP_SIGNATURE */
#endif
        } /* switch */

MODULE = B	PACKAGE = B::PADNAME	PREFIX = Padname

int
PadnameGEN(padn)
       B::PADNAME      padn
    CODE:
        RETVAL = padn->xpadn_gen;
    OUTPUT:
       RETVAL

MODULE = B     PACKAGE = B::PADLIST    PREFIX = Padlist

U32
PadlistID(padlist)
       B::PADLIST      padlist
    ALIAS: B::PADLIST::OUTID = 1
    CODE:
        RETVAL = ix ? padlist->xpadl_outid : padlist->xpadl_id;
    OUTPUT:
       RETVAL

MODULE = B     PACKAGE = B::PADNAMELIST        PREFIX = Padnamelist

size_t
PadnamelistMAXNAMED(padnl)
       B::PADNAMELIST  padnl

MODULE = B	PACKAGE = B::REGEXP	PREFIX = RX_

U32
RX_EXTFLAGS(rx)
	  B::REGEXP rx

MODULE = B	PACKAGE = B::COP	PREFIX = COP_

#if defined(USE_ITHREADS) && defined(CopSTASH_flags)

#define COP_stashflags(o)	CopSTASH_flags(o)

U32
COP_stashflags(o)
	B::COP	o

#endif

#ifdef CopLABEL_len_flags

SV*
COP_label(o)
    B::OP  o
PPCODE:
    {
      STRLEN len;
      U32 flags;
      const char *pv = CopLABEL_len_flags(cCOPo, &len, &flags);
      PERL_UNUSED_VAR(RETVAL);
      ST(0) = pv ? sv_2mortal(newSVpvn_flags(pv, len, flags))
                 : &PL_sv_undef;
    }
    XSRETURN(1);

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
	/*char *package = CopSTASHPV(cop);*/
#ifdef cop_hints_fetch_pvn
	hint = cop_hints_fetch_pvn(cop, "autovivification", strlen("autovivification"), a_hash, 0);
#else
	hint = Perl_refcounted_he_fetch(aTHX_ cop->cop_hints_hash,
					NULL, "autovivification", strlen("autovivification"), 0, a_hash);
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

MODULE = B__C          PACKAGE = B::C

SV*
get_linear_isa(classname)
    SV* classname;
CODE:
  {
    HV *class_stash = gv_stashsv(classname, 0);

    if (!class_stash) {
        /* No stash exists yet, give them just the classname */
        AV* isalin = newAV();
        av_push(isalin, newSVsv(classname));
        RETVAL = newRV(MUTABLE_SV(isalin));
    }
    else { /* just dfs */
      RETVAL = newRV(MUTABLE_SV(Perl_mro_get_linear_isa(aTHX_ class_stash)));
    }
  }
OUTPUT:
    RETVAL

BOOT:
{
    MY_CXT_INIT;
    PL_runops = my_runops;
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
