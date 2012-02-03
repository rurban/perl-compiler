#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

MODULE=B__Stash 	PACKAGE=B::Stash

PROTOTYPES: DISABLE

# cvname is not a constXSUB
bool
CvIsXSUB(cvname)
        SV* cvname;
   CODE:
	CV *cv;
#if PERL_VERSION < 8 || ((PERL_VERSION == 8) && (PERL_SUBVERSION < 9))
	GV *const gv = gv_fetchpv(SvPVX(cvname), 0, SVt_PVCV);
#else
	GV *const gv = gv_fetchsv(cvname, 0, SVt_PVCV);
#endif
	RETVAL = FALSE;
	if (gv && (cv = GvCV(gv))) {
	  if (CvXSUB(cv)) {
#if PERL_VERSION < 7
	    RETVAL = TRUE;
#else
	    if (!(CvFLAGS(cv) & CVf_CONST) || (CvFLAGS(cv) & CVf_ANON)) {
	      RETVAL = TRUE;
	    }
#endif
	  }
	}
    OUTPUT:
        RETVAL
