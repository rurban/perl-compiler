#      C.pm
#
#      Copyright (c) 1996, 1997, 1998 Malcolm Beattie
#      Copyright (c) 2008, 2009, 2010, 2011 Reini Urban
#      Copyright (c) 2010 Nick Koston
#      Copyright (c) 2011, 2012, 2013, 2014, 2015 cPanel Inc
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#

package B::C;
use strict;

our $VERSION = '5.024004';

our $check;

our %Config;

BEGIN {
    require B::C::Flags;
    *Config = \%B::C::Flags::Config;
}

use B::Flags;
use B::C::Config;    # import everything
use B::C::Config::Debug ();    # used for setting debug levels from cmdline

use B::C::File qw( init2 init0 init decl free
  heksect binopsect condopsect copsect padopsect listopsect logopsect
  opsect pmopsect pvopsect svopsect unopsect svsect xpvsect xpvavsect xpvhvsect xpvcvsect xpvivsect xpvuvsect
  xpvnvsect xpvmgsect xpvlvsect xrvsect xpvbmsect xpviosect padlistsect loopsect
);
use B::C::Helpers qw/set_curcv is_using_mro/;
use B::C::Helpers::Symtable qw(objsym savesym);

use strict;
use Exporter ();
use Errno    ();               #needed since 5.14
our %Regexp;

{                              # block necessary for caller to work
    my $caller = caller;
    if ( $caller eq 'O' or $caller eq 'Od' ) {
        require XSLoader;
        XSLoader::load('B::C');    # for r-magic and for utf8-keyed B::HV->ARRAY
    }
}

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(mark_skip set_callback save_context svop_or_padop_pv inc_cleanup opsect_common fixup_ppaddr);

# for 5.6.[01] better use the native B::C
# but 5.6.2 works fine
use B qw(minus_c sv_undef walkoptree walkoptree_slow main_root main_start peekop
  class cchar svref_2object compile_stats comppadlist hash
  init_av end_av opnumber cstring
  HEf_SVKEY SVf_POK SVf_ROK SVf_IOK SVf_NOK SVf_IVisUV SVf_READONLY);

BEGIN {
    @B::NV::ISA = 'B::IV';                                            # add IVX to nv. This fixes test 23 for Perl 5.8
    B->import(qw(regex_padav SVp_NOK SVp_IOK CVf_CONST CVf_ANON));    # both unsupported for 5.6

    sub SVf_UTF8 { 0x20000000 }

    B->import(qw(SVt_PVGV));                                          # added with 5.8.1

    # QUESTION: not sure it s still required  ( at least the two last )
    #           check if used & clean
    eval q[sub SVs_GMG { 0x00200000 }
           sub SVs_SMG { 0x00400000 }];
}

use FileHandle;

use B::FAKEOP  ();
use B::STASHGV ();

use B::C::Optimizer::DynaLoader     ();
use B::C::Optimizer::UnusedPackages ();
use B::C::OverLoad                  ();
use B::C::Packages qw/is_package_used mark_package_unused mark_package_used mark_package_removed get_all_packages_used/;
use B::C::Save qw(constpv savepv set_max_string_len savestashpv);
use B::C::Save::Signals ();

our $gv_index = 0;

# FIXME: this part can now be dynamic
# exclude all not B::C:: prefixed subs
# used in CV
our %all_bc_subs = map { $_ => 1 } qw(B::AV::save B::BINOP::save B::BM::save B::COP::save B::CV::save
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
our %all_bc_deps = map { $_ => 1 } @B::C::Flags::deps;

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

our ( $package_pv, @package_pv );    # global stash for methods since 5.13
our ( %xsub,       %init2_remap );
our ($staticxs);
our ( %dumped_package, %skip_package, %isa_cache );
my $output_file;

# fixme move to config
our ( $use_xsloader, $devel_peek_needed );

# can be improved
our $nullop_count     = 0;
our $unresolved_count = 0;

# options and optimizations shared with B::CC
our ( $init_name, %savINC, %curINC, $mainfile, @static_free );
our (
    $optimize_ppaddr, $optimize_warn_sv, $use_perl_script_name,
    $save_data_fh, $optimize_cop, $av_init, $av_init2, $ro_inc, $destruct,
    $fold, $warnings, $const_strings, $stash, $can_delete_pkg, $pv_copy_on_grow, $dyn_padlist,
    $walkall
);

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
    'stash'           => \$B::C::stash,                          # enable with -fstash
    'destruct'        => \$B::C::destruct,                       # disable with -fno-destruct
    'fold'            => \$B::C::fold,                           # disable with -fno-fold
    'warnings'        => \$B::C::warnings,                       # disable with -fno-warnings
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => sub { B::C::Save::Signals::set(@_) },
    'dyn-padlist'     => \$B::C::dyn_padlist,                    # with -O4, needed for cv cleanup with non-local exits since 5.18
    'cop'             => \$optimize_cop,                         # XXX very unsafe!
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

our @xpvav_sizes;
our ($in_endav);
my %static_core_pkg;                                                    # = map {$_ => 1} static_core_packages();

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
{
    # Scoped no warnings without loading the module.
    local $^W;
    BEGIN { ${^WARNING_BITS} = 0; }
    *DynaLoader::croak = sub { die @_ }
}

sub walk_and_save_optree {
    my ( $name, $root, $start ) = @_;
    if ($root) {

        # B.xs: walkoptree does more, reifying refs. rebless or recreating it.
        verbose() ? walkoptree_slow( $root, "save" ) : walkoptree( $root, "save" );
    }
    return objsym($start);
}

my $saveoptree_callback = \&walk_and_save_optree;
sub set_callback { $saveoptree_callback = shift }
sub saveoptree { &$saveoptree_callback(@_) }

{
    my $module;

    sub module {
        $module = shift if @_;
        return $module;
    }
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
            debug( gv => "NYI S_method_common op->sv==B::SPECIAL, keep $package_pv" );
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
                WARN(
                    sprintf(
                        "Experimentally try method_cv(sv=$sv,$package_pv) flags=0x%x",
                        $sv->FLAGS
                    )
                );

                # QUESTION: really, how can we test it ?
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
    return ( $_[0]->FLAGS & 0x10000000 );    # since 5.22
}

sub IsCOW_hek {
    return IsCOW( $_[0] ) && !$_[0]->LEN;
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
# 5.21.2: unsigned op_opt:1; unsigned op_slabbed:1; unsigned op_savefree:1; unsigned op_static:1; unsigned op_folded:1; unsigned op_lastsib:1; unsigned op_spare:1;

# fixme only use opsect common
{
    # should use a static variable
    # only for $] < 5.021002
    my $opsect_common = "next, sibling, ppaddr, " . ( MAD() ? "madprop, " : "" ) . "targ, type, " . "opt, slabbed, savefree, static, folded, moresib, spare" . ", flags, private";

    sub opsect_common {
        return $opsect_common;
    }

}

# dummy for B::C, only needed for B::CC
sub label { }

# save alternate ops if defined, and also add labels (needed for B::CC)
sub do_labels ($$@) {
    my $op    = shift;
    my $level = shift;

    for my $m (@_) {
        no strict 'refs';
        my $mo = $op->$m if $m;
        if ( $mo and $$mo ) {
            label($mo);
            $mo->save($level)
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
    debug( pkg => "save package_pv \"$package_pv\" for method_name from @{[(caller(1))[3]]}" )
      if !grep { $p eq $_ } @package_pv;
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
        WARN $name;
        return $name;
    }
    my $method;
    for ( $package_pv, @package_pv, 'main' ) {
        no strict 'refs';
        next unless defined $_;
        $method = $_ . '::' . $name;
        if ( defined(&$method) ) {
            debug( cv => "Found &%s::%s\n", $_, $name );
            mark_package_used($_);    # issue59
            mark_package( $_, 1 );
            last;
        }
        else {
            if ( my $parent = try_isa( $_, $name ) ) {
                debug( cv => "Found &%s::%s\n", $parent, $name );
                $method = $parent . '::' . $name;
                mark_package_used($parent);
                last;
            }
            debug( cv => "no definition for method_name \"$method\"" );
        }
    }

    $method = $name unless $method;
    if ( exists &$method ) {    # Do not try to save non-existing methods
        debug( cv => "save method_name \"$method\"$loc" );
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
        my @types = $c[0]->ARRAY;
        my @pad   = $c[1]->ARRAY;
        my $ix    = $op->can('padix') ? $op->padix : $op->targ;
        my $sv    = $pad[$ix];
        my $t     = $types[$ix];
        if ( defined($t) and ref($t) ne 'B::SPECIAL' ) {
            my $pv = $sv->can("PV") ? $sv->PV : ( $t->can('PVX') ? $t->PVX : '' );

            # need to fix B for SVpad_TYPEDI without formal STASH
            my $stash = ( ref($t) eq 'B::PVMG' and ref( $t->SvSTASH ) ne 'B::SPECIAL' ) ? $t->SvSTASH->NAME : '';
            return $pv;
        }
        elsif ($sv) {
            my $pv    = $sv->PV          if $sv->can("PV");
            my $stash = $sv->STASH->NAME if $sv->can("STASH");
            return $pv;
        }
    }
}

sub svop_name {
    my $op = shift;
    my $cv = shift;
    my $sv;
    if ( $op->can('name') and $op->name eq 'padsv' ) {
        return padop_name( $op, $cv );
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
                if ( $op->name eq 'gvsv' or $op->name eq 'gv' ) {
                    return $sv->STASH->NAME . '::' . $sv->NAME;
                }

                return
                    $sv->can('STASH') ? $sv->STASH->NAME
                  : $sv->can('NAME')  ? $sv->NAME
                  :                     $sv->PV;
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

# Maybe move to the unused optimizer
sub mark_skip {
    for (@_) {
        delete_unsaved_hashINC($_);

        $skip_package{$_} = 1 unless is_package_used($_);
    }
}

# mark threads::shared to be xs-loaded
sub mark_threads {
    if ( $INC{'threads.pm'} ) {
        my $stash = 'threads';
        mark_package($stash);
        $use_xsloader = 1;
        $xsub{$stash} = 'Dynamic-' . $INC{'threads.pm'};
        debug( mg => "mark threads for 'P' magic" );
    }
    else {
        debug( mg => "ignore to mark threads for 'P' magic" );
    }
    if ( $INC{'threads/shared.pm'} ) {
        my $stash = 'threads::shared';
        mark_package($stash);

        # XXX why is this needed? threads::shared should be initialized automatically
        $use_xsloader = 1;                                        # ensure threads::shared is initialized
        $xsub{$stash} = 'Dynamic-' . $INC{'threads/shared.pm'};
        debug( mg => "mark threads::shared for 'P' magic" );
    }
    else {
        debug( mg => "ignore to mark threads::shared for 'P' magic" );
    }
}

sub get_isa ($) {
    no strict 'refs';

    my $name = shift;
    if ( is_using_mro() ) {    # mro.xs loaded. c3 or dfs
        return @{ mro::get_linear_isa($name) };
    }

    # dfs only, without loading mro
    return @{ B::C::get_linear_isa($name) };
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
    debug(
        cv => "No definition for sub %s::%s. Try \@%s::ISA=(%s)",
        $cvstashname, $cvname, $cvstashname, join( ",", @isa )
    );
    for (@isa) {    # global @ISA or in pad
        next if $_ eq $cvstashname;
        debug( cv => "Try &%s::%s", $_, $cvname );
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
                    debug( gv => "Found &%s::%s", $parent, $cvname );
                    if ( exists( ${ $parent . '::' }{ISA} ) ) {
                        debug( pkg => "save \@$parent\::ISA" );
                        svref_2object( \@{ $parent . '::ISA' } )->save("$parent\::ISA");
                    }
                    if ( exists( ${ $_ . '::' }{ISA} ) ) {
                        debug( pkg => "save \@$_\::ISA\n" );
                        svref_2object( \@{ $_ . '::ISA' } )->save("$_\::ISA");
                    }
                    return $parent;
                }
            }
        }
    }
    return 0;    # not found
}

sub load_utf8_heavy {
    return if $savINC{"utf8_heavy.pl"};

    require 'utf8_heavy.pl';
    mark_package('utf8_heavy.pl');
    $curINC{'utf8_heavy.pl'} = $INC{'utf8_heavy.pl'};
    $savINC{"utf8_heavy.pl"} = 1;
    add_hashINC("utf8");

    # FIXME: we want to use add_hashINC for utf8_heavy, inc_packname should return an array
    # add_hashINC("utf8_heavy.pl");

    # In CORE utf8::SWASHNEW is demand-loaded from utf8 with Perl_load_module()
    # It adds about 1.6MB exe size 32-bit.
    svref_2object( \&{"utf8\::SWASHNEW"} )->save;

    return 1;
}

# If the sub or method is not found:
# 1. try @ISA, mark_package and return.
# 2. try UNIVERSAL::method
# 3. try compile-time expansion of AUTOLOAD to get the goto &sub addresses
sub try_autoload {
    my ( $cvstashname, $cvname ) = @_;
    no strict 'refs';
    return unless defined $cvstashname && defined $cvname;
    return 1 if try_isa( $cvstashname, $cvname );
    $cvname = '' unless defined $cvname;
    no strict 'refs';
    if ( defined( *{ 'UNIVERSAL::' . $cvname }{CODE} ) ) {
        debug( cv => "Found UNIVERSAL::$cvname" );
        return svref_2object( \&{ 'UNIVERSAL::' . $cvname } );
    }
    my $fullname = $cvstashname . '::' . $cvname;
    debug(
        cv => "No definition for sub %s. Try %s::AUTOLOAD",
        $fullname, $cvstashname
    );

    # First some exceptions, fooled by goto
    if ( $fullname eq 'utf8::SWASHNEW' ) {

        # utf8_heavy was loaded so far, so defer to a demand-loading stub
        # always require utf8_heavy, do not care if it s already in
        my $stub = sub { require 'utf8_heavy.pl'; goto &utf8::SWASHNEW };

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
        debug( cv => "require \"auto/$dir/$cvname.al\"" );
        eval { local $SIG{__DIE__}; require "auto/$dir/$cvname.al" unless $INC{"auto/$dir/$cvname.al"} };
        unless ($@) {
            verbose("Forced load of \"auto/$dir/$cvname.al\"");
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

my @_v = Internals::V();
sub __ANON__::_V { @_v }

sub save_object {
    foreach my $sv (@_) {
        svref_2object($sv)->save;
    }
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

    # If load_utf8_heavy doesn't happen before we walk utf8:: (when utf8_heavy has already been called) then the stored CV for utf8::SWASHNEW could be wrong.
    load_utf8_heavy() if ( $prefix eq 'utf8::' && defined $symref->{'SWASHNEW'} );

    my @list = sort {

        # we want these symbols to be saved last to avoid incomplete saves
        # +/- reverse is to defer + - to fix Tie::Hash::NamedCapturespecial cases. GH #247
        # _loose_name redefined from utf8_heavy.pl
        # re can be loaded by utf8_heavy
        foreach my $v (qw{- + re:: utf8:: bytes::}) {
            $a eq $v and return 1;
            $b eq $v and return -1;
        }

        # reverse order for now to preserve original behavior before improved patch
        $b cmp $a
    } keys %$symref;

    # reverse is to defer + - to fix Tie::Hash::NamedCapturespecial cases. GH #247
    foreach my $sym (@list) {
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
    debug( pkg => "walk_syms $package" ) if verbose();
    $dumped_package{$package} = 1;
    walksymtable( \%{ $package . '::' }, "savecv", sub { 1 }, $package . '::' );
}

# simplified walk_syms
# needed to populate @B::C::Flags::deps from Makefile.PL from within this %INC context
sub walk_stashes {
    my ( $symref, $prefix, $dependencies ) = @_;
    no strict 'refs';
    $prefix = '' unless defined $prefix;
    foreach my $sym ( sort keys %$symref ) {
        if ( $sym =~ /::$/ ) {
            $sym = $prefix . $sym;
            $dependencies->{ substr( $sym, 0, -2 ) }++;
            if ( $sym ne "main::" && $sym ne "<none>::" ) {
                walk_stashes( \%$sym, $sym, $dependencies );
            }
        }
    }
}

# Used by Makefile.PL to autogenerate %INC deps.
# QUESTION: why Moose and IO::Socket::SSL listed here
# QUESTION: can we skip B::C::* here
sub collect_deps {
    my %deps;
    walk_stashes( \%main::, undef, \%deps );
    print join " ", ( sort keys %deps );
}

sub mark_package {
    my $package = shift;
    my $force = shift || 0;

    return if skip_pkg($package);    # or $package =~ /^B::C(C?)::/;
    if ( !is_package_used($package) or $force ) {
        no strict 'refs';
        debug( pkg => "mark_package($package, $force)" );
        my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
        mark_package('IO') if grep { $package eq $_ } @IO;
        mark_package("DynaLoader") if $package eq 'XSLoader';
        $use_xsloader = 1 if $package =~ /^B|Carp$/;    # to help CC a bit (49)

        # i.e. if force
        my $flag_as_unused = is_package_used($package);
        if (    defined $flag_as_unused
            and !$flag_as_unused
            and $savINC{ inc_packname($package) } ) {
            verbose( "$package previously deleted, save now ", $force ? " (forced)" : "" );

            add_hashINC($package);
            walk_syms($package);
        }
        else {
            debug( pkg => "mark $package%s", $force ? " (forced)" : "" )
              if !is_package_used($package)
              and verbose();
            mark_package_used($package);

            walk_syms($package) if !$B::C::walkall;    # fixes i27-1
        }
        my @isa = get_isa($package);
        if (@isa) {

            # XXX walking the ISA is often not enough.
            # we should really check all new packages since the last full scan.
            foreach my $isa (@isa) {
                next if $isa eq $package;

                # QUESTION: why forcing bootstrap when it s a DynaLoader like ?
                #   is it to force the inclusion of XS code which is not called yet ?
                if ( $isa eq 'DynaLoader' ) {
                    unless ( defined( &{ $package . '::bootstrap' } ) ) {
                        verbose("Forcing bootstrap of $package");
                        eval { $package->bootstrap };
                    }
                }
                my $is_package_used = is_package_used($isa);
                if ( !$is_package_used and !$skip_package{$isa} ) {
                    no strict 'refs';
                    verbose("$isa saved (it is in $package\'s \@ISA)");
                    svref_2object( \@{ $isa . "::ISA" } )->save;    #308

                    if ( defined $is_package_used ) {
                        verbose("$isa previously deleted, save now");    # e.g. Sub::Name
                        mark_package($isa);
                        walk_syms($isa);                                 # avoid deep recursion
                    }
                    else {
                        #verbose( "isa $isa save" );
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
    mark_package_unused($package);
    if ( $curINC{$incpack} ) {

        #debug( pkg => "Deleting $package from \%INC" );
        $savINC{$incpack} = $curINC{$incpack} if !$savINC{$incpack};
        $curINC{$incpack} = undef;
        delete $curINC{$incpack};
    }
}

sub add_hashINC {
    my $package = shift;
    my $incpack = inc_packname($package);
    mark_package_used($package);
    unless ( $curINC{$incpack} ) {
        if ( $savINC{$incpack} ) {
            debug( pkg => "Adding $package to \%INC (again)" );
            $curINC{$incpack} = $savINC{$incpack};

            # need to check xsub
            $use_xsloader = 1 if $package =~ /^DynaLoader|XSLoader$/;
        }
        else {
            debug( pkg => "Adding $package to \%INC" );
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
            debug( walk => "Walkpackages $sym" ) if debug('pkg');

            # This walker skips main subs to avoid recursion into O compiler subs again
            # and main syms are already handled
            if ( $sym ne "main::" && $sym ne "<none>::" && &$recurse($sym) ) {
                walkpackages( \%glob, $recurse, $sym );
            }
        }
    }
}

sub inc_cleanup {
    my $rec_cnt = shift;

    # %INC sanity check issue 89:
    # omit unused, unsaved packages, so that at least run-time require will pull them in.

    my @deleted_inc;
    for my $package ( sort keys %INC ) {
        my $pkg = packname_inc($package);
        if ( $package =~ /^(Config_git\.pl|Config_heavy.pl)$/ and !$dumped_package{'Config'} ) {
            delete $curINC{$package};
        }
        elsif ( $package eq 'utf8_heavy.pl' and !is_package_used('utf8') ) {
            delete $curINC{$package};
            delete_unsaved_hashINC('utf8');
        }
        elsif ( !$B::C::walkall and !exists $dumped_package{$pkg} ) {
            delete_unsaved_hashINC($pkg);
            push @deleted_inc, $pkg;
        }
    }

    # sync %curINC deletions back to %INC
    for my $p ( sort keys %INC ) {
        if ( !exists $curINC{$p} ) {
            delete $INC{$p};
            push @deleted_inc, $p;
        }
    }
    if ( debug('pkg') and verbose() ) {
        debug( pkg => "\%include_package: " . join( " ", get_all_packages_used() ) );
        debug( pkg => "\%dumped_package:  " . join( " ", grep { $dumped_package{$_} } sort keys %dumped_package ) );
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
        if ( !exists $curINC{$p} and exists $INC{$p} ) {
            delete $INC{$p};
            push @deleted_inc, $p;
        }
    }

    if ( verbose() ) {
        debug( pkg => "Deleted from \%INC: " . join( " ", @deleted_inc ) ) if @deleted_inc;
        my @inc = grep !/auto\/.+\.(al|ix)$/, sort keys %INC;
        debug( pkg => "\%INC: " . join( " ", @inc ) );
    }
}

### ??? move to B::C::Optimizer::UnusedPackages
sub dump_rest {
    my $again;
    verbose("dump_rest");
    for my $p ( get_all_packages_used() ) {
        $p =~ s/^main:://;
        if (    is_package_used($p)
            and !exists $dumped_package{$p}
            and !$static_core_pkg{$p}
            and $p !~ /^(threads|main|__ANON__|PerlIO)$/ ) {
            if ( $p eq 'warnings::register' and !$B::C::warnings ) {
                delete_unsaved_hashINC('warnings::register');
                next;
            }
            $again++;
            debug( [qw/verbose pkg/], "$p marked but not saved, save now" );

            # mark_package( $p, 1);
            #eval {
            #  require(inc_packname($p)) && add_hashINC( $p );
            #} unless $savINC{inc_packname($p)};
            walk_syms($p);
        }
    }
    $again;
}

my @made_c3;

sub make_c3 {
    my $package = shift or die;

    return if ( grep { $_ eq $package } @made_c3 );
    push @made_c3, $package;

    mark_package( 'mro', 1 );
    mark_package($package);
    my $isa_packages = mro::get_linear_isa($package) || [];
    foreach my $isa (@$isa_packages) {
        mark_package($isa);
    }
    debug( pkg => "set c3 for $package" );

    ## from setmro.xs:
    # classname = ST(0);
    # class_stash = gv_stashsv(classname, GV_ADD);
    # meta = HvMROMETA(class_stash);
    # Perl_mro_set_mro(aTHX_ meta, ST(1));

    init2()->add( sprintf( 'Perl_mro_set_mro(aTHX_ HvMROMETA(%s), newSVpvs("c3"));', savestashpv($package) ) );
}

# global state only, unneeded for modules
sub save_context {

    # forbid run-time extends of curpad syms, names and INC
    verbose("save context:");

    my $warner = $SIG{__WARN__};
    B::C::Save::Signals::save($warner);    # FIXME ? $warner seems useless arg to save_sig call
                                           # honour -w and %^H
    init()->add( "/* honor -w */", sprintf "PL_dowarn = ( %s ) ? G_WARN_ON : G_WARN_OFF;", $^W );
    if ( $^{TAINT} ) {
        init()->add(
            "/* honor -Tt */",
            "PL_tainting = TRUE;",

            # -T -1 false, -t 1 true
            "PL_taint_warn = " . ( $^{TAINT} < 0 ? "FALSE" : "TRUE" ) . ";"
        );
    }

    # need to mark assign c3 to %main::. no need to assign the default dfs
    if ( is_using_mro() && mro::get_mro("main") eq 'c3' ) {
        make_c3('main');
    }

    no strict 'refs';
    if ( defined( objsym( svref_2object( \*{'main::!'} ) ) ) ) {
        use strict 'refs';
        if ( !is_package_used('Errno') ) {
            init()->add("/* force saving of Errno */");
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
        verbose("curpad names:");
        $curpad_nam = ( comppadlist->ARRAY )[0]->save('curpad_name');
        verbose("curpad syms:");
        init()->add("/* curpad syms */");
        $curpad_sym = ( comppadlist->ARRAY )[1]->save('curpad_syms');
    }
    my ( $inc_hv, $inc_av );
    {
        local $B::C::const_strings = 1 if $B::C::ro_inc;
        verbose("\%INC and \@INC:");
        init()->add('/* %INC */');
        inc_cleanup(0);
        my $inc_gv = svref_2object( \*main::INC );
        $inc_hv = $inc_gv->HV->save('main::INC');
        init()->add('/* @INC */');
        $inc_av = $inc_gv->AV->save('main::INC');
    }

    # ensure all included @ISA's are stored (#308), and also assign c3 (#325)
    my @saved_isa;
    for my $p ( get_all_packages_used() ) {
        no strict 'refs';
        if ( exists( ${ $p . '::' }{ISA} ) and ${ $p . '::' }{ISA} ) {
            push @saved_isa, $p;
            svref_2object( \@{ $p . '::ISA' } )->save( $p . '::ISA' );
            if ( is_using_mro() && mro::get_mro($p) eq 'c3' ) {
                make_c3($p);
            }
        }
    }
    debug( [qw/verbose pkg/], "Saved \@ISA for: " . join( " ", @saved_isa ) ) if @saved_isa;
    init()->add(
        "GvHV(PL_incgv) = $inc_hv;",
        "GvAV(PL_incgv) = $inc_av;",
        "PL_curpad = AvARRAY($curpad_sym);",
        "PL_comppad = $curpad_sym;",      # fixed "panic: illegal pad"
        "PL_stack_sp = PL_stack_base;"    # reset stack (was 1++)
    );

    init()->add(
        "PadlistNAMES(CvPADLIST(PL_main_cv)) = PL_comppad_name = $curpad_nam; /* namepad */",
        "PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)$curpad_sym; /* curpad */"
    );
}

sub save_main {
    verbose("Starting compile");
    verbose("Walking tree");
    %Exporter::Cache = ();                # avoid B::C and B symbols being stored
    _delete_macros_vendor_undefined();
    set_curcv(B::main_cv);

    if ( debug('walk') ) {
        verbose("Enabling B::debug / B::walkoptree_debug");
        B->debug(1);

        # this is enabling walkoptree_debug
        # which is useful when using walkoptree (not the slow version)
    }

    verbose()
      ? walkoptree_slow( main_root, "save" )
      : walkoptree( main_root, "save" );
    save_main_rest();
}

sub _delete_macros_vendor_undefined {
    foreach my $class (qw(POSIX IO Fcntl Socket Exporter Errno)) {
        no strict 'refs';
        no strict 'subs';
        no warnings 'uninitialized';
        my $symtab = $class . '::';
        for my $symbol ( sort keys %$symtab ) {
            next if $symbol !~ m{^[0-9A-Z_]+$} || $symbol =~ m{(?:^ISA$|^EXPORT|^DESTROY|^TIE|^VERSION|^AUTOLOAD|^BEGIN|^INIT|^__|^DELETE|^CLEAR|^STORE|^NEXTKEY|^FIRSTKEY|^FETCH|^EXISTS)};
            next if ref $symtab->{$symbol};
            local $@;
            my $code = "$class\:\:$symbol();";
            eval $code;
            if ( $@ =~ m{vendor has not defined} ) {
                delete $symtab->{$symbol};
                next;
            }
        }
    }
    return 1;
}

sub force_saving_xsloader {
    mark_package( "XSLoader", 1 );

    # mark_package("DynaLoader", 1);

    init()->add("/* custom XSLoader::load_file */");

    # does this really save the whole packages?
    $dumped_package{DynaLoader} = 1;
    svref_2object( \&XSLoader::load_file )->save;
    svref_2object( \&DynaLoader::dl_load_flags )->save;    # not saved as XSUB constant?

    add_hashINC("DynaLoader");
    $use_xsloader = 0;                                     # do not load again
}

sub save_main_rest {
    debug( [qw/verbose cv/], "done main optree, walking symtable for extras" );
    init()->add("");
    init()->add("/* done main optree, extra subs which might be unused */");
    B::C::Optimizer::UnusedPackages::optimize();
    init()->add("/* done extras */");

    # startpoints: XXX TODO push BEGIN/END blocks to modules code.
    debug( av => "Writing init_av" );
    my $init_av = init_av->save('INIT');
    my $end_av;
    {
        # >=5.10 need to defer nullifying of all vars in END, not only new ones.
        local ( $B::C::pv_copy_on_grow, $B::C::const_strings );
        $in_endav = 1;
        debug( 'av' => "Writing end_av" );
        init()->add("/* END block */");
        $end_av   = end_av->save('END');
        $in_endav = 0;
    }
    if ( !defined( module() ) ) {
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

    my %INC_BACKUP = %INC;
    save_context() unless defined( module() );

    # verbose("use_xsloader=$use_xsloader");
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

    fixup_ppaddr() if ($optimize_ppaddr);

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
        init2()->no_split;
        init2()->add("{");
        if ( HAVE_DLFCN_DLOPEN() ) {
            init2()->add("  #include <dlfcn.h>");
            init2()->add("  void *handle;");
        }
        else {
            init2()->add("  void *handle;");
            init2()->add(
                "  dTARG; dSP;",
                "  targ=sv_newmortal();"
            );
        }
        for my $pkg ( sort keys %init2_remap ) {
            if ( exists $xsub{$pkg} ) {
                if ( HAVE_DLFCN_DLOPEN() ) {
                    my $ldopt = 'RTLD_NOW|RTLD_NOLOAD';
                    $ldopt = 'RTLD_NOW' if $^O =~ /bsd/i;    # 351 (only on solaris and linux, not any bsd)
                    init2()->add( "", sprintf( "  handle = dlopen(%s, %s);", cstring( $init2_remap{$pkg}{FILE} ), $ldopt ) );
                }
                else {
                    init2()->add(
                        "  PUSHMARK(SP);",
                        sprintf( "  XPUSHs(newSVpvs(%s));", cstring( $init2_remap{$pkg}{FILE} ) ),
                        "  PUTBACK;",
                        "  XS_DynaLoader_dl_load_file(aTHX_ NULL);",
                        "  SPAGAIN;",
                        "  handle = INT2PTR(void*,POPi);",
                        "  PUTBACK;",
                    );
                }
                for my $mg ( @{ $init2_remap{$pkg}{MG} } ) {
                    verbose("init2 remap xpvmg_list[$mg->{ID}].xiv_iv to dlsym of $pkg\: $mg->{NAME}");
                    if ( HAVE_DLFCN_DLOPEN() ) {
                        init2()->add( sprintf( "  xpvmg_list[%d].xiv_iv = PTR2IV( dlsym(handle, %s) );", $mg->{ID}, cstring( $mg->{NAME} ) ) );
                    }
                    else {
                        init2()->add(
                            "  PUSHMARK(SP);",
                            "  XPUSHi(PTR2IV(handle));",
                            sprintf( "  XPUSHs(newSVpvs(%s));", cstring( $mg->{NAME} ) ),
                            "  PUTBACK;",
                            "  XS_DynaLoader_dl_load_file(aTHX_ NULL);",
                            "  SPAGAIN;",
                            sprintf( "  xpvmg_list[%d].xiv_iv = POPi;", $mg->{ID} ),
                            "  PUTBACK;",
                        );
                    }
                }
            }
        }
        init2()->add("}");
        init2()->split;
    }

    my %static_ext = map { ( $_ => 1 ) } grep { m/\S/ } split( /\s+/, $Config{static_ext} );
    my @stashxsubs = map { s/::/__/g; $_ } sort keys %static_ext;

    # Used to be in output_main_rest(). Seems to be trying to clean up xsub
    foreach my $stashname ( sort keys %xsub ) {
        my $incpack = $stashname;
        $incpack =~ s/\:\:/\//g;
        $incpack .= '.pm';
        unless ( exists $B::C::curINC{$incpack} ) {    # skip deleted packages
            debug( pkg => "skip xs_init for $stashname !\$INC{$incpack}" );
            mark_package_removed($stashname);
            delete $xsub{$stashname} unless $static_ext{$stashname};
        }

        # actually boot all non-b-c dependent modules here. we assume XSLoader (Moose, List::MoreUtils)
        if ( !exists( $xsub{$stashname} ) and is_package_used($stashname) ) {
            $xsub{$stashname} = 'Dynamic-' . $INC{$incpack};

            # Class::MOP without Moose: find Moose.pm
            $xsub{$stashname} = 'Dynamic-' . $B::C::savINC{$incpack} unless $INC{$incpack};
            if ( !$B::C::savINC{$incpack} ) {
                eval "require $stashname;";
                $xsub{$stashname} = 'Dynamic-' . $INC{$incpack};
            }
            verbose("Assuming xs loaded $stashname with $xsub{$stashname}");
        }
    }

    # Used to be buried in output_main_rest(); Seems to be more xsub cleanup.
    delete $xsub{'DynaLoader'};
    delete $xsub{'UNIVERSAL'};

    verbose("fast_perl_destruct (-fno-destruct)") if $destruct;

    my $dynaloader_optimizer = B::C::Optimizer::DynaLoader->new( { 'xsub' => \%xsub, 'skip_package' => \%skip_package, 'curINC' => \%curINC, 'output_file' => $output_file, 'staticxs' => $staticxs } );
    $dynaloader_optimizer->optimize();

    my $c_file_stash = build_template_stash( \%static_ext, \@stashxsubs, $dynaloader_optimizer );

    verbose("Writing output");
    %INC = %INC_BACKUP;    # Put back %INC now we've saved everything so Template can be loaded properly.
    B::C::File::write($c_file_stash);

    # Can use NyTProf with B::C
    if ( $INC{'Devel/NYTProf.pm'} ) {
        eval q/DB::finish_profile()/;
    }
}

sub build_template_stash {
    my ( $static_ext, $stashxsubs, $dynaloader_optimizer ) = @_;

    my $c_file_stash = {
        'verbose'                          => verbose(),
        'debug'                            => B::C::Config::Debug::save(),
        'creator'                          => "created at " . scalar localtime() . " with B::C $VERSION for $^X",
        'DEBUG_LEAKING_SCALARS'            => DEBUG_LEAKING_SCALARS(),
        'have_independent_comalloc'        => $B::C::Flags::have_independent_comalloc,
        'use_declare_independent_comalloc' => $B::C::Flags::use_declare_independent_comalloc,
        'av_init2'                         => $av_init2,
        'destruct'                         => $destruct,
        'static_ext'                       => $static_ext,
        'stashxsubs'                       => $stashxsubs,
        'init_name'                        => $init_name || "perl_init",
        'gv_index'                         => $gv_index,
        'MULTI'                            => USE_MULTIPLICITY(),
        'ITHREADS'                         => USE_ITHREADS(),
        'init2_remap'                      => \%init2_remap,
        'HAVE_DLFCN_DLOPEN'                => HAVE_DLFCN_DLOPEN(),
        'compile_stats'                    => compile_stats(),
        'nullop_count'                     => $nullop_count,
        'static_free'                      => \@static_free,
        'xsub'                             => \%xsub,
        'curINC'                           => \%curINC,
        'staticxs'                         => $staticxs,
        'module'                           => module(),
        'use_perl_script_name'             => $use_perl_script_name,
        'all_eval_pvs'                     => \@B::C::InitSection::all_eval_pvs,
        'TAINT'                            => ( ${^TAINT} ? 1 : 0 ),
        USE_ITHREADS() ? ( regex_padav_pad_len => regex_padav->FILL ) : (),    # Only needed for ITHREADS.
        'devel_peek_needed' => $devel_peek_needed,
        'optimizer'         => {
            'dynaloader' => $dynaloader_optimizer->stash(),
        }
    };
    chomp $c_file_stash->{'compile_stats'};                                    # Injects a new line when you call compile_stats()

    # Was in a section that wrote some stuff out instead of main's subroutine.
    if ( defined module() ) {
        init()->add("/* curpad syms */");
        $c_file_stash->{'module_curpad_sym'} = ( comppadlist->ARRAY )[1]->save;
    }

    # main() .c generation needs a buncha globals to be determined so the stash can access them.
    # Some of the vars are only put in the stash if they meet certain coditions.
    else {
        $c_file_stash->{'global_vars'} = {
            'dollar_0'             => $0,
            'dollar_caret_A'       => $^A,
            'dollar_caret_H'       => $^H,
            'dollar_caret_X'       => cstring($^X),
            'dollar_caret_UNICODE' => ${^UNICODE},
            'dollar_comma'         => ${,},
            'dollar_backslash'     => ${\},
            'dollar_pipe'          => $|,
            'dollar_percent'       => $%,
        };

        $c_file_stash->{'global_vars'}->{'dollar_semicolon'} = cstring($;)  if $; ne "\34";     # $;
        $c_file_stash->{'global_vars'}->{'dollar_quote'}     = cstring($")  if $" ne " ";       # $"
        $c_file_stash->{'global_vars'}->{'dollar_slash'}     = cstring($/)  if $/ ne "\n";      # $/  - RS
        $c_file_stash->{'global_vars'}->{'dollar_caret_L'}   = cstring($^L) if $^L ne "\f";     # $^L - FORMFEED
        $c_file_stash->{'global_vars'}->{'dollar_colon'}     = cstring($:)  if $: ne " \n-";    # $:  - LINE_BREAK_CHARACTERS
        $c_file_stash->{'global_vars'}->{'dollar_minus'} = $- unless ( $- == 0 or $- == 60 );   # $-  - LINES_LEFT
        $c_file_stash->{'global_vars'}->{'dollar_equal'} = $= if $= != 60;                      # $=  - LINES_PER_PAGE

        # Need more than just the cstring.
        $c_file_stash->{'global_vars'}->{'dollar_caret'} = { 'str' => cstring($^), 'len' => length($^) } if $^ ne "STDOUT_TOP";
        $c_file_stash->{'global_vars'}->{'dollar_tilde'} = { 'str' => cstring($~), 'len' => length($~) } if $~ ne "STDOUT";

        $[ and die 'Since the variable is deprecated, B::C does not support setting $[ to anything other than 0';
    }

    return $c_file_stash;
}

# init op addrs must be the last action, otherwise
# some ops might not be initialized
# but it needs to happen before CALLREGCOMP, as a /i calls a compiled utf8::SWASHNEW
sub fixup_ppaddr {
    return unless $B::C::optimize_ppaddr;

    foreach my $op_section_name ( B::C::File::op_sections() ) {
        my $section = B::C::File::get_sect($op_section_name);
        my $num     = $section->index;
        next unless $num >= 0;
        init_op_addr( $section->name, $num + 1 );
    }
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

# 5.15.3 workaround [perl #101336], without .bs support
# XSLoader::load_file($module, $modlibname, ...)
my $dlext = $Config{dlext};
eval q|
sub XSLoader::load_file {
  #package DynaLoader;
  my $module = shift or die "missing module name";
  my $modlibname = shift or die "missing module filepath";
  print STDOUT "XSLoader::load_file(\"$module\", \"$modlibname\" @_)\n"
      if ${DynaLoader::dl_debug};

  push @_, $module;
  # works with static linking too
  my $boots = "$module\::bootstrap";
  goto &$boots if defined &$boots;

  my @modparts = split(/::/,$module); # crashes threaded, issue 100
  my $modfname = $modparts[-1];
  my $modpname = join('/',@modparts);
  my $c = @modparts;
  $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
  die "missing module filepath" unless $modlibname;
  my $file = "$modlibname/auto/$modpname/$modfname."| . qq(."$dlext") . q|;

  # skip the .bs "bullshit" part, needed for some old solaris ages ago

  print STDOUT "goto DynaLoader::bootstrap_inherit\n"
      if ${DynaLoader::dl_debug} and not -f $file;
  goto \&DynaLoader::bootstrap_inherit if not -f $file;
  my $modxsname = $module;
  $modxsname =~ s/\W/_/g;
  my $bootname = "boot_".$modxsname;
  @DynaLoader::dl_require_symbols = ($bootname);

  my $boot_symbol_ref;
  if ($boot_symbol_ref = DynaLoader::dl_find_symbol(0, $bootname)) {
    print STDOUT "dl_find_symbol($bootname) ok => goto boot\n"
      if ${DynaLoader::dl_debug};
    goto boot; #extension library has already been loaded, e.g. darwin
  }
  # Many dynamic extension loading problems will appear to come from
  # this section of code: XYZ failed at line 123 of DynaLoader.pm.
  # Often these errors are actually occurring in the initialisation
  # C code of the extension XS file. Perl reports the error as being
  # in this perl code simply because this was the last perl code
  # it executed.

  my $libref = DynaLoader::dl_load_file($file, 0) or do {
    die("Can't load '$file' for module $module: " . DynaLoader::dl_error());
  };
  push(@DynaLoader::dl_librefs,$libref);  # record loaded object

  my @unresolved = DynaLoader::dl_undef_symbols();
  if (@unresolved) {
    die("Undefined symbols present after loading $file: @unresolved\n");
  }

  $boot_symbol_ref = DynaLoader::dl_find_symbol($libref, $bootname) or do {
    die("Can't find '$bootname' symbol in $file\n");
  };
  print STDOUT "dl_find_symbol($libref, $bootname) ok => goto boot\n"
    if ${DynaLoader::dl_debug};
  push(@DynaLoader::dl_modules, $module); # record loaded module

 boot:
  my $xs = DynaLoader::dl_install_xsub($boots, $boot_symbol_ref, $file);
  print STDOUT "dl_install_xsub($boots, $boot_symbol_ref, $file)\n"
    if ${DynaLoader::dl_debug};
  # See comment block above
  push(@DynaLoader::dl_shared_objects, $file); # record files loaded
  return &$xs(@_);
}
|;

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

sub compile {
    my @options = @_;

    # Allow debugging in CHECK blocks without Od
    $DB::single = 1 if defined &DB::DB;
    my ( $option, $opt, $arg );
    my @eval_at_startup;
    $B::C::can_delete_pkg = 1;
    B::C::Save::Signals::enable();
    $B::C::destruct         = 1;
    $B::C::stash            = 0;
    $B::C::fold             = 1;                                                 # always include utf8::Cased tables
    $B::C::warnings         = 1;                                                 # always include Carp warnings categories and B
    $B::C::optimize_warn_sv = 1 if $^O ne 'MSWin32' or $Config{cc} !~ m/^cl/i;
    $B::C::dyn_padlist      = 1;                                                 # default is dynamic and safe, disable with -O4
    $B::C::walkall          = 1;

    mark_skip qw(B::C B::C::Flags B::CC B::FAKEOP O
      B::Section B::Pseudoreg B::Shadow B::C::InitSection);

    #mark_skip('DB', 'Term::ReadLine') if defined &DB::DB;

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
            B::C::Helpers::Symtable::enable_warnings();
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
            elsif ( B::C::Config::Debug::enable_debug_level($arg) ) {
                next;
            }
            foreach my $arg ( split( //, $arg ) ) {
                next if B::C::Config::Debug::enable_debug_level($arg);
                if ( $arg eq "o" ) {
                    B::C::Config::Debug::enabe_verbose();
                    B->debug(1);
                }
                elsif ( $arg eq "F" ) {
                    B::C::Config::Debug::enable_debug_level('flags');
                    $all_bc_deps{'B::Flags'}++;
                }
                elsif ( $arg eq "r" ) {
                    B::C::Config::Debug::enable_debug_level('runtime');
                    $SIG{__WARN__} = sub {
                        WARN(@_);
                        my $s = join( " ", @_ );
                        chomp $s;
                        init()->add( "/* " . $s . " */" ) if init();
                    };
                }
                else {
                    WARN("ignoring unknown debug option: $arg");
                }
            }
        }
        elsif ( $opt eq "o" ) {
            $arg ||= shift @options;
            $output_file = $arg;
            if ($check) {
                WARN("Warning: -o argument ignored with -c");
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
            module($arg);
            mark_package_used($arg);
        }
        elsif ( $opt eq "v" ) {
            B::C::Config::Debug::enable_verbose();
        }
        elsif ( $opt eq "u" ) {
            $arg ||= shift @options;
            if ( $arg =~ /\.p[lm]$/ ) {
                eval "require(\"$arg\");";    # path as string
            }
            else {
                eval "require $arg;";         # package as bareword with ::
            }
            mark_package_used($arg);
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
                if ( ref $option_map{$arg} eq 'CODE' ) {
                    $option_map{$arg}->( !$no );
                }
                else {
                    ${ $option_map{$arg} } = !$no;
                }
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
            verbose( "options :", @opt );
        }
        elsif ( $opt eq "e" ) {
            push @eval_at_startup, $arg;
        }
        elsif ( $opt eq "l" ) {
            set_max_string_len($arg);
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
    $B::C::save_data_fh = 1 if USE_MULTIPLICITY();
    $B::C::destruct     = 1 if $^O eq 'MSWin32';     # skip -ffast-destruct there

    B::C::File::new($output_file);                   # Singleton.
    B::C::Packages::new();                           # Singleton.

    foreach my $i (@eval_at_startup) {
        init2()->add_eval($i);
    }
    if (@options) {                                  # modules or main?
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

It will also skip storing string values of internal regexp capture groups
C<$1> - C<$9>, which were used internally by the compiler or some module. They
are considered volatile.

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
