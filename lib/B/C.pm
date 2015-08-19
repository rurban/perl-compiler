#      C.pm
#
#      Copyright (c) 1996, 1997, 1998 Malcolm Beattie
#      Copyright (c) 2008, 2009, 2010, 2011 Reini Urban
#      Copyright (c) 2010 Nick Koston
#      Copyright (c) 2011, 2012, 2013, 2014 cPanel Inc
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#

package B::C;
use strict;

our $VERSION = '1.47_03';
our %debug;
our $check;
my $eval_pvs = '';
use Config;

# Thanks to Mattia Barbon for the C99 tip to init any union members
our $C99 = $Config{d_c99_variadic_macros};    # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962

use B::Flags;
use B::C::File qw( init2 init0 init decl free
  symsect heksect binopsect condopsect copsect padopsect listopsect logopsect
  opsect pmopsect pvopsect svopsect unopsect svsect xpvsect xpvavsect xpvhvsect xpvcvsect xpvivsect xpvuvsect
  xpvnvsect xpvmgsect xpvlvsect xrvsect xpvbmsect xpviosect padlistsect loopsect
);

use strict;
use Exporter ();
use Errno    ();                              #needed since 5.14
our %Regexp;

{                                             # block necessary for caller to work
    my $caller = caller;
    if ( $caller eq 'O' or $caller eq 'Od' ) {
        require XSLoader;
        XSLoader::load('B::C');               # for r-magic and for utf8-keyed B::HV->ARRAY
    }
}

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(mark_unused mark_skip set_callback save_unused_subs objsym save_context save_sig svop_or_padop_pv inc_cleanup ivx nvx opsect_common);

# for 5.6.[01] better use the native B::C
# but 5.6.2 works fine
use B qw(minus_c sv_undef walkoptree walkoptree_slow main_root main_start peekop
  class cchar svref_2object compile_stats comppadlist hash
  main_cv init_av end_av opnumber cstring
  HEf_SVKEY SVf_POK SVp_POK SVf_ROK SVf_IOK SVf_NOK SVf_IVisUV SVf_READONLY);

BEGIN {
    @B::NV::ISA = 'B::IV';                                            # add IVX to nv. This fixes test 23 for Perl 5.8
    B->import(qw(regex_padav SVp_NOK SVp_IOK CVf_CONST CVf_ANON));    # both unsupported for 5.6

    sub SVf_UTF8 { 0x20000000 }

    B->import(qw(SVt_PVGV));                                          # added with 5.8.1

    require mro;                                                      # mro->import();
                                                                      # not exported:
    sub SVf_OOK { 0x02000000 }
    eval q[sub SVs_GMG { 0x00200000 }
           sub SVs_SMG { 0x00400000 }];
    eval q[sub RXf_EVAL_SEEN { 0x0 }
           sub PMf_EVAL      { 0x0 }
           ];                                                         # unneeded
}

use B::C::Flags;
use FileHandle;

use B::FAKEOP  ();
use B::STASHGV ();

{
    # could use File::Basename
    my $bc_path = $INC{'B/C.pm'};
    $bc_path =~ s{\.pm$}{};
    my $load_from_dir = $bc_path . '/Save';
    die "Invalid dir for B/C/Save modules: $load_from_dir" unless -d $load_from_dir;

    # load overload modules B::C::Save::* to plug save methods
    foreach my $module ( sort glob qq{$load_from_dir/*.pm} ) {
        ($module) = $module =~ m/(.*)/;    # untaint
        eval qq{require "$module"; 1} or die "Cannot load $module";
    }
}

my $hv_index = 0;
our $gv_index = 0;
my $re_index      = 0;
my $pv_index      = 0;
my $cv_index      = 0;
my $hek_index     = 0;
my $anonsub_index = 0;
my $initsub_index = 0;
my $padlist_index = 0;

# FIXME: this part can now be dynamic
# exclude all not B::C:: prefixed subs
my %all_bc_subs = map { $_ => 1 } qw(B::AV::save B::BINOP::save B::BM::save B::COP::save B::CV::save
  B::FAKEOP::fake_ppaddr B::FAKEOP::flags B::FAKEOP::new B::FAKEOP::next
  B::FAKEOP::ppaddr B::FAKEOP::private B::FAKEOP::save B::FAKEOP::sibling
  B::FAKEOP::targ B::FAKEOP::type B::GV::save B::GV::savecv B::HV::save
  B::IO::save B::IO::save_data B::IV::save B::LISTOP::save B::LOGOP::save
  B::LOOP::save B::NULL::save B::NV::save B::OBJECT::save
  B::OP::_save_common B::OP::fake_ppaddr B::OP::isa B::OP::save
  B::PADLIST::save B::PADOP::save B::PMOP::save B::PV::save B::PVIV::save
  B::PVLV::save B::PVMG::save B::PVMG::save_magic B::PVNV::save B::PVOP::save
  B::REGEXP::save B::RV::save B::SPECIAL::save B::SPECIAL::savecv
  B::SV::save B::SVOP::save B::UNOP::save B::UV::save B::REGEXP::EXTFLAGS);

# track all internally used packages. all other may not be deleted automatically
# - hidden methods
# uses now @B::C::Flags::deps
our %all_bc_deps =
  map { $_ => 1 } @B::C::Flags::deps
  ? @B::C::Flags::deps
  : qw(AnyDBM_File AutoLoader B B::AV B::Asmdata B::BINOP B::BM B::C B::C::Flags B::C::InitSection B::C::Section B::CC B::COP B::CV B::FAKEOP B::FM B::GV B::HE B::HV B::IO B::IV B::LEXWARN B::LISTOP B::LOGOP B::LOOP B::MAGIC B::NULL B::NV B::OBJECT B::OP B::PADLIST B::PADOP B::PMOP B::PV B::PVIV B::PVLV B::PVMG B::PVNV B::PVOP B::REGEXP B::RHE B::RV B::SPECIAL B::STASHGV B::SV B::SVOP B::Section B::UNOP B::UV CORE CORE::GLOBAL Carp Config DB DynaLoader Errno Exporter Exporter::Heavy ExtUtils ExtUtils::Constant ExtUtils::Constant::ProxySubs Fcntl FileHandle IO IO::File IO::Handle IO::Poll IO::Seekable IO::Socket Internals O POSIX PerlIO PerlIO::Layer PerlIO::scalar Regexp SelectSaver Symbol UNIVERSAL XSLoader __ANON__ arybase arybase::mg base fields main maybe maybe::next mro next overload re strict threads utf8 vars version warnings warnings::register B::Flags);

# B::C stash footprint: mainly caused by blib, warnings, and Carp loaded with DynaLoader
# perl5.15.7d-nt -MO=C,-o/dev/null -MO=Stash -e0
# -umain,-ure,-umro,-ustrict,-uAnyDBM_File,-uFcntl,-uRegexp,-uoverload,-uErrno,-uExporter,-uExporter::Heavy,-uConfig,-uwarnings,-uwarnings::register,-uDB,-unext,-umaybe,-umaybe::next,-uFileHandle,-ufields,-uvars,-uAutoLoader,-uCarp,-uSymbol,-uPerlIO,-uPerlIO::scalar,-uSelectSaver,-uExtUtils,-uExtUtils::Constant,-uExtUtils::Constant::ProxySubs,-uthreads,-ubase
# perl5.15.7d-nt -MErrno -MO=Stash -e0
# -umain,-ure,-umro,-ustrict,-uRegexp,-uoverload,-uErrno,-uExporter,-uExporter::Heavy,-uwarnings,-uwarnings::register,-uConfig,-uDB,-uvars,-uCarp,-uPerlIO,-uthreads
# perl5.15.7d-nt -Mblib -MO=Stash -e0
# -umain,-ure,-umro,-ustrict,-uCwd,-uRegexp,-uoverload,-uFile,-uFile::Spec,-uFile::Spec::Unix,-uDos,-uExporter,-uExporter::Heavy,-uConfig,-uwarnings,-uwarnings::register,-uDB,-uEPOC,-ublib,-uScalar,-uScalar::Util,-uvars,-uCarp,-uVMS,-uVMS::Filespec,-uVMS::Feature,-uWin32,-uPerlIO,-uthreads
# perl -MO=Stash -e0
# -umain,-uTie,-uTie::Hash,-ure,-umro,-ustrict,-uRegexp,-uoverload,-uExporter,-uExporter::Heavy,-uwarnings,-uDB,-uCarp,-uPerlIO,-uthreads
# pb -MB::Stash -e0
# -umain,-ure,-umro,-uRegexp,-uPerlIO,-uExporter,-uDB

my ( $prev_op, $package_pv, @package_pv );    # global stash for methods since 5.13
my ( %cvforward, %lexwarnsym );
my ( %strtable, %hektable, %gptable );
our ( %xsub, %init2_remap );
my ( $warn_undefined_syms, $swash_init, $swash_ToCf );
our ( $staticxs, $outfile );
our ( %include_package, %dumped_package, %skip_package, %isa_cache );
our ($use_xsloader);

# can be improved
our $nullop_count     = 0;
our $unresolved_count = 0;

# options and optimizations shared with B::CC
our ( $module, $init_name, %savINC, %curINC, $mainfile, @static_free );
our ( $use_av_undef_speedup, $use_svpop_speedup ) = ( 1, 1 );
our (
    $optimize_ppaddr, $optimize_warn_sv, $use_perl_script_name,
    $save_data_fh, $save_sig, $optimize_cop,  $av_init, $av_init2,       $ro_inc,          $destruct,
    $fold,         $warnings, $const_strings, $stash,   $can_delete_pkg, $pv_copy_on_grow, $dyn_padlist,
    $walkall
);
our $verbose    = 0;
our %option_map = (

    #ignored until IsCOW has a seperate COWREFCNT field (5.22 maybe)
    'cog'             => \$B::C::pv_copy_on_grow,
    'const-strings'   => \$B::C::const_strings,
    'save-data'       => \$B::C::save_data_fh,
    'ppaddr'          => \$B::C::optimize_ppaddr,
    'walkall'         => \$B::C::walkall,
    'warn-sv'         => \$B::C::optimize_warn_sv,
    'av-init'         => \$B::C::av_init,
    'av-init2'        => \$B::C::av_init2,
    'delete-pkg'      => \$B::C::can_delete_pkg,
    'ro-inc'          => \$B::C::ro_inc,
    'stash'           => \$B::C::stash,              # enable with -fstash
    'destruct'        => \$B::C::destruct,           # disable with -fno-destruct
    'fold'            => \$B::C::fold,               # disable with -fno-fold
    'warnings'        => \$B::C::warnings,           # disable with -fno-warnings
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => \$B::C::save_sig,
    'dyn-padlist'     => \$B::C::dyn_padlist,        # with -O4, needed for cv cleanup with non-local exits since 5.18
    'cop'             => \$optimize_cop,             # XXX very unsafe!
                                                     # Better do it in CC, but get rid of
                                                     # NULL cops also there.
);
our %optimization_map = (
    0 => [qw()],                                                        # special case
    1 => [qw(-fppaddr -fav-init2)],                                     # falls back to -fav-init
    2 => [qw(-fro-inc -fsave-data)],
    3 => [qw(-fno-destruct -fconst-strings -fno-fold -fno-warnings)],
    4 => [qw(-fcop -fno-dyn-padlist)],
);
our %debug_map = (
    'O' => 'op',
    'A' => 'av',
    'H' => 'hv',
    'C' => 'cv',
    'M' => 'mg',
    'R' => 'rx',
    'G' => 'gv',
    'S' => 'sv',
    'P' => 'pv',
    'W' => 'walk',
    'c' => 'cops',
    's' => 'sub',
    'p' => 'pkg',

    #   'm' => 'meth',
    'u' => 'unused',
);

my @xpvav_sizes;
my ( $max_string_len, $in_endav );
my %static_core_pkg;    # = map {$_ => 1} static_core_packages();

# get rid of them... B::C::Setup
our $MULTI    = $Config{usemultiplicity};
our $ITHREADS = $Config{useithreads};

# switch to helper with static variable
sub USE_ITHREADS {
    my $cache = $Config{useithreads};
    return $cache;
}

# fixme move to B::C::Debug
my $DEBUGGING = ( $Config{ccflags} =~ m/-DDEBUGGING/ );
our $DEBUG_LEAKING_SCALARS = $Config{ccflags} =~ m/-DDEBUG_LEAKING_SCALARS/;

#my $C99 = $Config{d_c99_variadic_macros}; # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962
our $MAD = $Config{mad};
my $MYMALLOC = $Config{usemymalloc} eq 'define';
our $HAVE_DLFCN_DLOPEN = $Config{i_dlfcn} && $Config{d_dlopen};

# used by B::OBJECT
sub add_to_isa_cache {
    my ( $k, $v ) = @_;
    die unless defined $k;

    $isa_cache{$k} = $v;
    return;
}

sub add_to_currINC {
    my ( $k, $v ) = @_;
    die unless defined $k;

    $curINC{$k} = $v;
    return;
}

# This the Carp free workaround for DynaLoader::bootstrap
sub DynaLoader::croak { die @_ }

sub walk_and_save_optree;
my $saveoptree_callback = \&walk_and_save_optree;
sub set_callback { $saveoptree_callback = shift }
sub saveoptree { &$saveoptree_callback(@_) }
sub save_main_rest;

sub verbose {
    if (@_) { $verbose = shift; }
    else    { $verbose; }
}

sub module {
    if (@_) { $module = shift; }
    else    { $module; }
}

sub walk_and_save_optree {
    my ( $name, $root, $start ) = @_;
    if ($root) {
        $verbose ? walkoptree_slow( $root, "save" ) : walkoptree( $root, "save" );
    }
    return objsym($start);
}

# Look this up here so we can do just a number compare
# rather than looking up the name of every BASEOP in B::OP
# maybe use contant
our $OP_THREADSV = opnumber('threadsv');
our $OP_DBMOPEN  = opnumber('dbmopen');
our $OP_FORMLINE = opnumber('formline');
our $OP_UCFIRST  = opnumber('ucfirst');

# 1. called from method_named, so hashp should be defined
# 2. called from svop before method_named to cache the $package_pv
sub svop_or_padop_pv {
    my $op = shift;
    my $sv;
    if ( !$op->can("sv") ) {
        if ( $op->can('name') and $op->name eq 'padsv' ) {
            my @c   = comppadlist->ARRAY;
            my @pad = $c[1]->ARRAY;
            return $pad[ $op->targ ]->PV if $pad[ $op->targ ] and $pad[ $op->targ ]->can("PV");

            # This might fail with B::NULL (optimized ex-const pv) entries in the pad.
        }

        # $op->can('pmreplroot') fails for 5.14
        if ( ref($op) eq 'B::PMOP' and $op->pmreplroot->can("sv") ) {
            $sv = $op->pmreplroot->sv;
        }
        else {
            return $package_pv unless $op->flags & 4;

            # op->first is disallowed for !KIDS and OPpCONST_BARE
            return $package_pv if $op->name eq 'const' and $op->flags & 64;
            return $package_pv unless $op->first->can("sv");
            $sv = $op->first->sv;
        }
    }
    else {
        $sv = $op->sv;
    }

    # XXX see SvSHARED_HEK_FROM_PV for the stash in S_method_common pp_hot.c
    # In this hash the CV is stored directly
    if ( $sv and $$sv ) {

        return $sv->PV if $sv->can("PV");
        if ( ref($sv) eq "B::SPECIAL" ) {    # DateTime::TimeZone
                                             # XXX null -> method_named
            warn "NYI S_method_common op->sv==B::SPECIAL, keep $package_pv\n" if $debug{gv};
            return $package_pv;
        }
        if ( $sv->FLAGS & SVf_ROK ) {
            goto missing if $sv->isa("B::NULL");
            my $rv = $sv->RV;
            if ( $rv->isa("B::PVGV") ) {
                my $o = $rv->IO;
                return $o->STASH->NAME if $$o;
            }
            goto missing if $rv->isa("B::PVMG");
            return $rv->STASH->NAME;
        }
        else {
          missing:
            if ( $op->name ne 'method_named' ) {

                # Called from first const/padsv before method_named. no magic pv string, so a method arg.
                # The first const pv as method_named arg is always the $package_pv.
                return $package_pv;
            }
            elsif ( $sv->isa("B::IV") ) {
                warn sprintf(
                    "Experimentally try method_cv(sv=$sv,$package_pv) flags=0x%x",
                    $sv->FLAGS
                );

                # XXX untested!
                return svref_2object( method_cv( $$sv, $package_pv ) );
            }
        }
    }
    else {
        my @c   = comppadlist->ARRAY;
        my @pad = $c[1]->ARRAY;
        return $pad[ $op->targ ]->PV if $pad[ $op->targ ] and $pad[ $op->targ ]->can("PV");
    }
}

sub IsCOW {
    return 0;
}

sub IsCOW_hek {
    return IsCOW( $_[0] ) && !$_[0]->LEN;
}

sub savesym {
    my ( $obj, $value ) = @_;
    no strict 'refs';
    my $sym = sprintf( "s\\_%x", $$obj );
    $B::C::File::symtable{$sym} = $value;
    return $value;
}

sub objsym {
    my $obj = shift;
    no strict 'refs';
    return $B::C::File::symtable{ sprintf( "s\\_%x", $$obj ) };
}

sub getsym {
    my $sym = shift;
    my $value;

    return 0 if $sym eq "sym_0";    # special case
    $value = $B::C::File::symtable{$sym};
    if ( defined($value) ) {
        return $value;
    }
    else {
        warn "warning: undefined symbol $sym\n" if $warn_undefined_syms;
        return "UNUSED";
    }
}

sub delsym {
    my ($obj) = @_;
    my $sym = sprintf( "s\\_%x", $$obj );
    delete $B::C::File::symtable{$sym};
}

sub savere {
    my $re = shift;
    my $flags = shift || 0;
    my $sym;
    my $pv  = $re;
    my $cur = length $pv;
    my $len = 0;            # length( pack "a*", $pv ) + 2;

    xpvsect()->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], 1, %x, {%s}", xpvsect()->index,
            0x4405, ( $C99 ? ".svu_pv=" : "" ) . '(char*)' . savepv($pv)
        )
    );
    $sym = sprintf( "&sv_list[%d]", svsect()->index );

    return ( $sym, length( pack "a*", $re ) );
}

sub constpv {
    return savepv( shift, 1 );
}

sub savepv {
    my $pv      = shift;
    my $const   = shift;
    my $cstring = cstring($pv);

    # decl()->add( sprintf( "/* %s */", $cstring) ) if $debug{pv};
    return $strtable{$cstring} if defined $strtable{$cstring};
    $pv = pack "a*", $pv;
    my $pvsym = sprintf( "pv%d", $pv_index++ );
    $const = " const" if $const;
    if ( defined $max_string_len && length($pv) > $max_string_len ) {
        my $chars = join ', ', map { cchar $_ } split //, $pv;
        decl()->add( sprintf( "Static$const char %s[] = { %s };", $pvsym, $chars ) );
        $strtable{$cstring} = "$pvsym";
    }
    else {
        if ( $cstring ne "0" ) {    # sic
            decl()->add( sprintf( "Static$const char %s[] = %s;", $pvsym, $cstring ) );
            $strtable{$cstring} = "$pvsym";
        }
    }
    return wantarray ? ( $pvsym, length($pv) ) : $pvsym;
}

sub save_rv {
    my ( $sv, $fullname ) = @_;
    if ( !$fullname ) {
        $fullname = '(unknown)';
    }

    my $rv;

    $rv = $sv->RV->save($fullname);
    $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

    return $rv;
}

# => savesym, cur, len, pv, static
sub save_pv_or_rv {
    my ( $sv, $fullname ) = @_;

    my $rok   = $sv->FLAGS & SVf_ROK;
    my $pok   = $sv->FLAGS & SVf_POK;
    my $gmg   = $sv->FLAGS & SVs_GMG;
    my $iscow = IsCOW($sv);
    my ( $cur, $len, $savesym, $pv ) = ( 0, 1, 'NULL', "" );
    my ( $static, $shared_hek );

    # overloaded VERSION symbols fail to xs boot: ExtUtils::CBuilder with Fcntl::VERSION (i91)
    # 5.6: Can't locate object method "RV" via package "B::PV" Carp::Clan
    if ($rok) {

        # this returns us a SV*. 5.8 expects a char* in xpvmg.xpv_pv
        warn "save_pv_or_rv: save_rv(", $sv, ")\n" if $debug{sv};
        $savesym = save_rv( $sv, $fullname );
        $static = 1;    # avoid run-time overwrite of the PV/RV slot (#273)
        if ( $savesym =~ /(\(char\*\))?get_cv\("/ ) {    # Moose::Util::TypeConstraints::Builtins::_RegexpRef
            $static  = 0;
            $pv      = $savesym;
            $savesym = 'NULL';
        }
    }
    else {
        if ($pok) {
            $pv = pack "a*", $sv->PV;
            $cur = ( $sv and $sv->can('CUR') and ref($sv) ne 'B::GV' ) ? $sv->CUR : length($pv);
        }
        else {
            if ( $gmg && $fullname ) {
                no strict 'refs';
                $pv = ( $fullname and ref($fullname) ) ? "${$fullname}" : '';
                $cur = length( pack "a*", $pv );
                $pok = 1;
            }
            else {
                ( $pv, $cur ) = ( "", 0 );
            }
        }
        $shared_hek = ( ( $sv->FLAGS & 0x09000000 ) == 0x09000000 );
        $shared_hek = $shared_hek ? 1 : IsCOW_hek($sv);
        $static = $B::C::const_strings and ( $sv->FLAGS & SVf_READONLY ) ? 1 : 0;
        $static = 0
          if $shared_hek
          or ( $fullname and ( $fullname =~ m/ :pad/ or ( $fullname =~ /^DynaLoader/ and $pv =~ /^boot_/ ) ) );
        $static = 0 if $B::C::const_strings and $fullname and $fullname =~ /^warnings::(Dead)?Bits/;
        if ( $shared_hek and $pok and !$cur ) {    #272 empty key
            warn "use emptystring for empty shared key $fullname\n" if $debug{hv};
            $savesym = "emptystring";
            $static  = 0;
        }

        $static = 0 if $sv->FLAGS & 0x40000000;    # SVpad_NAME

        if ($pok) {
            my $s = "sv_list[" . ( svsect()->index + 1 ) . "]";

            no warnings 'numeric';
            if ( $static and abs($pv) > 0 ) {
                $static = 0;
            }

            # but we can optimize static set-magic ISA entries. #263, #91
            if ( $B::C::const_strings and ref($sv) eq 'B::PVMG' and $sv->FLAGS & SVs_SMG ) {
                $static = 1;                       # warn "static $fullname";
            }
            if ($static) {
                $len = 0;
                $savesym = $iscow ? savepv($pv) : constpv($pv);
                if ( $savesym =~ /^(\(char\*\))?get_cv\("/ ) {    # Moose::Util::TypeConstraints::Builtins::_RegexpRef
                    $static  = 0;
                    $len     = $cur + 1;
                    $pv      = $savesym;
                    $savesym = 'NULL';
                }
                $len = $cur + 2 if $iscow and $cur;

                #push @B::C::static_free, $savesym if $len and $savesym =~ /^pv/ and !$B::C::in_endav;
            }
            else {
                $len = $cur + 1;
                if ($shared_hek) {
                    if ( $savesym eq "emptystring" ) {
                        free()->add("    SvLEN(&$s) = 0;");
                    }
                    else {
                        $len = 0;
                    }
                    free()->add("    SvFAKE_off(&$s);");
                }
                else {
                    $len++ if $iscow and $cur;
                }
            }
        }
        else {
            $len = 0;
        }
    }
    warn sprintf(
        "Saving pv %s %s cur=%d, len=%d, static=%d cow=%d %s\n", $savesym, cstring($pv), $cur, $len,
        $static, $iscow, $shared_hek ? "shared, $fullname" : $fullname
    ) if $debug{pv};
    return ( $savesym, $cur, $len, $pv, $static );
}

# Shared global string in PL_strtab.
# Mostly GvNAME and GvFILE, but also CV prototypes or bareword hash keys.
sub save_hek {
    my $str     = shift;         # not cstring'ed
    my $dynamic = shift;         # not yet implemented. see lexsub CvNAME in CV::save
    my $len     = length $str;

    # force empty string for CV prototypes
    if ( !$len and !@_ ) { wantarray ? return ( "NULL", 0 ) : return "NULL"; }
    if ( defined $hektable{$str} ) {
        return wantarray
          ? ( $hektable{$str}, length( pack "a*", $hektable{$str} ) )
          : $hektable{$str};
    }
    my $cur = length( pack "a*", $str );

    if ( utf8::is_utf8($str) ) {
        my $pv = $str;
        utf8::encode($pv);
        $cur = -length $pv;
    }

    my $sym = sprintf( "hek%d", $hek_index++ );
    $hektable{$str} = $sym;
    my $cstr = cstring($str);
    decl()->add( sprintf( "Static HEK *%s;", $sym ) );
    warn sprintf( "Saving hek %s %s cur=%d\n", $sym, $cstr, $cur )
      if $debug{pv};

    # randomized global shared hash keys:
    #   share_hek needs a non-zero hash parameter, unlike hv_store.
    #   Vulnerable to oCERT-2011-003 style DOS attacks?
    #   user-input (object fields) does not affect strtab, it is pretty safe.
    # But we need to randomize them to avoid run-time conflicts
    #   e.g. "Prototype mismatch: sub bytes::length (_) vs (_)"
    init()->add(
        sprintf(
            "%s = share_hek(%s, %d, %s);",
            $sym, $cstr, $cur, '0'
        )
    );
    wantarray ? ( $sym, $cur ) : $sym;
}

sub ivx ($) {
    my $ivx       = shift;
    my $ivdformat = $Config{ivdformat};
    $ivdformat =~ s/"//g;    #" poor editor
    my $pow    = ( $Config{ivsize} * 4 - 1 );    # poor editor
    my $intmax = ( 1 << $pow ) - 1;
    my $L      = 'L';

    # LL for 32bit -2147483648L or 64bit -9223372036854775808L
    $L = 'LL' if $Config{ivsize} == 2 * $Config{ptrsize};

    # UL if > INT32_MAX = 2147483647
    my $sval = sprintf( "%${ivdformat}%s", $ivx, $ivx > $intmax ? "U$L" : "" );
    if ( $ivx < -$intmax ) {
        $sval = sprintf( "%${ivdformat}%s", $ivx, 'LL' );    # DateTime
    }
    if ( $INC{'POSIX.pm'} ) {

        # i262: LONG_MIN -9223372036854775808L integer constant is so large that it is unsigned
        if ( $ivx == POSIX::LONG_MIN() ) {
            $sval = "PERL_LONG_MIN";
        }
        elsif ( $ivx == POSIX::LONG_MAX() ) {
            $sval = "PERL_LONG_MAX";
        }

        #elsif ($ivx == POSIX::HUGE_VAL()) {
        #  $sval = "HUGE_VAL";
        #}
    }
    $sval = '0' if $sval =~ /(NAN|inf)$/i;
    return $sval;

    #return $C99 ? ".xivu_uv = $sval" : $sval; # this is version dependent
}

# protect from warning: floating constant exceeds range of ‘double’ [-Woverflow]
sub nvx ($) {
    my $nvx       = shift;
    my $nvgformat = $Config{nvgformat};
    $nvgformat =~ s/"//g;    #" poor editor
    my $dblmax = "1.79769313486232e+308";

    # my $ldblmax = "1.18973149535723176502e+4932L"
    my $ll = $Config{d_longdbl} ? "LL" : "L";
    if ( $nvgformat eq 'g' ) {    # a very poor choice to keep precision
                                  # on intel 17-18, on ppc 31, on sparc64/s390 34
        $nvgformat = $Config{uselongdouble} ? '.17Lg' : '.16g';
    }
    my $sval = sprintf( "%${nvgformat}%s", $nvx, $nvx > $dblmax ? $ll : "" );
    if ( $nvx < -$dblmax ) {
        $sval = sprintf( "%${nvgformat}%s", $nvx, $ll );
    }
    if ( $INC{'POSIX.pm'} ) {
        if ( $nvx == POSIX::DBL_MIN() ) {
            $sval = "DBL_MIN";
        }
        elsif ( $nvx == POSIX::DBL_MAX() ) {    #1.797693134862316e+308
            $sval = "DBL_MAX";
        }
    }
    $sval = '0' if $sval =~ /(NAN|inf)$/i;
    $sval .= '.00' if $sval =~ /^-?\d+$/;
    return $sval;
}

# for bytes and utf8 only
# TODO: Carp::Heavy, Exporter::Heavy
# special case: warnings::register via -fno-warnings
sub force_heavy {
    my $pkg       = shift;
    my $pkg_heavy = $pkg . "_heavy.pl";
    no strict 'refs';
    if ( !$include_package{$pkg_heavy} and !exists $savINC{$pkg_heavy} ) {

        #eval qq[sub $pkg\::AUTOLOAD {
        #    require '$pkg_heavy';
        #    goto &\$AUTOLOAD if defined &\$AUTOLOAD;
        #    warn("Undefined subroutine \$AUTOLOAD called");
        #  }];
        #warn "Redefined $pkg\::AUTOLOAD to omit Carp\n" if $debug{gv};
        warn "Forcing early $pkg_heavy\n" if $debug{pkg};
        require $pkg_heavy;
        mark_package( $pkg_heavy, 1 );

        #walk_syms($pkg); #before we stub unloaded CVs
    }
    return svref_2object( \*{ $pkg . "::AUTOLOAD" } );
}

# This pair is needed because B::FAKEOP::save doesn't scalar dereference
# $op->next and $op->sibling

# For 5.8:
# Current workaround/fix for op_free() trying to free statically
# defined OPs is to set op_seq = -1 and check for that in op_free().
# Instead of hardwiring -1 in place of $op->seq, we use $op_seq
# so that it can be changed back easily if necessary. In fact, to
# stop compilers from moaning about a U16 being initialised with an
# uncast -1 (the printf format is %d so we can't tweak it), we have
# to "know" that op_seq is a U16 and use 65535. Ugh.

# For 5.9 the hard coded text is the values for op_opt and op_static in each
# op.  The value of op_opt is irrelevant, and the value of op_static needs to
# be 1 to tell op_free that this is a statically defined op and that is
# shouldn't be freed.

# For 5.10 op_seq = -1 is gone, the temp. op_static also, but we
# have something better, we can set op_latefree to 1, which frees the children
# (e.g. savepvn), but not the static op.

# 5.8: U16 op_seq;
# 5.9.4: unsigned op_opt:1; unsigned op_static:1; unsigned op_spare:5;
# 5.10: unsigned op_opt:1; unsigned op_latefree:1; unsigned op_latefreed:1; unsigned op_attached:1; unsigned op_spare:3;
# 5.18: unsigned op_opt:1; unsigned op_slabbed:1; unsigned op_savefree:1; unsigned op_static:1; unsigned op_spare:3;
# 5.19: unsigned op_opt:1; unsigned op_slabbed:1; unsigned op_savefree:1; unsigned op_static:1; unsigned op_folded:1; unsigned op_spare:2;

# fixme only use opsect common
{
    # should use a static variable
    my $opsect_common;

    sub opsect_common {
        my $opsect_common ||= "next, sibling, ppaddr, " . ( $MAD ? "madprop, " : "" ) . "targ, type, " . "opt, latefree, latefreed, attached, spare" . ", flags, private";

        return $opsect_common;
    }

}

# dummy for B::C, only needed for B::CC
sub label { }

# save alternate ops if defined, and also add labels (needed for B::CC)
sub do_labels ($@) {
    my $op = shift;
    for my $m (@_) {
        if ( ${ $op->$m } ) {
            label( $op->$m );
            $op->$m->save
              if $m ne 'first'
              or ( $op->flags & 4
                and !( $op->name eq 'const' and $op->flags & 64 ) );    #OPpCONST_BARE has no first
        }
    }
}

# XXX Until we know exactly the package name for a method_call
# we improve the method search heuristics by maintaining this mru list.
sub push_package ($) {
    my $p = shift or return;
    warn "save package_pv \"$package_pv\" for method_name from @{[(caller(1))[3]]}\n"
      if $debug{cv}
      or $debug{pkg} and !grep { $p eq $_ } @package_pv;
    @package_pv = grep { $p ne $_ } @package_pv if @package_pv;    # remove duplicates at the end
    unshift @package_pv, $p;                                       # prepend at the front
    mark_package($p);
}

# method_named is in 5.6.1
sub method_named {
    my $name = shift;
    return unless $name;
    my $cop = shift;
    my $loc = $cop ? " at " . $cop->file . " line " . $cop->line : "";

    # Note: the pkg PV is unacessible(?) at PL_stack_base+TOPMARK+1.
    # But it is also at the const or padsv after the pushmark, before all args.
    # See L<perloptree/"Call a method">
    # We check it in op->_save_common
    if ( ref($name) eq 'B::CV' ) {
        warn $name;
        return $name;
    }
    my $method;
    for ( $package_pv, @package_pv, 'main' ) {
        no strict 'refs';
        next unless defined $_;
        $method = $_ . '::' . $name;
        if ( defined(&$method) ) {
            warn sprintf( "Found &%s::%s\n", $_, $name ) if $debug{cv};
            $include_package{$_} = 1;    # issue59
            mark_package( $_, 1 );
            last;
        }
        else {
            if ( my $parent = try_isa( $_, $name ) ) {
                warn sprintf( "Found &%s::%s\n", $parent, $name ) if $debug{cv};
                $method = $parent . '::' . $name;
                $include_package{$parent} = 1;
                last;
            }
            warn "no definition for method_name \"$method\"\n" if $debug{cv};
        }
    }

    $method = $name unless $method;
    if ( exists &$method ) {    # Do not try to save non-existing methods
        warn "save method_name \"$method\"$loc\n" if $debug{cv};
        return svref_2object( \&{$method} );
    }
    else {
        return 0;
    }
}

# scalar: pv. list: (stash,pv,sv)
# pads are not named, but may be typed
sub padop_name {
    my $op = shift;
    my $cv = shift;
    if (
        $op->can('name')
        and (  $op->name eq 'padsv'
            or $op->name eq 'method_named'
            or ref($op) eq 'B::SVOP' )
      )    #threaded
    {
        return () if $cv and ref( $cv->PADLIST ) eq 'B::SPECIAL';
        my @c     = ( $cv and ref($cv) eq 'B::CV' and ref( $cv->PADLIST ) ne 'B::NULL' ) ? $cv->PADLIST->ARRAY : comppadlist->ARRAY;
        my @pad   = $c[1]->ARRAY;
        my @types = $c[0]->ARRAY;
        my $ix    = $op->can('padix') ? $op->padix : $op->targ;
        my $sv    = $pad[$ix];
        my $t     = $types[$ix];
        if ( defined($t) and ref($t) ne 'B::SPECIAL' ) {
            my $pv = $sv->can("PV") ? $sv->PV : ( $t->can('PVX') ? $t->PVX : '' );

            # need to fix B for SVpad_TYPEDI without formal STASH
            my $stash = ( ref($t) eq 'B::PVMG' and ref( $t->SvSTASH ) ne 'B::SPECIAL' ) ? $t->SvSTASH->NAME : '';
            return wantarray ? ( $stash, $pv, $sv ) : $pv;
        }
        elsif ($sv) {
            my $pv    = $sv->PV          if $sv->can("PV");
            my $stash = $sv->STASH->NAME if $sv->can("STASH");
            return wantarray ? ( $stash, $pv, $sv ) : $pv;
        }
    }
}

sub svop_name {
    my $op = shift;
    my $cv = shift;
    my $sv;
    if ( $op->can('name') and $op->name eq 'padsv' ) {
        my @r = padop_name( $op, $cv );
        return wantarray ? @r : ( $r[1] ? $r[1] : $r[0] );
    }
    else {
        if ( !$op->can("sv") ) {
            if ( ref($op) eq 'B::PMOP' and $op->pmreplroot->can("sv") ) {
                $sv = $op->pmreplroot->sv;
            }
            else {
                $sv = $op->first->sv
                  unless $op->flags & 4
                  or ( $op->name eq 'const' and $op->flags & 34 )
                  or $op->first->can("sv");
            }
        }
        else {
            $sv = $op->sv;
        }
        if ( $sv and $$sv ) {
            if ( $sv->FLAGS & SVf_ROK ) {
                return '' if $sv->isa("B::NULL");
                my $rv = $sv->RV;
                if ( $rv->isa("B::PVGV") ) {
                    my $o = $rv->IO;
                    return $o->STASH->NAME if $$o;
                }
                return '' if $rv->isa("B::PVMG");
                return $rv->STASH->NAME;
            }
            else {
                if ( $op->name eq 'gvsv' ) {
                    return wantarray ? ( $sv->STASH->NAME, $sv->NAME ) : $sv->STASH->NAME . '::' . $sv->NAME;
                }
                elsif ( $op->name eq 'gv' ) {
                    return wantarray ? ( $sv->STASH->NAME, $sv->NAME ) : $sv->STASH->NAME . '::' . $sv->NAME;
                }
                else {
                    return
                        $sv->can('STASH') ? $sv->STASH->NAME
                      : $sv->can('NAME')  ? $sv->NAME
                      :                     $sv->PV;
                }
            }
        }
    }
}

# return the next COP for file and line info
sub nextcop {
    my $op = shift;
    while ( $op and ref($op) ne 'B::COP' and ref($op) ne 'B::NULL' ) { $op = $op->next; }
    return ( $op and ref($op) eq 'B::COP' ) ? $op : undef;
}

sub savepvn {
    my ( $dest, $pv, $sv, $cur ) = @_;
    my @init;

    # work with byte offsets/lengths
    $pv = pack "a*", $pv if defined $pv;
    if ( defined $max_string_len && length($pv) > $max_string_len ) {
        push @init, sprintf( "Newx(%s,%u,char);", $dest, length($pv) + 2 );
        my $offset = 0;
        while ( length $pv ) {
            my $str = substr $pv, 0, $max_string_len, '';
            push @init,
              sprintf(
                "Copy(%s,$dest+$offset,%u,char);",
                cstring($str), length($str)
              );
            $offset += length $str;
        }
        push @init, sprintf( "%s[%u] = '\\0';", $dest, $offset );
        warn sprintf( "Copying overlong PV %s to %s\n", cstring($pv), $dest )
          if $debug{sv} or $debug{pv};
    }
    else {
        # If READONLY and FAKE use newSVpvn_share instead. (test 75)
        if ( $sv and ( ( $sv->FLAGS & 0x09000000 ) == 0x09000000 ) ) {
            warn sprintf( "Saving shared HEK %s to %s\n", cstring($pv), $dest ) if $debug{sv};
            my $hek = save_hek($pv);
            push @init, sprintf( "%s = HEK_KEY($hek);", $dest ) unless $hek eq 'NULL';
            if ($DEBUGGING) {    # we have to bypass a wrong HE->HEK assert in hv.c
                push @B::C::static_free, $dest;
            }
        }
        else {
            my $cstr = cstring($pv);
            my $cur =
                $cur ? $cur
              : ( $sv and ref($sv) and $sv->can('CUR') and ref($sv) ne 'B::GV' ) ? $sv->CUR
              :                                                                    length( pack "a*", $pv );
            if ( $sv and IsCOW($sv) ) {
                $pv .= "\0\001";
                $cstr = cstring($pv);
                $cur += 2;
            }
            warn sprintf( "Saving PV %s:%d to %s\n", $cstr, $cur, $dest ) if $debug{sv};
            $cur = 0 if $cstr eq "" and $cur == 7;    # 317
            push @init, sprintf( "%s = savepvn(%s, %u);", $dest, $cstr, $cur );
        }
    }
    return @init;
}

sub B::PVLV::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($in_endav) {
            warn "in_endav: static_free without $sym\n" if $debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $pvsym, $cur, $len, $pv, $static ) = save_pv_or_rv( $sv, $fullname );
    my ( $lvtarg, $lvtarg_sym );    # XXX missing

    xpvlvsect()->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    xpvlvsect()->add(
        sprintf(
            "Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %s, %u, %u, Nullsv, %s",
            $cur,         $len,         nvx( $sv->NVX ),
            $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE )
        )
    );
    svsect()->add(
        sprintf(
            "&xpvlv_list[%d], %lu, 0x%x, {(char*)%s}",
            xpvlvsect()->index, $sv->REFCNT, $sv->FLAGS, $pvsym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( !$static ) {

        init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    $sv->save_magic($fullname);
    savesym( $sv, "&" . $s );
}

sub B::PVIV::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($in_endav) {
            warn "in_endav: static_free without $sym\n" if $debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv( $sv, $fullname );

    xpvivsect()->comment('STASH, MAGIC, cur, len, IVX');
    xpvivsect()->add( sprintf( "Nullhv, {0}, %u, %u, {%s}", $cur, $len, ivx( $sv->IVX ) ) );    # IVTYPE long

    svsect()->add(
        sprintf(
            "&xpviv_list[%d], %u, 0x%x %s",
            xpvivsect()->index, $sv->REFCNT, $sv->FLAGS,
            ", {" . ( $C99 ? ".svu_pv=" : "" ) . "(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( defined($pv) ) {

        if ( !$static ) {
            init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
        }
    }
    savesym( $sv, "&" . $s );
}

sub B::PVNV::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($in_endav) {
            warn "in_endav: static_free without $sym\n" if $debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv( $sv, $fullname );
    my $nvx;
    my $ivx = ivx( $sv->IVX );    # here must be IVX!
    if ( $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {

        # it could be a double, or it could be 2 ints - union xpad_cop_seq
        $nvx = nvx( $sv->NV );
    }
    else {
        if ($C99) {
            $nvx = sprintf(
                ".xpad_cop_seq.xlow = %s, .xpad_cop_seq.xhigh = %s",
                ivx( $sv->COP_SEQ_RANGE_LOW ), ivx( $sv->COP_SEQ_RANGE_HIGH ),
            );
        }
        else {
            $nvx = nvx( $sv->NVX );
        }
    }

    # For some time the stringification works of NVX double to two ints worked ok.
    xpvnvsect()->comment('STASH, MAGIC, cur, len, IVX, NVX');
    xpvnvsect()->add( sprintf( "Nullhv, {0}, %u, %u, {%s}, {%s}", $cur, $len, $ivx, $nvx ) );

    unless ( $C99 or $sv->FLAGS & ( SVf_NOK | SVp_NOK ) ) {
        warn "NV => run-time union xpad_cop_seq init\n" if $debug{sv};
        init()->add(
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xlow = %s;",
                xpvnvsect()->index, ivx( $sv->COP_SEQ_RANGE_LOW )
            ),

            # pad.c: PAD_MAX = I32_MAX (4294967295)
            # U suffix <= "warning: this decimal constant is unsigned only in ISO C90"
            sprintf(
                "xpvnv_list[%d].xnv_u.xpad_cop_seq.xhigh = %s;",
                xpvnvsect()->index, ivx( $sv->COP_SEQ_RANGE_HIGH )
            )
        );
    }

    svsect()->add(
        sprintf(
            "&xpvnv_list[%d], %lu, 0x%x %s",
            xpvnvsect()->index, $sv->REFCNT, $sv->FLAGS,
            ", {" . ( $C99 ? ".svu_pv=" : "" ) . "(char*)$savesym}"
        )
    );
    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( defined($pv) ) {
        if ( !$static ) {
            init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
        }
    }
    savesym( $sv, "&" . $s );
}

sub B::BM::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);

    $sv = bless $sv, "B::BM";
    my $pv  = pack "a*", ( $sv->PV . "\0" . $sv->TABLE );
    my $cur = $sv->CUR;
    my $len = $cur + length( $sv->TABLE ) + 1;
    my $s;

    warn "Saving FBM for GV $sym\n" if $debug{gv};
    init()->add(
        sprintf("$sym = (GV*)newSV_type(SVt_PVGV);"),
        sprintf( "SvFLAGS($sym) = 0x%x;",  $sv->FLAGS ),
        sprintf( "SvREFCNT($sym) = %u;",   $sv->REFCNT + 1 ),
        sprintf( "SvPVX($sym) = %s;",      cstring($pv) ),
        sprintf( "SvCUR_set($sym, %d);",   $cur ),
        sprintf( "SvLEN_set($sym, %d);",   $len ),
        sprintf( "BmRARE($sym) = %d;",     $sv->RARE ),
        sprintf( "BmPREVIOUS($sym) = %d;", $sv->PREVIOUS ),
        sprintf( "BmUSEFUL($sym) = %d;",   $sv->USEFUL )
    );

    # Restore possible additional magic. fbm_compile adds just 'B'.
    $sv->save_magic($fullname);

    return $sym;
}

sub B::PV::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($in_endav) {
            warn "in_endav: static_free without $sym\n" if $debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my $flags = $sv->FLAGS;
    my $shared_hek = ( ( $flags & 0x09000000 ) == 0x09000000 );
    $shared_hek = $shared_hek ? 1 : IsCOW_hek($sv);
    my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv( $sv, $fullname );
    $static = 0 if !( $flags & SVf_ROK ) and $sv->PV and $sv->PV =~ /::bootstrap$/;
    my $refcnt = $sv->REFCNT;

    # static pv, do not destruct. test 13 with pv0 "3".

    if ( $B::C::const_strings and !$shared_hek and $flags & SVf_READONLY and !$len ) {
        $flags &= ~0x01000000;
        warn sprintf( "constpv turn off SVf_FAKE %s %s %s\n", $sym, cstring($pv), $fullname )
          if $debug{pv};
    }
    xpvsect()->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], %lu, 0x%x, {%s}",
            xpvsect()->index, $refcnt, $flags,
            $savesym eq 'NULL'
            ? '0'
            : ( $C99 ? ".svu_pv=(char*)" : "(char*)" ) . $savesym
        )
    );
    if ( defined($pv) and !$static ) {
        if ($shared_hek) {
            my $hek = save_hek($pv);
            init()->add( sprintf( "sv_list[%d].sv_u.svu_pv = HEK_KEY(%s);", svsect()->index, $hek ) )
              unless $hek eq 'NULL';
        }
        else {
            init()->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", svsect()->index ), $pv, $sv, $cur ) );
        }
    }
    if ( $debug{flags} and $DEBUG_LEAKING_SCALARS ) {    # add sv_debug_file
        init()->add(
            sprintf(
                qq(sv_list[%d].sv_debug_file = %s" sv_list[%d] 0x%x";),
                svsect()->index, cstring($pv) eq '0' ? '"NULL"' : cstring($pv),
                svsect()->index, $sv->FLAGS
            )
        );
    }

    my $s = "sv_list[" . svsect()->index . "]";
    svsect()->debug( $fullname, $sv );
    savesym( $sv, "&" . $s );
}

sub lexwarnsym {
    my $pv = shift;
    if ( $lexwarnsym{$pv} ) {
        return $lexwarnsym{$pv};
    }
    else {
        my $sym = sprintf( "lexwarn%d", $pv_index++ );

        # if 8 use UVSIZE, if 4 use LONGSIZE
        my $t = ( $Config{longsize} == 8 ) ? "J" : "L";
        my ($iv) = unpack( $t, $pv );    # unsigned longsize
        if ( $iv >= 0 and $iv <= 2 ) {   # specialWARN: single STRLEN
            decl()->add( sprintf( "Static const STRLEN* %s = %d;", $sym, $iv ) );
        }
        else {                           # sizeof(STRLEN) + (WARNsize)
            my $packedpv = pack( "$t a*", length($pv), $pv );
            decl()->add( sprintf( "Static const char %s[] = %s;", $sym, cstring($packedpv) ) );
        }

        $lexwarnsym{$pv} = $sym;
        return $sym;
    }
}

# pre vs. post 5.8.9/5.9.4 logic for lexical warnings
@B::LEXWARN::ISA = qw(B::PV B::IV);

sub B::LEXWARN::save {
    my ( $sv, $fullname ) = @_;

    return lexwarnsym( $sv->PV );    # look for shared const int's
}

# post 5.11: When called from save_rv not from PMOP::save precomp
sub B::REGEXP::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    return $sym if defined $sym;
    my $pv  = $sv->PV;
    my $cur = $sv->CUR;

    # construct original PV
    $pv =~ s/^(\(\?\^[adluimsx-]*\:)(.*)\)$/$2/;
    $cur -= length( $sv->PV ) - length($pv);
    my $cstr = cstring($pv);

    # Unfortunately this XPV is needed temp. Later replaced by struct regexp.
    xpvsect()->add( sprintf( "Nullhv, {0}, %u, %u", $cur, 0 ) );
    svsect()->add(
        sprintf(
            "&xpv_list[%d], %lu, 0x%x, {%s}",
            xpvsect()->index, $sv->REFCNT, $sv->FLAGS, $cstr
        )
    );
    my $ix = svsect()->index;
    warn "Saving RX $cstr to sv_list[$ix]\n" if $debug{rx} or $debug{sv};

    init()->add(    # replace sv_any->XPV with struct regexp. need pv and extflags
        sprintf(
            "SvANY(&sv_list[$ix]) = SvANY(CALLREGCOMP(newSVpvn(%s, %d), 0x%x));",
            $cstr, $cur, $sv->EXTFLAGS
        )
    );

    init()->add(
        sprintf( "SvCUR(&sv_list[$ix]) = %d;", $cur ),
        "SvLEN(&sv_list[$ix]) = 0;"
    );

    svsect()->debug( $fullname, $sv );
    $sym = savesym( $sv, sprintf( "&sv_list[%d]", $ix ) );
    $sv->save_magic($fullname);
    return $sym;
}

sub save_remap {
    my ( $key, $pkg, $name, $ivx, $mandatory ) = @_;
    my $id = xpvmgsect()->index + 1;

    #my $svid = svsect()->index + 1;
    warn "init remap for $key\: $name in xpvmg_list[$id]\n" if $verbose;
    my $props = { NAME => $name, ID => $id, MANDATORY => $mandatory };
    $init2_remap{$key}{MG} = [] unless $init2_remap{$key}{'MG'};
    push @{ $init2_remap{$key}{MG} }, $props;
}

sub patch_dlsym {
    my ( $sv, $fullname, $ivx ) = @_;
    my $pkg = '';
    if ( ref($sv) eq 'B::PVMG' ) {
        my $stash = $sv->SvSTASH;
        $pkg = $stash->can('NAME') ? $stash->NAME : '';
    }
    my $name = $sv->FLAGS & SVp_POK ? $sv->PVX : "";

    # Encode RT #94221
    if ( $name =~ /encoding$/ and $Encode::VERSION eq '2.58' ) {
        $name =~ s/-/_/g;
        $pkg = 'Encode' if $pkg eq 'Encode::XS';    # TODO foreign classes
        mark_package($pkg) if $fullname eq '(unknown)' and $ITHREADS;
        warn "$pkg $Encode::VERSION with remap support for $name\n" if $verbose;
    }
    elsif ( $pkg eq 'Encode::XS' ) {
        $pkg = 'Encode';
        if ( $fullname eq 'Encode::Encoding{iso-8859-1}' ) {
            $name = "iso8859_1_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{null}' ) {
            $name = "null_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{ascii-ctrl}' ) {
            $name = "ascii_ctrl_encoding";
        }
        elsif ( $fullname eq 'Encode::Encoding{ascii}' ) {
            $name = "ascii_encoding";
        }

        if ( $name and $name !~ /encoding$/ and $Encode::VERSION gt '2.58' and Encode::find_encoding($name) ) {
            my $enc = Encode::find_encoding($name);
            $pkg = ref($enc) if ref($enc) ne 'Encode::XS';
            $pkg =~ s/^(Encode::\w+)(::.*)/$1/;
            $name .= "_encoding";
            $name =~ s/-/_/g;
            warn "$pkg $Encode::VERSION with remap support for $name\n" if $verbose;
            if ( $fullname eq '(unknown)' and $ITHREADS ) {
                mark_package( $pkg, 1 );
                if ( $pkg ne 'Encode' ) {
                    svref_2object( \&{"$pkg\::bootstrap"} )->save;
                    mark_package( 'Encode', 1 );
                }
            }
        }
        else {
            for my $n ( Encode::encodings() ) {    # >=5.16 constsub without name
                my $enc = Encode::find_encoding($n);
                if ( $enc and ref($enc) ne 'Encode::XS' ) {    # resolve alias such as Encode::JP::JIS7=HASH(0x292a9d0)
                    $pkg = ref($enc);
                    $pkg =~ s/^(Encode::\w+)(::.*)/$1/;        # collapse to the @dl_module name
                    $enc = Encode->find_alias($n);
                }
                if ( $enc and ref($enc) eq 'Encode::XS' and $sv->IVX == $$enc ) {
                    $name = $n;
                    $name =~ s/-/_/g;
                    $name .= "_encoding" if $name !~ /_encoding$/;
                    if ( $fullname eq '(unknown)' and $ITHREADS ) {
                        mark_package( $pkg, 1 );
                        if ( $pkg ne 'Encode' ) {
                            svref_2object( \&{"$pkg\::bootstrap"} )->save;
                            mark_package( 'Encode', 1 );
                        }
                    }
                    last;
                }
            }
            if ($name) {
                warn "$pkg $Encode::VERSION remap found for constant $name\n" if $verbose;
            }
            else {
                warn "Warning: Possible missing remap for compile-time XS symbol in $pkg $fullname $ivx [#305]\n";
            }
        }
    }

    # Encode-2.59 uses a different name without _encoding
    elsif ( $name !~ /encoding$/ and $Encode::VERSION gt '2.58' and Encode::find_encoding($name) ) {
        $name .= "_encoding";
        $name =~ s/-/_/g;
        $pkg = 'Encode' unless $pkg;
        warn "$pkg $Encode::VERSION with remap support for $name\n" if $verbose;
    }

    # now that is a weak heuristic, which misses #305
    elsif ( defined($Net::DNS::VERSION)
        and $Net::DNS::VERSION =~ /^0\.(6[789]|7[1234])/ ) {
        if ( $fullname eq 'svop const' ) {
            $name = "ascii_encoding";
            $pkg = 'Encode' unless $pkg;
            warn "Warning: Patch Net::DNS external XS symbol $pkg\::$name $ivx [RT #94069]\n";
        }
    }
    elsif ( $pkg eq 'Net::LibIDN' ) {
        $name = "idn_to_ascii";    # ??
    }

    # new API (only Encode so far)
    if ( $pkg and $name and $name =~ /^[a-zA-Z_0-9-]+$/ ) {    # valid symbol name
        warn "Remap IOK|POK $pkg with $name\n" if $verbose;
        save_remap( $pkg, $pkg, $name, $ivx, 0 );
        $ivx = "0UL /* $ivx => $name */";
        mark_package( $pkg, 1 ) if $fullname =~ /^(svop const|padop)/;
    }
    else {
        warn "Warning: Possible missing remap for compile-time XS symbol in $pkg $fullname $ivx [#305]\n";
    }
    return $ivx;
}

sub B::PVMG::save {
    my ( $sv, $fullname ) = @_;
    my $sym = objsym($sv);
    if ( defined $sym ) {
        if ($in_endav) {
            warn "in_endav: static_free without $sym\n" if $debug{av};
            @B::C::static_free = grep { !/$sym/ } @B::C::static_free;
        }
        return $sym;
    }
    my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv( $sv, $fullname );

    my ( $ivx, $nvx );

    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    if ( ref($sv) eq 'B::REGEXP' ) {
        return B::REGEXP::save( $sv, $fullname );
    }
    else {
        $ivx = ivx( $sv->IVX );    # XXX How to detect HEK* namehek?
        $nvx = nvx( $sv->NVX );    # it cannot be xnv_u.xgv_stash ptr (BTW set by GvSTASH later)

        # See #305 Encode::XS: XS objects are often stored as SvIV(SvRV(obj)). The real
        # address needs to be patched after the XS object is initialized. But how detect them properly?
        # Detect ptr to extern symbol in shared library and remap it in init2
        # Safe and mandatory currently only Net-DNS-0.67 - 0.74.
        # svop const or pad OBJECT,IOK
        if (
            ( ( !$ITHREADS and $fullname and $fullname =~ /^svop const|^padop|^Encode::Encoding| :pad\[1\]/ ) or $ITHREADS )
            and $sv->IVX > 5000000    # some crazy heuristic for a so ptr (> image_base)
            and ref( $sv->SvSTASH ) ne 'B::SPECIAL'
          ) {
            $ivx = patch_dlsym( $sv, $fullname, $ivx );
        }
    }

    if ( $sv->FLAGS & SVf_ROK ) {     # sv => sv->RV cannot be initialized static.
        init()->add( sprintf( "SvRV_set(&sv_list[%d], (SV*)%s);", svsect()->index + 1, $savesym ) )
          if $savesym ne '';
        $savesym = 'NULL';
        $static  = 1;
    }

    xpvmgsect()->comment("STASH, MAGIC, cur, len, xiv_u, xnv_u");
    xpvmgsect()->add(
        sprintf(
            "Nullhv, {0}, %u, %u, {%s}, {%s}",
            $cur, $len, $ivx, $nvx
        )
    );

    svsect()->add(
        sprintf(
            "&xpvmg_list[%d], %lu, 0x%x, {%s}",
            xpvmgsect()->index, $sv->REFCNT, $sv->FLAGS,
            $savesym eq 'NULL'
            ? '0'
            : ( $C99 ? ".svu_pv=(char*)" : "(char*)" ) . $savesym
        )
    );

    svsect()->debug( $fullname, $sv );
    my $s = "sv_list[" . svsect()->index . "]";
    if ( !$static ) {    # do not overwrite RV slot (#273)
                         # XXX comppadnames need &PL_sv_undef instead of 0 (?? which testcase?)
        init()->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    $sym = savesym( $sv, "&" . $s );
    $sv->save_magic($fullname);
    return $sym;
}

# mark threads::shared to be xs-loaded
sub mark_threads {
    if ( $INC{'threads.pm'} ) {
        my $stash = 'threads';
        mark_package($stash);
        $use_xsloader = 1;
        $xsub{$stash} = 'Dynamic-' . $INC{'threads.pm'};
        warn "mark threads for 'P' magic\n" if $debug{mg};
    }
    else {
        warn "ignore to mark threads for 'P' magic\n" if $debug{mg};
    }
    if ( $INC{'threads/shared.pm'} ) {
        my $stash = 'threads::shared';
        mark_package($stash);

        # XXX why is this needed? threads::shared should be initialized automatically
        $use_xsloader = 1;                                        # ensure threads::shared is initialized
        $xsub{$stash} = 'Dynamic-' . $INC{'threads/shared.pm'};
        warn "mark threads::shared for 'P' magic\n" if $debug{mg};
    }
    else {
        warn "ignore to mark threads::shared for 'P' magic\n" if $debug{mg};
    }
}

sub B::PVMG::save_magic {
    my ( $sv, $fullname ) = @_;
    my $sv_flags = $sv->FLAGS;
    if ( $debug{mg} ) {
        my $flagspv = "";
        $fullname = '' unless $fullname;
        $flagspv = $sv->flagspv if $debug{flags} and !$sv->MAGICAL;
        warn sprintf(
            "saving magic for %s $fullname (0x%x) flags=0x%x%s  - called from %s:%s\n",
            class($sv), $$sv, $sv_flags, $debug{flags} ? "(" . $flagspv . ")" : "",
            @{ [ ( caller(1) )[3] ] }, @{ [ ( caller(1) )[2] ] }
        );
    }

    # crashes on STASH=0x18 with HV PERL_MAGIC_overload_table stash %version:: flags=0x3280000c
    # issue267 GetOpt::Long SVf_AMAGIC|SVs_RMG|SVf_OOK
    # crashes with %Class::MOP::Instance:: flags=0x2280000c also
    my $pkg = $sv->SvSTASH;
    if ($$pkg) {
        warn sprintf( "stash isa class(\"%s\") 0x%x\n", $pkg->NAME, $$pkg )
          if $debug{mg} or $debug{gv};

        $pkg->save($fullname);

        no strict 'refs';
        warn sprintf( "xmg_stash = \"%s\" (0x%x)\n", $pkg->NAME, $$pkg )
          if $debug{mg} or $debug{gv};

        # Q: Who is initializing our stash from XS? ->save is missing that.
        # A: We only need to init it when we need a CV
        # defer for XS loaded stashes with AMT magic
        init()->add( sprintf( "SvSTASH_set(s\\_%x, (HV*)s\\_%x);", $$sv, $$pkg ) );
        init()->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
        init()->add("++PL_sv_objcount;") unless ref($sv) eq "B::IO";

        # XXX
        #push_package($pkg->NAME);  # correct code, but adds lots of new stashes
    }

    # Protect our SVs against non-magic or SvPAD_OUR. Fixes tests 16 and 14 + 23
    if ( !$sv->MAGICAL ) {
        warn sprintf(
            "Skipping non-magical PVMG type=%d, flags=0x%x%s\n",
            $sv_flags && 0xff, $sv_flags, $debug{flags} ? "(" . $sv->flagspv . ")" : ""
        ) if $debug{mg};
        return '';
    }
    init()->add( sprintf( "SvREADONLY_off((SV*)s\\_%x);", $$sv ) ) if $sv_flags & SVf_READONLY;

    my @mgchain = $sv->MAGIC;
    my ( $mg, $type, $obj, $ptr, $len, $ptrsv );
    my $magic = '';
    foreach $mg (@mgchain) {
        $type = $mg->TYPE;
        $ptr  = $mg->PTR;
        $len  = $mg->LENGTH;
        $magic .= $type;
        if ( $debug{mg} ) {
            warn sprintf( "%s %s magic\n", $fullname, cchar($type) );

            #eval {
            #  warn sprintf( "magic %s (0x%x), obj %s (0x%x), type %s, ptr %s\n",
            #                class($sv), $$sv, class($obj), $$obj, cchar($type),
            #		      cstring($ptr) );
            #};
        }

        unless ( $type =~ /^[rDn]$/ ) {    # r - test 23 / D - Getopt::Long
                                           # 5.10: Can't call method "save" on unblessed reference
                                           #warn "Save MG ". $obj . "\n" if $PERL510;
                                           # 5.11 'P' fix in B::IV::save, IV => RV
            $obj = $mg->OBJ;
            $obj->save($fullname) if ( ref $obj ne 'SCALAR' );
            mark_threads if $type eq 'P';
        }

        if ( $len == HEf_SVKEY ) {

            # The pointer is an SV* ('s' sigelem e.g.)
            # XXX On 5.6 ptr might be a SCALAR ref to the PV, which was fixed later
            if ( ref($ptr) eq 'SCALAR' ) {
                $ptrsv = svref_2object($ptr)->save($fullname);
            }
            else {
                $ptrsv = $ptr->save($fullname);
            }
            warn "MG->PTR is an SV*\n" if $debug{mg};
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, (char *)%s, %d);",
                    $$sv, $$obj, cchar($type), $ptrsv, $len
                )
            );
        }

        # coverage $Template::Stash::PRIVATE
        elsif ( $type eq 'r' ) {    # qr magic, for 5.6 done in C.xs. test 20
            my $rx = $mg->REGEX;

            # stored by some PMOP *pm = cLOGOP->op_other (pp_ctl.c) in C.xs
            my $pmop = $Regexp{$rx};
            if ( !$pmop ) {
                warn "Warning: C.xs PMOP missing for QR\n";
            }
            else {
                my ( $resym, $relen );
                ( $resym, $relen ) = savere( $mg->precomp );

                my $pmsym = $pmop->save($fullname);
                push @B::C::static_free, $resym;
                init()->add(
                    split /\n/,
                    sprintf <<CODE1, $pmop->pmflags, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = CALLREGCOMP((SV* const)$resym, %d);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE1
            }
        }
        elsif ( $type eq 'D' ) {    # XXX regdata AV - coverage? i95, 903
                                    # see Perl_mg_copy() in mg.c
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
                    $$sv, $fullname eq 'main::-' ? 0 : $$sv, "'D'", cstring($ptr), $len
                )
            );
        }
        elsif ( $type eq 'n' ) {    # shared_scalar is from XS dist/threads-shared
                                    # XXX check if threads is loaded also? otherwise it is only stubbed
            mark_threads;
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, Nullsv, %s, %s, %d);",
                    $$sv, "'n'", cstring($ptr), $len
                )
            );
        }
        elsif ( $type eq 'c' ) {
            init()->add(
                sprintf(
                    "/* AMT overload table for the stash s\\_%x is generated dynamically */",
                    $$sv
                )
            );
        }
        elsif ( $type eq ':' ) {    # symtab magic
                                    # search $ptr in list of pmops and replace it. e.g. (char*)&pmop_list[0]
            my $pmop_ptr = unpack( "J", $mg->PTR );
            my $pmop = $Regexp{$pmop_ptr};
            warn sprintf( "pmop 0x%x not found in our B::C Regexp hash", $pmop_ptr )
              unless $pmop;
            my $pmsym = $pmop ? $pmop->save($fullname) : '&pmop_list[0]';
            init()->add(
                "{\tU32 elements;",    # toke.c: PL_multi_open == '?'
                sprintf( "\tMAGIC *mg = sv_magicext((SV*)s\\_%x, 0, ':', 0, 0, 0);", $$sv ),
                "\telements = mg->mg_len / sizeof(PMOP**);",
                "\tRenewc(mg->mg_ptr, elements + 1, PMOP*, char);",
                sprintf( "\t((OP**)mg->mg_ptr) [elements++] = %s;", $pmsym ),
                "\tmg->mg_len = elements * sizeof(PMOP**);", "}"
            );
        }
        else {
            init()->add(
                sprintf(
                    "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
                    $$sv, $$obj, cchar($type), cstring($ptr), $len
                )
            );
        }
    }
    init()->add( sprintf( "SvREADONLY_on((SV*)s\\_%x);", $$sv ) ) if $sv_flags & SVf_READONLY;
    $magic;
}

sub get_isa ($) {
    no strict 'refs';

    return @{ mro::get_linear_isa( $_[0] ) };
}

# try_isa($pkg,$name) returns the found $pkg for the method $pkg::$name
# If a method can be called (via UNIVERSAL::can) search the ISA's. No AUTOLOAD needed.
# XXX issue 64, empty @ISA if a package has no subs. in Bytecode ok
sub try_isa {
    my ( $cvstashname, $cvname ) = @_;
    return 0 unless defined $cvstashname;
    if ( my $found = $isa_cache{"$cvstashname\::$cvname"} ) {
        return $found;
    }
    no strict 'refs';

    # XXX theoretically a valid shortcut. In reality it fails when $cvstashname is not loaded.
    # return 0 unless $cvstashname->can($cvname);
    my @isa = get_isa($cvstashname);
    warn sprintf(
        "No definition for sub %s::%s. Try \@%s::ISA=(%s)\n",
        $cvstashname, $cvname, $cvstashname, join( ",", @isa )
    ) if $debug{cv};
    for (@isa) {    # global @ISA or in pad
        next if $_ eq $cvstashname;
        warn sprintf( "Try &%s::%s\n", $_, $cvname ) if $debug{cv};
        if ( defined( &{ $_ . '::' . $cvname } ) ) {
            if ( exists( ${ $cvstashname . '::' }{ISA} ) ) {
                svref_2object( \@{ $cvstashname . '::ISA' } )->save("$cvstashname\::ISA");
            }
            $isa_cache{"$cvstashname\::$cvname"} = $_;
            mark_package( $_, 1 );    # force
            return $_;
        }
        else {
            $isa_cache{"$_\::$cvname"} = 0;
            if ( get_isa($_) ) {
                my $parent = try_isa( $_, $cvname );
                if ($parent) {
                    $isa_cache{"$_\::$cvname"}           = $parent;
                    $isa_cache{"$cvstashname\::$cvname"} = $parent;
                    warn sprintf( "Found &%s::%s\n", $parent, $cvname ) if $debug{gv};
                    if ( exists( ${ $parent . '::' }{ISA} ) ) {
                        warn "save \@$parent\::ISA\n" if $debug{pkg};
                        svref_2object( \@{ $parent . '::ISA' } )->save("$parent\::ISA");
                    }
                    if ( exists( ${ $_ . '::' }{ISA} ) ) {
                        warn "save \@$_\::ISA\n" if $debug{pkg};
                        svref_2object( \@{ $_ . '::ISA' } )->save("$_\::ISA");
                    }
                    return $parent;
                }
            }
        }
    }
    return 0;    # not found
}

# If the sub or method is not found:
# 1. try @ISA, mark_package and return.
# 2. try UNIVERSAL::method
# 3. try compile-time expansion of AUTOLOAD to get the goto &sub addresses
sub try_autoload {
    my ( $cvstashname, $cvname ) = @_;
    no strict 'refs';
    return 1 if try_isa( $cvstashname, $cvname );

    no strict 'refs';
    if ( defined( *{ 'UNIVERSAL::' . $cvname }{CODE} ) ) {
        warn "Found UNIVERSAL::$cvname\n" if $debug{cv};
        return svref_2object( \&{ 'UNIVERSAL::' . $cvname } );
    }
    my $fullname = $cvstashname . '::' . $cvname;
    warn sprintf(
        "No definition for sub %s. Try %s::AUTOLOAD\n",
        $fullname, $cvstashname
    ) if $debug{cv};

    # First some exceptions, fooled by goto
    if ( $cvstashname eq 'Config' ) {
        return svref_2object( \&{'Config::launcher'} );
    }
    if ( $fullname eq 'utf8::SWASHNEW' ) {

        # utf8_heavy was loaded so far, so defer to a demand-loading stub
        my $stub = sub { require 'utf8_heavy.pl' unless $savINC{"utf8_heavy.pl"}; goto &utf8::SWASHNEW; };
        return svref_2object($stub);
    }

    # Handle AutoLoader classes. Any more general AUTOLOAD
    # use should be handled by the class itself.
    my @isa = get_isa($cvstashname);
    if ( $cvstashname =~ /^POSIX|Storable|DynaLoader|Net::SSLeay|Class::MethodMaker$/
        or ( exists ${ $cvstashname . '::' }{AUTOLOAD} and grep( $_ eq "AutoLoader", @isa ) ) ) {

        # Tweaked version of AutoLoader::AUTOLOAD
        my $dir = $cvstashname;
        $dir =~ s(::)(/)g;
        warn "require \"auto/$dir/$cvname.al\"\n" if $debug{cv};
        eval { local $SIG{__DIE__}; require "auto/$dir/$cvname.al" unless $INC{"auto/$dir/$cvname.al"} };
        unless ($@) {
            warn "Forced load of \"auto/$dir/$cvname.al\"\n" if $verbose;
            return svref_2object( \&$fullname )
              if defined &$fullname;
        }
    }

    # XXX TODO Check Selfloader (test 31?)
    svref_2object( \*{ $cvstashname . '::AUTOLOAD' } )->save
      if $cvstashname and exists ${ $cvstashname . '::' }{AUTOLOAD};
    svref_2object( \*{ $cvstashname . '::CLONE' } )->save
      if $cvstashname and exists ${ $cvstashname . '::' }{CLONE};
}
sub Dummy_initxs { }

sub B::CV::is_lexsub {
    return 0;
}

sub B::CV::save {
    my ($cv) = @_;
    my $sym = objsym($cv);
    if ( defined($sym) ) {
        warn sprintf( "CV 0x%x already saved as $sym\n", $$cv ) if $$cv and $debug{cv};
        return $sym;
    }
    my $gv = $cv->GV;
    my ( $cvname, $cvstashname, $fullname );
    my $CvFLAGS = $cv->CvFLAGS;
    if ( $gv and $$gv ) {
        $cvstashname = $gv->STASH->NAME;
        $cvname      = $gv->NAME;
        $fullname    = $cvstashname . '::' . $cvname;
        warn sprintf(
            "CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
            $$cv, $$gv, $fullname, $CvFLAGS
        ) if $debug{cv};

        # XXX not needed, we already loaded utf8_heavy
        #return if $fullname eq 'utf8::AUTOLOAD';
        return '0' if $all_bc_subs{$fullname} or skip_pkg($cvstashname);
        $CvFLAGS &= ~0x400;    # no CVf_CVGV_RC otherwise we cannot set the GV
        mark_package( $cvstashname, 1 ) unless $include_package{$cvstashname};
    }
    elsif ( $cv->is_lexsub($gv) ) {
        $fullname = $cv->NAME_HEK;
        warn sprintf("CV NAME_HEK $fullname\n") if $debug{cv};
        if ( $fullname =~ /^(.*)::(.*?)$/ ) {
            $cvstashname = $1;
            $cvname      = $2;
        }
    }

    # XXX TODO need to save the gv stash::AUTOLOAD if exists
    my $root   = $cv->ROOT;
    my $cvxsub = $cv->XSUB;
    my $isconst;
    {
        no strict 'subs';
        $isconst = $CvFLAGS & CVf_CONST;
    }

    if ( !$isconst && $cvxsub && ( $cvname ne "INIT" ) ) {
        my $egv       = $gv->EGV;
        my $stashname = $egv->STASH->NAME;
        $fullname = $stashname . '::' . $cvname;
        if ( $cvname eq "bootstrap" and !$xsub{$stashname} ) {
            my $file = $gv->FILE;
            decl()->add("/* bootstrap $file */");
            warn "Bootstrap $stashname $file\n" if $verbose;
            mark_package($stashname);

            # Without DynaLoader we must boot and link static
            if ( !$Config{usedl} ) {
                $xsub{$stashname} = 'Static';
            }

            # if it not isa('DynaLoader'), it should hopefully be XSLoaded
            # ( attributes being an exception, of course )
            elsif ( !UNIVERSAL::isa( $stashname, 'DynaLoader' ) ) {
                my $stashfile = $stashname;
                $stashfile =~ s/::/\//g;
                if ( $file =~ /XSLoader\.pm$/ ) {    # almost always the case
                    $file = $INC{ $stashfile . ".pm" };
                }
                unless ($file) {                     # do the reverse as DynaLoader: soname => pm
                    my ($laststash) = $stashname =~ /::([^:]+)$/;
                    $laststash = $stashname unless $laststash;
                    my $sofile = "auto/" . $stashfile . '/' . $laststash . '\.' . $Config{dlext};
                    for (@DynaLoader::dl_shared_objects) {
                        if (m{^(.+/)$sofile$}) {
                            $file = $1 . $stashfile . ".pm";
                            last;
                        }
                    }
                }
                $xsub{$stashname} = 'Dynamic-' . $file;
                force_saving_xsloader();
            }
            else {
                $xsub{$stashname} = 'Dynamic';

                # DynaLoader was for sure loaded, before so we execute the branch which
                # does walk_syms and add_hashINC
                mark_package( 'DynaLoader', 1 );
            }

            # INIT is removed from the symbol table, so this call must come
            # from PL_initav->save. Re-bootstrapping  will push INIT back in,
            # so nullop should be sent.
            warn $fullname . "\n" if $debug{sub};
            return qq/NULL/;
        }
        else {
            # XSUBs for IO::File, IO::Handle, IO::Socket, IO::Seekable and IO::Poll
            # are defined in IO.xs, so let's bootstrap it
            my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
            if ( grep { $stashname eq $_ } @IO ) {

                # mark_package('IO', 1);
                # $xsub{IO} = 'Dynamic-'. $INC{'IO.pm'}; # XSLoader (issue59)
                svref_2object( \&IO::bootstrap )->save;
                mark_package( 'IO::Handle',  1 );
                mark_package( 'SelectSaver', 1 );

                #for (@IO) { # mark all IO packages
                #  mark_package($_, 1);
                #}
            }
        }
        warn $fullname . "\n" if $debug{sub};
        unless ( in_static_core( $stashname, $cvname ) ) {
            no strict 'refs';
            warn sprintf( "XSUB $fullname CV 0x%x\n", $$cv )
              if $debug{cv};
            svref_2object( \*{"$stashname\::bootstrap"} )->save
              if $stashname;    # and defined ${"$stashname\::bootstrap"};
                                # delsym($cv);
            return qq/get_cv("$fullname", 0)/;
        }
        else {                  # Those cvs are already booted. Reuse their GP.
                                # Esp. on windows it is impossible to get at the XS function ptr
            warn sprintf( "core XSUB $fullname CV 0x%x\n", $$cv ) if $debug{cv};
            return qq/get_cv("$fullname", 0)/;
        }
    }
    if ( $cvxsub && $cvname eq "INIT" ) {
        no strict 'refs';
        warn $fullname . "\n" if $debug{sub};
        return svref_2object( \&Dummy_initxs )->save;
    }

    if ( $isconst and !( $CvFLAGS & CVf_ANON ) ) {
        my $stash = $gv->STASH;
        warn sprintf( "CV CONST 0x%x %s::%s\n", $$gv, $cvstashname, $cvname )
          if $debug{cv};

        # warn sprintf( "%s::%s\n", $cvstashname, $cvname) if $debug{sub};
        my $stsym = $stash->save;
        my $name  = cstring($cvname);
        my $sv    = $cv->XSUBANY;
        my $vsym  = $sv->save;
        my $cvi   = "cv" . $cv_index;
        decl()->add("Static CV* $cvi;");
        init()->add("$cvi = newCONSTSUB( $stsym, $name, (SV*)$vsym );");
        my $sym = savesym( $cv, $cvi );
        $cv_index++;
        return $sym;
    }

    # This define is forwarded to the real sv below
    # The new method, which saves a SV only works since 5.10 (? Does not work in newer perls)
    my $sv_ix = svsect()->index + 1;
    my $xpvcv_ix;
    my $new_cv_fw = 0;
    if ($new_cv_fw) {
        $sym = savesym( $cv, "CVIX$sv_ix" );
    }
    else {
        svsect()->add("CVIX$sv_ix");
        svsect()->debug( "&" . $fullname, $cv );
        $xpvcv_ix = xpvcvsect()->index + 1;
        xpvcvsect()->add("XPVCVIX$xpvcv_ix");

        # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
        $sym = savesym( $cv, "&sv_list[$sv_ix]" );
    }

    warn sprintf( "saving $fullname CV 0x%x as $sym\n", $$cv )
      if $debug{cv};

    if ( $fullname eq 'utf8::SWASHNEW' ) {    # bypass utf8::AUTOLOAD, a new 5.13.9 mess
        require "utf8_heavy.pl" unless $savINC{"utf8_heavy.pl"};

        # sub utf8::AUTOLOAD {}; # How to ignore &utf8::AUTOLOAD with Carp? The symbol table is
        # already polluted. See issue 61 and force_heavy()
        svref_2object( \&{"utf8\::SWASHNEW"} )->save;
    }

    if ( $fullname eq 'IO::Socket::SSL::SSL_Context::new' ) {
        if ( $IO::Socket::SSL::VERSION ge '1.956' and $IO::Socket::SSL::VERSION lt '1.984' ) {
            warn "Warning: Your IO::Socket::SSL version $IO::Socket::SSL::VERSION is too old to create\n" . "  a server. Need to upgrade IO::Socket::SSL to 1.984 [CPAN #95452]\n";
        }
    }

    if ( !$$root && !$cvxsub ) {
        my $reloaded;
        if ( $cvstashname =~ /^(bytes|utf8)$/ ) {    # no autoload, force compile-time
            force_heavy($cvstashname);
            $cv       = svref_2object( \&{"$cvstashname\::$cvname"} );
            $reloaded = 1;
        }
        elsif ( $fullname eq 'Coro::State::_jit' ) {    # 293
                                                        # need to force reload the jit src
            my ($pl) = grep { m|^Coro/jit-| } keys %INC;
            if ($pl) {
                delete $INC{$pl};
                require $pl;
                $cv       = svref_2object( \&{$fullname} );
                $reloaded = 1;
            }
        }
        if ($reloaded) {
            $gv = $cv->GV;
            warn sprintf(
                "Redefined CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
                $$cv, $$gv, $fullname, $CvFLAGS
            ) if $debug{cv};
            $sym    = savesym( $cv, $sym );
            $root   = $cv->ROOT;
            $cvxsub = $cv->XSUB;
        }
    }
    if ( !$$root && !$cvxsub ) {
        if ( my $auto = try_autoload( $cvstashname, $cvname ) ) {
            if ( ref $auto eq 'B::CV' ) {    # explicit goto or UNIVERSAL
                $root   = $auto->ROOT;
                $cvxsub = $auto->XSUB;
                if ($$auto) {

                    # XXX This has now created a wrong GV name!
                    my $oldcv = $cv;
                    $cv = $auto;             # This is new. i.e. via AUTOLOAD or UNIVERSAL, in another stash
                    my $gvnew = $cv->GV;
                    if ($$gvnew) {
                        if ( $cvstashname ne $gvnew->STASH->NAME or $cvname ne $gvnew->NAME ) {    # UNIVERSAL or AUTOLOAD
                            my $newname = $gvnew->STASH->NAME . "::" . $gvnew->NAME;
                            warn " New $newname autoloaded. remove old cv\n" if $debug{sub};       # and wrong GV?
                            unless ($new_cv_fw) {
                                svsect()->remove;
                                xpvcvsect()->remove;
                            }
                            delsym($oldcv);

                            no strict 'refs';
                            my $newsym = svref_2object( \*{$newname} )->save;
                            my $cvsym = defined objsym($cv) ? objsym($cv) : $cv->save($newname);
                            if ( my $oldsym = objsym($gv) ) {
                                warn "Alias polluted $oldsym to $newsym\n" if $debug{gv};
                                init()->add("$oldsym = $newsym;");
                                delsym($gv);
                            }    # else {
                                 #init()->add("GvCV_set(gv_fetchpv(\"$fullname\", GV_ADD, SVt_PV), (CV*)NULL);");
                                 #}
                            return $cvsym;
                        }
                    }
                    $sym = savesym( $cv, "&sv_list[$sv_ix]" );    # GOTO
                    warn "$fullname GOTO\n" if $verbose;
                }
            }
            else {
                # Recalculated root and xsub
                $root   = $cv->ROOT;
                $cvxsub = $cv->XSUB;
                my $gv = $cv->GV;
                if ($$gv) {
                    if ( $cvstashname ne $gv->STASH->NAME or $cvname ne $gv->NAME ) {    # UNIVERSAL or AUTOLOAD
                        my $newname = $gv->STASH->NAME . "::" . $gv->NAME;
                        warn "Recalculated root and xsub $newname. remove old cv\n" if $verbose;
                        svsect()->remove;
                        xpvcvsect()->remove;
                        delsym($cv);
                        return $cv->save($newname);
                    }
                }
            }
            if ( $$root || $cvxsub ) {
                warn "Successful forced autoload\n" if $verbose and $debug{cv};
            }
        }
    }
    if ( !$$root ) {
        if ( exists &$fullname ) {
            warn "Warning: Empty &" . $fullname . "\n" if $debug{sub};
            init()->add("/* empty CV $fullname */") if $verbose or $debug{sub};
        }
        elsif ( $cv->is_lexsub($gv) ) {

            # need to find the attached lexical sub (#130 + #341) at run-time
            # in the PadNAMES array. So keep the empty PVCV
            warn "lexsub &" . $fullname . " saved as empty $sym\n" if $debug{sub};
        }
        else {
            warn "Warning: &" . $fullname . " not found\n" if $debug{sub};
            init()->add("/* CV $fullname not found */") if $verbose or $debug{sub};

            # This block broke test 15, disabled
            if ( $sv_ix == svsect()->index and !$new_cv_fw ) {    # can delete, is the last SV
                warn "No definition for sub $fullname (unable to autoload), skip CV[$sv_ix]\n"
                  if $debug{cv};
                svsect()->remove;
                xpvcvsect()->remove;
                delsym($cv);

                # Empty CV (methods) must be skipped not to disturb method resolution
                # (e.g. t/testm.sh POSIX)
                return '0';
            }
            else {
                # interim &AUTOLOAD saved, cannot delete. e.g. Fcntl, POSIX
                warn "No definition for sub $fullname (unable to autoload), stub CV[$sv_ix]\n"
                  if $debug{cv} or $verbose;

                # continue, must save the 2 symbols from above
            }
        }
    }

    my $startfield = 0;
    my $padlist    = $cv->PADLIST;
    $B::C::curcv = $cv;
    my $padlistsym = 'NULL';
    my $pv         = $cv->PV;
    my $xsub       = 0;
    my $xsubany    = "Nullany";
    if ($$root) {
        warn sprintf(
            "saving op tree for CV 0x%x, root=0x%x\n",
            $$cv, $$root
        ) if $debug{cv} and $debug{gv};
        my $ppname = "";
        if ( $cv->is_lexsub($gv) ) {
            my $name = $cv->can('NAME_HEK') ? $cv->NAME_HEK : "anonlex";
            $ppname   = "pp_lexsub_" . $name;
            $fullname = "<lex>" . $name;
        }
        elsif ( $gv and $$gv ) {
            my ( $stashname, $gvname );
            $stashname = $gv->STASH->NAME;
            $gvname    = $gv->NAME;
            $fullname  = $stashname . '::' . $gvname;
            $ppname    = ( ${ $gv->FORM } == $$cv ) ? "pp_form_" : "pp_sub_";
            if ( $gvname ne "__ANON__" ) {
                $ppname .= ( $stashname eq "main" ) ? $gvname : "$stashname\::$gvname";
                $ppname =~ s/::/__/g;
                $ppname =~ s/(\W)/sprintf("0x%x", ord($1))/ge;
                if ( $gvname eq "INIT" ) {
                    $ppname .= "_$initsub_index";
                    $initsub_index++;
                }
            }
        }
        if ( !$ppname ) {
            $ppname = "pp_anonsub_$anonsub_index";
            $anonsub_index++;
        }
        $startfield = saveoptree( $ppname, $root, $cv->START, $padlist->ARRAY );

        #warn sprintf( "done saving op tree for CV 0x%x, flags (%s), name %s, root=0x%x => start=%s\n",
        #  $$cv, $debug{flags}?$cv->flagspv:sprintf("0x%x",$cv->FLAGS), $ppname, $$root, $startfield )
        #  if $debug{cv};
        # XXX missing cv_start for AUTOLOAD on 5.8
        $startfield = objsym( $root->next ) unless $startfield;    # 5.8 autoload has only root
        $startfield = "0" unless $startfield;
        if ($$padlist) {

            # XXX readonly comppad names and symbols invalid
            #local $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
            warn sprintf( "saving PADLIST 0x%x for CV 0x%x\n", $$padlist, $$cv )
              if $debug{cv} and $debug{gv};

            # XXX avlen 2
            $padlistsym = $padlist->save( $fullname . ' :pad' );
            warn sprintf(
                "done saving %s 0x%x for CV 0x%x\n",
                $padlistsym, $$padlist, $$cv
            ) if $debug{cv} and $debug{gv};

            # do not record a forward for the pad only

            init()->add("CvPADLIST($sym) = $padlistsym;");
        }
        warn $fullname . "\n" if $debug{sub};
    }
    elsif ( $cv->is_lexsub($gv) ) {
        ;
    }
    elsif ( !exists &$fullname ) {
        warn $fullname . " not found\n" if $debug{sub};
        warn "No definition for sub $fullname (unable to autoload)\n"
          if $debug{cv};
        init()->add("/* $fullname not found */") if $verbose or $debug{sub};

        # XXX empty CV should not be saved. #159, #235
        # svsect()->remove( $sv_ix );
        # xpvcvsect()->remove( $xpvcv_ix );
        # delsym( $cv );
        if ( !$new_cv_fw ) {
            symsect()->add("XPVCVIX$xpvcv_ix\t0");
        }
        $CvFLAGS &= ~0x1000;                   # CVf_DYNFILE
        $CvFLAGS &= ~0x400 if $gv and $$gv;    #CVf_CVGV_RC
        symsect()->add(
            sprintf(
                "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
                $sv_ix, $xpvcv_ix, $cv->REFCNT, $CvFLAGS
            )
        );
        return qq/get_cv("$fullname", 0)/;
    }

    # Now it is time to record the CV
    if ($new_cv_fw) {
        $sv_ix = svsect()->index + 1;
        if ( !$cvforward{$sym} ) {    # avoid duplicates
            symsect()->add( sprintf( "$sym\t&sv_list[%d]", $sv_ix ) );    # forward the old CVIX to the new CV
            $cvforward{$sym}++;
        }
        $sym = savesym( $cv, "&sv_list[$sv_ix]" );
    }

    # $pv = '' unless defined $pv;    # Avoid use of undef warnings
    #warn sprintf( "CV prototype %s for CV 0x%x\n", cstring($pv), $$cv )
    #  if $pv and $debug{cv};
    my $proto = defined $pv ? cstring($pv) : 'NULL';
    my $pvsym = 'NULL';
    my $cur   = defined $pv ? $cv->CUR : 0;
    my $len   = $cur + 1;
    $len++ if IsCOW($cv);
    $len = 0 if $B::C::const_strings;

    # need to survive cv_undef as there is no protection against static CVs
    my $refcnt = $cv->REFCNT + 1;

    # GV cannot be initialized statically
    my $xcv_outside = ${ $cv->OUTSIDE };
    if ( $xcv_outside == ${ main_cv() } and !$MULTI ) {

        # Provide a temp. debugging hack for CvOUTSIDE. The address of the symbol &PL_main_cv
        # is known to the linker, the address of the value PL_main_cv not. This is set later
        # (below) at run-time.
        $xcv_outside = '&PL_main_cv';
    }
    elsif ( ref( $cv->OUTSIDE ) eq 'B::CV' ) {
        $xcv_outside = 0;    # just a placeholder for a run-time GV
    }

    $pvsym = save_hek($pv);

    # XXX issue 84: we need to check the cv->PV ptr not the value.
    # "" is different to NULL for prototypes
    $len = $cur ? $cur + 1 : 0;

    # TODO:
    # my $ourstash = "0";  # TODO stash name to bless it (test 16: "main::")

    # cv_undef wants to free it when CvDYNFILE(cv) is true.
    # E.g. DateTime: boot_POSIX. newXS reuses cv if autoloaded. So turn it off globally.
    $CvFLAGS &= ~0x1000;    # CVf_DYNFILE off
    my $xpvc = sprintf

      # stash magic cur len cvstash start root cvgv cvfile cvpadlist     outside outside_seq cvflags cvdepth
      (
        "Nullhv, {0}, %u, %u, %s, {%s}, {s\\_%x}, %s, %s, %s, (CV*)%s, %s, 0x%x, %d",
        $cur,        $len, "Nullhv",    #CvSTASH later
        $startfield, $$root,
        "0",                            #GV later
        "NULL",                         #cvfile later (now a HEK)
        $padlistsym,
        $xcv_outside,                   #if main_cv set later
        ivx( $cv->OUTSIDE_SEQ ),
        $CvFLAGS,
        $cv->DEPTH
      );

    # repro only with 5.15.* threaded -q (70c0620) Encode::Alias::define_alias
    warn "lexwarnsym in XPVCV OUTSIDE: $xpvc" if $xpvc =~ /, \(CV\*\)iv\d/;    # t/testc.sh -q -O3 227
    if ( !$new_cv_fw ) {
        symsect()->add("XPVCVIX$xpvcv_ix\t$xpvc");

        #symsect()->add
        #  (sprintf("CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}"),
        #	   $sv_ix, $xpvcv_ix, $cv->REFCNT, $cv->FLAGS
        #	  ));
    }
    else {
        xpvcvsect()->comment('STASH mg_u cur len CV_STASH START_U ROOT_U GV file PADLIST OUTSIDE outside_seq flags depth');
        xpvcvsect()->add($xpvc);
        svsect()->add(
            sprintf(
                "&xpvcv_list[%d], %lu, 0x%x, {0}",
                xpvcvsect()->index, $cv->REFCNT, $cv->FLAGS
            )
        );
        svsect()->debug( $fullname, $cv );
    }

    if ($$cv) {

        my $gvstash = $gv->STASH;

        # defer GvSTASH because with DEBUGGING it checks for GP but
        # there's no GP yet.
        # But with -fstash the gvstash is set later
        init()->add(
            sprintf(
                "GvXPVGV(s\\_%x)->xnv_u.xgv_stash = s\\_%x;",
                $$cv, $$gvstash
            )
        ) if $gvstash and !$B::C::stash;
        warn sprintf( "done saving GvSTASH 0x%x for CV 0x%x\n", $$gvstash, $$cv )
          if $gvstash
          and $debug{cv}
          and $debug{gv};

    }
    if ( $cv->OUTSIDE_SEQ ) {
        my $cop = $B::C::File::symtable{ sprintf( "s\\_%x", $cv->OUTSIDE_SEQ ) };
        init()->add( sprintf( "CvOUTSIDE_SEQ(%s) = %s;", $sym, $cop ) ) if $cop;
    }

    $xcv_outside = ${ $cv->OUTSIDE };
    if ( $xcv_outside == ${ main_cv() } or ref( $cv->OUTSIDE ) eq 'B::CV' ) {

        # patch CvOUTSIDE at run-time
        if ( $xcv_outside == ${ main_cv() } ) {
            init()->add(
                "CvOUTSIDE($sym) = PL_main_cv;",
                "SvREFCNT_inc(PL_main_cv);"
            );
        }
        else {
            init()->add( sprintf( "CvOUTSIDE($sym) = (CV*)s\\_%x;", $xcv_outside ) );
        }
    }

    if ( $gv and $$gv ) {

        #test 16: Can't call method "FETCH" on unblessed reference. gdb > b S_method_common
        warn sprintf( "Saving GV 0x%x for CV 0x%x\n", $$gv, $$cv ) if $debug{cv} and $debug{gv};
        $gv->save;

        init()->add( sprintf( "CvGV_set((CV*)%s, (GV*)%s);", $sym, objsym($gv) ) );

        # Since 5.13.3 and CvGV_set there are checks that the CV is not RC (refcounted).
        # Assertion "!CvCVGV_RC(cv)" failed: file "gv.c", line 219, function: Perl_cvgv_set
        # We init with CvFLAGS = 0 and set it later, as successfully done in the Bytecode compiler
        if ( $CvFLAGS & 0x0400 ) {    # CVf_CVGV_RC
            warn sprintf(
                "CvCVGV_RC turned off. CV flags=0x%x %s CvFLAGS=0x%x \n",
                $cv->FLAGS, $debug{flags} ? $cv->flagspv : "", $CvFLAGS & ~0x400
            ) if $debug{cv};
            init()->add(
                sprintf(
                    "CvFLAGS((CV*)%s) = 0x%x; %s", $sym, $CvFLAGS,
                    $debug{flags} ? "/* " . $cv->flagspv . " */" : ""
                )
            );
        }
        init()->add("CvSTART($sym) = $startfield;");    # XXX TODO someone is overwriting CvSTART also

        warn sprintf(
            "done saving GV 0x%x for CV 0x%x\n",
            $$gv, $$cv
        ) if $debug{cv} and $debug{gv};
    }
    unless ($optimize_cop) {
        if ($MULTI) {
            init()->add( savepvn( "CvFILE($sym)", $cv->FILE ) );
        }
        else {
            init()->add( sprintf( "CvFILE(%s) = %s;", $sym, cstring( $cv->FILE ) ) );
        }
    }
    my $stash = $cv->STASH;
    if ( $$stash and ref($stash) ) {

        # init()->add("/* saving STASH $fullname */\n" if $debug{cv};
        $stash->save($fullname);

        # $sym fixed test 27
        init()->add( sprintf( "CvSTASH_set((CV*)$sym, s\\_%x);", $$stash ) );

        warn sprintf( "done saving STASH 0x%x for CV 0x%x\n", $$stash, $$cv )
          if $debug{cv} and $debug{gv};
    }
    my $magic = $cv->MAGIC;
    if ( $magic and $$magic ) {
        $cv->save_magic($fullname);    # XXX will this work?
    }
    if ( !$new_cv_fw ) {
        symsect()->add(
            sprintf(
                "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
                $sv_ix, $xpvcv_ix, $cv->REFCNT, $cv->FLAGS
            )
        );
    }
    if ($cur) {
        warn sprintf( "Saving CV proto %s for CV $sym 0x%x\n", cstring($pv), $$cv ) if $debug{cv};
    }

    # issue 84: empty prototypes sub xx(){} vs sub xx{}
    if ( defined $pv ) {
        if ($cur) {
            init()->add( sprintf( "SvPVX(&sv_list[%d]) = HEK_KEY(%s);", $sv_ix, $pvsym ) );
        }
        elsif ( !$B::C::const_strings ) {    # not static, they are freed when redefined
            init()->add(
                sprintf(
                    "SvPVX(&sv_list[%d]) = savepvn(%s, %u);",
                    $sv_ix, $proto, $cur
                )
            );
        }
        else {
            init()->add(
                sprintf(
                    "SvPVX(&sv_list[%d]) = %s;",
                    $sv_ix, $proto
                )
            );
        }
    }
    return $sym;
}

my @_v = Internals::V();
sub __ANON__::_V { @_v }

sub B::GV::save {
    my ( $gv, $filter ) = @_;
    my $sym = objsym($gv);
    if ( defined($sym) ) {
        warn sprintf( "GV 0x%x already saved as $sym\n", $$gv ) if $debug{gv};
        return $sym;
    }
    else {
        my $ix = $gv_index++;
        $sym = savesym( $gv, "gv_list[$ix]" );
        warn sprintf( "Saving GV 0x%x as $sym\n", $$gv ) if $debug{gv};
    }

    warn sprintf(
        "  GV %s $sym type=%d, flags=0x%x %s\n", $gv->NAME,

        # B::SV::SvTYPE not with 5.6
        B::SV::SvTYPE($gv), $gv->FLAGS
    ) if $debug{gv};

    if ( $gv->FLAGS & 0x40000000 ) {    # SVpbm_VALID
        warn sprintf("  GV $sym isa FBM\n") if $debug{gv};
        return B::BM::save($gv);
    }

    my $gvname = $gv->NAME;
    my $package;
    if ( ref( $gv->STASH ) eq 'B::SPECIAL' ) {
        $package = '__ANON__';
        warn sprintf("GV STASH = SPECIAL $gvname\n") if $debug{gv};
    }
    else {
        $package = $gv->STASH->NAME;
    }
    return $sym if skip_pkg($package);

    my $fullname = $package . "::" . $gvname;
    my $fancyname;
    if ( $filter and $filter =~ m/ :pad/ ) {
        $fancyname = cstring($filter);
        $filter    = 0;
    }
    else {
        $fancyname = cstring($fullname);
    }

    # checked for defined'ness in Carp. So the GV must exist, the CV not
    if ( $fullname =~ /^threads::(tid|AUTOLOAD)$/ and !$ITHREADS ) {
        $filter = 8;
    }

    my $is_empty = $gv->is_empty;
    if ( !defined $gvname and $is_empty ) {    # 5.8 curpad name
        return q/(SV*)&PL_sv_undef/;
    }
    my $name    = $package eq 'main' ? cstring($gvname) : cstring($fullname);
    my $notqual = $package eq 'main' ? 'GV_NOTQUAL'     : '0';
    warn "  GV name is $fancyname\n" if $debug{gv};
    my $egvsym;
    my $is_special = ref($gv) eq 'B::SPECIAL';

    if ( $fullname =~ /^(bytes|utf8)::AUTOLOAD$/ ) {
        $gv = force_heavy($package);           # defer to run-time autoload, or compile it in?
        $sym = savesym( $gv, $sym );           # override new gv ptr to sym
    }
    if ( !$is_empty ) {
        my $egv = $gv->EGV;
        unless ( ref($egv) eq 'B::SPECIAL' or ref( $egv->STASH ) eq 'B::SPECIAL' ) {
            my $estash = $egv->STASH->NAME;
            if ( $$gv != $$egv ) {
                warn(
                    sprintf(
                        "EGV name is %s, saving it now\n",
                        $estash . "::" . $egv->NAME
                    )
                ) if $debug{gv};
                $egvsym = $egv->save;
            }
        }
    }

    my $core_syms = {
        ENV    => 'PL_envgv',
        ARGV   => 'PL_argvgv',
        INC    => 'PL_incgv',
        STDIN  => 'PL_stdingv',
        STDERR => 'PL_stderrgv',
        "\010" => 'PL_hintgv',     # ^H
        "_"    => 'PL_defgv',
        "@"    => 'PL_errgv',
        "\022" => 'PL_replgv',     # ^R
    };
    my $is_coresym;

    # those are already initialized in init_predump_symbols()
    # and init_main_stash()
    for my $s ( sort keys %$core_syms ) {
        if ( $fullname eq 'main::' . $s ) {
            $sym = savesym( $gv, $core_syms->{$s} );

            # init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
            # return $sym;
            $is_coresym++;
        }
    }
    if ( $fullname =~ /^main::std(in|out|err)$/ ) {    # same as uppercase above
        init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
        return $sym;
    }
    elsif ( $fullname eq 'main::0' ) {                 # dollar_0 already handled before, so don't overwrite it
        init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PV);]);
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
        return $sym;
    }

    # gv_fetchpv loads Errno resp. Tie::Hash::NamedCapture, but needs *INC #90
    #elsif ( $fullname eq 'main::!' or $fullname eq 'main::+' or $fullname eq 'main::-') {
    #  init2()->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PVGV);]); # defer until INC is setup
    #  init2()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    #  return $sym;
    #}
    my $svflags    = $gv->FLAGS;
    my $savefields = 0;
    sub Save_HV()   { 1 }
    sub Save_AV()   { 2 }
    sub Save_SV()   { 4 }
    sub Save_CV()   { 8 }
    sub Save_FORM() { 16 }
    sub Save_IO()   { 32 }

    my $gp;
    my $gvadd = $notqual ? "$notqual|GV_ADD" : "GV_ADD";
    if ( $gv->isGV_with_GP and !$is_coresym ) {
        $gp = $gv->GP;    # B limitation
                          # warn "XXX EGV='$egvsym' for IMPORTED_HV" if $gv->GvFLAGS & 0x40;
        if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
            warn(
                sprintf(
                    "Shared GV alias for *$fullname 0x%x%s %s to $egvsym\n",
                    $svflags, $debug{flags} ? "(" . $gv->flagspv . ")" : "",
                )
            ) if $debug{gv};

            # Shared glob *foo = *bar
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd|GV_ADDMULTI, SVt_PVGV);]);
            init()->add("GvGP_set($sym, GvGP($egvsym));");
            $is_empty = 1;
        }
        elsif ( $gp and exists $gptable{ 0 + $gp } ) {
            warn(
                sprintf(
                    "Shared GvGP for *$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $debug{gv};
            init()->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
            init()->add( sprintf( "GvGP_set($sym, %s);", $gptable{ 0 + $gp } ) );
            $is_empty = 1;
        }
        elsif ( $gp and !$is_empty and $gvname =~ /::$/ ) {
            warn(
                sprintf(
                    "Shared GvGP for stash %$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $debug{gv};
            init()->add(qq[$sym = gv_fetchpv($name, GV_ADD, SVt_PVHV);]);
            $gptable{ 0 + $gp } = "GvGP($sym)" if 0 + $gp;
        }
        elsif ( $gp and !$is_empty ) {
            warn(
                sprintf(
                    "New GV for *$fullname 0x%x%s %s GP:0x%x\n",
                    $svflags, $debug{flags} ? "(" . $gv->flagspv . ")" : "",
                    $gv->FILE, $gp
                )
            ) if $debug{gv};

            # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
            $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
            $gptable{ 0 + $gp } = "GvGP($sym)";
        }
        else {
            init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PVGV);]);
        }
    }
    elsif ( !$is_coresym ) {
        init()->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
    }
    my $gvflags = $gv->GvFLAGS;

    init()->add(
        sprintf(
            "SvFLAGS($sym) = 0x%x;%s", $svflags,
            $debug{flags} ? " /* " . $gv->flagspv . " */" : ""
        ),
        sprintf(
            "GvFLAGS($sym) = 0x%x; %s", $gvflags,
            $debug{flags} ? "/* " . $gv->flagspv(SVt_PVGV) . " */" : ""
        )
    );
    init()->add(
        sprintf(
            "GvLINE($sym) = %d;",
            (
                $gv->LINE > 2147483647    # S32 INT_MAX
                ? 4294967294 - $gv->LINE
                : $gv->LINE
            )
        )
    ) unless $is_empty;

    # walksymtable creates an extra reference to the GV (#197)
    if ( $gv->REFCNT > 1 ) {
        init()->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    }
    return $sym if $is_empty;

    my $gvrefcnt = $gv->GvREFCNT;
    if ( $gvrefcnt > 1 ) {
        init()->add( sprintf( "GvREFCNT($sym) += %u;", $gvrefcnt - 1 ) );
    }

    warn "check which savefields for \"$gvname\"\n" if $debug{gv};

    # some non-alphabetic globs require some parts to be saved
    # ( ex. %!, but not $! )
    if ( $gvname !~ /^([^A-Za-z]|STDIN|STDOUT|STDERR|ARGV|SIG|ENV)$/ ) {
        $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname eq 'main::!' ) {    #Errno
        $savefields = Save_HV | Save_SV | Save_CV;
    }
    elsif ( $fullname eq 'main::ENV' or $fullname eq 'main::SIG' ) {
        $savefields = Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname eq 'main::ARGV' ) {
        $savefields = Save_HV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    elsif ( $fullname =~ /^main::STD(IN|OUT|ERR)$/ ) {
        $savefields = Save_FORM | Save_IO;
    }
    $savefields &= ~$filter if ( $filter
        and $filter !~ m/ :pad/
        and $filter =~ /^\d+$/
        and $filter > 0
        and $filter < 64 );

    # issue 79: Only save stashes for stashes.
    # But not other values to avoid recursion into unneeded territory.
    # We walk via savecv, not via stashes.
    if ( ref($gv) eq 'B::STASHGV' and $gvname !~ /::$/ ) {
        return $sym;
    }

    # attributes::bootstrap is created in perl_parse.
    # Saving it would overwrite it, because perl_init() is
    # called after perl_parse(). But we need to xsload it.
    if ( $fullname eq 'attributes::bootstrap' ) {
        unless ( defined( &{ $package . '::bootstrap' } ) ) {
            warn "Forcing bootstrap of $package\n" if $verbose;
            eval { $package->bootstrap };
        }
        mark_package( 'attributes', 1 );
        $savefields &= ~Save_CV;
        $xsub{attributes} = 'Dynamic-' . $INC{'attributes.pm'};    # XSLoader
        $use_xsloader = 1;
    }

    my $gvsv;
    if ($savefields) {

        # Don't save subfields of special GVs (*_, *1, *# and so on)
        warn "GV::save saving subfields $savefields\n" if $debug{gv};
        $gvsv = $gv->SV;
        if ( $$gvsv && $savefields & Save_SV ) {
            warn "GV::save \$" . $sym . " $gvsv\n" if $debug{gv};
            my $core_svs = {                                       # special SV syms to assign to the right GvSV
                "\\" => 'PL_ors_sv',
                "/"  => 'PL_rs',
                "@"  => 'PL_errors',
            };
            for my $s ( sort keys %$core_svs ) {
                if ( $fullname eq 'main::' . $s ) {
                    savesym( $gvsv, $core_svs->{$s} );             # TODO: This could bypass BEGIN settings (->save is ignored)
                }
            }
            if ( $gvname eq 'VERSION' and $xsub{$package} and $gvsv->FLAGS & SVf_ROK ) {
                warn "Strip overload from $package\::VERSION, fails to xs boot (issue 91)\n" if $debug{gv};
                my $rv     = $gvsv->object_2svref();
                my $origsv = $$rv;
                no strict 'refs';
                ${$fullname} = "$origsv";
                svref_2object( \${$fullname} )->save($fullname);
                init()->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
            }
            else {
                $gvsv->save($fullname);    #even NULL save it, because of gp_free nonsense
                                           # we need sv magic for the core_svs (PL_rs -> gv) (#314)
                if ( exists $core_svs->{$gvname} ) {
                    if ( $gvname eq "\\" ) {    # ORS special case #318 (initially NULL)
                        return $sym;
                    }
                    else {
                        $gvsv->save_magic($fullname) if ref($gvsv) eq 'B::PVMG';
                        init()->add( sprintf( "SvREFCNT(s\\_%x) += 1;", $$gvsv ) );
                    }
                }
                init()->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
            }
            if ( $fullname eq 'main::$' ) {     # $$ = PerlProc_getpid() issue #108
                warn sprintf("  GV $sym \$\$ perlpid\n") if $debug{gv};
                init()->add("sv_setiv(GvSV($sym), (IV)PerlProc_getpid());");
            }
            warn "GV::save \$$fullname\n" if $debug{gv};
        }
        my $gvav = $gv->AV;
        if ( $$gvav && $savefields & Save_AV ) {
            warn "GV::save \@$fullname\n" if $debug{gv};
            $gvav->save($fullname);
            init()->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
            if ( $fullname eq 'main::-' ) {
                init()->add(
                    sprintf( "AvFILLp(s\\_%x) = -1;", $$gvav ),
                    sprintf( "AvMAX(s\\_%x) = -1;",   $$gvav )
                );
            }
        }
        my $gvhv = $gv->HV;
        if ( $$gvhv && $savefields & Save_HV ) {
            if ( $fullname ne 'main::ENV' ) {
                warn "GV::save \%$fullname\n" if $debug{gv};
                if ( $fullname eq 'main::!' ) {    # force loading Errno
                    init()->add("/* \%! force saving of Errno */");
                    mark_package( 'Config', 1 );    # Errno needs Config to set the EGV
                    walk_syms('Config');
                    mark_package( 'Errno', 1 );     # B::C needs Errno but does not import $!
                }
                elsif ( $fullname eq 'main::+' or $fullname eq 'main::-' ) {
                    init()->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");

                    mark_package( 'Config', 1 );    # DynaLoader needs Config to set the EGV
                    walk_syms('Config');
                    svref_2object( \&{'Tie::Hash::NamedCapture::bootstrap'} )->save;

                    mark_package( 'Tie::Hash::NamedCapture', 1 );
                }

                # XXX TODO 49: crash at BEGIN { %warnings::Bits = ... }
                if ( $fullname ne 'main::INC' ) {
                    $gvhv->save($fullname);
                    init()->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
                }
            }
        }
        my $gvcv = $gv->CV;
        if ( !$$gvcv and $savefields & Save_CV ) {
            warn "Empty CV $fullname, AUTOLOAD and try again\n" if $debug{gv};
            no strict 'refs';

            # Fix test 31, catch unreferenced AUTOLOAD. The downside:
            # It stores the whole optree and all its children.
            # Similar with test 39: re::is_regexp
            svref_2object( \*{"$package\::AUTOLOAD"} )->save
              if $package and exists ${"$package\::"}{AUTOLOAD};
            svref_2object( \*{"$package\::CLONE"} )->save
              if $package and exists ${"$package\::"}{CLONE};
            $gvcv = $gv->CV;    # try again
        }
        if (    $$gvcv
            and $savefields & Save_CV
            and ref($gvcv) eq 'B::CV'
            and ref( $gvcv->GV->EGV ) ne 'B::SPECIAL'
            and !skip_pkg($package) ) {
            my $origname = $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME;
            my $cvsym;
            if ( $gvcv->XSUB and $fullname ne $origname ) {    #XSUB CONSTSUB alias
                my $package = $gvcv->GV->EGV->STASH->NAME;
                $origname = cstring($origname);
                warn "Boot $package, XS CONSTSUB alias of $fullname to $origname\n" if $debug{pkg};
                mark_package( $package, 1 );
                {
                    no strict 'refs';
                    svref_2object( \&{"$package\::bootstrap"} )->save
                      if $package and defined &{"$package\::bootstrap"};
                }

                # XXX issue 57: incomplete xs dependency detection
                my %hack_xs_detect = (
                    'Scalar::Util'  => 'List::Util',
                    'Sub::Exporter' => 'Params::Util',
                );
                if ( my $dep = $hack_xs_detect{$package} ) {
                    svref_2object( \&{"$dep\::bootstrap"} )->save;
                }

                # must save as a 'stub' so newXS() has a CV to populate
                init2()->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
            }
            elsif ($gp) {
                $origname = cstring($origname);
                if ( $fullname eq 'Internals::V' ) {
                    $gvcv = svref_2object( \&__ANON__::_V );
                }

                # TODO: may need fix CvGEN if >0 to re-validate the CV methods
                # on PERL510 (>0 + <subgeneration)
                warn "GV::save &$fullname...\n" if $debug{gv};
                $cvsym = $gvcv->save($fullname);

                # backpatch "$sym = gv_fetchpv($name, GV_ADD, SVt_PV)" to SVt_PVCV
                if ( $cvsym =~ /(\(char\*\))?get_cv\("/ ) {
                    if ( !$xsub{$package} and in_static_core( $package, $gvname ) ) {
                        my $in_gv;
                        for ( @{ init()->[-1]{current} } ) {
                            if ($in_gv) {
                                s/^.*\Q$sym\E.*=.*;//;
                                s/GvGP_set\(\Q$sym\E.*;//;
                            }
                            if (/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/) {
                                s/^\Q$sym = gv_fetchpv($name, GV_ADD, SVt_PV);\E/$sym = gv_fetchpv($name, GV_ADD, SVt_PVCV);/;
                                $in_gv++;
                                warn "removed $sym GP assignments $origname (core CV)\n" if $debug{gv};
                            }
                        }
                        init()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                    }
                    elsif ( $xsub{$package} ) {

                        # must save as a 'stub' so newXS() has a CV to populate later in dl_init()
                        warn "save stub CvGV for $sym GP assignments $origname (XS CV)\n" if $debug{gv};
                        init2()->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
                    }
                    else {
                        init2()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                    }
                }
                elsif ( $cvsym =~ /^(cv|&sv_list)/ ) {
                    init()->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
                }
                else {
                    warn "wrong CvGV for $sym $origname: $cvsym\n" if $debug{gv} or $verbose;
                }
            }

            # special handling for backref magic
            if ( $cvsym and $cvsym !~ /(get_cv\("|NULL|lexwarn)/ and $gv->MAGICAL ) {
                my @magic = $gv->MAGIC;
                foreach my $mg (@magic) {
                    init()->add(
                        "sv_magic((SV*)$sym, (SV*)$cvsym, '<', 0, 0);",
                        "CvCVGV_RC_off($cvsym);"
                    ) if $mg->TYPE eq '<';
                }
            }
        }
        if ($gp) {

            # TODO implement heksect to place all heks at the beginning
            #heksect()->add($gv->FILE);
            #init()->add(sprintf("GvFILE_HEK($sym) = hek_list[%d];", heksect()->index));

            # XXX Maybe better leave it NULL or asis, than fighting broken
            if ( $B::C::stash and $fullname =~ /::$/ ) {

                # ignore stash hek asserts when adding the stash
                # he->shared_he_he.hent_hek == hek assertions (#46 with IO::Poll::)
            }
            else {
                init()->add( sprintf( "GvFILE_HEK($sym) = %s;", save_hek( $gv->FILE ) ) )
                  if !$optimize_cop;
            }

            # init()->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;

            my $gvform = $gv->FORM;
            if ( $$gvform && $savefields & Save_FORM ) {
                warn "GV::save GvFORM(*$fullname) ...\n" if $debug{gv};
                $gvform->save($fullname);
                init()->add( sprintf( "GvFORM($sym) = (CV*)s\\_%x;", $$gvform ) );

                # glob_assign_glob analog to CV
                init()->add( sprintf( "SvREFCNT_inc(s\\_%x);", $$gvform ) );
                warn "GV::save GvFORM(*$fullname) done\n" if $debug{gv};
            }
            my $gvio = $gv->IO;
            if ( $$gvio && $savefields & Save_IO ) {
                warn "GV::save GvIO(*$fullname)...\n" if $debug{gv};
                if ( $fullname =~ m/::DATA$/
                    && ( $fullname eq 'main::DATA' or $B::C::save_data_fh ) )    # -O2 or 5.8
                {
                    no strict 'refs';
                    my $fh = *{$fullname}{IO};
                    use strict 'refs';
                    warn "GV::save_data $sym, $fullname ...\n" if $debug{gv};
                    $gvio->save( $fullname, 'is_DATA' );
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                    $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
                }
                elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
                    $gvio->save( $fullname, 'is_DATA' );
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                    warn "Warning: __DATA__ handle $fullname not stored. Need -O2 or -fsave-data.\n";
                }
                else {
                    $gvio->save($fullname);
                    init()->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
                }
                warn "GV::save GvIO(*$fullname) done\n" if $debug{gv};
            }
            init()->add("");
        }
    }

    # Shouldn't need to do save_magic since gv_fetchpv handles that. Esp. < and IO not
    # $gv->save_magic($fullname) if $PERL510;
    warn "GV::save *$fullname done\n" if $debug{gv};
    return $sym;
}

sub B::AV::save {
    my ( $av, $fullname ) = @_;
    my $sym = objsym($av);
    return $sym if defined $sym;

    $fullname = '' unless $fullname;
    my ( $fill, $avreal, $max );

    # cornercase: tied array without FETCHSIZE
    eval { $fill = $av->FILL; };
    $fill = -1 if $@;    # catch error in tie magic
    my $ispadlist = ref($av) eq 'B::PADLIST';
    $max = $fill;
    my $svpcast = $ispadlist ? "(PAD*)" : "(SV*)";

    # 5.14
    # 5.13.3: STASH, MAGIC, fill max ALLOC
    my $line = "Nullhv, {0}, -1, -1, 0";
    $line = "Nullhv, {0}, $fill, $max, 0" if $B::C::av_init or $B::C::av_init2;
    xpvavsect()->add($line);
    svsect()->add(
        sprintf(
            "&xpvav_list[%d], %lu, 0x%x, {%s}",
            xpvavsect()->index, $av->REFCNT, $av->FLAGS,
            '0'
        )
    );

    my ( $av_index, $magic );
    if ( !$ispadlist ) {
        svsect()->debug( $fullname, $av );
        my $sv_ix = svsect()->index;
        $av_index = xpvavsect()->index;

        # protect against recursive self-references (Getopt::Long)
        $sym = savesym( $av, "(AV*)&sv_list[$sv_ix]" );
        $magic = $av->save_magic($fullname);
    }

    if ( $debug{av} ) {
        my $line = sprintf( "saving AV $fullname 0x%x [%s] FILL=$fill", $$av, class($av) );
        warn "$line\n";
    }

    # XXX AVf_REAL is wrong test: need to save comppadlist but not stack
    if ( $fill > -1 and $magic !~ /D/ ) {
        my @array = $av->ARRAY;    # crashes with D magic (Getopt::Long)
        if ( $debug{av} ) {
            my $i = 0;
            foreach my $el (@array) {
                my $val = '';

                # if SvIOK print iv, POK pv
                if ( $el->can('FLAGS') ) {
                    $val = $el->IVX           if $el->FLAGS & SVf_IOK;
                    $val = cstring( $el->PV ) if $el->FLAGS & SVf_POK;
                }
                warn sprintf( "AV $av \[%d] = %s $val\n", $i++, class($el) );
            }
        }

        #	my @names = map($_->save, @array);
        # XXX Better ways to write loop?
        # Perhaps svp[0] = ...; svp[1] = ...; svp[2] = ...;
        # Perhaps I32 i = 0; svp[i++] = ...; svp[i++] = ...; svp[i++] = ...;

        # micro optimization: op/pat.t ( and other code probably )
        # has very large pads ( 20k/30k elements ) passing them to
        # ->add is a performance bottleneck: passing them as a
        # single string cuts runtime from 6min20sec to 40sec

        # you want to keep this out of the no_split/split
        # map("\t*svp++ = (SV*)$_;", @names),
        my $acc = '';

        # Init optimization by Nick Koston
        # The idea is to create loops so there is less C code. In the real world this seems
        # to reduce the memory usage ~ 3% and speed up startup time by about 8%.
        my ( $count, @values );
        {
            local $B::C::const_strings = $B::C::const_strings;
            if ( !$ispadlist ) {    # force dynamic PADNAME strings
                $B::C::const_strings = 0 if $av->FLAGS & 0x40000000;
            }
            @values = map { $_->save( $fullname . "[" . $count++ . "]" ) || () } @array;
        }
        $count = 0;
        for ( my $i = 0; $i <= $#array; $i++ ) {
            if (   $use_svpop_speedup
                && defined $values[$i]
                && defined $values[ $i + 1 ]
                && defined $values[ $i + 2 ]
                && $values[$i] =~ /^\&sv_list\[(\d+)\]/
                && $values[ $i + 1 ] eq "&sv_list[" . ( $1 + 1 ) . "]"
                && $values[ $i + 2 ] eq "&sv_list[" . ( $1 + 2 ) . "]" ) {
                $count = 0;
                while ( defined( $values[ $i + $count + 1 ] ) and $values[ $i + $count + 1 ] eq "&sv_list[" . ( $1 + $count + 1 ) . "]" ) {
                    $count++;
                }
                $acc .= "\tfor (gcount=" . $1 . "; gcount<" . ( $1 + $count + 1 ) . "; gcount++) {" . " *svp++ = $svpcast&sv_list[gcount]; };\n\t";
                $i += $count;
            }
            elsif ($use_av_undef_speedup
                && defined $values[$i]
                && defined $values[ $i + 1 ]
                && defined $values[ $i + 2 ]
                && $values[$i] =~ /^ptr_undef|&PL_sv_undef$/
                && $values[ $i + 1 ] =~ /^ptr_undef|&PL_sv_undef$/
                && $values[ $i + 2 ] =~ /^ptr_undef|&PL_sv_undef$/ ) {
                $count = 0;
                while ( defined $values[ $i + $count + 1 ] and $values[ $i + $count + 1 ] =~ /^ptr_undef|&PL_sv_undef$/ ) {
                    $count++;
                }
                $acc .= "\tfor (gcount=0; gcount<" . ( $count + 1 ) . "; gcount++) {" . " *svp++ = $svpcast&PL_sv_undef; };\n\t";
                $i += $count;
            }
            else {    # XXX 5.8.9d Test::NoWarnings has empty values
                $acc .= "\t*svp++ = $svpcast" . ( $values[$i] ? $values[$i] : '&PL_sv_undef' ) . ";\n\t";
            }
        }
        init()->no_split;

        if ( ref $av eq 'B::PADLIST' ) {
            my $fill1 = $fill + 1;
            init()->add( "{", "\tPAD **svp;" );
            init()->add("\tregister int gcount;") if $count;
            init()->add(
                "\tPADLIST *padl = $sym;",
                sprintf( "\tNewxz(svp, %d, PAD *);", $fill + 1 ),
                "\tPadlistARRAY(padl) = svp;",
            );
            init()->add( substr( $acc, 0, -2 ) );
            init()->add("}");
        }

        # With -fav-init2 use independent_comalloc()
        elsif ($B::C::av_init2) {
            my $i = $av_index;
            $xpvav_sizes[$i] = $fill;
            my $init_add = "{ SV **svp = avchunks[$i]; AV *av = $sym;\n";
            $init_add .= "\tregister int gcount;\n" if $count;
            if ( $fill > -1 ) {

                $init_add .= "\tAvALLOC(av) = svp;\n" . "\tAvARRAY(av) = svp;\n";
            }
            $init_add .= substr( $acc, 0, -2 );
            init()->add( $init_add . "}" );
        }

        # With -fav-init faster initialize the array as the initial av_extend()
        # is very expensive.
        # The problem was calloc, not av_extend.
        # Since we are always initializing every single element we don't need
        # calloc, only malloc. wmemset'ting the pointer to PL_sv_undef
        # might be faster also.
        elsif ($B::C::av_init) {
            init()->add(
                "{", "\tSV **svp;",
                "\tAV *av = $sym;"
            );
            init()->add("\tregister int gcount;") if $count;
            my $fill1 = $fill < 3 ? 3 : $fill + 1;
            if ( $fill > -1 ) {

                # Perl_safesysmalloc (= calloc => malloc) or Perl_malloc (= mymalloc)?
                if ($MYMALLOC) {
                    init()->add(
                        sprintf( "\tNewx(svp, %d, SV*);", $fill1 ),
                        "\tAvALLOC(av) = svp;"
                    );
                }
                else {
                    # Bypassing Perl_safesysmalloc on darwin fails with "free from wrong pool", test 25.
                    # So with DEBUGGING perls we have to track memory and use calloc.
                    init()->add(
                        "#ifdef PERL_TRACK_MEMPOOL",
                        sprintf( "\tsvp = (SV**)Perl_safesysmalloc(%d * sizeof(SV*));", $fill1 ),
                        "#else",
                        sprintf( "\tsvp = (SV**)malloc(%d * sizeof(SV*));", $fill1 ),
                        "#endif",
                        "\tAvALLOC(av) = svp;"
                    );
                }

                init()->add("\tAvARRAY(av) = svp;");
            }
            init()->add( substr( $acc, 0, -2 ) );    # AvFILLp already in XPVAV
            init()->add("}");
        }
        else {                                       # unoptimized with the full av_extend()
            my $fill1 = $fill < 3 ? 3 : $fill + 1;
            init()->add( "{", "\tSV **svp;" );
            init()->add("\tregister int gcount;") if $count;
            init()->add(
                "\tAV *av = $sym;",
                "\tav_extend(av, $fill1);",
                "\tsvp = AvARRAY(av);"
            );
            init()->add( substr( $acc, 0, -2 ) );
            init()->add( "\tAvFILLp(av) = $fill;", "}" );
        }
        init()->split;

        # we really added a lot of lines ( B::C::InitSection->add
        # should really scan for \n, but that would slow
        # it down
        init()->inc_count($#array);
    }
    else {
        my $max = $av->MAX;
        init()->add("av_extend($sym, $max);")
          if $max > -1;
    }

    return $sym;
}

sub B::PADLIST::save {
    return B::AV::save(@_);
}

sub B::HV::save {
    my ( $hv, $fullname ) = @_;
    $fullname = '' unless $fullname;
    my $sym = objsym($hv);
    return $sym if defined $sym;
    my $name     = $hv->NAME;
    my $is_stash = $name;
    my $magic;
    if ($name) {

        # It's a stash. See issue 79 + test 46
        warn sprintf(
            "Saving stash HV \"%s\" from \"$fullname\" 0x%x MAX=%d\n",
            $name, $$hv, $hv->MAX
        ) if $debug{hv};

        # A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
        # the only symptom is that sv_reset tries to reset the PMf_USED flag of
        # a trashed op but we look at the trashed op_type and segfault.
        #my $adpmroot = ${$hv->PMROOT}; # XXX When was this fixed?
        my $adpmroot = 0;
        decl()->add("Static HV *hv$hv_index;");

        my $cname = cstring($name);
        my $len   = length( pack "a*", $name );    # not yet 0-byte safe. HEK len really
                                                   # TODO utf8 stashes
        if ( $name eq 'main' ) {
            init()->add(qq[hv$hv_index = gv_stashpvn($cname, $len, 0);\t/* get main:: stash */]);
        }
        else {
            init()->add(qq[hv$hv_index = gv_stashpvn($cname, $len, GV_ADD);\t/* stash */]);
        }
        if ($adpmroot) {
            init()->add(
                sprintf(
                    "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;",
                    $adpmroot
                )
            );
        }
        $sym = savesym( $hv, "hv$hv_index" );
        $hv_index++;

        # issue 79, test 46: save stashes to check for packages.
        # and via B::STASHGV we only save stashes for stashes.
        # For efficiency we skip most stash symbols unless -fstash.
        # However it should be now safe to save all stash symbols.
        # $fullname !~ /::$/ or
        if ( !$B::C::stash ) {    # -fno-stash: do not save stashes
            $magic = $hv->save_magic( '%' . $name . '::' );    #symtab magic set in PMOP #188 (#267)
            if ( mro::get_mro($name) eq 'c3' ) {
                mark_package( 'mro', 1 );
            }

            #if ($magic =~ /c/) {
            # defer AMT magic of XS loaded hashes. #305 Encode::XS with tiehash magic
            #  init2()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI);]);
            #}
            return $sym;
        }
        return $sym if skip_pkg($name) or $name eq 'main';
        init()->add("SvREFCNT_inc($sym);");
        warn "Saving stash keys for HV \"$name\" from \"$fullname\"\n" if $debug{hv};
    }

    # Ordinary HV or Stash
    # KEYS = 0, inc. dynamically below with hv_store

    xpvhvsect()->comment("stash mgu max keys");
    xpvhvsect()->add(
        sprintf(
            "Nullhv, {0}, %d, %d",
            $hv->MAX, 0
        )
    );

    svsect()->add(
        sprintf(
            "&xpvhv_list[%d], %lu, 0x%x, {0}",
            xpvhvsect()->index, $hv->REFCNT,
            $hv->FLAGS & ~SVf_READONLY
        )
    );

    # XXX failed at 16 (tied magic) for %main::
    if ( !$is_stash and ( $hv->FLAGS & SVf_OOK ) ) {
        $sym = sprintf( "&sv_list[%d]", svsect()->index );
        my $hv_max = $hv->MAX + 1;

        # riter required, new _aux struct at the end of the HvARRAY. allocate ARRAY also.
        init()->add(
            "{\tHE **a; struct xpvhv_aux *aux;",
            "#ifdef PERL_USE_LARGE_HV_ALLOC",
            sprintf(
                "\tNewxz(a, PERL_HV_ARRAY_ALLOC_BYTES(%d) + sizeof(struct xpvhv_aux), HE*);",
                $hv_max
            ),
            "#else",
            sprintf( "\tNewxz(a, %d + sizeof(struct xpvhv_aux), HE*);", $hv_max ),
            "#endif",
            "\tHvARRAY($sym) = a;",
            sprintf( "\tHvRITER_set($sym, %d);", $hv->RITER ),
            "}"
        );
    }

    svsect()->debug( $fullname, $hv );
    my $sv_list_index = svsect()->index;
    warn sprintf(
        "saving HV %" . $fullname . " &sv_list[$sv_list_index] 0x%x MAX=%d KEYS=%d\n",
        $$hv, $hv->MAX, $hv->KEYS
    ) if $debug{hv};

    # XXX B does not keep the UTF8 flag [RT 120535] #200
    # shared heks only since 5.10, our fixed C.xs variant
    my @contents = ( $hv->can('ARRAY_utf8') ) ? $hv->ARRAY_utf8 : $hv->ARRAY;    # protect against recursive self-reference
                                                                                 # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
                                                                                 # value => rv => cv => ... => rv => same hash
    $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
    if (@contents) {
        local $B::C::const_strings = $B::C::const_strings;
        my ( $i, $length );
        $length = scalar(@contents);
        for ( $i = 1; $i < @contents; $i += 2 ) {
            my $key = $contents[ $i - 1 ];                                       # string only
            my $sv  = $contents[$i];
            warn sprintf( "HV recursion? with $fullname\{$key\} -> %s\n", $sv->RV )
              if ref($sv) eq 'B::RV'

              #and $sv->RV->isa('B::CV')
              and defined objsym($sv)
              and $debug{hv};
            if ($is_stash) {
                if ( ref($sv) eq "B::GV" and $sv->NAME =~ /::$/ ) {
                    $sv = bless $sv, "B::STASHGV";                               # do not expand stash GV's only other stashes
                    warn "saving STASH $fullname" . '{' . $key . "}\n" if $debug{hv};
                    $contents[$i] = $sv->save( $fullname . '{' . $key . '}' );
                }
                else {
                    warn "skip STASH symbol *", $fullname . $key, "\n" if $debug{hv};
                    $contents[$i] = undef;
                    $length -= 2;

                    # warn "(length=$length)\n" if $debug{hv};
                }
            }
            else {
                warn "saving HV \$" . $fullname . '{' . $key . "}\n" if $debug{hv};
                $contents[$i] = $sv->save( $fullname . '{' . $key . '}' );
            }
        }
        if ($length) {    # there may be skipped STASH symbols
            init()->no_split;
            init()->add(
                "{",
                sprintf( "\tHV *hv = %s$sym;", $sym =~ /^hv|\(HV/ ? '' : '(HV*)' )
            );
            while (@contents) {
                my ( $key, $value ) = splice( @contents, 0, 2 );
                if ($value) {
                    $value = "(SV*)$value" if $value !~ /^&sv_list/;
                    my $cur = length( pack "a*", $key );

                    if ( utf8::is_utf8($key) ) {
                        my $pv = $key;
                        utf8::encode($pv);
                        $cur = 0 - length($pv);
                    }

                    # issue 272: if SvIsCOW(sv) && SvLEN(sv) == 0 => sharedhek (key == "")
                    # >= 5.10: SvSHARED_HASH: PV offset to hek_hash
                    init()->add(
                        sprintf(
                            "\thv_store(hv, %s, %d, %s, %s);",
                            cstring($key), $cur, $value, 0
                        )
                    );    # !! randomized hash keys
                    warn sprintf( "  HV key \"%s\" = %s\n", $key, $value ) if $debug{hv};
                    if (   !$swash_ToCf
                        and $fullname =~ /^utf8::SWASHNEW/
                        and cstring($key) eq '"utf8\034unicore/To/Cf.pl\0340"'
                        and $cur == 23 ) {
                        $swash_ToCf = $value;
                        warn sprintf("Found PL_utf8_tofold ToCf swash $value\n") if $verbose;
                    }
                }
            }
            init()->add("}");
            init()->split;
            init()->add( sprintf( "HvTOTALKEYS($sym) = %d;", $length / 2 ) );
        }
    }
    else {    # empty contents still needs to set keys=0
              # test 36, 140
        init()->add("HvTOTALKEYS($sym) = 0;");
    }
    $magic = $hv->save_magic($fullname);
    init()->add("SvREADONLY_on($sym);") if $hv->FLAGS & SVf_READONLY;
    if ( $magic =~ /c/ ) {

        # defer AMT magic of XS loaded hashes
        my $cname = cstring($name);
        my $len = length( pack "a*", $name );    # not yet 0-byte safe. HEK len really
        init2()->add(qq[$sym = gv_stashpvn($cname, $len, GV_ADDWARN|GV_ADDMULTI);]);
    }
    if ( $name and mro::get_mro($name) eq 'c3' ) {
        mark_package( 'mro', 1 );
    }
    return $sym;
}

sub B::IO::save_data {
    my ( $io, $sym, $globname, @data ) = @_;
    my $data = join '', @data;

    # XXX using $DATA might clobber it!
    my $ref = svref_2object( \\$data )->save;
    init()->add("/* save $globname in RV ($ref) */") if $verbose;
    init()->add("GvSVn( $sym ) = (SV*)$ref;");

    # force inclusion of PerlIO::scalar as it was loaded in BEGIN.
    init()->add_eval( sprintf 'open(%s, \'<:scalar\', $%s);', $globname, $globname );

    # => eval_pv("open(main::DATA, '<:scalar', $main::DATA);",1); DATA being a ref to $data
    init()->pre_destruct( sprintf 'eval_pv("close %s;", 1);', $globname );
    $use_xsloader = 1;    # layers are not detected as XSUB CV, so force it
    require PerlIO         unless $savINC{'PerlIO.pm'};
    require PerlIO::scalar unless $savINC{'PerlIO/Scalar.pm'};
    mark_package( "PerlIO", 1 );

    # $savINC{'PerlIO.pm'} = $INC{'PerlIO.pm'};  # as it was loaded from BEGIN
    mark_package( "PerlIO::scalar", 1 );

    # $savINC{'PerlIO/scalar.pm'} = $INC{'PerlIO/scalar.pm'};
    $xsub{'PerlIO::scalar'} = 'Dynamic-' . $INC{'PerlIO/scalar.pm'};    # force dl_init boot
}

sub B::IO::save {
    my ( $io, $fullname, $is_DATA ) = @_;
    my $sym = objsym($io);
    return $sym if defined $sym;
    my $pv = $io->PV;
    $pv = '' unless defined $pv;
    my ( $pvsym, $len, $cur );
    if ($pv) {
        $pvsym = savepv($pv);
        $cur   = $io->CUR;
    }
    else {
        $pvsym = 'NULL';
        $cur   = 0;
    }
    if ($cur) {
        $len = $cur + 1;
        $len++ if IsCOW($io);
    }
    else {
        $len = 0;
    }
    warn sprintf( "IO $fullname sv_list[%d] 0x%x (%s) = '%s'\n", svsect()->index + 1, $$io, $io->SvTYPE, $pv )
      if $debug{sv};    # no method "SvTYPE" via package "B::IO"

    # IFP in sv.sv_u.svu_fp
    xpviosect()->comment("STASH, xmg_u, cur, len, xiv_u, xio_ofp, xio_dirpu, page, page_len, ..., type, flags");
    my $tmpl =
      "Nullhv, /*STASH later*/\n\t{0}, /*MAGIC later*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%d}, /*LINES*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{}   unless $verbose;
    xpviosect()->add(
        sprintf(
            $tmpl,
            $cur, $len,
            $io->LINES,    # moved to IVX with 5.11.1
            $io->PAGE,            $io->PAGE_LEN,
            $io->LINES_LEFT,      "NULL",
            "NULL",               "NULL",
            cchar( $io->IoTYPE ), $io->IoFLAGS
        )
    );
    svsect()->add(
        sprintf(
            "&xpvio_list[%d], %lu, 0x%x, {%s}",
            xpviosect()->index, $io->REFCNT, $io->FLAGS,
            $B::C::pv_copy_on_grow ? $pvsym : 0
        )
    );

    svsect()->debug( $fullname, $io );
    $sym = savesym( $io, sprintf( "(IO*)&sv_list[%d]", svsect()->index ) );

    if ( !$B::C::pv_copy_on_grow and $cur ) {
        init()->add( sprintf( "SvPVX(sv_list[%d]) = $pvsym;", svsect()->index ) );
    }
    my ($field);
    foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
        my $fsym = $io->$field();
        if ($$fsym) {
            init()->add( sprintf( "Io$field($sym) = (GV*)s\\_%x;", $$fsym ) );
            $fsym->save;
        }
    }
    foreach $field (qw(TOP_NAME FMT_NAME BOTTOM_NAME)) {
        my $fsym = $io->$field;
        init()->add(
            sprintf(
                "Io$field($sym) = savepvn(%s, %u);",
                cstring($fsym), length $fsym
            )
        ) if $fsym;
    }
    $io->save_magic($fullname);    # This handle the stash also (we need to inc the refcnt)
    if ( !$is_DATA ) {             # PerlIO
                                   # deal with $x = *STDIN/STDOUT/STDERR{IO} and aliases
        my $perlio_func;

        # Note: all single-direction fp use IFP, just bi-directional pipes and
        # sockets use OFP also. But we need to set both, pp_print checks OFP.
        my $o = $io->object_2svref();
        eval "require " . ref($o) . ";";
        my $fd = $o->fileno();

        # use IO::Handle ();
        # my $fd = IO::Handle::fileno($o);
        my $i = 0;
        foreach (qw(stdin stdout stderr)) {
            if ( $io->IsSTD($_) or ( defined($fd) and $fd == -$i ) ) {
                $perlio_func = $_;
            }
            $i++;
        }
        if ($perlio_func) {
            init()->add("IoIFP(${sym}) = IoOFP(${sym}) = PerlIO_${perlio_func}();");

            #if ($fd < 0) { # fd=-1 signals an error
            # XXX print may fail at flush == EOF, wrong init-time?
            #}
        }
        else {
            my $iotype  = $io->IoTYPE;
            my $ioflags = $io->IoFLAGS;

            # If an IO handle was opened at BEGIN, we try to re-init it, based on fd and IoTYPE.
            # IOTYPE:
            #  -    STDIN/OUT           HANDLE IoIOFP alias
            #  I    STDIN/OUT/ERR       HANDLE IoIOFP alias
            #  <    read-only           HANDLE fdopen
            #  >    write-only          HANDLE if fd<3 or IGNORE warn and comment
            #  a    append              HANDLE     -"-
            #  +    read and write      HANDLE fdopen
            #  s    socket              DIE
            #  |    pipe                DIE
            #  #    NUMERIC             HANDLE fdopen
            #  space closed             IGNORE
            #  \0   ex/closed?          IGNORE
            if ( $iotype eq "\c@" or $iotype eq " " ) {
                warn sprintf(
                    "Ignore closed IO Handle %s %s (%d)\n",
                    cstring($iotype), $fullname, $ioflags
                ) if $debug{gv};
            }
            elsif ( $iotype =~ /[a>]/ ) {    # write-only
                warn "Warning: Write BEGIN-block $fullname to FileHandle $iotype \&$fd\n"
                  if $fd >= 3 or $verbose;
                my $mode = $iotype eq '>' ? 'w' : 'a';

                #init()->add( sprintf("IoIFP($sym) = IoOFP($sym) = PerlIO_openn(aTHX_ NULL,%s,%d,0,0,NULL,0,NULL);",
                #		    cstring($mode), $fd));
                init()->add(
                    sprintf(
                        "%sIoIFP($sym) = IoOFP($sym) = PerlIO_fdopen(%d, %s);%s",
                        $fd < 3 ? '' : '/*', $fd, cstring($mode), $fd < 3 ? '' : '*/'
                    )
                );
            }
            elsif ( $iotype =~ /[<#\+]/ ) {

                # skips warning if it's one of our PerlIO::scalar __DATA__ handles
                warn "Warning: Read BEGIN-block $fullname from FileHandle $iotype \&$fd\n"
                  if $fd >= 3 or $verbose;    # need to setup it up before
                init()->add(
                    "/* XXX WARNING: Read BEGIN-block $fullname from FileHandle */",
                    "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"r\");"
                );
                my $tell;
                if ( $io->can("tell") and $tell = $io->tell() ) {
                    init()->add("PerlIO_seek(IoIFP($sym), $tell, SEEK_SET);");
                }
            }
            else {
                # XXX We should really die here
                warn sprintf(
                    "ERROR: Unhandled BEGIN-block IO Handle %s\&%d (%d) from %s\n",
                    cstring($iotype), $fd, $ioflags, $fullname
                );
                init()->add(
                    "/* XXX WARNING: Unhandled BEGIN-block IO Handle ",
                    "IoTYPE=$iotype SYMBOL=$fullname, IoFLAGS=$ioflags */",
                    "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"$iotype\");"
                );
            }
        }
    }

    #my $stash = $io->SvSTASH;
    #if ($$stash) {
    #  init()->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$stash ) );
    #  $stash->save;
    #  init()->add( sprintf( "IoSTASH(s\\_%x) = s\\_%x;", $$io, $$stash ) );
    #  warn sprintf( "done saving STASH 0x%x for IO 0x%x\n", $$stash, $$io )
    #    if $debug{gv};
    #}

    return $sym;
}

sub dump_symtable {

    # For debugging
    my ( $sym, $val );
    warn "----Symbol table:\n";

    for $sym ( sort keys %B::C::File::symtable ) {
        $val = $B::C::File::symtable{$sym};
        warn "$sym => $val\n";
    }
    warn "---End of symbol table\n";
}

sub save_object {
    my $sv;
    foreach $sv (@_) {
        svref_2object($sv)->save;
    }
}

sub B::GV::savecv {
    my $gv      = shift;
    my $package = $gv->STASH->NAME;
    my $name    = $gv->NAME;
    my $cv      = $gv->CV;
    my $sv      = $gv->SV;
    my $av      = $gv->AV;
    my $hv      = $gv->HV;

    my $fullname = $package . "::" . $name;
    warn sprintf( "Checking GV *%s 0x%x\n", cstring($fullname), $$gv )
      if $debug{gv} and $verbose;

    # We may be looking at this package just because it is a branch in the
    # symbol table which is on the path to a package which we need to save
    # e.g. this is 'Getopt' and we need to save 'Getopt::Long'
    #
    return if ( $package ne 'main' and !$include_package{$package} );
    return if ( $package eq 'main'
        and $name =~ /^([^_A-Za-z0-9].*|_\<.*|INC|ARGV|SIG|ENV|BEGIN|main::|!)$/ );

    warn sprintf( "Used GV \*$fullname 0x%x\n", $$gv ) if $debug{gv};
    return unless ( $$cv || $$av || $$sv || $$hv || $gv->IO || $gv->FORM );
    if ( $$cv and $name eq 'bootstrap' and $cv->XSUB ) {

        #return $cv->save($fullname);
        warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
        return;
    }
    if (
        $$cv and in_static_core( $package, $name ) and ref($cv) eq 'B::CV'    # 5.8,4 issue32
        and $cv->XSUB
      ) {
        warn("Skip internal XS $fullname\n") if $debug{gv};

        # but prevent it from being deleted
        unless ( $dumped_package{$package} ) {
            $dumped_package{$package} = 1;
            mark_package( $package, 1 );
        }
        return;
    }
    if ( $package eq 'B::C' ) {
        warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
        return;
    }
    if ( $fullname =~ /^(bytes|utf8)::AUTOLOAD$/ ) {
        $gv = force_heavy($package);
    }

    # XXX fails and should not be needed. The B::C part should be skipped 9 lines above, but be defensive
    return if $fullname eq 'B::walksymtable' or $fullname eq 'B::C::walksymtable';

    # Config is marked on any Config symbol. TIE and DESTROY are exceptions,
    # used by the compiler itself
    if ( $name eq 'Config' ) {
        mark_package( 'Config', 1 ) if !$include_package{'Config'};
    }
    $dumped_package{$package} = 1 if !exists $dumped_package{$package} and $package !~ /::$/;
    warn sprintf( "Saving GV \*$fullname 0x%x\n", $$gv ) if $debug{gv};
    $gv->save($fullname);
}

# Fixes bug #307: use foreach, not each
# each is not safe to use (at all). walksymtable is called recursively which might add
# symbols to the stash, which might cause re-ordered rehashes, which will fool the hash
# iterator, leading to missing symbols in the binary.
# Old perl5 bug: The iterator should really be stored in the op, not the hash.
sub walksymtable {
    my ( $symref, $method, $recurse, $prefix ) = @_;
    my ( $sym, $ref, $fullname );
    $prefix = '' unless defined $prefix;
    foreach my $sym ( sort keys %$symref ) {
        no strict 'refs';
        $ref      = $symref->{$sym};
        $fullname = "*main::" . $prefix . $sym;
        if ( $sym =~ /::$/ ) {
            $sym = $prefix . $sym;
            if ( svref_2object( \*$sym )->NAME ne "main::" && $sym ne "<none>::" && &$recurse($sym) ) {
                walksymtable( \%$fullname, $method, $recurse, $sym );
            }
        }
        else {
            svref_2object( \*$fullname )->$method();
        }
    }
}

sub walk_syms {
    my $package = shift;
    no strict 'refs';
    return if $dumped_package{$package};
    warn "walk_syms $package\n" if $debug{pkg} and $verbose;
    $dumped_package{$package} = 1;
    walksymtable( \%{ $package . '::' }, "savecv", sub { 1 }, $package . '::' );
}

# simplified walk_syms
# needed to populate @B::C::Flags::deps from Makefile.PL from within this %INC context
sub walk_stashes {
    my ( $symref, $prefix ) = @_;
    no strict 'refs';
    $prefix = '' unless defined $prefix;
    foreach my $sym ( sort keys %$symref ) {
        if ( $sym =~ /::$/ ) {
            $sym = $prefix . $sym;
            $B::C::deps{ substr( $sym, 0, -2 ) }++;
            if ( $sym ne "main::" && $sym ne "<none>::" ) {
                walk_stashes( \%$sym, $sym );
            }
        }
    }
}

# Used by Makefile.PL to autogenerate %INC deps.
sub collect_deps {
    %B::C::deps = ();
    walk_stashes( \%main:: );
    print join " ", ( sort keys %B::C::deps );
}

sub mark_package {
    my $package = shift;
    my $force   = shift;

    return if skip_pkg($package);    # or $package =~ /^B::C(C?)::/;
    if ( !$include_package{$package} or $force ) {
        no strict 'refs';
        my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
        mark_package('IO') if grep { $package eq $_ } @IO;
        mark_package("DynaLoader") if $package eq 'XSLoader';
        $use_xsloader = 1 if $package =~ /^B|Carp$/;    # to help CC a bit (49)
                                                        # i.e. if force
        if (    exists $include_package{$package}
            and !$include_package{$package}
            and $savINC{ inc_packname($package) } ) {
            warn sprintf(
                "$package previously deleted, save now%s\n",
                $force ? " (forced)" : ""
            ) if $verbose;

            # $include_package{$package} = 1;
            add_hashINC($package);
            walk_syms($package);
        }
        else {
            warn sprintf( "mark $package%s\n", $force ? " (forced)" : "" )
              if !$include_package{$package}
              and $verbose
              and $debug{pkg};
            $include_package{$package} = 1;

            walk_syms($package) if !$B::C::walkall;    # fixes i27-1
        }
        my @isa = get_isa($package);
        if (@isa) {

            # XXX walking the ISA is often not enough.
            # we should really check all new packages since the last full scan.
            foreach my $isa (@isa) {
                next if $isa eq $package;
                if ( $isa eq 'DynaLoader' ) {
                    unless ( defined( &{ $package . '::bootstrap' } ) ) {
                        warn "Forcing bootstrap of $package\n" if $verbose;
                        eval { $package->bootstrap };
                    }
                }
                if ( !$include_package{$isa} and !$skip_package{$isa} ) {
                    no strict 'refs';
                    warn "$isa saved (it is in $package\'s \@ISA)\n" if $verbose;
                    B::svref_2object( \@{ $isa . "::ISA" } )->save;    #308
                    if ( exists $include_package{$isa} ) {
                        warn "$isa previously deleted, save now\n" if $verbose;    # e.g. Sub::Name
                        mark_package($isa);
                        walk_syms($isa);                                           # avoid deep recursion
                    }
                    else {
                        #warn "isa $isa save\n" if $verbose;
                        mark_package($isa);
                    }
                }
            }
        }
    }
    return 1;
}

# XS in CORE which do not need to be bootstrapped extra.
# There are some specials like mro,re,UNIVERSAL.
sub in_static_core {
    my ( $stashname, $cvname ) = @_;
    if ( $stashname eq 'UNIVERSAL' ) {
        return $cvname =~ /^(isa|can|DOES|VERSION)$/;
    }
    %static_core_pkg = map { $_ => 1 } static_core_packages()
      unless %static_core_pkg;
    return 1 if $static_core_pkg{$stashname};
    if ( $stashname eq 'mro' ) {
        return $cvname eq 'method_changed_in';
    }
    if ( $stashname eq 're' ) {
        return $cvname =~ /^(is_regexp|regname|regnames|regnames_count|regexp_pattern)$/;
    }
    if ( $stashname eq 'PerlIO' ) {
        return $cvname eq 'get_layers';
    }
    if ( $stashname eq 'PerlIO::Layer' ) {
        return $cvname =~ /^(find|NoWarnings)$/;
    }
    return 0;
}

# XS modules in CORE. Reserved namespaces.
# Note: mro,re,UNIVERSAL have both, static core and dynamic/static XS
# version has an external ::vxs
sub static_core_packages {
    my @pkg = qw(Internals utf8 UNIVERSAL);

    push @pkg, 'version';

    #push @pkg, 'DynaLoader'	      if $Config{usedl};
    # Win32CORE only in official cygwin pkg. And it needs to be bootstrapped,
    # handled by static_ext.
    push @pkg, 'Cygwin'                     if $^O eq 'cygwin';
    push @pkg, 'NetWare'                    if $^O eq 'NetWare';
    push @pkg, 'OS2'                        if $^O eq 'os2';
    push @pkg, qw(VMS VMS::Filespec vmsish) if $^O eq 'VMS';

    push @pkg, split( / /, $Config{static_ext} );
    return @pkg;
}

sub skip_pkg {
    my $package = shift;
    if (
        $package =~ /^(main::)?(Internals|O)::/

        #or $package =~ /::::/ #  CORE/base/lex.t 54
        or $package =~ /^B::C::/
        or $package eq '__ANON__'
        or index( $package, " " ) != -1    # XXX skip invalid package names
        or index( $package, "(" ) != -1    # XXX this causes the compiler to abort
        or index( $package, ")" ) != -1    # XXX this causes the compiler to abort
        or exists $skip_package{$package} or ( $DB::deep and $package =~ /^(DB|Term::ReadLine)/ )
      ) {
        return 1;
    }
    return 0;
}

# Do not delete/ignore packages which were brought in from the script,
# i.e. not defined in B::C or O. Just to be on the safe side.
sub can_delete {
    my $pkg = shift;
    if ( exists $all_bc_deps{$pkg} and $B::C::can_delete_pkg ) { return 1 }
    return undef;
}

sub should_save {
    no strict qw(vars refs);
    my $package = shift;
    $package =~ s/::$//;
    if ( skip_pkg($package) ) {
        delete_unsaved_hashINC($package) if can_delete($package);
        return 0;
    }
    return $include_package{$package} = 0
      if ( $package =~ /::::/ );    # skip ::::ISA::CACHE etc.
    warn "Considering $package\n" if $debug{pkg};    #$include_package{$package}
    return if index( $package, " " ) != -1;          # XXX skip invalid package names
    return if index( $package, "(" ) != -1;          # XXX this causes the compiler to abort
    return if index( $package, ")" ) != -1;          # XXX this causes the compiler to abort
                                                     # core static mro has exactly one member, ext/mro has more
    if ( $package eq 'mro' ) {

        if ( keys %{mro::} == 1 ) {                  # core or ext?
            warn "ext/mro not loaded - skip\n" if $debug{pkg};
            return;
        }
        else {
            warn "ext/mro already loaded\n" if $debug{pkg};

            # $include_package{mro} = 1 if grep { $_ eq 'mro' } @DynaLoader::dl_modules;
            return $include_package{mro};
        }
    }
    if ( $package eq 'attributes'
        and grep { $_ eq 'attributes' } @DynaLoader::dl_modules ) {
        mark_package( $package, 1 );
        return 1;
    }
    if ( exists $all_bc_deps{$package} ) {
        foreach my $u ( grep( $include_package{$_}, sort keys %include_package ) ) {

            # If this package is a prefix to something we are saving, traverse it
            # but do not mark it for saving if it is not already
            # e.g. to get to B::OP we need to traverse B:: but need not save B
            my $p = $package;
            $p =~ s/(\W)/\\$1/g;
            return 1 if ( $u =~ /^$p\:\:/ ) && $include_package{$package};
        }
    }

    # Needed since 5.12.2: Check already if deleted
    my $incpack = inc_packname($package);

    # issue348: only drop B::C packages, not any from user code.
    if (   ( $package =~ /^DynaLoader|XSLoader$/ and $use_xsloader )
        or ( !exists $all_bc_deps{$package} ) ) {
        $include_package{$package} = 1;
    }

    # If this package is in the same file as main:: or our source, save it. (72, 73)
    if ($mainfile) {

        # Find the first cv in this package for CV->FILE
        no strict 'refs';
        for my $sym ( sort keys %{ $package . '::' } ) {
            if ( defined &{ $package . '::' . $sym } ) {

                # compare cv->FILE to $mainfile
                my $cv = svref_2object( \&{ $package . '::' . $sym } );
                if ( $cv and $cv->can('FILE') and $cv->FILE ) {
                    $include_package{$package} = 1 if $mainfile eq $cv->FILE;
                    last;
                }
            }
        }
    }

    # add overloaded but otherwise empty packages (#172)
    if ( $savINC{'overload.pm'} and exists ${ $package . '::' }{OVERLOAD} and exists ${ $package . '::' }{'()'} ) {
        mark_package( $package,   1 );
        mark_package( 'overload', 1 );
        return 1;
    }

    # Omit the packages which we use (and which cause grief
    # because of fancy "goto &$AUTOLOAD" stuff).
    # XXX Surely there must be a nicer way to do this.
    if ( exists $include_package{$package} ) {
        if ( !exists $all_bc_deps{$package} ) {
            $include_package{$package} = 1;
            $curINC{$incpack}          = $savINC{$incpack};
            warn "Cached new $package is kept\n" if $debug{pkg};
        }
        elsif ( !$include_package{$package} ) {
            delete_unsaved_hashINC($package) if can_delete($package);
            warn "Cached $package is already deleted\n" if $debug{pkg};
        }
        else {
            warn "Cached $package is cached\n" if $debug{pkg};
        }
        return $include_package{$package};
    }

    # Now see if current package looks like an OO class. This is probably too strong.
    if ( !$all_bc_deps{$package} ) {
        foreach my $m (qw(new DESTROY TIESCALAR TIEARRAY TIEHASH TIEHANDLE)) {

            # 5.10 introduced version and Regexp::DESTROY, which we dont want automatically.
            # XXX TODO This logic here is wrong and unstable. Fixes lead to more failures.
            # The walker deserves a rewrite.
            if ( UNIVERSAL::can( $package, $m ) and $package !~ /^(B::C|version|Regexp|utf8|SelectSaver)$/ ) {
                next if $package eq 'utf8'                              and $m eq 'DESTROY';    # utf8::DESTROY is empty
                                                                                                # we load Errno by ourself to avoid double Config warnings [perl #]
                                                                                                # and we have special logic to detect and include it
                next if $package =~ /^(Errno|Tie::Hash::NamedCapture)$/ and $m eq 'TIEHASH';

                # XXX Config and FileHandle should not just return. If unneeded skip em.
                return 0 if $package eq 'Config'                            and $m =~ /DESTROY|TIEHASH/;    # Config detected in GV
                                                                                                            # IO::File|IO::Handle added for B::CC only
                return 0 if $package =~ /^(FileHandle|IO::File|IO::Handle)/ and $m eq 'new';
                warn "$package has method $m: saving package\n" if $debug{pkg};
                return mark_package($package);
            }
        }
    }
    if ( $package !~ /^PerlIO/ and can_delete($package) ) {
        delete_unsaved_hashINC($package);
    }
    if ( can_delete($package) ) {
        warn "Delete $package\n" if $debug{pkg};
        return $include_package{$package} = 0;
    }
    elsif ( !exists $all_bc_deps{$package} ) {    # and not in @deps
        warn "Keep $package\n" if $debug{pkg};
        return $include_package{$package} = 1;
    }
    else {                                        # in @deps
                                                  # warn "Ignore $package\n" if $debug{pkg};
        return;
    }
}

sub inc_packname {
    my $package = shift;

    # See below at the reverse packname_inc: utf8 => utf8.pm + utf8_heavy.pl
    $package =~ s/\:\:/\//g;
    $package .= '.pm';
    return $package;
}

sub packname_inc {
    my $package = shift;
    $package =~ s/\//::/g;
    if ( $package =~ /^(Config_git\.pl|Config_heavy.pl)$/ ) {
        return 'Config';
    }
    if ( $package eq 'utf8_heavy.pl' ) {
        return 'utf8';
    }
    $package =~ s/\.p[lm]$//;
    return $package;
}

sub delete_unsaved_hashINC {
    my $package = shift;
    my $incpack = inc_packname($package);

    # Not already saved package, so it is not loaded again at run-time.
    return if $dumped_package{$package};

    # Never delete external packages, but this check is done before
    return
          if $package =~ /^DynaLoader|XSLoader$/
      and defined $use_xsloader
      and $use_xsloader == 0;
    return if $^O eq 'MSWin32' and $package =~ /^Carp|File::Basename$/;
    $include_package{$package} = 0;
    if ( $curINC{$incpack} ) {
        warn "Deleting $package from \%INC\n" if $debug{pkg};
        $savINC{$incpack} = $curINC{$incpack} if !$savINC{$incpack};
        $curINC{$incpack} = undef;
        delete $curINC{$incpack};
    }
}

sub add_hashINC {
    my $package = shift;
    my $incpack = inc_packname($package);
    $include_package{$package} = 1;
    unless ( $curINC{$incpack} ) {
        if ( $savINC{$incpack} ) {
            warn "Adding $package to \%INC (again)\n" if $debug{pkg};
            $curINC{$incpack} = $savINC{$incpack};

            # need to check xsub
            $use_xsloader = 1 if $package =~ /^DynaLoader|XSLoader$/;
        }
        else {
            warn "Adding $package to \%INC\n" if $debug{pkg};
            for (@INC) {
                my $p = $_ . '/' . $incpack;
                if ( -e $p ) { $curINC{$incpack} = $p; last; }
            }
            $curINC{$incpack} = $incpack unless $curINC{$incpack};
        }
    }
}

sub walkpackages {
    my ( $symref, $recurse, $prefix ) = @_;
    no strict 'vars';
    $prefix = '' unless defined $prefix;

    # check if already deleted - failed since 5.15.2
    return if $savINC{ inc_packname( substr( $prefix, 0, -2 ) ) };
    for my $sym ( sort keys %$symref ) {
        my $ref = $symref->{$sym};
        next unless $ref;
        local (*glob);
        *glob = $ref;
        if ( $sym =~ /::$/ ) {
            $sym = $prefix . $sym;
            warn("Walkpackages $sym\n") if $debug{pkg} and $debug{walk};

            # This walker skips main subs to avoid recursion into O compiler subs again
            # and main syms are already handled
            if ( $sym ne "main::" && $sym ne "<none>::" && &$recurse($sym) ) {
                walkpackages( \%glob, $recurse, $sym );
            }
        }
    }
}

sub save_unused_subs {
    no strict qw(refs);
    my %sav_debug;
    if ( $debug{unused} ) {
        %sav_debug = %debug;
        %debug     = ();
    }
    my $main = $module ? $module . "::" : "main::";

    # -fwalkall: better strategy for compile-time added and required packages:
    # loop savecv and check pkg cache for new pkgs.
    # if so loop again with those new pkgs only, until the list of new pkgs is empty
    my ( $walkall_cnt, @init_unused, @unused, @dumped ) = (0);

    #do
    @init_unused = grep { $include_package{$_} } keys %include_package;
    if ($verbose) {
        warn "Prescan for unused subs in $main " . ( $sav_debug{unused} ? " (silent)\n" : "\n" );
    }

    # XXX TODO better strategy for compile-time added and required packages:
    # loop savecv and check pkg cache for new pkgs.
    # if so loop again with those new pkgs only, until the list of new pkgs is empty
    descend_marked_unused();
    walkpackages( \%{$main}, \&should_save, $main eq 'main::' ? undef : $main );
    warn "Saving unused subs in $main" . ( $sav_debug{unused} ? " (silent)\n" : "\n" )
      if $verbose;
    walksymtable( \%{$main}, "savecv", \&should_save );
    @unused = grep { $include_package{$_} } keys %include_package;
    @dumped = grep { $dumped_package{$_} and $_ ne 'main' } keys %dumped_package;
    warn sprintf( "old unused: %d, new: %d, dumped: %d\n", scalar @init_unused, scalar @unused, scalar @dumped )
      if $verbose;

    if ( !$B::C::walkall ) {
        @unused = @init_unused = ();
    }
    else {
        my $done;
        do {
            $done   = dump_rest();
            @unused = grep { $include_package{$_} } keys %include_package;
            @dumped = grep { $dumped_package{$_} and $_ ne 'main' } keys %dumped_package;
        } while @unused > @dumped and $done;
        last if $walkall_cnt++ > 3;
    }

    #} while @unused > @init_unused;

    if ( $sav_debug{unused} ) {
        %debug = %sav_debug;
    }

    # If any m//i is run-time loaded we'll get a "Undefined subroutine utf8::SWASHNEW"
    # With -fno-fold we don't insist on loading utf8_heavy and Carp.
    # Until it is compile-time required.
    if (
           exists( $INC{'unicore/To/Title.pl'} )
        or exists( $INC{'unicore/To/Tc.pl'} )    #242
        or exists( $INC{'unicore/Heavy.pl'} )    #242
        or ( $savINC{'utf8_heavy.pl'} and ( $B::C::fold or exists( $savINC{'utf8.pm'} ) ) )
      ) {
        require "utf8.pm" unless $savINC{"utf8.pm"};
        mark_package('utf8');
        require "utf8_heavy.pl" unless $savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
        mark_package('utf8_heavy.pl');

        # In CORE utf8::SWASHNEW is demand-loaded from utf8 with Perl_load_module()
        # It adds about 1.6MB exe size 32-bit.
        svref_2object( \&{"utf8\::SWASHNEW"} )->save;
        add_hashINC("utf8");
    }

    # run-time Carp
    # With -fno-warnings we don't insist on initializing warnings::register_categories and Carp.
    # Until it is compile-time required.
    # 68KB exe size 32-bit
    if ( $B::C::warnings and exists $dumped_package{Carp} ) {
        svref_2object( \&{"warnings\::register_categories"} )->save;    # 68Kb 32bit
        add_hashINC("warnings");
        add_hashINC("warnings::register");
    }
    if ($use_xsloader) {
        force_saving_xsloader();
        mark_package( 'Config', 1 );                                    # required by Dynaloader and special cased previously
    }
}

sub inc_cleanup {
    my $rec_cnt = shift;

    # %INC sanity check issue 89:
    # omit unused, unsaved packages, so that at least run-time require will pull them in.

    for my $package ( sort keys %INC ) {
        my $pkg = packname_inc($package);
        if ( $package =~ /^(Config_git\.pl|Config_heavy.pl)$/ and !$dumped_package{'Config'} ) {
            delete $curINC{$package};
        }
        elsif ( $package eq 'utf8_heavy.pl' and !$include_package{'utf8'} ) {
            delete $curINC{$package};
            delete_unsaved_hashINC('utf8');
        }
        elsif ( !$B::C::walkall ) {
            delete_unsaved_hashINC($pkg) unless exists $dumped_package{$pkg};
        }
    }

    # sync %curINC deletions back to %INC
    for my $p ( sort keys %INC ) {
        if ( !exists $curINC{$p} ) {
            delete $INC{$p};
            warn "Deleting $p from %INC\n" if $debug{pkg};
        }
    }
    if ( $debug{pkg} and $verbose ) {
        warn "\%include_package: " . join( " ", grep { $include_package{$_} } sort keys %include_package ) . "\n";
        warn "\%dumped_package:  " . join( " ", grep { $dumped_package{$_} } sort keys %dumped_package ) . "\n";
        my @inc = grep !/auto\/.+\.(al|ix)$/, sort keys %INC;
        warn "\%INC: " . join( " ", @inc ) . "\n";
    }

    # issue 340,350: do only on -fwalkall? do it in the main walker step
    # as in branch walkall-early?
    if ($B::C::walkall) {
        my $again = dump_rest();
        inc_cleanup( $rec_cnt++ ) if $again and $rec_cnt < 2;    # maximal 3 times
    }

    # final cleanup
    for my $p ( sort keys %INC ) {
        my $pkg = packname_inc($p);
        delete_unsaved_hashINC($pkg) unless exists $dumped_package{$pkg};

        # sync %curINC deletions back to %INC
        delete $INC{$p} if !exists $curINC{$p};
    }
}

sub dump_rest {
    my $again;
    warn "dump_rest\n" if $verbose or $debug{pkg};
    for my $p ( sort keys %INC ) {
    }
    for my $p ( sort keys %include_package ) {
        $p =~ s/^main:://;
        if (    $include_package{$p}
            and !exists $dumped_package{$p}
            and !$static_core_pkg{$p}
            and $p !~ /^(threads|main|__ANON__|PerlIO)$/ ) {
            if ( $p eq 'warnings::register' and !$B::C::warnings ) {
                delete_unsaved_hashINC('warnings::register');
                next;
            }
            $again++;
            warn "$p marked but not saved, save now\n" if $verbose or $debug{pkg};

            # mark_package( $p, 1);
            #eval {
            #  require(inc_packname($p)) && add_hashINC( $p );
            #} unless $savINC{inc_packname($p)};
            walk_syms($p);
        }
    }
    $again;
}

sub save_context {

    # forbid run-time extends of curpad syms, names and INC
    warn "save context:\n" if $verbose;

    # need to mark assign c3 to %main::. no need to assign the default dfs
    if ( mro::get_mro("main") eq 'c3' ) {
        mark_package( 'mro', 1 );
        warn "set c3 for main\n" if $debug{pkg};
        init()->add_eval('mro::set_mro("main", "c3");');
    }

    no strict 'refs';
    if ( defined( objsym( svref_2object( \*{'main::!'} ) ) ) ) {
        use strict 'refs';
        if ( !$include_package{'Errno'} ) {
            init()->add("/* force saving of Errno */");
            mark_package( 'Config', 1 );
            walk_syms('Config');
            mark_package( 'Errno', 1 );
            svref_2object( \&{'Errno::bootstrap'} )->save;
        }    # else already included
    }
    else {
        use strict 'refs';
        delete_unsaved_hashINC('Errno');
    }

    my ( $curpad_nam, $curpad_sym );
    {
        # Record comppad sv's names, may not be static
        local $B::C::const_strings = 0;
        init()->add("/* curpad names */");
        warn "curpad names:\n" if $verbose;
        $curpad_nam = ( comppadlist->ARRAY )[0]->save('curpad_name');
        warn "curpad syms:\n" if $verbose;
        init()->add("/* curpad syms */");
        $curpad_sym = ( comppadlist->ARRAY )[1]->save('curpad_syms');
    }
    my ( $inc_hv, $inc_av );
    {
        local $B::C::const_strings = 1 if $B::C::ro_inc;
        warn "\%INC and \@INC:\n" if $verbose;
        init()->add('/* %INC */');
        inc_cleanup(0);
        my $inc_gv = svref_2object( \*main::INC );
        $inc_hv = $inc_gv->HV->save('main::INC');
        init()->add('/* @INC */');
        $inc_av = $inc_gv->AV->save('main::INC');
    }

    # ensure all included @ISA's are stored (#308), and also assign c3 (#325)
    my @saved_isa;
    for my $p ( sort keys %include_package ) {
        no strict 'refs';
        if ( $include_package{$p} and exists( ${ $p . '::' }{ISA} ) and ${ $p . '::' }{ISA} ) {
            push @saved_isa, $p;
            svref_2object( \@{ $p . '::ISA' } )->save( $p . '::ISA' );
            if ( mro::get_mro($p) eq 'c3' ) {

                # for mro c3 set the algo. there's no C api, only XS
                warn "set c3 for $p\n" if $debug{pkg};
                init()->add_eval( sprintf( 'mro::set_mro(%s, "c3");', cstring($p) ) );
            }
        }
    }
    warn "Saved \@ISA for: " . join( " ", @saved_isa ) . "\n" if @saved_isa and ( $verbose or $debug{pkg} );
    init()->add(
        "GvHV(PL_incgv) = $inc_hv;",
        "GvAV(PL_incgv) = $inc_av;",
        "PL_curpad = AvARRAY($curpad_sym);",
        "PL_comppad = $curpad_sym;",      # fixed "panic: illegal pad"
        "PL_stack_sp = PL_stack_base;"    # reset stack (was 1++)
    );

    init()->add(
        "av_store((AV*)CvPADLIST(PL_main_cv), 0, SvREFCNT_inc($curpad_nam)); /* namepad */",
        "av_store((AV*)CvPADLIST(PL_main_cv), 1, SvREFCNT_inc($curpad_sym)); /* curpad */"
    );

    my $amagic_generate = B::amagic_generation();
    warn "amagic_generation = $amagic_generate\n" if $verbose;
    init()->add("PL_amagic_generation = $amagic_generate;");
}

sub descend_marked_unused {

    #if ($B::C::walkall) {
    #  for my $pack (keys %all_bc_deps) {
    #    mark_unused($pack, 0) if !exists $include_package{$pack} and !skip_pkg($pack);
    #  }
    #}
    foreach my $pack ( sort keys %INC ) {
        my $p = packname_inc($pack);
        mark_package($p) if !skip_pkg($p) and !$all_bc_deps{$p};
    }
    if ( $debug{pkg} and $verbose ) {
        warn "\%include_package: " . join( " ", grep { $include_package{$_} } sort keys %include_package ) . "\n";
        warn "\%skip_package: " . join( " ", sort keys %skip_package ) . "\n";
    }
    foreach my $pack ( sort keys %include_package ) {
        mark_package($pack) unless skip_pkg($pack);
    }
    warn "descend_marked_unused: " . join( " ", sort keys %include_package ) . "\n" if $debug{pkg};
}

sub save_main {
    warn "Starting compile\n" if $verbose;
    warn "Walking tree\n"     if $verbose;
    $B::C::curcv = B::main_cv;
    $verbose
      ? walkoptree_slow( main_root, "save" )
      : walkoptree( main_root, "save" );
    save_main_rest();
}

# save %SIG ( in case it was set in a BEGIN block )
sub save_sig {

    # local $SIG{__WARN__} = shift;
    init()->no_split;
    my @save_sig;
    foreach my $k ( sort keys %SIG ) {
        next unless ref $SIG{$k};
        my $cvref = svref_2object( \$SIG{$k} );
        next if ref($cvref) eq 'B::CV' and $cvref->FILE =~ m|B/C\.pm$|;    # ignore B::C SIG warn handler
        push @save_sig, [ $k, $cvref ];
    }
    unless (@save_sig) {
        init()->add("/* no %SIG in BEGIN block */") if $verbose;
        warn "no %SIG in BEGIN block\n" if $verbose;
        return;
    }
    init()->add("/* save %SIG */") if $verbose;
    warn "save %SIG\n" if $verbose;
    init()->add( "{", "\tHV* hv = get_hv(\"main::SIG\",GV_ADD);" );
    foreach my $x (@save_sig) {
        my ( $k, $cvref ) = @$x;
        my $sv = $cvref->save;
        init()->add( '{', sprintf "\t" . 'SV* sv = (SV*)%s;', $sv );
        init()->add(
            sprintf(
                "\thv_store(hv, %s, %u, %s, %s);",
                cstring($k), length( pack "a*", $k ),
                'sv',        0
            )
        );    # XXX randomized hash keys!
        init()->add( "\t" . 'mg_set(sv);', '}' );
    }
    init()->add('}');
    init()->split;
}

sub force_saving_xsloader {
    mark_package( "XSLoader", 1 );

    # mark_package("DynaLoader", 1);

    init()->add("/* force saving of XSLoader::load */");
    eval { XSLoader::load; };

    # does this really save the whole packages?
    $dumped_package{XSLoader} = 1;
    svref_2object( \&XSLoader::load )->save;

    add_hashINC("XSLoader");
    add_hashINC("DynaLoader");
    $use_xsloader = 0;    # do not load again
}

sub save_main_rest {

    # this is mainly for the test suite
    my $warner = $SIG{__WARN__};

    # local $SIG{__WARN__} = sub { print STDERR @_ } unless $debug{runtime};

    warn "done main optree, walking symtable for extras\n"
      if $verbose or $debug{cv};
    init()->add("");
    init()->add("/* done main optree, extra subs which might be unused */");
    save_unused_subs();
    init()->add("/* done extras */");

    save_sig($warner) if $B::C::save_sig;

    # honour -w
    init()->add(
        "/* honor -w */",
        sprintf "PL_dowarn = ( %s ) ? G_WARN_ON : G_WARN_OFF;", $^W
    );
    if ( $^{TAINT} ) {
        init()->add(
            "/* honor -Tt */",
            "PL_tainting = TRUE;",
            "PL_taint_warn = " . ( $^{TAINT} < 0 ? "FALSE" : "TRUE" ) . ";"
        );    # -T -1 false, -t 1 true
    }

    # startpoints: XXX TODO push BEGIN/END blocks to modules code.
    warn "Writing initav\n" if $debug{av};
    my $init_av = init_av->save;
    my $end_av;
    {
        # >=5.10 need to defer nullifying of all vars in END, not only new ones.
        local ( $B::C::pv_copy_on_grow, $B::C::const_strings );
        $in_endav = 1;
        warn "Writing endav\n" if $debug{av};
        init()->add("/* END block */");
        $end_av   = end_av->save;
        $in_endav = 0;
    }
    if ( !defined($module) ) {
        init()->add(
            "/* startpoints */",
            sprintf( "PL_main_root = s\\_%x;",  ${ main_root() } ),
            sprintf( "PL_main_start = s\\_%x;", ${ main_start() } ),
        );
        init()->add(
            index( $init_av, '(AV*)' ) >= 0
            ? "PL_initav = $init_av;"
            : "PL_initav = (AV*)$init_av;"
        );
        init()->add(
            index( $end_av, '(AV*)' ) >= 0
            ? "PL_endav = $end_av;"
            : "PL_endav = (AV*)$end_av;"
        );
    }
    save_context() unless defined($module);

    # warn "use_xsloader=$use_xsloader\n" if $verbose;
    # If XSLoader was forced later, e.g. in curpad, INIT or END block
    force_saving_xsloader() if $use_xsloader;

    return if $check;

    # These calls were buried in output statements. They don't belong there so pulling them in front of write for now.
    if ($B::C::av_init2) {
        my $last = xpvavsect()->index;
        my $size = $last + 1;
        if ($last) {
            decl()->add("Static void* avchunks[$size];");
            decl()->add("Static size_t avsizes[$size] = ");
            my $ptrsize = $Config{ptrsize};
            my $acc     = "";
            for ( 0 .. $last ) {
                if ( $xpvav_sizes[$_] > 0 ) {
                    $acc .= $xpvav_sizes[$_] * $ptrsize;
                }
                else {
                    $acc .= 3 * $ptrsize;
                }
                $acc .= "," if $_ != $last;
                $acc .= "\n\t" unless ( $_ + 1 ) % 30;
            }
            decl()->add("\t{$acc};");
            init()->add_initav("if (!independent_comalloc( $size, avsizes, avchunks ))");
            init()->add_initav("    Perl_die(aTHX_ \"panic: AV alloc failed\");");
        }
    }

    # formerly sub fixup_ppaddr {
    # init op addrs must be the last action, otherwise
    # some ops might not be initialized
    # but it needs to happen before CALLREGCOMP, as a /i calls a compiled utf8::SWASHNEW
    if ($optimize_ppaddr) {
        foreach my $op_section_name ( B::C::File::op_sections() ) {
            my $section = B::C::File::get_sect($op_section_name);
            next unless $section->index >= 0;
            init_op_addr( $section->name, $section->index + 1 );
        }
    }

    my $remap = 0;
    for my $pkg ( sort keys %init2_remap ) {
        if ( exists $xsub{$pkg} ) {    # check if not removed in between
            my ($stashfile) = $xsub{$pkg} =~ /^Dynamic-(.+)$/;

            # get so file from pm. Note: could switch prefix from vendor/site//
            $init2_remap{$pkg}{FILE} = dl_module_to_sofile( $pkg, $stashfile );
            $remap++;
        }
    }

    if ($remap) {

        # XXX now emit arch-specific dlsym code
        init2()->add( "{", "  void *handle, *ptr;" );
        if ($HAVE_DLFCN_DLOPEN) {
            init2()->add("  #include <dlfcn.h>");
        }
        else {
            init2()->add(
                "  dTARG; dSP;",
                "  targ=sv_newmortal();"
            );
        }
        for my $pkg ( sort keys %init2_remap ) {
            if ( exists $xsub{$pkg} ) {
                if ($HAVE_DLFCN_DLOPEN) {
                    my $ldopt = 'RTLD_NOW|RTLD_NOLOAD';
                    $ldopt = 'RTLD_NOW' if $^O =~ /bsd/i;    # 351 (only on solaris and linux, not any bsd)
                    init2()->add(
                        sprintf( "  handle = dlopen(%s,", cstring( $init2_remap{$pkg}{FILE} ) ),
                        "                  $ldopt);",
                    );
                }
                else {
                    init2()->add(
                        "  PUSHMARK(SP);",
                        sprintf( "  XPUSHs(newSVpvs(%s));", cstring( $init2_remap{$pkg}{FILE} ) ),
                        "  PUTBACK;",
                        "  XS_DynaLoader_dl_load_file(aTHX);",
                        "  SPAGAIN;",
                        "  handle = INT2PTR(void*,POPi);",
                        "  PUTBACK;",
                    );
                }
                for my $mg ( @{ $init2_remap{$pkg}{MG} } ) {
                    warn "init2 remap xpvmg_list[$mg->{ID}].xiv_iv to dlsym of $pkg\: $mg->{NAME}\n" if verbose();
                    if ($HAVE_DLFCN_DLOPEN) {
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

    B::C::File::write();
}

# needed for init2 remap and Dynamic annotation
sub dl_module_to_sofile {
    my $module     = shift or die "missing module name";
    my $modlibname = shift or die "missing module filepath";
    my @modparts = split( /::/, $module );
    my $modfname = $modparts[-1];
    my $modpname = join( '/', @modparts );
    my $c        = @modparts;
    $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
    die "missing module filepath" unless $modlibname;
    my $sofile = "$modlibname/auto/$modpname/$modfname." . $Config{dlext};
    return $sofile;
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

sub mark_unused {
    my ( $pkg, $val ) = @_;
    $include_package{$pkg} = $val;
}

sub mark_skip {
    for (@_) {
        delete_unsaved_hashINC($_);

        # $include_package{$_} = 0;
        $skip_package{$_} = 1 unless $include_package{$_};
    }
}

sub compile {
    my @options = @_;

    # Allow debugging in CHECK blocks without Od
    $DB::single = 1 if defined &DB::DB;
    my ( $option, $opt, $arg );
    my @eval_at_startup;
    $B::C::can_delete_pkg   = 1;
    $B::C::save_sig         = 1;
    $B::C::destruct         = 1;
    $B::C::stash            = 0;
    $B::C::fold             = 1;                                                 # always include utf8::Cased tables
    $B::C::warnings         = 1;                                                 # always include Carp warnings categories and B
    $B::C::optimize_warn_sv = 1 if $^O ne 'MSWin32' or $Config{cc} !~ m/^cl/i;
    $B::C::walkall          = 1;

    mark_skip qw(B::C B::C::Flags B::CC B::Asmdata B::FAKEOP O
      B::Section B::Pseudoreg B::Shadow B::C::InitSection);

    #mark_skip('DB', 'Term::ReadLine') if defined &DB::DB;

    my $output_file;

  OPTION:
    while ( $option = shift @options ) {
        if ( $option =~ /^-(.)(.*)/ ) {
            $opt = $1;
            $arg = $2;
        }
        else {
            unshift @options, $option;
            last OPTION;
        }
        if ( $opt eq "-" && $arg eq "-" ) {
            shift @options;
            last OPTION;
        }
        if ( $opt eq "w" ) {
            $warn_undefined_syms = 1;
        }
        if ( $opt eq "c" ) {
            $check = 1;
        }
        elsif ( $opt eq "D" ) {
            $arg ||= shift @options;
            if ( $arg eq 'full' ) {
                $arg = 'OcAHCMGSPpsWF';
                $all_bc_deps{'B::Flags'}++;
            }
            elsif ( $arg eq 'ufull' ) {
                $arg = 'uOcAHCMGSPpsWF';
                $all_bc_deps{'B::Flags'}++;
            }
            foreach my $arg ( split( //, $arg ) ) {
                if ( exists $debug_map{$arg} ) {
                    $debug{ $debug_map{$arg} }++;
                }
                elsif ( $arg eq "o" ) {
                    $verbose++;
                    B->debug(1);
                }
                elsif ( $arg eq "F" ) {
                    $debug{flags}++;
                    $all_bc_deps{'B::Flags'}++;
                }
                elsif ( $arg eq "r" ) {
                    $debug{runtime}++;
                    $SIG{__WARN__} = sub {
                        warn @_;
                        my $s = join( " ", @_ );
                        chomp $s;
                        init()->add( "/* " . $s . " */" ) if init();
                    };
                }
                else {
                    warn "ignoring unknown debug option: $arg\n";
                }
            }
        }
        elsif ( $opt eq "o" ) {
            $arg ||= shift @options;
            $output_file = $arg;
            if ($check) {
                warn "Warning: -o argument ignored with -c\n";
            }
        }
        elsif ( $opt eq "s" and $arg eq "taticxs" ) {
            $staticxs = 1;
        }
        elsif ( $opt eq "n" ) {
            $arg ||= shift @options;
            $init_name = $arg;
        }
        elsif ( $opt eq "m" ) {

            # $arg ||= shift @options;
            $module = $arg;
            mark_unused( $arg, 1 );
        }
        elsif ( $opt eq "v" ) {
            $verbose = 1;
        }
        elsif ( $opt eq "u" ) {
            $arg ||= shift @options;
            if ( $arg =~ /\.p[lm]$/ ) {
                eval "require(\"$arg\");";    # path as string
            }
            else {
                eval "require $arg;";         # package as bareword with ::
            }
            mark_unused( $arg, 1 );
        }
        elsif ( $opt eq "U" ) {
            $arg ||= shift @options;
            mark_skip($arg);
        }
        elsif ( $opt eq "f" ) {
            $arg ||= shift @options;
            $arg =~ m/(no-)?(.*)/;
            my $no = defined($1) && $1 eq 'no-';
            $arg = $no ? $2 : $arg;
            if ( exists $option_map{$arg} ) {
                ${ $option_map{$arg} } = !$no;
            }
            else {
                die "Invalid optimization '$arg'";
            }
        }
        elsif ( $opt eq "O" ) {
            $arg = 1 if $arg eq "";
            my @opt;
            foreach my $i ( 1 .. $arg ) {
                push @opt, @{ $optimization_map{$i} }
                  if exists $optimization_map{$i};
            }
            unshift @options, @opt;
            warn "options : " . ( join " ", @opt ) . "\n" if $verbose;
        }
        elsif ( $opt eq "e" ) {
            push @eval_at_startup, $arg;
        }
        elsif ( $opt eq "l" ) {
            $max_string_len = $arg;
        }
    }
    if ( !$B::C::Flags::have_independent_comalloc ) {
        if ($B::C::av_init2) {
            $B::C::av_init  = 1;
            $B::C::av_init2 = 0;
        }
        elsif ($B::C::av_init) {
            $B::C::av_init2 = 0;
        }
    }
    elsif ( $B::C::av_init2 and $B::C::av_init ) {
        $B::C::av_init = 0;
    }
    $B::C::save_data_fh = 1 if $MULTI;
    $B::C::destruct     = 1 if $^O eq 'MSWin32';    # skip -ffast-destruct there

    B::C::File::new($output_file);                  # Singleton.
    %curINC = %savINC = %INC;

    foreach my $i (@eval_at_startup) {
        init()->add_eval($i);
    }
    if (@options) {                                 # modules or main?
        return sub {
            my $objname;
            foreach $objname (@options) {
                eval "save_object(\\$objname)";
            }
            B::C::File::output_all( $init_name || "init_module" );
          }
    }
    else {
        return sub { save_main() };
    }
}

1;

__END__

=head1 NAME

B::C - Perl compiler's C backend

=head1 SYNOPSIS

	perl -MO=C[,OPTIONS] foo.pl

=head1 DESCRIPTION

This compiler backend takes Perl source and generates C source code
corresponding to the internal structures that perl uses to run
your program. When the generated C source is compiled and run, it
cuts out the time which perl would have taken to load and parse
your program into its internal semi-compiled form. That means that
compiling with this backend will not help improve the runtime
execution speed of your program but may improve the start-up time.
Depending on the environment in which your program runs this may be
either a help or a hindrance.

=head1 OPTIONS

If there are any non-option arguments, they are taken to be
names of objects to be saved (probably doesn't work properly yet).
Without extra arguments, it saves the main program.

=over 4

=item B<-o>I<filename>

Output to filename instead of STDOUT

=item B<-c>

Check and abort.

Compiles and prints only warnings, but does not emit C code.

=item B<-m>I<Packagename> I<(NYI)>

Prepare to compile a module with all dependent code to a single shared
library rather than to standalone program.

Currently this just means that the code for initialising C<main_start>,
C<main_root> and C<curpad> are omitted.
The F<.pm> stub to bootstrap the shared lib is not generated.
This option should be used via C<perlcc -m>.

Not yet implemented.

=item B<-n>I<init_name>

Default: "perl_init" and "init_module"

=item B<-v>

Verbose compilation. Currently gives a few compilation statistics.

=item B<-->

Force end of options

=item B<-u>I<Package> "use Package"

Force all subs from Package to be compiled.

This allows programs to use eval "foo()" even when sub foo is never
seen to be used at compile time. The down side is that any subs which
really are never used also have code generated. This option is
necessary, for example, if you have a signal handler foo which you
initialise with C<$SIG{BAR} = "foo">.  A better fix, though, is just
to change it to C<$SIG{BAR} = \&foo>. You can have multiple B<-u>
options. The compiler tries to figure out which packages may possibly
have subs in which need compiling but the current version doesn't do
it very well. In particular, it is confused by nested packages (i.e.
of the form C<A::B>) where package C<A> does not contain any subs.

=item B<-U>I<Package> "unuse" skip Package

Ignore all subs from Package to be compiled.

Certain packages might not be needed at run-time, even if the pessimistic
walker detects it.

=item B<-staticxs>

Dump a list of bootstrapped XS package names to F<outfile.lst>
needed for C<perlcc --staticxs>.
Add code to DynaLoader to add the .so/.dll path to PATH.

=item B<-D>C<[OPTIONS]>

Debug options, concatenated or separate flags like C<perl -D>.
Verbose debugging options are crucial, because the interactive
debugger L<Od> adds a lot of ballast to the resulting code.

=item B<-Dfull>

Enable all full debugging, as with C<-DoOcAHCMGSpWF>.
All but C<-Du>.

=item B<-Do>

All Walkop'ed OPs

=item B<-DO>

OP Type,Flags,Private

=item B<-DS>

Scalar SVs, prints B<SV/RE/RV> information on saving.

=item B<-DP>

Extra PV information on saving. (static, len, hek, fake_off, ...)

=item B<-Dc>

B<COPs>, prints COPs as processed (incl. file & line num)

=item B<-DA>

prints B<AV> information on saving.

=item B<-DH>

prints B<HV> information on saving.

=item B<-DC>

prints B<CV> information on saving.

=item B<-DG>

prints B<GV> information on saving.

=item B<-DM>

prints B<MAGIC> information on saving.

=item B<-DR>

prints B<REGEXP> information on saving.

=item B<-Dp>

prints cached B<package> information, if used or not.

=item B<-Ds>

prints all compiled sub names, optionally with " not found".

=item B<-DF>

Add Flags info to the code.

=item B<-DW>

Together with B<-Dp> also prints every B<walked> package symbol.

=item B<-Du>

do not print B<-D> information when parsing for the unused subs.

=item B<-Dr>

Writes debugging output to STDERR and to the program's generated C file.
Otherwise writes debugging info to STDERR only.

=item B<-f>I<OPTIM>

Force options/optimisations on or off one at a time. You can explicitly
disable an option using B<-fno-option>. All options default to
B<disabled>.

=over 4

=item B<-fcog> I<(Ignored)>

Future flag to enable Copy-on-grow, i.e Copy-on-write, when perl
will store the COWREFCNT in a seperate field and not in the string buffer.

Some strings are declared and initialised statically independent
of C<-fcog>, see C<-fconst-strings> instead.

=item B<-fav-init>

Faster pre-initialization of AVs (arrays and pads).
Also used if -fav-init2 is used and independent_comalloc() is not detected.

Enabled with C<-O1>.

=item B<-fav-init2>

Even more faster pre-initialization of AVs with B<independent_comalloc()> if supported.
Excludes C<-fav_init> if so; uses C<-fav_init> if C<independent_comalloc()> is not supported.

C<independent_comalloc()> is recommended from B<ptmalloc3>, but also included in
C<ptmalloc>, C<dlmalloc> and C<nedmalloc>.
Download C<ptmalloc3> here: L<http://www.malloc.de/en/>
Note: C<independent_comalloc()> is not included in C<google-perftools> C<tcmalloc>.

Enabled with C<-O1>.

=item B<-fppaddr>

Optimize the initialization of C<op_ppaddr>.

Enabled with C<-O1>.

=item B<-fwarn-sv>

Use static initialization for cop_warnings. Automatically disabled for MSVC 5.

Disable with C<-fno-warn-sv>.

=item B<-fro-inc>

Set read-only B<@INC> and B<%INC> pathnames (C<-fconst-string>, not the AV)
to store them const and statically, not via malloc at run-time.

This forbids run-time extends of INC path strings,
the run-time will crash then.

Enabled with C<-O2>.

=item B<-fsave-data>

Save package::DATA filehandles ( only available with PerlIO ).
Does not work yet on Perl 5.6, 5.12 and non-threaded 5.10, and is
enabled automatically where it is known to work.

Enabled with C<-O2>.

=item B<-fconst-strings>

Declares static readonly strings as const.
Note that readonly strings in eval'd string code will
cause a run-time failure.

Enabled with C<-O3>.

=item B<-fno-destruct>

Does no global C<perl_destruct()> at the end of the process, leaving
the memory cleanup to operating system.

This will cause problems if used embedded or as shared library/module,
but not in long-running processes.

This helps with destruction problems of static data in the
default perl destructor, and enables C<-fcog> since 5.10.

Enabled with C<-O3>.

=item B<-fno-walkall>

C<-fno-walkall> uses the simple old algorithm to detect which packages
needs to be stored.
C<-fwalkall> was introduced to catch previously uncompiled packages for
computed methods or undetected deeper run-time dependencies.

=item B<-fno-save-sig-hash>

Disable compile-time modifications to the %SIG hash.

=item B<-fno-fold> I<(since 5.14)>

m//i since 5.13.10 requires the whole unicore/To/Fold table in memory,
which is about 1.6MB on 32-bit. In CORE this is demand-loaded from F<utf8.pm>.

If you are sure not to use or require any case-insensitive
matching you can strip this table from memory with C<-fno-fold>.

Enabled with C<-O3>.

=item B<-fno-warnings> I<(since 5.14)>

Run-time warnings since 5.13.5 require some C<warnings::register_categories>
in memory, which is about 68kB on 32-bit. In CORE this is demand-loaded
from F<warnings.pm>.

You can strip this table from memory with C<-fno-warnings>.

Enabled with C<-O3>.

=item B<-fstash>

Add dynamic creation of stashes, which are nested hashes of symbol tables,
names ending with C<::>, starting at C<%main::>.

These are rarely needed, sometimes for checking of existance of packages,
which could be better done by checking C<%INC>, and cost about 10% space and
startup-time.

If an explicit stash member or the stash itself C<%package::> is used in
the source code, the requested stash member(s) is/are automatically created.

C<-fno-stash> is the default.

=item B<-fno-delete-pkg>

Do not delete compiler-internal and dependent packages which appear to be
nowhere used automatically. This might miss run-time called stringified methods.
See L<B::C::Flags> for C<@deps> which packages are affected.

C<-fdelete-pkg> is the default.

=item B<-fuse-script-name>

Use the script name instead of the program name as C<$0>.

Not enabled with any C<-O> option.

=item B<-fno-dyn-padlist>

Disable dynamic padlists since 5.17.6.  Dynamic padlists are needed to prevent
from C<cv_undef> crashes on static padlists when cleaning up the stack on non-local
exits, like C<die> or C<exit>.

All functions in END blocks and all Attribute::Handler function padlists
are automatically dynamic.

Enabled with C<-O4>.

=item B<-fcop>

DO NOT USE YET!

Omit COP info (nextstate without labels, unneeded NULL ops,
files, linenumbers) for ~10% faster execution and less space,
but warnings and errors will have no file and line infos.

It will most likely not work yet. I<(was -fbypass-nullops in earlier
compilers)>

Enabled with C<-O4>.

=back

=item B<-On>

Optimisation level (n = 0, 1, 2, 3, 4). B<-O> means B<-O1>.

=over 4

=item B<-O0>

Disable all optimizations.

=item B<-O1>

Enable B<-fcog>, B<-fav-init2>/B<-fav-init>, B<-fppaddr> and B<-fwarn-sv>.

Note that C<-fcog> without C<-fno-destruct> will be disabled >= 5.10.

=item B<-O2>

Enable B<-O1> plus B<-fro-inc> and B<-fsave-data>.

=item B<-O3>

Enable B<-O2> plus B<-fno-destruct> and B<-fconst-strings>.

=item B<-O4>

Enable B<-O3> plus B<-fcop> and B<-fno-dyn-padlist>.
Very unsafe, rarely works, 10% faster, 10% smaller.

=back

=item B<-l>I<limit>

"line length limit".

Some C compilers impose an arbitrary limit on the length of string
constants (e.g. 2048 characters for Microsoft Visual C++).
B<-l2048> tells the C backend not to generate string literals
exceeding that limit.

=item B<-e ARG>

Evaluate ARG at startup

=back

=head1 EXAMPLES

    perl -MO=C,-ofoo.c foo.pl
    perl cc_harness -o foo foo.c

Note that C<cc_harness> lives in the C<B> subdirectory of your perl
library directory. The utility called C<perlcc> may also be used to
help make use of this compiler.

    perlcc foo.pl

    perl -MO=C,-v,-DcA,-l2048 bar.pl > /dev/null

=head1 CAVEAT

With 5.6 it is not possible to use the __DATA__ filehandle, because
compatible access via PerlIO::scalar was added with 5.8.1

It is generally not possible to restore all of the compiled BEGIN-time state.
Esp. problematic are non-standard filehandles (i.e. fd>2), process ids,
environment specific knowledge, because only with the compiler BEGIN blocks
are not executed in the client environment.

The compiler produces some warnings, which might need source code changes
or changed compiler options.

=over

=item Warning: Problem with require "$name" - $INC{file.pm}

Dynamic load of $name did not add the expected %INC key.

=item Warning: C.xs PMOP missing for QR

In an initial C.xs runloop all QR regex ops are stored, so that they
can matched later to PMOPs.

=item Warning: DynaLoader broken with 5.15.2-5.15.3.

[perl #100138] DynaLoader symbols were XS_INTERNAL. Strict linking
could not resolve it. Usually libperl was patched to overcome this
for these two versions.
Setting the environment variable NO_DL_WARN=1 omits this warning.

=item Warning: __DATA__ handle $fullname not stored. Need -O2 or -fsave-data.

Since processing the __DATA__ filehandle involves some overhead, requiring
PerlIO::scalar with all its dependencies, you must use -O2 or -fsave-data.

=item Warning: Write BEGIN-block $fullname to FileHandle $iotype \&$fd

Critical problem. This must be fixed in the source.

=item Warning: Read BEGIN-block $fullname from FileHandle $iotype \&$fd

Critical problem. This must be fixed in the source.

=item Warning: -o argument ignored with -c

-c does only check, but not accumulate C output lines.

=item Warning: unresolved $section symbol s\\xxx

This symbol was not resolved during compilation, and replaced by 0.

With B::C this is most likely a critical internal compiler bug, esp. if in
an op section. See [issue #110].

With B::CC it can be caused by valid optimizations, e.g. when op->next
pointers were inlined or inlined GV or CONST ops were optimized away.

=back

=head1 BUGS

Current status: A few known bugs, but usable in production

5.6:
    reading from __DATA__ handles (15)
    AUTOLOAD xsubs (27)

>=5.10:
    Attribute::Handlers and run-time attributes
    @- (#281)
    compile-time perlio layers
    run-time loading of DynaLoader packages which use AutoLoad
      i.e. BSD::Resource. (#308)
    format STDOUT or STDERR (#285)

=head1 AUTHOR

Malcolm Beattie C<MICB at cpan.org> I<(1996-1998, retired)>,
Nick Ing-Simmons <nik at tiuk.ti.com> I(1998-1999),
Vishal Bhatia <vishal at deja.com> I(1999),
Gurusamy Sarathy <gsar at cpan.org> I(1998-2001),
Mattia Barbon <mbarbon at dsi.unive.it> I(2002),
Reini Urban C<perl-compiler@googlegroups.com> I(2008-)

=head1 SEE ALSO

L<perlcompiler> for a general overview,
L<B::CC> for the optimising C compiler,
L<B::Bytecode> + L<ByteLoader> for the bytecode compiler,
L<Od> for source level debugging in the L<B::Debugger>,
L<illguts> for the illustrated Perl guts,
L<perloptree> for the Perl optree.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 2
#   fill-column: 78
# End:
# vim: expandtab shiftwidth=2:
