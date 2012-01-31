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
	GV *const gv = gv_fetchsv(cvname, 0, SVt_PVCV);
	RETVAL = FALSE;
	if (gv && (cv = GvCV(gv))) {
	  if (CvXSUB(cv)) {
#if PERLVERSION < 7
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
