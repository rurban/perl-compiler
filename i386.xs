/* -*- c -*- */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#if __GNUC__ - 0 > 1 && defined (__i386__)

#include <setjmp.h>
#include <signal.h>
#include <string.h>

/* Making this stuff reentrant is not out of the question.  */

static jmp_buf j;

/* Asm stuff. */
static void back_to_c () __attribute__ ((unused));
static void back_to_c () { longjmp (j, 1); }

static int signo;
static struct sig_regs *r;

static struct
{
  unsigned char *start_esp;
  unsigned char *stop_esp;
  const char *signame;
  unsigned char *start_eip;
  unsigned char *sig_eip;
} etc;

static struct
{
  /* This register order corresponds to "pushfl; pushal". */
  unsigned long edi, esi, ebp, esp, ebx, edx, ecx, eax, eflags;
} regs;
static char end_regs[0] __attribute__ ((unused));

/* Declare these vars extern to fool the compiler. */
extern char in, out, jmp;
extern unsigned int insz, outsz, jmpsz;
asm ("
start_esp = etc
stop_esp = etc + 4

in:
	movl %esp, start_esp
	movl $regs, %esp
	popal
	popfl
	movl start_esp, %esp
insz:
	.long insz - in

out:
	movl %esp, stop_esp
	movl $end_regs, %esp
	pushfl
	pushal
	movl start_esp, %esp
outsz:
	.long outsz - out

jmp:
	pushl $back_to_c
	ret
jmpsz:
	.long jmpsz - jmp
");

/* see linux/arch/i386/kernel/signal.c */
struct sig_regs {
  unsigned long gs, fs, es, ds, edi, esi, ebp, esp, ebx, edx, ecx, eax;
  unsigned long trap_no, error_code, eip, cs, eflags, esp_again, ss;
  void *fp_state;
  /* Linux extensions */
  unsigned long oldmask, cs2;
};

static void
xhandler (int signo, struct sig_regs *r)
{
  memcpy (&regs.edi, &r->edi, 32);
  etc.sig_eip = (unsigned char *) r->eip;
  etc.stop_esp = (unsigned char *) r->esp;
  regs.eflags = (unsigned long) r->eflags;
  switch (signo)
    {
    case 0: etc.signame = ""; break;
    case SIGQUIT: etc.signame = "QUIT"; break;
    case SIGILL:  etc.signame = "ILL"; break;
    case SIGTRAP: etc.signame = "TRAP"; break;
    case SIGFPE:  etc.signame = "FPE"; break;
    case SIGSEGV: etc.signame = "SEGV"; break;
    default:      etc.signame = "_BUG_IN_" __FILE__; break;
    }
  longjmp (j, 2);
}

#endif


MODULE = B::Asm::i386		PACKAGE = B::Asm::i386

#if __GNUC__ - 0 > 1 && defined (__i386__)

SV *
_in ()
	CODE:
	RETVAL = Perl_newSVpvn (&in, insz);
	OUTPUT:
	RETVAL

SV *
_out ()
	CODE:
	RETVAL = Perl_newSVpvn (&out, outsz);
	OUTPUT:
	RETVAL

SV *
_jmp ()
	CODE:
	RETVAL = Perl_newSVpvn (&jmp, jmpsz);
	OUTPUT:
	RETVAL

SV *
_etc ()
	CODE:
	RETVAL = Perl_newSVpvn ((char *) &etc, sizeof etc);
	OUTPUT:
	RETVAL

SV *
_regs ()
	CODE:
	RETVAL = Perl_newSVpvn ((char *) &regs, sizeof regs);
	OUTPUT:
	RETVAL

void
_set_regs (str)
	unsigned char *	str
	CODE:
	memcpy (&regs, str, sizeof regs);

void
_do (str)
	unsigned char *	str
	CODE:
	{
	  struct sigaction quit, ill, trap, fpe, segv, mine;

	  memset (&mine, '\0', sizeof mine);
	  mine.sa_handler = (void (*)()) &&handler;
	  sigaction (SIGQUIT, &mine, &quit);
	  sigaction (SIGILL, &mine, &ill);
	  sigaction (SIGTRAP, &mine, &trap);
	  sigaction (SIGFPE, &mine, &fpe);
	  sigaction (SIGSEGV, &mine, &segv);
	  etc.start_eip = str;
	  if (! setjmp (j))
	    asm ("pushl %0; ret" : : "r"(str));
	  sigaction (SIGQUIT,&quit, 0);
	  sigaction (SIGILL, &ill, 0);
	  sigaction (SIGTRAP, &trap, 0);
	  sigaction (SIGFPE, &fpe, 0);
	  sigaction (SIGSEGV, &segv, 0);
	  goto end_handler;

	handler:
	  /* Why doesn't it need %% ??? */
	  asm ("
	movl 4(%esp), %ebx	# signo
	leal 8(%esp), %eax	# sig_regs pointer
	pushl %eax
	pushl %ebx
	call xhandler
");
	end_handler:
	}

#endif
