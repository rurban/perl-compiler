/* This XS part is unused since B-C-1.18 for all perls > 5.7,
 * but Win32 needs some privatized CORE parts since 5.12
 */

/* CPAN #28912: MSWin32 as only platform does not export PERL_CORE functions,
 * such as Perl_store_cop_label, so re-implement and/or disable features on MSWin32, ...
 * platforms like cygwin using gcc --export-all-symbols are non-strict.
 * TODO: POSIX with export PERL_DL_NONLAZY=1 also fail to link against undefined symbols.
 */
#if (defined(WIN32) && (defined(_MSC_VER) || defined(__MINGW32_VERSION))) || \
    (defined(__CYGWIN__) && (__GNUC__ > 3)) || \
    defined(AIX)
# define DISABLE_PERL_CORE_EXPORTED
#endif


#include <EXTERN.h>
#ifdef DISABLE_PERL_CORE_EXPORTED
# define PERL_CORE
#endif
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

#if PERL_VERSION < 7

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

            op->op_pmreplroot = NULL;
            op->op_pmreplstart = NULL;
            op->op_pmnext = NULL;
            op->op_pmregexp = 0;

            sv_setiv( key, PTR2IV( rx ) );
            sv_setref_iv( rv, "B::PMOP", PTR2IV( op ) );

            hv_store_ent( regexp_hv, key, rv, 0 );
        }
    } while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX)));

    SvREFCNT_dec( key );

    TAINT_NOT;
    return 0;
}
#endif

#if (PERL_VERSION > 11) && defined(DISABLE_PERL_CORE_EXPORTED)
/* embed.fnc:xpoM  |struct refcounted_he *|store_cop_label
 *
 *  Have to copy from CORE as they do not care about us.
 */

static struct refcounted_he *
refcounted_he_new_common(pTHX_ struct refcounted_he *const parent,
			   const char *const key_p, const STRLEN key_len,
			   const char flags, char value_type,
			   const void *value, const STRLEN value_len) {
    dVAR;
    struct refcounted_he *he;
    U32 hash;
    const bool is_pv = value_type == HVrhek_PV || value_type == HVrhek_PV_UTF8;
    STRLEN key_offset = is_pv ? value_len + 2 : 1;

    /*PERL_ARGS_ASSERT_REFCOUNTED_HE_NEW_COMMON;*/

#ifdef USE_ITHREADS
    he = (struct refcounted_he*)
	PerlMemShared_malloc(sizeof(struct refcounted_he) - 1
			     + key_len
			     + key_offset);
#else
    he = (struct refcounted_he*)
	PerlMemShared_malloc(sizeof(struct refcounted_he) - 1
			     + key_offset);
#endif

    he->refcounted_he_next = parent;

    if (is_pv) {
	Copy((char *)value, he->refcounted_he_data + 1, value_len + 1, char);
	he->refcounted_he_val.refcounted_he_u_len = value_len;
    } else if (value_type == HVrhek_IV) {
	he->refcounted_he_val.refcounted_he_u_iv = SvIVX((const SV *)value);
    } else if (value_type == HVrhek_UV) {
	he->refcounted_he_val.refcounted_he_u_uv = SvUVX((const SV *)value);
    }

    PERL_HASH(hash, key_p, key_len);

#ifdef USE_ITHREADS
    he->refcounted_he_hash = hash;
    he->refcounted_he_keylen = key_len;
    Copy(key_p, he->refcounted_he_data + key_offset, key_len, char);
#else
    he->refcounted_he_hek = share_hek_flags(key_p, key_len, hash, flags);
#endif

    if (flags & HVhek_WASUTF8) {
	/* If it was downgraded from UTF-8, then the pointer returned from
	   bytes_from_utf8 is an allocated pointer that we must free.  */
	Safefree(key_p);
    }

    he->refcounted_he_data[0] = flags;
    he->refcounted_he_refcnt = 1;

    return he;
}

/* As newSTATEOP currently gets passed plain char* labels, we will only provide
   that interface. Once it works out how to pass in length and UTF-8 ness, this
   function will need superseding.  */
struct refcounted_he *
Perl_store_cop_label(pTHX_ struct refcounted_he *const chain, const char *label)
{
    PERL_ARGS_ASSERT_STORE_COP_LABEL;

    return refcounted_he_new_common(aTHX_ chain, ":", 1, HVrhek_PV, HVrhek_PV,
				    label, strlen(label));
}
#endif


MODULE = B__MAGIC	PACKAGE = B::MAGIC

#if PERL_VERSION < 7

SV*
precomp(mg)
        B::MAGIC        mg
    CODE:
        if (mg->mg_type == 'r') {
            REGEXP* rx = (REGEXP*)mg->mg_obj;
            RETVAL = Nullsv;
            if( rx )
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

#if PERL_VERSION < 7

BOOT:
    PL_runops = my_runops;

#endif
