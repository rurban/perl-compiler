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

use B::C::Config;
use B::C::Helpers::Symtable qw(get_symtable_ref);
use B::C::Section     ();
use B::C::InitSection ();

use B qw(cstring comppadlist);
use Config;

our @ISA = qw(Exporter);

my $self;

our $AUTOLOAD;

sub code_section_names {
    return qw{
      decl init0 free sym hek binop condop cop padop listop logop
      op pmop pvop svop unop sv xpv xpvav xpvhv xpvcv xpviv xpvuv
      xpvnv xpvmg xpvlv xrv xpvbm xpvio padlist loop
    };
}

sub init_section_names { return qw /init init2/ }

sub op_sections {
    return qw { binop condop cop padop loop listop logop op pmop pvop svop unop };
}

BEGIN {
    our @EXPORT_OK = map { ( $_, "${_}sect" ) } code_section_names();
    push @EXPORT_OK, init_section_names();

}

sub new {
    $self and die("Re-initialized???");

    my $outfile = shift;
    $self = bless { 'c_file_name' => $outfile };

    foreach my $section_name ( code_section_names() ) {
        $self->{$section_name} = B::C::Section->new( $section_name, get_symtable_ref(), 0 );
    }

    foreach my $section_name ( init_section_names() ) {
        $self->{$section_name} = B::C::InitSection->new( $section_name, get_symtable_ref(), 0 );
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
    my $c_file_stash = shift or die;

    $c_file_stash->{section_list} = [qw( cop op unop binop logop condop listop pmop svop padop pvop loop xpv xpvav xpvhv xpvcv padlist xpviv xpvuv xpvnv xpvmg xpvlv xrv xpvbm xpvio sv )];

    foreach my $section ( code_section_names(), init_section_names() ) {
        $c_file_stash->{'section'}->{$section} = $self->{$section};
    }

    $self->{'verbose'} = $c_file_stash->{'verbose'};    # So verbose() will work. TODO: Remove me when all verbose() are gone.

    my $template_dir = $B::C::savINC{'B/C.pm'};
    $template_dir =~ s{\.pm$}{};
    $template_dir .= "/Templates";
    my $template_file = "$template_dir/base.c.tt2";
    -e $template_file or die("Can't find or read $template_file for generating B::C C code.");

    # op/magic-27839.t sets SIG{WARN} in a begin block and then never releases it.
    eval 'delete $INC{Template} if(!$INC{Template}); local $SIG{__WARN__} = sub {}; require Exporter::Heavy; require Template';
    $INC{'Template.pm'} or die("Can't load Template Toolkit at run time to render the C file.");

    # some useful options (see below for full list)
    my $config = {
        INCLUDE_PATH => $template_dir,
        INTERPOLATE  => 0,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # Don't cleanup whitespace
        EVAL_PERL    => 1,               # evaluate Perl code blocks
    };

    if ( verbose() ) {
        WARN $c_file_stash->{'compile_stats'};
        WARN "NULLOP count: $c_file_stash->{nullop_count}";
    }

    # Used to be buried in output_main_rest();
    my @possible_static_free_errors = grep { $_ !~ m/^(cop_list|&sv_list|sv_list)|^ptr_undef$/ } @{ $c_file_stash->{'static_free'} };
    if (@possible_static_free_errors) {
        WARN("unknown $_ found in \@static_free") foreach @possible_static_free_errors;
    }

    # Used to be buried in output_main_rest();
    if ( verbose() ) {
        foreach my $stashname ( sort keys %static_ext ) {
            verbose("bootstrapping static $stashname added to xs_init");
        }
    }

    # create Template object
    my $template = Template->new($config);

    # process input template, substituting variables
    $template->process( 'base.c.tt2', $c_file_stash, $self->{'c_file_name'} ) or die $template->error();

    open( $cfh, '>>', $self->{'c_file_name'} ) or die("Failed to open $self->{c_file_name} for write: $!");

    if ( defined($B::C::module) ) {
        my $cmodule = $B::C::module ? $B::C::module : "main";
        $cmodule =~ s/::/__/g;

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
    PL_op = op_list[0];
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
        if ( USE_ITHREADS() ) {

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
        foreach my $s ( @{ init()->{pre_destruct} } ) {
            print {$cfh} "    " . $s . "\n";
        }

        if ( !$B::C::destruct ) {
            verbose("fast_perl_destruct (-fno-destruct)");
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
