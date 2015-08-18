package B::C::File;

=head1 NAME

B::C::File - Responsible for rendering generated C snippets into a C file for use with perlcc

=head1 SYNOPSIS

    # In B::C
    use B::C::File ();
    B::C::File::new(); # Singleton.
    ...
    B::C::File::write() # C File to generate.
    
    # In code that needs to contribute snippets
    use B::C::File qw/unopsect init objsym savesym svop_name padop_name mark_package do_labels/;
    ...
    unopsect()->comment("$opsect_common, first");
    unopsect()->add( sprintf( "%s, s\\_%x", $op->_save_common, ${ $op->first } ) );
    unopsect()->debug( $op->name, $op );

=head1 DESCRIPTION

B<B::C::File> Is an attempt to provide a single interfce to all data that is deemed ready to go to the C file.
It handles the snippets (sections) as they're determined. It also handles the final render of the C file.

=cut

use strict;
use warnings;

use Exporter ();

use B::C::Section     ();
use B::C::InitSection ();

use B qw(cstring comppadlist);
use Config;

our @ISA = qw(Exporter);

my $self;

our %symtable;
our $AUTOLOAD;

sub code_section_names {
    return qw{
      decl init0 free sym hek binop condop cop padop listop logop
      op pmop pvop svop unop sv xpv xpvav xpvhv xpvcv xpviv xpvuv
      xpvnv xpvmg xpvlv xrv xpvbm xpvio padlist loop
    };
}

sub init_section_names { return qw /init init2/ }

sub to_move { return qw/objsym savesym svop_name padop_name mark_package do_labels save_rv/ }

sub op_sections {
    return qw { binop condop cop padop loop listop logop  op pmop pvop svop unop };
}

BEGIN {
    our @EXPORT_OK = map { ( $_, "${_}sect" ) } code_section_names();
    push @EXPORT_OK, init_section_names(), to_move();

}

# wip to be moved
*objsym       = \&B::C::objsym;
*savesym      = \&B::C::savesym;
*svop_name    = \&B::C::svop_name;
*padop_name   = \&B::C::padop_name;
*mark_package = \&B::C::mark_package;
*do_labels    = \&B::C::do_labels;
*save_rv      = \&B::C::save_rv;

sub new {
    $self and die("Re-initialized???");

    my $outfile = shift;
    $self = bless { 'c_file_name' => $outfile, 'verbose' => $B::C::verbose, 'debug' => \%B::C::debug };

    foreach my $section_name ( code_section_names() ) {
        $self->{$section_name} = B::C::Section->new( $section_name, \%symtable, 0 );
    }

    foreach my $section_name ( init_section_names() ) {
        $self->{$section_name} = B::C::InitSection->new( $section_name, \%symtable, 0 );
    }
}

sub get_sect {
    my $section = shift;
    return $self->{$section};
}

sub DESTROY { }    # Because we're doing autoload.

sub AUTOLOAD {
    my $sect = $AUTOLOAD;
    $sect =~ s/.*:://;

    $sect =~ s/sect$//;    # Strip sect off the call so we can just access the key.

    exists $self->{$sect} or die("Tried to call undefined subroutine '$sect'");
    return $self->{$sect};
}

my $cfh;
my %static_ext;

sub write {
    warn "Writing output\n" if verbose();

    open( $cfh, '>', $self->{'c_file_name'} ) or die("Failed to open $self->{c_file_name} for write: $!");

    output_boilerplate();

    # add static modules like " Win32CORE"
    foreach my $stashname ( split /\s+/, $Config{static_ext} ) {
        next if $stashname =~ /^\s*$/;    # often a leading space
        $static_ext{$stashname}++;
        my $stashxsub = $stashname;
        $stashxsub =~ s/::/__/g;
        print {$cfh} "EXTERN_C void boot_$stashxsub (pTHX_ CV* cv);\n";
    }
    print {$cfh} "\n";
    output_all( $B::C::init_name || "perl_init" );
    print {$cfh} "\n";
    output_main_rest();

    if ( defined($B::C::module) ) {
        my $cmodule = $B::C::module ? $B::C::module : "main";
        $cmodule =~ s/::/__/g;

        my $start = "op_list[0]";
        warn "curpad syms:\n" if verbose();
        init()->add("/* curpad syms */");
        my $curpad_sym = ( comppadlist->ARRAY )[1]->save;

        print {$cfh} <<"EOT";

#include "XSUB.h"
XS(boot_$cmodule)
{
    dXSARGS;
    perl_init();
    ENTER;
    SAVETMPS;
    SAVEVPTR(PL_curpad);
    SAVEVPTR(PL_op);
    dl_init(aTHX);
    PL_curpad = AvARRAY($curpad_sym);
    PL_comppad = $curpad_sym;
    PL_op = $start;
    perl_run( aTHX ); /* Perl_runops_standard(aTHX); */
    FREETMPS;
    LEAVE;
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}
EOT

    }
    else {
        output_main();
    }
    close $cfh;
}

sub output_boilerplate {
    my $creator = "created at " . scalar localtime() . " with B::C $B::C::VERSION";
    $creator .= $B::C::REVISION if $B::C::REVISION;
    print {$cfh} "/* $creator */\n";

    # Store the sv_list index in sv_debug_file when debugging
    print {$cfh} "#define DEBUG_LEAKING_SCALARS 1\n" if $self->{'debug'}->{flags} and $B::C::DEBUG_LEAKING_SCALARS;
    if ($B::C::Flags::have_independent_comalloc) {
        print {$cfh} <<'_EOT1';
#ifdef NEED_MALLOC_283
# include "malloc-2.8.3.h"
#endif
_EOT1

    }
    print {$cfh} <<'_EOT2';
#define PERL_CORE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Workaround for mapstart: the only op which needs a different ppaddr */
#undef Perl_pp_mapstart
#define Perl_pp_mapstart Perl_pp_grepstart
#undef OP_MAPSTART
#define OP_MAPSTART OP_GREPSTART

/* Since 5.8.8 */
#ifndef Newx
#define Newx(v,n,t)    New(0,v,n,t)
#endif
/* No longer available when C<PERL_CORE> is defined. */
#ifndef Nullsv
#define Null(type) ((type)NULL)
#define Nullsv Null(SV*)
#define Nullhv Null(HV*)
#define Nullgv Null(GV*)
#define Nullop Null(OP*)
#endif
#ifndef GV_NOTQUAL
#define GV_NOTQUAL 0
#endif

#define XS_DynaLoader_boot_DynaLoader boot_DynaLoader
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void xs_init (pTHX);
static void dl_init (pTHX);
_EOT2

    if ( $B::C::av_init2 and $B::C::Flags::use_declare_independent_comalloc ) {
        print {$cfh} "void** dlindependent_comalloc(size_t, size_t*, void**);\n";
    }

    if ( !$B::C::destruct ) {
        print {$cfh} <<'__EOT';
int fast_perl_destruct( PerlInterpreter *my_perl );
static void my_curse( pTHX_ SV* const sv );

#ifndef dVAR
# ifdef PERL_GLOBAL_STRUCT
#  define dVAR		pVAR    = (struct perl_vars*)PERL_GET_VARS()
# else
#  define dVAR		dNOOP
# endif
#endif
__EOT

    }
    else {
        print {$cfh} <<'__EOT';
int my_perl_destruct( PerlInterpreter *my_perl );
__EOT

    }
}

sub output_all {
    my $init_name = shift;
    my $section;

    # return if $check; # Who's calling this in a check block??

    my @sections = (
        copsect(),    opsect(),    unopsect(),  binopsect(), logopsect(), condopsect(),
        listopsect(), pmopsect(),  svopsect(),  padopsect(), pvopsect(),  loopsect(),
        xpvsect(),    xpvavsect(), xpvhvsect(), xpvcvsect(), padlistsect(),
        xpvivsect(),  xpvuvsect(), xpvnvsect(), xpvmgsect(), xpvlvsect(),
        xrvsect(),    xpvbmsect(), xpviosect(), svsect()
    );
    printf {$cfh} "\t/* %s */", symsect()->comment if ( verbose() and symsect()->comment );
    symsect()->output( $cfh, "#define %s\n" );
    print {$cfh} "\n";
    output_declarations();

    # XXX add debug versions with ix=opindex
    foreach $section (@sections) {
        my $lines = $section->index + 1;
        if ($lines) {
            my $name     = $section->name;
            my $typename = $section->typename;
            print {$cfh} "Static $typename ${name}_list[$lines];\n";
        }
    }

    # hack for when Perl accesses PVX of GVs
    print {$cfh} 'Static const char emptystring[] = "\0";', "\n";

    # newXS for core XS needs a filename
    print {$cfh} 'Static const char xsfile[] = "universal.c";', "\n";
    if ($B::C::MULTI) {
        print {$cfh} "#define ptr_undef 0\n";
    }
    else {
        print {$cfh} "#define ptr_undef &PL_sv_undef\n";
        print {$cfh} "#undef CopFILE_set\n";
        print {$cfh} "#define CopFILE_set(c,pv)  CopFILEGV_set((c), gv_fetchfile(pv))\n";

    }

    if ( %B::C::init2_remap and !$B::C::HAVE_DLFCN_DLOPEN ) {
        print {$cfh} <<'EOT';
XS(XS_DynaLoader_dl_load_file);
XS(XS_DynaLoader_dl_find_symbol);
EOT
    }
    printf {$cfh} "\t/* %s */\n", decl()->comment if ( verbose() and decl()->comment );
    decl()->output( $cfh, "%s\n" );
    print {$cfh} "\n";

    foreach $section (@sections) {
        my $lines = $section->index + 1;
        if ($lines) {
            printf {$cfh} "Static %s %s_list[%u] = {\n", $section->typename, $section->name, $lines;
            if ( verbose() and $section->comment ) {
                printf {$cfh} "\t/* %s */\n", $section->comment;
            }
            $section->output( $cfh, "\t{ %s }, /* %s_list[%d] %s */%s\n" );
            print {$cfh} "};\n\n";
        }
    }

    fixup_ppaddr();
    print {$cfh} "static int perl_init0(pTHX) /* fixup_ppaddr */
{";
    init0()->output( $cfh, "\t%s\n" );
    print {$cfh} "};\n\n";

    printf {$cfh} "\t/* %s */\n", init()->comment if verbose() and init()->comment;
    init()->output( $cfh, "\t%s\n", $init_name );
    my $init2_name = 'perl_init2';
    printf {$cfh} "/* deferred init of XS/Dyna loaded modules */\n" if verbose();
    printf {$cfh} "/* %s */\n", init2()->comment if verbose() and init2()->comment;
    my $remap = 0;
    for my $pkg ( sort keys %B::C::init2_remap ) {
        if ( exists $B::C::xsub{$pkg} ) {    # check if not removed in between
            my ($stashfile) = $B::C::xsub{$pkg} =~ /^Dynamic-(.+)$/;

            # get so file from pm. Note: could switch prefix from vendor/site//
            $B::C::init2_remap{$pkg}{FILE} = dl_module_to_sofile( $pkg, $stashfile );
            $remap++;
        }
    }
    if ($remap) {

        # XXX now emit arch-specific dlsym code
        init2()->add( "{", "  void *handle, *ptr;" );
        if ($B::C::HAVE_DLFCN_DLOPEN) {
            init2()->add("  #include <dlfcn.h>");
        }
        else {
            init2()->add(
                "  dTARG; dSP;",
                "  targ=sv_newmortal();"
            );
        }
        for my $pkg ( sort keys %B::C::init2_remap ) {
            if ( exists $B::C::xsub{$pkg} ) {
                if ($B::C::HAVE_DLFCN_DLOPEN) {
                    my $ldopt = 'RTLD_NOW|RTLD_NOLOAD';
                    $ldopt = 'RTLD_NOW' if $^O =~ /bsd/i;    # 351 (only on solaris and linux, not any bsd)
                    init2()->add(
                        sprintf( "  handle = dlopen(%s,", cstring( $B::C::init2_remap{$pkg}{FILE} ) ),
                        "                  $ldopt);",
                    );
                }
                else {
                    init2()->add(
                        "  PUSHMARK(SP);",
                        sprintf( "  XPUSHs(newSVpvs(%s));", cstring( $B::C::init2_remap{$pkg}{FILE} ) ),
                        "  PUTBACK;",
                        "  XS_DynaLoader_dl_load_file(aTHX);",
                        "  SPAGAIN;",
                        "  handle = INT2PTR(void*,POPi);",
                        "  PUTBACK;",
                    );
                }
                for my $mg ( @{ $B::C::init2_remap{$pkg}{MG} } ) {
                    warn "init2 remap xpvmg_list[$mg->{ID}].xiv_iv to dlsym of $pkg\: $mg->{NAME}\n" if verbose();
                    if ($B::C::HAVE_DLFCN_DLOPEN) {
                        init2()->add( sprintf( "  ptr = dlsym(handle, %s);", cstring( $mg->{NAME} ) ) );
                    }
                    else {
                        init2()->add(
                            "  PUSHMARK(SP);",
                            "  XPUSHi(PTR2IV(handle));",
                            sprintf( "  XPUSHs(newSVpvs(%s));", cstring( $mg->{NAME} ) ),
                            "  PUTBACK;",
                            "  XS_DynaLoader_dl_find_symbol(aTHX);",
                            "  SPAGAIN;",
                            "  ptr = INT2PTR(void*,POPi);",
                            "  PUTBACK;",
                        );
                    }
                    init2()->add( sprintf( "  xpvmg_list[%d].xiv_iv = PTR2IV(ptr);", $mg->{ID} ) );
                }
            }
        }
        init2()->add("}");
    }
    init2()->output( $cfh, "\t%s\n", $init2_name );
    if ( verbose() ) {
        my $caller = caller;
        warn $caller eq 'B::CC' ? B::CC::compile_stats() : compile_stats();
        warn "NULLOP count: $B::C::nullop_count\n";
    }
}

sub output_declarations {
    print {$cfh} <<'EOT';
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
EOT

    # Tricky hack for -fcog since 5.10 on !c99 compilers required. We need a char* as
    # *first* sv_u element to be able to statically initialize it. A int does not allow it.
    # gcc error: initializer element is not computable at load time
    # We introduce a SVPV as SV.
    # In core since 5.12

    print {$cfh} "typedef struct p5rx RE;\n";
    print {$cfh} "Static GV *gv_list[$B::C::gv_index];\n" if $B::C::gv_index;

    # Need fresh re-hash of strtab. share_hek does not allow hash = 0

    print {$cfh} <<'_EOT0';
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );
_EOT0

    print {$cfh} "\n";
}

sub fixup_ppaddr {

    # init op addrs must be the last action, otherwise
    # some ops might not be initialized
    # but it needs to happen before CALLREGCOMP, as a /i calls a compiled utf8::SWASHNEW
    if ($B::C::optimize_ppaddr) {
        foreach my $op_section_name ( B::C::File::op_sections() ) {
            my $section = B::C::File::get_sect($op_section_name);
            next unless $section->index >= 0;
            init_op_addr( $section->name, $section->index + 1 );
        }
    }
}

sub init_op_addr {
    my ( $op_type, $num ) = @_;
    my $op_list = $op_type . "_list";

    init0()->add( split /\n/, <<_EOT3 );
{
    register int i;
    for( i = 0; i < ${num}; ++i ) {
        ${op_list}\[i].op_ppaddr = PL_ppaddr[PTR2IV(${op_list}\[i].op_ppaddr)];
    }
}
_EOT3

}

sub output_main_rest {

    print {$cfh} <<'_EOT5';
HEK *
my_share_hek( pTHX_ const char *str, I32 len, register U32 hash ) {
    if (!hash) {
      PERL_HASH(hash, str, abs(len));
    }
    return Perl_share_hek(aTHX_ str, len, hash);
}

_EOT5

    # -fno-destruct only >=5.8
    if ( !$B::C::destruct ) {
        print {$cfh} <<'_EOT6';

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
_EOT6

    }

    # special COW handling for 5.10 because of S_unshare_hek_or_pvn limitations
    # XXX This fails in S_doeval SAVEFREEOP(PL_eval_root): test 15
    else {
        print {$cfh} <<'_EOT7';
int my_perl_destruct( PerlInterpreter *my_perl ) {
    /* set all our static pv and hek to &PL_sv_undef for perl_destruct() */
_EOT7

        for ( 0 .. $#B::C::static_free ) {

            # set the sv/xpv to &PL_sv_undef, not the pv itself.
            # If set to NULL pad_undef will fail in SvPVX_const(namesv) == '&'
            # XXX Another idea >5.10 is SvFLAGS(pv) = SVTYPEMASK
            my $s = $B::C::static_free[$_];
            if ( $s =~ /^sv_list\[\d+\]\./ ) {    # pv directly (unused)
                print {$cfh} "    $s = NULL;\n";
            }
            elsif ( $s =~ /^sv_list/ ) {
                print {$cfh} "    SvLEN(&$s) = 0;\n";
                print {$cfh} "    SvPV_set(&$s, (char*)&PL_sv_undef);\n";
            }
            elsif ( $s =~ /^&sv_list/ ) {
                print {$cfh} "    SvLEN($s) = 0;\n";
                print {$cfh} "    SvPV_set($s, (char*)&PL_sv_undef);\n";

                # dead code ---
            }
            elsif ( $s =~ /^cop_list/ ) {
                if ( $B::C::ITHREADS or !$B::C::MULTI ) {
                    print {$cfh} "    CopFILE_set(&$s, NULL);";
                }
                if ($B::C::ITHREADS) {
                    print {$cfh} " CopSTASHPV(&$s) = NULL;\n";
                }
                elsif ( !$B::C::ITHREADS ) {
                    print {$cfh} " CopSTASH(&$s) = NULL;\n";
                }
                else {    # 5.16 experiment
                    print {$cfh} " CopSTASHPV_set(&$s, NULL, 0);\n";
                }

                # end dead code ---
                #} elsif ($s =~ /^pv\d/) {
                #	print {$cfh} "    $s = \"\";\n";
            }
            elsif ( $s ne 'ptr_undef' ) {
                warn("unknown $s at \@static_free[$_]");
            }
        }
        free()->output( $cfh, "%s\n" );
        print {$cfh} <<'_EOT7a';

    /* B::C specific: prepend static svs to arena for sv_clean_objs */
    SvANY(&sv_list[0]) = (void *)PL_sv_arenaroot;
    PL_sv_arenaroot = &sv_list[0];
#if PERL_VERSION > 7
    if (DEBUG_D_TEST) {
        SV* sva;
        PerlIO_printf(Perl_debug_log, "\n");
        for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
            PerlIO_printf(Perl_debug_log, "sv_arena: 0x%p - 0x%p (%u)\n",
              sva, sva+SvREFCNT(sva), SvREFCNT(sva));
        }
    }
    return perl_destruct( my_perl );
#else
    perl_destruct( my_perl );
    return 0;
#endif
}
_EOT7a
    }

    print {$cfh} <<'_EOT8';

/* yanked from perl.c */
static void
xs_init(pTHX)
{
	char *file = __FILE__;
	dTARG; dSP;
_EOT8

    #if ($B::C::staticxs) { #FIXME!
    #  print {$cfh} "\n#undef USE_DYNAMIC_LOADING
    #}
    print {$cfh} "\n#ifdef USE_DYNAMIC_LOADING";
    print {$cfh} "\n\tnewXS(\"DynaLoader::boot_DynaLoader\", boot_DynaLoader, file);";
    print {$cfh} "\n#endif\n";

    delete $B::C::xsub{'DynaLoader'};
    delete $B::C::xsub{'UNIVERSAL'};
    print {$cfh} "/* XS bootstrapping code*/\n";
    print {$cfh} "\tSAVETMPS;\n";
    print {$cfh} "\ttarg=sv_newmortal();\n";
    foreach my $stashname ( sort keys %static_ext ) {
        my $stashxsub = $stashname;
        $stashxsub =~ s/::/__/g;

        #if ($stashxsub =~ m/\/(\w+)\.\w+$/ {$stashxsub = $1;}
        # cygwin has Win32CORE in static_ext
        warn "bootstrapping static $stashname added to xs_init\n" if verbose();
        print {$cfh} "\tnewXS(\"$stashname\::bootstrap\", boot_$stashxsub, file);\n";
    }
    print {$cfh} "#ifdef USE_DYNAMIC_LOADING\n";
    print {$cfh} "\tPUSHMARK(sp);\n";
    printf {$cfh} "\tXPUSHp(\"DynaLoader\", %d);\n", length("DynaLoader");
    print {$cfh} "\tPUTBACK;\n";
    warn "bootstrapping DynaLoader added to xs_init\n" if verbose();
    print {$cfh} "\tboot_DynaLoader(aTHX_ NULL);\n";
    print {$cfh} "\tSPAGAIN;\n";
    print {$cfh} "#endif\n";

    # my %core = map{$_ => 1} core_packages();
    foreach my $stashname ( sort keys %B::C::xsub ) {
        my $incpack = inc_packname($stashname);
        unless ( exists $B::C::curINC{$incpack} ) {    # skip deleted packages
            warn "skip xs_init for $stashname !\$INC{$incpack}\n" if $self->{'debug'}->{pkg};
            delete $B::C::xsub{$stashname} unless $static_ext{$stashname};
            next;
        }
        if ( $B::C::xsub{$stashname} !~ m/^Dynamic/ and !$static_ext{$stashname} ) {
            my $stashxsub = $stashname;
            warn "bootstrapping $stashname added to xs_init\n" if verbose();
            $stashxsub =~ s/::/__/g;
            print  {$cfh} "\tPUSHMARK(sp);\n";
            printf {$cfh} "\tXPUSHp(\"%s\", %d);\n",    # "::bootstrap" gets appended, TODO
              0 ? "strdup($stashname)" : $stashname, length($stashname);
            print {$cfh} "\tPUTBACK;\n";
            print {$cfh} "\tboot_$stashxsub(aTHX_ NULL);\n";
            print {$cfh} "\tSPAGAIN;\n";
        }
    }
    print {$cfh} "\tFREETMPS;\n/* end XS bootstrapping code */\n";
    print {$cfh} "}\n";

    print {$cfh} <<'_EOT9';

static void
dl_init(pTHX)
{
	char *file = __FILE__;
_EOT9

    my ( $dl, $xs );
    my @dl_modules = @DynaLoader::dl_modules;
    my @PERLMODS = split( /\,/, $ENV{'PERLMODS'} ) if $ENV{'PERLMODS'};    # from cpanel
    foreach my $perlmod (@PERLMODS) {
        warn "Extra module ${perlmod}\n";
        push @dl_modules, $perlmod unless grep { $_ ne $perlmod } @dl_modules;
    }

    # filter out unused dynaloaded B modules, used within the compiler only.
    for my $c (qw(B B::C)) {
        if ( !$B::C::xsub{$c} and !$B::C::include_package{$c} ) {

            # (hopefully, see test 103)
            warn "no dl_init for $c, not marked\n" if verbose() and !$B::C::skip_package{$c};

            # RT81332 pollute
            @dl_modules = grep { $_ ne $c } @dl_modules;

            # XXX Be sure to store the new @dl_modules
        }
    }
    for my $c ( sort keys %B::C::skip_package ) {
        warn "no dl_init for $c, skipped\n" if verbose() and $B::C::xsub{$c};
        delete $B::C::xsub{$c};
        $B::C::include_package{$c} = undef;
        @dl_modules = grep { $_ ne $c } @dl_modules;
    }
    @DynaLoader::dl_modules = @dl_modules;
    warn "\@dl_modules: ", join( " ", @dl_modules ), "\n" if verbose();
    foreach my $stashname (@dl_modules) {
        my $incpack = inc_packname($stashname);

        #unless (exists $INC{$incpack}) { # skip deleted packages
        #  warn "XXX skip dl_init for $stashname !\$INC{$incpack}\n" if $self->{'debug'}->{pkg};
        #  delete $B::C::xsub{$stashname};
        #  @dl_modules = grep { $_ ne $stashname } @dl_modules;
        #}
        if ( $stashname eq 'attributes' ) {
            $B::C::xsub{$stashname} = 'Dynamic-' . $INC{'attributes.pm'};
        }

        # TODO: special Moose bootstrap quirks (XS since which version?)
        if ( $stashname eq 'Moose' and $B::C::include_package{Moose} and $Moose::VERSION gt '2.0' ) {
            $B::C::xsub{$stashname} = 'Dynamic-' . $INC{'Moose.pm'};
        }
        if ( exists( $B::C::xsub{$stashname} ) && $B::C::xsub{$stashname} =~ m/^Dynamic/ ) {

            # XSLoader.pm: $modlibname = (caller())[1]; needs a path at caller[1] to find auto,
            # otherwise we only have -e
            $xs++ if $B::C::xsub{$stashname} ne 'Dynamic';
            $dl++;
        }
    }
    warn "\%B::C::xsub: ", join( " ", sort keys %B::C::xsub ), "\n" if verbose() and $self->{'debug'}->{cv};

    # XXX Adding DynaLoader is too late here! The sections like $init are already dumped (#125)
    if ( $dl and !$B::C::curINC{'DynaLoader.pm'} ) {
        die "Error: DynaLoader required but not dumped. Too late to add it.\n";
    }
    elsif ( $xs and !$B::C::curINC{'XSLoader.pm'} ) {
        die "Error: XSLoader required but not dumped. Too late to add it.\n";
    }
    if ($dl) {
        if ( grep { $_ eq 'attributes' } @dl_modules ) {

            # enforce attributes at the front of dl_init, #259
            @dl_modules = grep { $_ ne 'attributes' } @dl_modules;
            unshift @dl_modules, 'attributes';
        }
        if ($B::C::staticxs) {
            open( XS, ">", $self->{'c_file_name'} . ".lst" ) or die("Can't open $self->{c_file_name}.lst: $!");
        }
        print {$cfh} "\tdTARG; dSP;\n";
        print {$cfh} "/* DynaLoader bootstrapping */\n";
        print {$cfh} "\tENTER;\n";
        print {$cfh} "\t++cxstack_ix; cxstack[cxstack_ix].blk_oldcop = PL_curcop;\n" if $xs;
        print {$cfh} "\t/* assert(cxstack_ix == 0); */\n" if $xs;
        print {$cfh} "\tSAVETMPS;\n";

        if ( exists $B::C::xsub{"Coro::State"} and grep { $_ eq "Coro::State" } @dl_modules ) {

            # needed before dl_init, and after init
            print {$cfh} "\t{\n\t  GV *sym;\n";
            for my $s (qw(Coro Coro::API Coro::current)) {
                print {$cfh} "\t  sym = gv_fetchpv(\"$s\",0,SVt_PV);\n";
                print {$cfh} "\t  if (sym && GvSVn(sym)) SvREADONLY_off(GvSVn(sym));\n";
            }
            print {$cfh} "\t  sym = gv_fetchpv(\"Coro::pool_handler)\",0,SVt_PVCV);\n";
            print {$cfh} "\t  if (sym && GvCV(sym)) SvREADONLY_off(GvCV(sym));\n";
            print {$cfh} "\t}\n";
        }
        foreach my $stashname (@dl_modules) {
            if ( exists( $B::C::xsub{$stashname} ) && $B::C::xsub{$stashname} =~ m/^Dynamic/ ) {
                $B::C::use_xsloader = 1;
                print {$cfh} "\n\tPUSHMARK(sp);\n";

                # XXX -O1 or -O2 needs XPUSHs with dynamic pv
                printf {$cfh} "\t%s(%s, %d);\n",    # "::bootstrap" gets appended
                  "mXPUSHp", "\"$stashname\"", length($stashname);
                if ( $B::C::xsub{$stashname} eq 'Dynamic' ) {
                    no strict 'refs';
                    warn "dl_init $stashname\n" if verbose();

                    # just in case we missed it. DynaLoader really needs the @ISA (#308)
                    B::svref_2object( \@{ $stashname . "::ISA" } )->save;
                    print {$cfh} "#ifndef STATICXS\n";
                    print {$cfh} "\tPUTBACK;\n";
                    print {$cfh} qq/\tcall_method("DynaLoader::bootstrap_inherit", G_VOID|G_DISCARD);\n/;
                }
                else {                              # XS: need to fix cx for caller[1] to find auto/...
                    my ($stashfile) = $B::C::xsub{$stashname} =~ /^Dynamic-(.+)$/;
                    print {$cfh} "#ifndef STATICXS\n";
                    print {$cfh} "\tPUTBACK;\n";
                    warn "bootstrapping $stashname added to XSLoader dl_init\n" if verbose();

                    # XSLoader has the 2nd insanest API in whole Perl, right after make_warnings_object()
                    printf {$cfh} qq/\tCopFILE_set(cxstack[cxstack_ix].blk_oldcop, "%s");\n/, $stashfile if $stashfile;
                    print {$cfh} qq/\tcall_pv("XSLoader::load", G_VOID|G_DISCARD);\n/;
                }
                if ($B::C::staticxs) {
                    my ($laststash) = $stashname =~ /::([^:]+)$/;
                    my $path = $stashname;
                    $path =~ s/::/\//g;
                    $path .= "/" if $path;    # can be empty
                    $laststash = $stashname unless $laststash;    # without ::
                    my $sofile = "auto/" . $path . $laststash . '\.' . $Config{dlext};

                    #warn "staticxs search $sofile in @DynaLoader::dl_shared_objects\n"
                    #  if verbose() and $self->{'debug'}->{pkg};
                    for (@DynaLoader::dl_shared_objects) {
                        if (m{^(.+/)$sofile$}) {
                            print XS $stashname, "\t", $_, "\n";
                            warn "staticxs $stashname\t$_\n" if verbose();
                            $sofile = '';
                            last;
                        }
                    }
                    print XS $stashname, "\n" if $sofile;    # error case
                    warn "staticxs $stashname\t - $sofile not loaded\n" if $sofile and verbose();
                }
                print {$cfh} "#else\n";
                print {$cfh} "\tPUTBACK;\n";
                my $stashxsub = $stashname;
                $stashxsub =~ s/::/__/g;
                if ($B::C::staticxs) {

                    # CvSTASH(CvGV(cv)) is invalid without (issue 86)
                    print {$cfh} "\tboot_$stashxsub(aTHX_ get_cv(\"$stashname\::bootstrap\", GV_ADD));\n";
                }
                else {
                    print {$cfh} "\tboot_$stashxsub(aTHX_ NULL);\n";
                }
                print {$cfh} "#endif\n";
                print {$cfh} "\tSPAGAIN;\n";

                #print {$cfh} "\tPUTBACK;\n";
            }
            else {
                warn "no dl_init for $stashname, " . ( !$B::C::xsub{$stashname} ? "not marked\n" : "marked as $B::C::xsub{$stashname}\n" )
                  if verbose();

                # XXX Too late. This might fool run-time DynaLoading.
                # We really should remove this via init from @DynaLoader::dl_modules
                @DynaLoader::dl_modules = grep { $_ ne $stashname } @DynaLoader::dl_modules;

            }
        }
        print {$cfh} "\tFREETMPS;\n";
        print {$cfh} "\tcxstack_ix--;\n" if $xs;               # i.e. POPBLOCK
        print {$cfh} "\tLEAVE;\n";
        print {$cfh} "/* end DynaLoader bootstrapping */\n";
        close XS if $B::C::staticxs;
    }
    print {$cfh} "}\n";
}

sub output_main {
    if ( !defined($B::C::module) ) {
        print {$cfh} <<'_EOT10';

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
_EOT10
        if ($B::C::ITHREADS) {

            # XXX init free elems!
            my $pad_len = regex_padav->FILL;    # first is an empty avref
            print {$cfh} <<_EOT11;
#ifdef USE_ITHREADS
    if (!*PL_regex_pad) {
      /* Someone is overwriting regex_pad since 5.15, but not on -fno-warnings */
      PL_regex_padav = newAV();
#if PERL_VERSION > 10
      av_push(PL_regex_padav, newSVpvs("")); /* First entry is empty */
#else
      av_push(PL_regex_padav, newSViv(0));
#endif
      PL_regex_pad = AvARRAY(PL_regex_padav);
    }
    for( i = 0; i < $pad_len; ++i ) {
        av_push( PL_regex_padav, newSViv(0) );
    }
    PL_regex_pad = AvARRAY( PL_regex_padav );
#endif
_EOT11

        }
        print {$cfh} "    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;\n";

        # XXX With -e "" we need to fake parse_body() scriptname = BIT_BUCKET
        print {$cfh} <<'_EOT13';
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
_EOT13

        # honour -T
        if ( ${^TAINT} ) {
            print {$cfh} <<'_EOT14';
    fakeargv[options_count] = "-T";
    ++options_count;
_EOT14

        }
        print {$cfh} <<'_EOT15';
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
_EOT15

        if ($B::C::use_perl_script_name) {
            my $dollar_0 = cstring($0);
            printf {$cfh} ( qq{    sv_setpv_mg(get_sv("0", GV_ADD|GV_NOTQUAL), %s);\n}, $dollar_0 );
            printf {$cfh} ( qq{    CopFILE_set(&PL_compiling, %s);\n}, $dollar_0 );
        }
        else {
            print {$cfh} qq{    sv_setpv_mg(get_sv("0", GV_ADD|GV_NOTQUAL), argv[0]);\n};
            print {$cfh} qq{    CopFILE_set(&PL_compiling, argv[0]);\n};
        }

        # more global vars
        print {$cfh} "    PL_hints = $^H;\n"           if $^H;
        print {$cfh} "    PL_unicode = ${^UNICODE};\n" if ${^UNICODE};

        # nomg
        printf {$cfh} ( qq{    sv_setpv(get_sv(";", GV_ADD|GV_NOTQUAL), %s);\n},      cstring($;) ) if $; ne "\34";
        printf {$cfh} ( qq{    sv_setpv(get_sv("\\"", GV_NOTQUAL), %s); /* \$" */\n}, cstring($") ) if $" ne " ";

        # global IO vars

        printf {$cfh} ( qq{    sv_setpv_mg(GvSVn(PL_ofsgv), %s); /* \$, */\n}, cstring($,) ) if $,;
        printf {$cfh} ( qq{    sv_setpv_mg(get_sv("\\\\", GV_ADD|GV_NOTQUAL), %s); /* \$\\ */\n}, cstring($\) ) if $\;    #ORS

        printf {$cfh} ( qq{    sv_setpv_mg(get_sv("/", GV_NOTQUAL), %s);\n}, cstring($/) ) if $/ ne "\n";    #RS
        print {$cfh} qq{    sv_setiv_mg(get_sv("|", GV_ADD|GV_NOTQUAL), $|);\n} if $|;                       #OUTPUT_AUTOFLUSH
                                                                                                             # global format vars
        printf {$cfh} ( qq{    sv_setpv_mg(get_sv("^A", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($^A) ) if $^A;             #ACCUMULATOR
        printf {$cfh} ( qq{    sv_setpv_mg(get_sv("^L", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($^L) ) if $^L ne "\f";     #FORMFEED
        printf {$cfh} ( qq{    sv_setpv_mg(get_sv(":", GV_ADD|GV_NOTQUAL), %s);\n},  cstring($:) )  if $: ne " \n-";    #LINE_BREAK_CHARACTERS
        printf {$cfh} ( qq/    sv_setpv_mg(get_sv("^", GV_ADD|GV_NOTQUAL), savepvn(%s, %u));\n/, cstring($^), length($^) )
          if $^ ne "STDOUT_TOP";
        printf {$cfh} ( qq/    sv_setpv_mg(get_sv("~", GV_ADD|GV_NOTQUAL), savepvn(%s, %u));\n/, cstring($~), length($~) )
          if $~ ne "STDOUT";
        print {$cfh} qq{    sv_setiv_mg(get_sv("%", GV_ADD|GV_NOTQUAL), $%);\n} if $%;                                  #PAGE_NUMBER
        print {$cfh} qq{    sv_setiv_mg(get_sv("-", GV_ADD|GV_NOTQUAL), $-);\n} unless ( $- == 0 or $- == 60 );         #LINES_LEFT
        print {$cfh} qq{    sv_setiv_mg(get_sv("=", GV_ADD|GV_NOTQUAL), $=);\n} if $= != 60;                            #LINES_PER_PAGE

        # deprecated global vars
        print {$cfh} qq{    {SV* s = get_sv("[",GV_NOTQUAL); sv_setiv(s, $[); mg_set(s);}\n} if $[;                     #ARRAY_BASE

        printf {$cfh} ( qq{    sv_setpv_mg(get_sv("\030", GV_ADD|GV_NOTQUAL), %s); /* \$^X */\n}, cstring($^X) );
        print {$cfh} <<"EOT";
    TAINT_NOT;

    #if PERL_VERSION < 10 || ((PERL_VERSION == 10) && (PERL_SUBVERSION < 1))
      PL_compcv = 0;
    #else
      PL_compcv = MUTABLE_CV(newSV_type(SVt_PVCV));
      CvUNIQUE_on(PL_compcv);
      CvPADLIST(PL_compcv) = pad_new(0);
    #endif

    /* our special compiled init */
    exitstatus = perl_init(aTHX);
    if (exitstatus)
	exit( exitstatus );
    dl_init(aTHX);
    perl_init2(aTHX);
EOT

        print {$cfh} $B::C::eval_pvs if $B::C::eval_pvs;
        print {$cfh} "    exitstatus = perl_run( my_perl );\n";
        foreach my $s ( @{ init()->[-1]{pre_destruct} } ) {
            print {$cfh} "    " . $s . "\n";
        }

        if ( !$B::C::destruct ) {
            warn "fast_perl_destruct (-fno-destruct)\n" if verbose();
            print {$cfh} "    fast_perl_destruct( my_perl );\n";
        }
        else {
            print {$cfh} "    my_perl_destruct( my_perl );\n";
        }

        # XXX endav is called via call_list and so it is freed right after usage. Setting dirty here is useless
        #print {$cfh} "    PL_dirty = 1;\n" unless $B::C::pv_copy_on_grow; # protect against pad undef in END block
        print {$cfh} <<'EOT1';
    perl_free( my_perl );

    PERL_SYS_TERM();

    exit( exitstatus );
}
EOT1

    }    # module
}

# This is a redundant helper sub from B::C
sub inc_packname {
    my $package = shift;

    # See below at the reverse packname_inc: utf8 => utf8.pm + utf8_heavy.pl
    $package =~ s/\:\:/\//g;
    $package .= '.pm';
    return $package;
}

1;
