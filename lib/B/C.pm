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

our $VERSION = '1.44';
my %debug;
our $check;
my $eval_pvs = '';
use Config;
# Thanks to Mattia Barbon for the C99 tip to init any union members
my $C99 = $Config{d_c99_variadic_macros}; # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962

package B::C::Section;
use strict;

use B ();
use base 'B::Section';

sub new {
  my $class = shift;
  my $o     = $class->SUPER::new(@_);
  push @$o, { values => [] };
  return $o;
}

sub add {
  my $section = shift;
  push( @{ $section->[-1]{values} }, @_ );
}

sub remove {
  my $section = shift;
  pop @{ $section->[-1]{values} };
}

sub index {
  my $section = shift;
  return scalar( @{ $section->[-1]{values} } ) - 1;
}

sub typename {
  my $section = shift;
  my $name = $section->name;
  my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);
  # -fcog hack to statically initialize PVs (SVPV for 5.10-5.11 only)
  $typename = 'SVPV' if $typename eq 'SV' and $] > 5.009005 and $] < 5.012 and !$C99;
  # $typename = 'const '.$typename if $name !~ /^(cop_|sv_)/;
  return $typename;
}

sub comment {
  my $section = shift;
  $section->[-1]{comment} = join( "", @_ ) if @_;
  $section->[-1]{comment};
}

# add debugging info - stringified flags on -DF
sub debug {
  my $section = shift;
  my $dbg = join( " ", @_ );
  $section->[-1]{dbg}->[ $section->index ] = $dbg if $dbg;
}

sub output {
  my ( $section, $fh, $format ) = @_;
  my $sym = $section->symtable || {};
  my $default = $section->default;
  return if $B::C::check;
  my $i = 0;
  my $dodbg = 1 if $debug{flags} and $section->[-1]{dbg};
  foreach ( @{ $section->[-1]{values} } ) {
    my $dbg = "";
    my $ref = "";
    if (m/(s\\_[0-9a-f]+)/) {
      if (!exists($sym->{$1}) and $1 ne 's\_0') {
        $ref = $1;
        $B::C::unresolved_count++;
        if ($B::C::verbose) {
          my $caller = caller(1);
          warn "Warning: unresolved ".$section->name." symbol $ref\n"
            if $caller eq 'B::C';
        }
      }
    }
    s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
    if ($dodbg and $section->[-1]{dbg}->[$i]) {
      $dbg = " /* ".$section->[-1]{dbg}->[$i]." ".$ref." */";
    }
    printf $fh $format, $_, $section->name, $i, $ref, $dbg;
    ++$i;
  }
}

package B::C::InitSection;
use strict;

# avoid use vars
@B::C::InitSection::ISA = qw(B::C::Section);

sub new {
  my $class     = shift;
  my $max_lines = 10000;                    #pop;
  my $section   = $class->SUPER::new(@_);

  $section->[-1]{evals}     = [];
  $section->[-1]{initav}    = [];
  $section->[-1]{chunks}    = [];
  $section->[-1]{nosplit}   = 0;
  $section->[-1]{current}   = [];
  $section->[-1]{count}     = 0;
  $section->[-1]{max_lines} = $max_lines;

  return $section;
}

sub split {
  my $section = shift;
  $section->[-1]{nosplit}--
    if $section->[-1]{nosplit} > 0;
}

sub no_split {
  shift->[-1]{nosplit}++;
}

sub inc_count {
  my $section = shift;

  $section->[-1]{count} += $_[0];

  # this is cheating
  $section->add();
}

sub add {
  my $section = shift->[-1];
  my $current = $section->{current};
  my $nosplit = $section->{nosplit};

  push @$current, @_;
  $section->{count} += scalar(@_);
  if ( !$nosplit && $section->{count} >= $section->{max_lines} ) {
    push @{ $section->{chunks} }, $current;
    $section->{current} = [];
    $section->{count}   = 0;
  }
}

sub add_eval {
  my $section = shift;
  my @strings = @_;

  foreach my $i (@strings) {
    $i =~ s/\"/\\\"/g;
  }
  push @{ $section->[-1]{evals} }, @strings;
}

sub add_initav {
  my $section = shift;
  push @{ $section->[-1]{initav} }, @_;
}

sub output {
  my ( $section, $fh, $format, $init_name ) = @_;
  my $sym = $section->symtable || {};
  my $default = $section->default;
  return if $B::C::check;
  push @{ $section->[-1]{chunks} }, $section->[-1]{current};

  my $name = "aaaa";
  foreach my $i ( @{ $section->[-1]{chunks} } ) {
    # dTARG and dSP unused -nt
    print $fh <<"EOT";
static int ${init_name}_${name}(pTHX)
{
EOT
    foreach my $i ( @{ $section->[-1]{initav} } ) {
      print $fh "\t",$i,"\n";
    }
    foreach my $j (@$i) {
      $j =~ s{(s\\_[0-9a-f]+)}
                   { exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
      print $fh "\t$j\n";
    }
    print $fh "\treturn 0;\n}\n";

    $section->SUPER::add("${init_name}_${name}(aTHX);");
    ++$name;
  }
  # We need to output evals after dl_init.
  foreach my $s ( @{ $section->[-1]{evals} } ) {
    ${B::C::eval_pvs} .= "    eval_pv(\"$s\",1);\n";
  }

  print $fh <<"EOT";
static int ${init_name}(pTHX)
{
EOT
  $section->SUPER::output( $fh, $format );
  print $fh "\treturn 0;\n}\n";
}

package B::C;
use strict;
use Exporter ();
use Errno (); #needed since 5.14
our %Regexp;

{ # block necessary for caller to work
  my $caller = caller;
  if ( $caller eq 'O' or $caller eq 'Od' ) {
    require XSLoader;
    XSLoader::load('B::C'); # for r-magic and for utf8-keyed B::HV->ARRAY
  }
}

our @ISA        = qw(Exporter);
our @EXPORT_OK =
  qw(output_all output_boilerplate output_main output_main_rest mark_unused mark_skip
     init_sections set_callback save_unused_subs objsym save_context fixup_ppaddr
     save_sig svop_or_padop_pv inc_cleanup ivx nvx);

# for 5.6.[01] better use the native B::C
# but 5.6.2 works fine
use B
  qw(minus_c sv_undef walkoptree walkoptree_slow walksymtable main_root main_start peekop
  class cchar svref_2object compile_stats comppadlist hash
  threadsv_names main_cv init_av end_av opnumber cstring
  HEf_SVKEY SVf_POK SVf_ROK SVf_IOK SVf_NOK SVf_IVisUV SVf_READONLY);

BEGIN {
  if ($] >=  5.008) {
    @B::NV::ISA = 'B::IV';		  # add IVX to nv. This fixes test 23 for Perl 5.8
    B->import(qw(regex_padav SVp_NOK SVp_IOK CVf_CONST CVf_ANON)); # both unsupported for 5.6
  } else {
    eval q[
      sub SVp_NOK() {0}; # unused
      sub SVp_IOK() {0};
      sub CVf_ANON() {4};
      sub PMf_ONCE() {0xff}; # unused
     ];
    @B::PVMG::ISA = qw(B::PVNV B::RV);
  }
  if ($] >=  5.008001) {
    B->import(qw(SVt_PVGV)); # added with 5.8.1
  } else {
    eval q[sub SVt_PVGV() {13}];
  }
  if ($] >= 5.010) {
    require mro; mro->import;
    # not exported:
    sub SVf_OOK { 0x02000000 }
    eval q[sub SVs_GMG { 0x00200000 }
               sub SVs_SMG { 0x00400000 }];
    if ($] >= 5.018) {  # PMf_ONCE also not exported
      eval q[sub PMf_ONCE(){ 0x10000 }];
    } elsif ($] >= 5.014) {
      eval q[sub PMf_ONCE(){ 0x8000 }];
    } elsif ($] >= 5.012) {
      eval q[sub PMf_ONCE(){ 0x0080 }];
    } else { # 5.10. not used with <= 5.8
      eval q[sub PMf_ONCE(){ 0x0002 }];
    }
  } else {
    eval q[sub SVs_GMG { 0x00002000 }
               sub SVs_SMG { 0x00004000 }];
  }
}
use B::Asmdata qw(@specialsv_name);

use B::C::Flags;
use FileHandle;
#use Carp;

my $hv_index      = 0;
my $gv_index      = 0;
my $re_index      = 0;
my $pv_index      = 0;
my $cv_index      = 0;
my $hek_index     = 0;
my $anonsub_index = 0;
my $initsub_index = 0;
my $padlist_index = 0;

# exclude all not B::C:: prefixed subs
my %all_bc_subs = map {$_=>1}
  qw(B::AV::save B::BINOP::save B::BM::save B::COP::save B::CV::save
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
my %all_bc_deps = map {$_=>1}
  @B::C::Flags::deps ? @B::C::Flags::deps
  : qw(AnyDBM_File AutoLoader B B::AV B::Asmdata B::BINOP B::BM B::C B::C::Flags B::C::InitSection B::C::Section B::CC B::COP B::CV B::FAKEOP B::FM B::GV B::HE B::HV B::IO B::IV B::LEXWARN B::LISTOP B::LOGOP B::LOOP B::MAGIC B::NULL B::NV B::OBJECT B::OP B::PADLIST B::PADOP B::PMOP B::PV B::PVIV B::PVLV B::PVMG B::PVNV B::PVOP B::REGEXP B::RHE B::RV B::SPECIAL B::STASHGV B::SV B::SVOP B::Section B::UNOP B::UV CORE CORE::GLOBAL Carp Config DB DynaLoader Errno Exporter Exporter::Heavy ExtUtils ExtUtils::Constant ExtUtils::Constant::ProxySubs Fcntl FileHandle IO IO::File IO::Handle IO::Poll IO::Seekable IO::Socket Internals O POSIX PerlIO PerlIO::Layer PerlIO::scalar Regexp SelectSaver Symbol UNIVERSAL XSLoader __ANON__ arybase arybase::mg base fields main maybe maybe::next mro next overload re strict threads utf8 vars version warnings warnings::register );

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

my ($prev_op, $package_pv, @package_pv); # global stash for methods since 5.13
my (%symtable, %cvforward, %lexwarnsym);
my (%strtable, %hektable, %gptable);
my %xsub;
my $warn_undefined_syms;
my ($staticxs, $outfile);
my (%include_package, %skip_package, %saved, %isa_cache);
my %static_ext;
my ($use_xsloader);
my $nullop_count         = 0;
my $unresolved_count     = 0;
# options and optimizations shared with B::CC
our ($module, $init_name, %savINC, $mainfile, @static_free);
our ($use_av_undef_speedup, $use_svpop_speedup) = (1, 1);
our ($optimize_ppaddr, $optimize_warn_sv, $use_perl_script_name,
    $save_data_fh, $save_sig, $optimize_cop, $av_init, $av_init2, $ro_inc, $destruct,
    $fold, $warnings, $const_strings, $stash, $can_delete_pkg, $pv_copy_on_grow);
our $verbose = 0;
our %option_map = (
    #ignored until IsCOW has a seperate COWREFCNT field (5.22 maybe)
    'cog'             => \$B::C::pv_copy_on_grow,
    'const-strings'   => \$B::C::const_strings,
    'save-data'       => \$B::C::save_data_fh,
    'ppaddr'          => \$B::C::optimize_ppaddr,
    'warn-sv'         => \$B::C::optimize_warn_sv,
    'av-init'         => \$B::C::av_init,
    'av-init2'        => \$B::C::av_init2,
    'delete-pkg'      => \$B::C::can_delete_pkg,
    'ro-inc'          => \$B::C::ro_inc,
    'stash'           => \$B::C::stash,    # enable with -fstash
    'destruct'        => \$B::C::destruct, # disable with -fno-destruct
    'fold'            => \$B::C::fold,     # disable with -fno-fold
    'warnings'        => \$B::C::warnings, # disable with -fno-warnings
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => \$B::C::save_sig,
    'cop'             => \$optimize_cop, # XXX very unsafe!
					 # Better do it in CC, but get rid of
					 # NULL cops also there.
);
our %optimization_map = (
    0 => [qw()],                # special case
    1 => [qw(-fppaddr -fwarn-sv -fav-init2)], # falls back to -fav-init
    2 => [qw(-fro-inc -fsave-data)],
    3 => [qw(-fno-destruct -fconst-strings -fno-fold -fno-warnings)],
    4 => [qw(-fcop)],
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
my ($max_string_len, $in_endav);
my %static_core_pkg; # = map {$_ => 1} static_core_packages();

my $MULTI = $Config{usemultiplicity};
my $ITHREADS = $Config{useithreads};
my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $DEBUG_LEAKING_SCALARS = $Config{ccflags} =~ m/-DDEBUG_LEAKING_SCALARS/;
my $PERL514  = ( $] >= 5.013002 );
my $PERL512  = ( $] >= 5.011 );
my $PERL510  = ( $] >= 5.009005 );
my $PERL56   = ( $] <  5.008001 ); # yes. 5.8.0 is a 5.6.x
#my $C99 = $Config{d_c99_variadic_macros}; # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962
my $MAD      = $Config{mad};
my $MYMALLOC = $Config{usemymalloc} eq 'define';
my @threadsv_names;

BEGIN {
  @threadsv_names = threadsv_names();
}

# This the Carp free workaround for DynaLoader::bootstrap
sub DynaLoader::croak {die @_}

# 5.15.3 workaround [perl #101336], without .bs support
# XSLoader::load_file($module, $modlibname, ...)
my $dlext = $Config::Config{dlext};
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
  my $file = "$modlibname/auto/$modpname/$modfname."|.qq(."$dlext").q|;

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
| if $] >= 5.015003;

# Code sections
my (
  $init,      $decl,      $symsect,    $binopsect, $condopsect,
  $copsect,   $padopsect, $listopsect, $logopsect, $loopsect,
  $opsect,    $pmopsect,  $pvopsect,   $svopsect,  $unopsect,
  $svsect,    $xpvsect,    $xpvavsect, $xpvhvsect, $xpvcvsect,
  $xpvivsect, $xpvuvsect,  $xpvnvsect, $xpvmgsect, $xpvlvsect,
  $xrvsect,   $xpvbmsect, $xpviosect,  $heksect,   $free,
  $padlistsect, $init2
);
my @op_sections = \(
  $binopsect,  $condopsect, $copsect,  $padopsect,
  $listopsect, $logopsect,  $loopsect, $opsect,
  $pmopsect,   $pvopsect,   $svopsect, $unopsect
);
# push @op_sections, ($resect) if $PERL512;
sub walk_and_save_optree;
my $saveoptree_callback = \&walk_and_save_optree;
sub set_callback { $saveoptree_callback = shift }
sub saveoptree { &$saveoptree_callback(@_) }
sub save_main_rest;
sub verbose { if (@_) { $verbose = shift; } else { $verbose; } }
sub module  { if (@_) { $module = shift; } else { $module; } }

sub walk_and_save_optree {
  my ( $name, $root, $start ) = @_;
  if ($root) {
    $verbose ? walkoptree_slow( $root, "save" ) : walkoptree( $root, "save" );
  }
  return objsym($start);
}

# Look this up here so we can do just a number compare
# rather than looking up the name of every BASEOP in B::OP
my $OP_THREADSV = opnumber('threadsv');
my $OP_DBMOPEN = opnumber('dbmopen');
my $OP_FORMLINE = opnumber('formline');
my $OP_UCFIRST = opnumber('ucfirst');

# special handling for nullified COP's.
my %OP_COP = ( opnumber('nextstate') => 1 );
$OP_COP{ opnumber('setstate') } = 1 if $] > 5.005003 and $] < 5.005062;
$OP_COP{ opnumber('dbstate') }  = 1 unless $PERL512;
warn %OP_COP if $debug{cops};

# 1. called from method_named, so hashp should be defined
# 2. called from svop before method_named to cache the $package_pv
sub svop_or_padop_pv {
  my $op = shift;
  my $sv;
  if (!$op->can("sv")) {
    if ($op->can('name') and $op->name eq 'padsv') {
      my @c = comppadlist->ARRAY;
      my @pad = $c[1]->ARRAY;
      return $pad[$op->targ]->PV if $pad[$op->targ] and $pad[$op->targ]->can("PV");
      # This might fail with B::NULL (optimized ex-const pv) entries in the pad.
    }
    # $op->can('pmreplroot') fails for 5.14
    if (ref($op) eq 'B::PMOP' and $op->pmreplroot->can("sv")) {
      $sv = $op->pmreplroot->sv;
    } else {
      return $package_pv unless $op->flags & 4;
      # op->first is disallowed for !KIDS and OPpCONST_BARE
      return $package_pv if $op->name eq 'const' and $op->flags & 64;
      return $package_pv unless $op->first->can("sv");
      $sv = $op->first->sv;
    }
  } else {
    $sv = $op->sv;
  }
  # XXX see SvSHARED_HEK_FROM_PV for the stash in S_method_common pp_hot.c
  # In this hash the CV is stored directly
  if ($sv and $$sv) {
    #if ($PERL510) { # PVX->hek_hash - STRUCT_OFFSET(struct hek, hek_key)
    #} else {        # UVX
    #}
    return $sv->PV if $sv->can("PV");
    if (ref($sv) eq "B::SPECIAL") { # DateTime::TimeZone
      # XXX null -> method_named
      warn "NYI S_method_common op->sv==B::SPECIAL, keep $package_pv\n" if $debug{gv};
      return $package_pv;
    }
    if ($sv->FLAGS & SVf_ROK) {
      goto missing if $sv->isa("B::NULL");
      my $rv = $sv->RV;
      if ($rv->isa("B::PVGV")) {
	my $o = $rv->IO;
	return $o->STASH->NAME if $$o;
      }
      goto missing if $rv->isa("B::PVMG");
      return $rv->STASH->NAME;
    } else {
  missing:
      if ($op->name ne 'method_named') {
	# Called from first const/padsv before method_named. no magic pv string, so a method arg.
	# The first const pv as method_named arg is always the $package_pv.
	return $package_pv;
      } elsif ($sv->isa("B::IV")) {
        warn sprintf("Experimentally try method_cv(sv=$sv,$package_pv) flags=0x%x",
                     $sv->FLAGS);
        # XXX untested!
        return svref_2object(method_cv($$sv, $package_pv));
      }
    }
  } else {
    my @c = comppadlist->ARRAY;
    my @pad = $c[1]->ARRAY;
    return $pad[$op->targ]->PV if $pad[$op->targ] and $pad[$op->targ]->can("PV");
  }
}

sub IsCOW {
  return $] >= 5.017008 and $_[0]->FLAGS & 0x00010000; # since 5.17.8
}
sub IsCOW_hek {
  return IsCOW($_[0]) && !$_[0]->LEN;
}

sub savesym {
  my ( $obj, $value ) = @_;
  no strict 'refs';
  my $sym = sprintf( "s\\_%x", $$obj );
  $symtable{$sym} = $value;
  return $value;
}

sub objsym {
  my $obj = shift;
  no strict 'refs';
  return $symtable{ sprintf( "s\\_%x", $$obj ) };
}

sub getsym {
  my $sym = shift;
  my $value;

  return 0 if $sym eq "sym_0";    # special case
  $value = $symtable{$sym};
  if ( defined($value) ) {
    return $value;
  }
  else {
    warn "warning: undefined symbol $sym\n" if $warn_undefined_syms;
    return "UNUSED";
  }
}

sub delsym {
  my ( $obj ) = @_;
  my $sym = sprintf( "s\\_%x", $$obj );
  delete $symtable{$sym};
}

sub savere {
  my $re = shift;
  my $flags = shift || 0;
  my $sym;
  my $pv    = $re;
  my $cur   = length $pv;
  my $len = 0; # length( pack "a*", $pv ) + 2;
  if ($PERL514) {
    $xpvsect->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {%s}", $xpvsect->index,
                           0x4405, ($C99?".svu_pv=":"").'(char*)'.savepv($pv) ) );
    $sym = sprintf( "&sv_list[%d]", $svsect->index );
  }
  elsif ($PERL510) {
    # BUG! Should be the same as newSVpvn($resym, $relen) but is not
    #$sym = sprintf("re_list[%d]", $re_index++);
    #$resect->add(sprintf("0,0,0,%s", cstring($re)));
    my $s1 = ($PERL514 ? "NULL," : "") . "{0}, %u, %u";
    $xpvsect->add( sprintf( $s1, $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {%s}", $xpvsect->index,
                           0x4405, ($C99?".svu_pv=":"").'(char*)'.savepv($pv) ) );
    my $s = "sv_list[".$svsect->index."]";
    $sym = "&$s";
    push @B::C::static_free, $s if $len; # and $B::C::pv_copy_on_grow;
    # $resect->add(sprintf("&xpv_list[%d], %lu, 0x%x", $xpvsect->index, 1, 0x4405));
  }
  else {
    $sym = sprintf( "re%d", $re_index++ );
    $decl->add( sprintf( "Static const char *$sym = %s;", cstring($re) ) );
  }
  return ( $sym, length( pack "a*", $re ) );
}

sub constpv {
  return savepv(shift, 1);
}

sub savepv {
  my $pv    = shift;
  my $const = shift;
  my $cstring = cstring($pv);
  # $decl->add( sprintf( "/* %s */", $cstring) ) if $debug{pv};
  return $strtable{$cstring} if defined $strtable{$cstring};
  $pv    = pack "a*", $pv;
  my $pvsym = sprintf( "pv%d", $pv_index++ );
  $const = " const" if $const;
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    my $chars = join ', ', map { cchar $_ } split //, $pv;
    $decl->add( sprintf( "Static$const char %s[] = { %s };", $pvsym, $chars ) );
    $strtable{$cstring} = "$pvsym";
  } else {
    if ( $cstring ne "0" ) {    # sic
      $decl->add( sprintf( "Static$const char %s[] = %s;", $pvsym, $cstring ) );
      $strtable{$cstring} = "$pvsym";
    }
  }
  return wantarray ? ( $pvsym, length($pv) ) : $pvsym;
}

sub save_rv {
  my ($sv, $fullname) = @_;
  if (!$fullname) {
    $fullname = '(unknown)';
  }
  # confess "Can't save RV: not ROK" unless $sv->FLAGS & SVf_ROK;
  # 5.6: Can't locate object method "RV" via package "B::PVMG"
  # since 5.11 it must be a PV, the RV was removed from the IV
  my $rv;
  #if ($] >= 5.011 and ref($sv) =~ /^B::[IP]V$/) {
  #  warn "$sv is no IV nor PV\n" if $debug{sv};
  #  $sv = bless $sv, 'B::PV'; # only observed with DB::args[0]
  #}
  #elsif ($] < 5.011 and ref($sv) =~ /^B::[RP]V$/) {
  #  warn "$sv is no RV nor PV\n" if $debug{sv};
  #  $sv = bless $sv, 'B::RV';
  #}
  $rv = $sv->RV->save($fullname);
  $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

  return $rv;
}

# => savesym, cur, len, pv, static
sub save_pv_or_rv {
  my ($sv, $fullname) = @_;

  my $rok = $sv->FLAGS & SVf_ROK;
  my $pok = $sv->FLAGS & SVf_POK;
  my $gmg = $sv->FLAGS & SVs_GMG;
  my ( $cur, $len, $savesym, $pv ) = ( 0, 1, 'NULL' );
  my ($static, $shared_hek);
  # overloaded VERSION symbols fail to xs boot: ExtUtils::CBuilder with Fcntl::VERSION (i91)
  # 5.6: Can't locate object method "RV" via package "B::PV" Carp::Clan
  if ($rok and !$PERL56) {
    # this returns us a SV*. 5.8 expects a char* in xpvmg.xpv_pv
    warn "save_pv_or_rv: save_rv(",$sv,")\n" if $debug{sv};
    $savesym = ($PERL510 ? "" : "(char*)") . save_rv($sv, $fullname);
    $static = 1; # avoid run-time overwrite of the PV/RV slot (#273)
    if ($savesym =~ /(\(char\*\))?get_cv\("/) { # Moose::Util::TypeConstraints::Builtins::_RegexpRef
      $static = 0;
      $pv = $savesym;
      $savesym = 'NULL';
    }
  }
  else {
    if ($pok) {
      $pv = pack "a*", $sv->PV;
      $cur = ($sv and $sv->can('CUR') and ref($sv) ne 'B::GV') ? $sv->CUR : length($pv);
    } else {
      if ($gmg && $fullname) {
	no strict 'refs';
	$pv = ($fullname and ref($fullname)) ? "${$fullname}" : '';
	$cur = length (pack "a*", $pv);
	$pok = 1;
      } else {
	($pv,$cur) = (undef,0);
      }
    }
    $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
    $shared_hek = $shared_hek ? 1 : IsCOW_hek($sv);
    $static = $B::C::const_strings and ($sv->FLAGS & SVf_READONLY) ? 1 : 0;
    $static = 0 if $shared_hek or ($fullname and ($fullname =~ / :pad/ or ($fullname =~ /^DynaLoader/ and $pv =~ /^boot_/)));
    if ($shared_hek and $pok and !$cur) { #272 empty key
      warn "use emptystring for empty shared key $fullname\n" if $debug{hv};
      $savesym = "emptystring";
      $static = 0;
    }
    if ($PERL510) { # force dynamic PADNAME strings
      if ($] < 5.016) { $static = 0 if $sv->FLAGS & 0x40000000; }      # SVpad_NAME
      else { $static = 0 if ($sv->FLAGS & 0x40008000 == 0x40008000); } # SVp_SCREAM|SVpbm_VALID
    }
    if ($pok) {
      my $s = "sv_list[" . ($svsect->index + 1) . "]";
      # static pv (!SvLEN) only valid since cd84013aab030da47b76a44fb3 (sv.c: !SvLEN does not mean undefined)
      # i.e. since v5.17.6. because conversion to IV would fail.
      # But a "" or "0" or "[a-z]+" string can have SvLEN=0
      # since its is converted to 0
      no warnings 'numeric';
      if ($static and $] < 5.017006 and abs($pv) > 0) {
        $static = 0;
      }
      # but we can optimize static set-magic ISA entries. #263, #91
      if ($B::C::const_strings and ref($sv) eq 'B::PVMG' and $sv->FLAGS & SVs_SMG) {
        $static = 1;
      }
      if ($static) {
	$len = 0;
	$savesym = IsCOW($sv) ? savepv($pv) : constpv($pv);
        if ($savesym =~ /^(\(char\*\))?get_cv\("/) { # Moose::Util::TypeConstraints::Builtins::_RegexpRef
          $static = 0;
	  $len = $cur +1;
          $pv = $savesym;
          $savesym = 'NULL';
        }
        $len = $cur+2 if IsCOW($sv) and $cur;
        push @B::C::static_free, $s if $len and !$B::C::in_endav;
      } else {
	$len = $cur+1;
        if ($shared_hek) {
          if ($savesym eq "emptystring") {
            $free->add("    SvLEN(&$s) = 0;") ;
          } else {
            $len = 0;
          }
          $free->add("    SvFAKE_off(&$s);");
        } else {
          $len++ if IsCOW($sv) and $cur;
        }
      }
    } else {
      $len = 0;
    }
  }
  warn sprintf("Saving pv %s %s cur=%d, len=%d, static=%d %s\n", $savesym, cstring($pv), $cur, $len,
               $static, $shared_hek ? "shared, $fullname" : $fullname) if $debug{pv};
  return ( $savesym, $cur, $len, $pv, $static );
}

# Shared global string in PL_strtab.
# Mostly GvNAME and GvFILE, but also CV prototypes or bareword hash keys.
sub save_hek {
  my $str = shift; # not cstring'ed
  my $len = length $str;
  # force empty string for CV prototypes
  if (!$len and !@_) { wantarray ? return ( "NULL", 0 ) : return "NULL"; }
  if (defined $hektable{$str}) {
    return wantarray ? ($hektable{$str}, length( pack "a*", $hektable{$str} ))
      : $hektable{$str};
  }
  my $cur = length( pack "a*", $str );
  if (!$PERL56) {
    if (utf8::is_utf8($str)) {
      my $pv = $str;
      utf8::encode($pv);
      $cur = - length $pv;
    }
  }
  my $sym = sprintf( "hek%d", $hek_index++ );
  $hektable{$str} = $sym;
  my $cstr = cstring($str);
  $decl->add(sprintf("Static HEK *%s;",$sym));
  warn sprintf("Saving hek %s %s cur=%d\n", $sym, $cstr, $cur)
    if $debug{pv};
  # randomized global shared hash keys:
  #   share_hek needs a non-zero hash parameter, unlike hv_store.
  #   Vulnerable to oCERT-2011-003 style DOS attacks?
  #   user-input (object fields) does not affect strtab, it is pretty safe.
  # But we need to randomize them to avoid run-time conflicts
  #   e.g. "Prototype mismatch: sub bytes::length (_) vs (_)"
  $init->add(sprintf("%s = share_hek(%s, %d, %s);",
		     $sym, $cstr, $cur, '0'));
  wantarray ? ( $sym, $cur ) : $sym;
}

sub ivx ($) {
  my $ivx = shift;
  my $ivdformat = $Config{ivdformat};
  $ivdformat =~ s/"//g; #" poor editor
  my $intmax = (1 << ($Config{ivsize}*4-1)) - 1;
  my $L = 'L';
  # LL for 32bit -2147483648L or 64bit -9223372036854775808L
  $L = 'LL' if $Config{ivsize} == 2*$Config{ptrsize};
  # UL if > INT32_MAX = 2147483647
  my $sval = sprintf("%${ivdformat}%s", $ivx, $ivx > $intmax ? "U$L" : "");
  if ($ivx < -$intmax) {
    $sval = sprintf("%${ivdformat}%s", $ivx, 'LL'); # DateTime
  }
  if ($INC{'POSIX.pm'}) {
    # i262: LONG_MIN -9223372036854775808L integer constant is so large that it is unsigned
    if ($ivx == POSIX::LONG_MIN()) {
      $sval = "LONG_MIN";
    }
    elsif ($ivx == POSIX::LONG_MAX()) {
      $sval = "LONG_MAX";
    }
  }
  $sval = '0' if $sval =~ /(NAN|inf)$/i;
  return $sval;
  #return $C99 ? ".xivu_uv = $sval" : $sval; # this is version dependent
}

# protect from warning: floating constant exceeds range of ‘double’ [-Woverflow]
sub nvx ($) {
  my $nvx = shift;
  my $nvgformat = $Config{nvgformat};
  $nvgformat =~ s/"//g; #" poor editor
  my $dblmax = "1.79769313486232e+308";
  # my $ldblmax = "1.18973149535723176502e+4932L"
  my $ll = $Config{d_longdbl} ? "LL" : "L";
  if ($nvgformat eq 'g') { # a very poor choice to keep precision
    # on intel 17-18, on ppc 31, on sparc64/s390 34
    $nvgformat = $Config{uselongdouble} ? '.17Lg' : '.16g';
  }
  my $sval = sprintf("%${nvgformat}%s", $nvx, $nvx > $dblmax ? $ll : "");
  if ($nvx < -$dblmax) {
    $sval = sprintf("%${nvgformat}%s", $nvx, $ll);
  }
  if ($INC{'POSIX.pm'}) {
    if ($nvx == POSIX::DBL_MIN()) {
      $sval = "DBL_MIN";
    }
    elsif ($nvx == POSIX::DBL_MAX()) { #1.797693134862316e+308
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
  my $pkg = shift;
  my $pkg_heavy = $pkg."_heavy.pl";
  no strict 'refs';
  if (!$include_package{$pkg_heavy}) {
    #eval qq[sub $pkg\::AUTOLOAD {
    #    require '$pkg_heavy';
    #    goto &\$AUTOLOAD if defined &\$AUTOLOAD;
    #    warn("Undefined subroutine \$AUTOLOAD called");
    #  }];
    #warn "Redefined $pkg\::AUTOLOAD to omit Carp\n" if $debug{gv};
    warn "Forcing early $pkg_heavy\n" if $debug{pkg};
    require $pkg_heavy;
    mark_package($pkg_heavy, 1);
    #walk_syms($pkg); #before we stub unloaded CVs
  }
  return svref_2object( \*{$pkg."::AUTOLOAD"} );
}

# See also init_op_ppaddr below; initializes the ppaddr to the
# OpTYPE; init_op_ppaddr iterates over the ops and sets
# op_ppaddr to PL_ppaddr[op_ppaddr]; this avoids an explicit assignment
# in perl_init ( ~10 bytes/op with GCC/i386 )
sub B::OP::fake_ppaddr {
  return "NULL" unless $_[0]->can('name');
  return $B::C::optimize_ppaddr
    ? sprintf( "INT2PTR(void*,OP_%s)", uc( $_[0]->name ) )
    : ( $verbose ? sprintf( "/*OP_%s*/NULL", uc( $_[0]->name ) ) : "NULL" );
}
sub B::FAKEOP::fake_ppaddr { "NULL" }
# XXX HACK! duct-taping around compiler problems
sub B::OP::isa { UNIVERSAL::isa(@_) } # walkoptree_slow misses that
sub B::OP::can { UNIVERSAL::can(@_) }
sub B::OBJECT::name  { "" }           # B misses that
$isa_cache{'B::OBJECT::can'} = 'UNIVERSAL';

# This pair is needed because B::FAKEOP::save doesn't scalar dereference
# $op->next and $op->sibling
my $opsect_common =
  "next, sibling, ppaddr, " . ( $MAD ? "madprop, " : "" ) . "targ, type, ";
{

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
  my $static;
  if ( $] < 5.009004 ) {
    $static = sprintf "%u", 65535;
    $opsect_common .= "seq";
  }
  elsif ( $] < 5.010 ) {
    $static = '0, 1, 0';
    $opsect_common .= "opt, static, spare";
  }
  elsif ($] < 5.017002) {
    $static = '0, 1, 0, 0, 0';
    $opsect_common .= "opt, latefree, latefreed, attached, spare";
  }
  elsif ($] < 5.017004) {
    $static = '0, 1, 0, 0, 0, 0, 0';
    $opsect_common .= "opt, latefree, latefreed, attached, slabbed, savefree, spare";
  }
  elsif ($] < 5.017006) {
    $static = '0, 1, 0, 0, 0, 0, 0';
    $opsect_common .= "opt, latefree, latefreed, attached, slabbed, savefree, spare";
  }
  elsif ($] < 5.019002) { # 90840c5d1d 5.17.6
    $static = '0, 0, 0, 1, 0';
    $opsect_common .= "opt, slabbed, savefree, static, spare";
  }
  else {
    $static = '0, 0, 0, 1, 0, 0';
    $opsect_common .= "opt, slabbed, savefree, static, folded, spare";
  }

  sub B::OP::_save_common_middle {
    my $op = shift;
    my $madprop = $MAD ? "0," : "";
    # XXX maybe add a ix=opindex string for debugging if $debug{flags}
    sprintf( "%s,%s %u, %u, $static, 0x%x, 0x%x",
      $op->fake_ppaddr, $madprop, $op->targ, $op->type, $op->flags, $op->private );
  }
  $opsect_common .= ", flags, private";
}

sub B::OP::_save_common {
  my $op = shift;
  # compile-time method_named packages are always const PV sM/BARE, they should be optimized.
  # run-time packages are in gvsv/padsv. This is difficult to optimize.
  #   my Foo $obj = shift; $obj->bar(); # TODO typed $obj
  # entersub -> pushmark -> package -> args...
  # See perl -MO=Terse -e '$foo->bar("var")'
  # See also http://www.perl.com/pub/2000/06/dougpatch.html
  # XXX TODO 5.8 ex-gvsv
  # XXX TODO Check for method_named as last argument
  if ($op->type > 0 and
      $op->name eq 'entersub' and $op->first and $op->first->can('name') and
      $op->first->name eq 'pushmark' and
      # Foo->bar()  compile-time lookup, 34 = BARE in all versions
      (($op->first->next->name eq 'const' and $op->first->next->flags == 34)
       or $op->first->next->name eq 'padsv'      # or $foo->bar() run-time lookup
       or ($] < 5.010 and $op->first->next->name eq 'gvsv' and !$op->first->next->type  # 5.8 ex-gvsv
	   and $op->first->next->next->name eq 'const' and $op->first->next->next->flags == 34))
     ) {
    my $pkgop = $op->first->next;
    if ($] < 5.010 and !$op->first->next->type) { # 5.8 ex-gvsv
      $pkgop = $op->first->next->next;
    }
    warn "check package_pv ".$pkgop->name." for method_name\n" if $debug{cv};
    my $pv = svop_or_padop_pv($pkgop); # 5.13: need to store away the pkg pv
    if ($pv and $pv !~ /[! \(]/) {
      $package_pv = $pv;
      push_package($package_pv);
    } else {
      # mostly optimized-away padsv NULL pads with 5.8
      warn "package_pv for method_name not found\n" if $debug{cv} or $debug{pkg};
    }
  }
  # $prev_op = $op;
  return sprintf(
    "s\\_%x, s\\_%x, %s",
    ${ $op->next },
    ${ $op->sibling },
    $op->_save_common_middle
  );
}

sub B::OP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $type = $op->type;
  $nullop_count++ unless $type;
  if ( $type == $OP_THREADSV ) {
    # saves looking up ppaddr but it's a bit naughty to hard code this
    $init->add(sprintf( "(void)find_threadsv(%s);", cstring( $threadsv_names[ $op->targ ])));
  }
  if ( $type == $OP_UCFIRST ) {
    $B::C::fold = 1;
    if ($] >= 5.013009) {
      warn "enabling -ffold with ucfirst\n" if $verbose;
      require "utf8.pm" unless $INC{"utf8.pm"};
      require "utf8_heavy.pl" unless $INC{"utf8_heavy.pl"}; # bypass AUTOLOAD
      mark_package("utf8");
      mark_package("utf8_heavy.pl");
    }
  }
  if (ref($op) eq 'B::OP') { # check wrong BASEOPs
    # [perl #80622] Introducing the entrytry hack, needed since 5.12, fixed with 5.13.8 a425677
    #   ck_eval upgrades the UNOP entertry to a LOGOP, but B gets us just a B::OP (BASEOP).
    #   op->other points to the leavetry op, which is needed for the eval scope.
    if ($op->name eq 'entertry') {
      warn "[perl #80622] Upgrading entertry from BASEOP to LOGOP...\n" if $verbose;
      bless $op, 'B::LOGOP';
      return $op->save($level);
    }
  }

  # since 5.10 nullified cops free their additional fields
  if ( $PERL510 and !$type and $OP_COP{ $op->targ } ) {
    warn sprintf( "Null COP: %d\n", $op->targ ) if $debug{cops};
    if (0 and $optimize_cop) {
      # XXX when is the NULL COP save to skip?
      # unsafe after entersub, entereval, anoncode, sort block (pushmark pushmark)
      # Rather skip this with CC not with C because we need the context.
      # XXX we dont have the prevop, it can be any op type.
      if ($verbose or $debug{cops}) {
        my $prevop = getsym(sprintf("&op_list[%d]", $opsect->index));
        warn sprintf( "Skip Null COP: %d, prev=\\s%x\n",
                      $op->targ, $prevop);
      }
      return savesym( $op, $op->next->save );
    }
    if ($ITHREADS and $] >= 5.017) {
      $copsect->comment(
	      "$opsect_common, line, stashoff, file, hints, seq, warnings, hints_hash");
      $copsect->add(sprintf("%s, 0, 0, (char *)NULL, 0, 0, NULL, NULL",
			    $op->_save_common));
    }
    elsif ($ITHREADS and $] >= 5.016) {
      $copsect->comment(
        "$opsect_common, line, stashpv, file, stashlen, hints, seq, warnings, hints_hash");
      $copsect->add(sprintf("%s, 0, (char *)NULL, NULL, 0, 0, 0, NULL, NULL",
			    $op->_save_common));
    }
    elsif ($ITHREADS and $] >= 5.015004) {
      $copsect->comment(
        "$opsect_common, line, stash, file, hints, seq, warnings, hints_hash");
      $copsect->add(sprintf("%s, 0, (char *)NULL, NULL, 0, 0, NULL, NULL",
			    $op->_save_common));
    }
    elsif ($PERL512) {
      $copsect->comment(
        "$opsect_common, line, stash, file, hints, seq, warnings, hints_hash");
      $copsect->add(sprintf("%s, 0, %s, NULL, 0, 0, NULL, NULL",
			    $op->_save_common, $ITHREADS ? "(char *)NULL" : "Nullhv"));
    }
    elsif ($PERL510) {
      $copsect->comment("$opsect_common, line, label, seq, warn_int, hints_hash");
      $copsect->add(sprintf("%s, %u, NULL, " . "NULL, NULL, 0, " . "%u, %d, NULL",
			    $op->_save_common, 0, 0, 0));
    }
    else {
      $copsect->comment(
        "$opsect_common, label, seq, arybase, line, warnings, hints_hash");
      $copsect->add(
        sprintf( "%s, NULL, NULL, NULL, 0, 0, 0, NULL", $op->_save_common ) );
    }
    my $ix = $copsect->index;
    $init->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    savesym( $op, "(OP*)&cop_list[$ix]" );
  }
  else {
    $opsect->comment($opsect_common);
    $opsect->add( $op->_save_common );

    $opsect->debug( $op->name, $op->flagspv ) if $debug{flags};
    my $ix = $opsect->index;
    $init->add( sprintf( "op_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    warn( sprintf( "  OP=%s targ=%d flags=0x%x private=0x%x\n",
		   peekop($op), $op->targ, $op->flags, $op->private ) ) if $debug{op};
    savesym( $op, "&op_list[$ix]" );
  }
}

# needed for special GV logic: save only stashes for stashes
package B::STASHGV;
our @ISA = ('B::GV');

package B::FAKEOP;

our @ISA = qw(B::OP);

sub new {
  my ( $class, %objdata ) = @_;
  bless \%objdata, $class;
}

sub save {
  my ( $op, $level ) = @_;
  $opsect->add(
    sprintf( "%s, %s, %s", $op->next, $op->sibling, $op->_save_common_middle )
  );
  my $ix = $opsect->index;
  $init->add( sprintf( "op_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  return "&op_list[$ix]";
}

*_save_common_middle = \&B::OP::_save_common_middle;
sub next    { $_[0]->{"next"}  || 0 }
sub type    { $_[0]->{type}    || 0 }
sub sibling { $_[0]->{sibling} || 0 }
sub ppaddr  { $_[0]->{ppaddr}  || 0 }
sub targ    { $_[0]->{targ}    || 0 }
sub flags   { $_[0]->{flags}   || 0 }
sub private { $_[0]->{private} || 0 }

package B::C;

# dummy for B::C, only needed for B::CC
sub label {}

# save alternate ops if defined, and also add labels (needed for B::CC)
sub do_labels ($@) {
  my $op = shift;
  for my $m (@_) {
    if ( ${ $op->$m } ) {
      label($op->$m);
      $op->$m->save if $m ne 'first'
       or ($op->flags & 4
           and !($op->name eq 'const' and $op->flags & 64)); #OPpCONST_BARE has no first
    }
  }
}

sub B::UNOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $unopsect->comment("$opsect_common, first");
  $unopsect->add( sprintf( "%s, s\\_%x", $op->_save_common, ${ $op->first } ) );
  $unopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $unopsect->index;
  $init->add( sprintf( "unop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $sym = savesym( $op, "(OP*)&unop_list[$ix]" );
  do_labels ($op, 'first');
  $sym;
}

sub B::BINOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $binopsect->comment("$opsect_common, first, last");
  $binopsect->add(
    sprintf(
      "%s, s\\_%x, s\\_%x",
      $op->_save_common,
      ${ $op->first },
      ${ $op->last }
    )
  );
  $binopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $binopsect->index;
  $init->add( sprintf( "binop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $sym = savesym( $op, "(OP*)&binop_list[$ix]" );
  do_labels ($op, 'first', 'last');
  $sym;
}

sub B::LISTOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $listopsect->comment("$opsect_common, first, last");
  $listopsect->add(
    sprintf(
      "%s, s\\_%x, s\\_%x",
      $op->_save_common,
      ${ $op->first },
      ${ $op->last }
    )
  );
  $listopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $listopsect->index;
  $init->add( sprintf( "listop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $sym = savesym( $op, "(OP*)&listop_list[$ix]" );
  if ($op->type == $OP_DBMOPEN) {
    # resolves it at compile-time, not at run-time
    # mark_package('AnyDBM_File') does too much, just bootstrap the single ISA
    require AnyDBM_File;
    my $dbm = $AnyDBM_File::ISA[0];
    svref_2object( \&{"$dbm\::bootstrap"} )->save;
  } elsif ($op->type == $OP_FORMLINE and $B::C::const_strings) { # -O3 ~
    # non-static only for all const strings containing ~ #277
    my $sv;
    my $fop = $op;
    my $svop = $op->first;
    while ($svop != $op and ref($svop) ne 'B::NULL') {
      if ($svop->name == 'const' and $svop->can('sv')) {
        $sv = $svop->sv;
      }
      if ($sv and $sv->can("PV") and $sv->PV =~ /~/m) {
        local $B::C::const_strings;
        warn "force non-static formline arg ",cstring($sv->PV),"\n" if $debug{pv};
        $svop->save("svop const");
      }
      $svop = $svop->next;
    }
  }
  do_labels ($op, 'first', 'last');
  $sym;
}

sub B::LOGOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $logopsect->comment("$opsect_common, first, other");
  $logopsect->add(
    sprintf(
      "%s, s\\_%x, s\\_%x",
      $op->_save_common,
      ${ $op->first },
      ${ $op->other }
    )
  );
  $logopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $logopsect->index;
  $init->add( sprintf( "logop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $sym = savesym( $op, "(OP*)&logop_list[$ix]" );
  do_labels ($op, 'first', 'other');
  $sym;
}

sub B::LOOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;

  #warn sprintf("LOOP: redoop %s, nextop %s, lastop %s\n",
  #		 peekop($op->redoop), peekop($op->nextop),
  #		 peekop($op->lastop)) if $debug{op};
  $loopsect->comment("$opsect_common, first, last, redoop, nextop, lastop");
  $loopsect->add(
    sprintf(
      "%s, s\\_%x, s\\_%x, s\\_%x, s\\_%x, s\\_%x",
      $op->_save_common,
      ${ $op->first },
      ${ $op->last },
      ${ $op->redoop },
      ${ $op->nextop },
      ${ $op->lastop }
    )
  );
  $loopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $loopsect->index;
  $init->add( sprintf( "loop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $sym = savesym( $op, "(OP*)&loop_list[$ix]" );
  do_labels($op, qw(first last redoop nextop lastop));
  $sym;
}

sub B::PVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $loopsect->comment("$opsect_common, pv");
  # op_pv must be dynamic
  $pvopsect->add( sprintf( "%s, NULL", $op->_save_common ) );
  $pvopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $pvopsect->index;
  $init->add( sprintf( "pvop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  my $pv = pack "a*", $op->pv;
  my $cur = length($pv);
  if (!$PERL56) {
    if (utf8::is_utf8($pv)) {
      utf8::encode($pv);
      $cur = length $pv;
    }
  }
  $init->add( sprintf( "pvop_list[$ix].op_pv = savepvn(%s, %u);", cstring( $pv ), $cur ) );
  savesym( $op, "(OP*)&pvop_list[$ix]" );
}

# XXX Until we know exactly the package name for a method_call
# we improve the method search heuristics by maintaining this mru list.
sub push_package ($) {
  my $p = shift or return;
  warn "save package_pv \"$package_pv\" for method_name from @{[(caller(1))[3]]}\n"
    if $debug{cv} or $debug{pkg} and !grep { $p eq $_ } @package_pv;
  @package_pv = grep { $p ne $_ } @package_pv if @package_pv; # remove duplicates at the end
  unshift @package_pv, $p; 		       # prepend at the front
  mark_package($p);
}

# method_named is in 5.6.1
sub method_named {
  my $name = shift;
  return unless $name;
  my $cop = shift;
  my $loc = $cop ? " at ".$cop->file." line ".$cop->line : "";
  # Note: the pkg PV is unacessible(?) at PL_stack_base+TOPMARK+1.
  # But it is also at the const or padsv after the pushmark, before all args.
  # See L<perloptree/"Call a method">
  # We check it in op->_save_common
  if (ref($name) eq 'B::CV') {
    warn $name;
    return $name;
  }
  my $method;
  for ($package_pv, @package_pv, 'main') {
    no strict 'refs';
    next unless defined $_;
    $method = $_ . '::' . $name;
    if (defined(&$method)) {
      warn sprintf( "Found &%s::%s\n", $_, $name ) if $debug{cv};
      $include_package{$_} = 1; # issue59
      mark_package($_, 1);
      last;
    } else {
      if (my $parent = try_isa($_,$name)) {
	warn sprintf( "Found &%s::%s\n", $parent, $name ) if $debug{cv};
	$method = $parent . '::' . $name;
	$include_package{$parent} = 1;
	last;
      }
      warn "no definition for method_name \"$method\"\n" if $debug{cv};
    }
  }
  #my $b = $Config{archname}."/B\.pm";
  #if ($name !~ /^tid|can|isa|pmreplroot$/ and $loc !~ m/$b line / and $package_pv !~ /^B::/) {
  #  return undef if $ITHREADS;
  #}
  $method = $name unless $method;
  if (exists &$method) { # Do not try to save non-existing methods
    warn "save method_name \"$method\"$loc\n" if $debug{cv};
    return svref_2object( \&{$method} );
  } else {
    return 0;
  }
}


# scalar: pv. list: (stash,pv,sv)
# pads are not named, but may be typed
sub padop_name {
  my $op = shift;
  my $cv = shift;
  if ($op->can('name')
      and ($op->name eq 'padsv' or $op->name eq 'method_named'
	   or ref($op) eq 'B::SVOP')) #threaded
  {
    return () if $cv and ref($cv->PADLIST) eq 'B::SPECIAL';
    my @c = ($cv and ref($cv) eq 'B::CV' and ref($cv->PADLIST) ne 'B::NULL')
             ? $cv->PADLIST->ARRAY : comppadlist->ARRAY;
    my @pad = $c[1]->ARRAY;
    my @types = $c[0]->ARRAY;
    my $ix = $op->can('padix') ? $op->padix : $op->targ;
    my $sv = $pad[$ix];
    my $t = $types[$ix];
    if (defined($t) and ref($t) ne 'B::SPECIAL') {
      my $pv = $sv->can("PV") ? $sv->PV : ($t->can('PVX') ? $t->PVX : '');
      # need to fix B for SVpad_TYPEDI without formal STASH
      my $stash = (ref($t) eq 'B::PVMG' and ref($t->SvSTASH) ne 'B::SPECIAL') ? $t->SvSTASH->NAME : '';
      return wantarray ? ($stash,$pv,$sv) : $pv;
    } elsif ($sv) {
      my $pv = $sv->PV if $sv->can("PV");
      my $stash = $sv->STASH->NAME if $sv->can("STASH");
      return wantarray ? ($stash,$pv,$sv) : $pv;
    }
  }
}

sub svop_name {
  my $op = shift;
  my $cv = shift;
  my $sv;
  if ($op->can('name') and $op->name eq 'padsv') {
    my @r = padop_name($op, $cv);
    return wantarray ? @r : ($r[1] ? $r[1] : $r[0]);
  } else {
    if (!$op->can("sv")) {
      if (ref($op) eq 'B::PMOP' and $op->pmreplroot->can("sv")) {
	$sv = $op->pmreplroot->sv;
      } else {
	$sv = $op->first->sv unless $op->flags & 4
	  or ($op->name eq 'const' and $op->flags & 34) or $op->first->can("sv");
      }
    } else {
      $sv = $op->sv;
    }
    if ($sv and $$sv) {
      if ($sv->FLAGS & SVf_ROK) {
	return '' if $sv->isa("B::NULL");
	my $rv = $sv->RV;
	if ($rv->isa("B::PVGV")) {
	  my $o = $rv->IO;
	  return $o->STASH->NAME if $$o;
	}
	return '' if $rv->isa("B::PVMG");
	return $rv->STASH->NAME;
      } else {
	if ($op->name eq 'gvsv') {
	  return wantarray ? ($sv->STASH->NAME, $sv->NAME) : $sv->STASH->NAME.'::'.$sv->NAME;
	} elsif ($op->name eq 'gv') {
	  return wantarray ? ($sv->STASH->NAME, $sv->NAME) : $sv->STASH->NAME.'::'.$sv->NAME;
	} else {
	  return $sv->can('STASH') ? $sv->STASH->NAME
	    : $sv->can('NAME') ? $sv->NAME : $sv->PV;
	}
      }
    }
  }
}

# return the next COP for file and line info
sub nextcop {
  my $op = shift;
  while ($op and ref($op) ne 'B::COP' and ref($op) ne 'B::NULL') { $op = $op->next; }
  return ($op and ref($op) eq 'B::COP') ? $op : undef;
}

sub B::SVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $svsym = 'Nullsv';
  # XXX moose1 crash with 5.8.5-nt, Cwd::_perl_abs_path also
  if ($op->name eq 'aelemfast' and $op->flags & 128) { #OPf_SPECIAL
    $svsym = '&PL_sv_undef'; # pad does not need to be saved
    warn sprintf("SVOP->sv aelemfast pad %d\n", $op->flags) if $debug{sv};
  } elsif ($op->name eq 'gv' and $op->next and $op->next->name eq 'rv2cv'
	   and $op->next->next and $op->next->next->name eq 'defined' ) {
    # 96 do not save a gvsv->cv if just checked for defined'ness
    my $gv = $op->sv;
    my $gvsv = svop_name($op);
    if ($gvsv !~ /^DynaLoader::/) {
      warn "skip saving defined(&$gvsv)\n" if $debug{gv}; # defer to run-time
      $svsym  = '(SV*)' . $gv->save( 8 ); # ~Save_CV in B::GV::save
    } else {
      $svsym  = '(SV*)' . $gv->save();
    }
  } else {
    my $sv    = $op->sv;
    $svsym  = '(SV*)' . $sv->save("svop ".$op->name);
  }
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op), nextcop($op));
    $cv->save if $cv;
  }
  my $is_const_addr = $svsym =~ m/Null|\&/;
  if ($MULTI and $svsym =~ /\(SV\*\)\&PL_sv_(yes|no)/) { # t/testm.sh Test::Pod
    $is_const_addr = 0;
  }
  $svopsect->comment("$opsect_common, sv");
  $svopsect->add(
    sprintf( "%s, %s",
      $op->_save_common, ( $is_const_addr ? $svsym : 'Nullsv' ) )
  );
  $svopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $svopsect->index;
  $init->add( sprintf( "svop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $init->add("svop_list[$ix].op_sv = $svsym;")
    unless $is_const_addr;
  savesym( $op, "(OP*)&svop_list[$ix]" );
}

sub B::PADOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $skip_defined;
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op), nextcop($op));
    $cv->save if $cv;
  } elsif ($op->name eq 'gv' and $op->next and $op->next->name eq 'rv2cv'
	   and $op->next->next and $op->next->next->name eq 'defined' ) {
    # 96 do not save a gvsv->cv if just checked for defined'ness
    $skip_defined++;
  }
  # This is saved by curpad syms at the end. But with __DATA__ handles it is better to save earlier
  if ($op->name eq 'padsv' or $op->name eq 'gvsv' or $op->name eq 'gv') {
    my @c = comppadlist->ARRAY;
    my @pad = $c[1]->ARRAY;
    my $ix = $op->can('padix') ? $op->padix : $op->targ;
    my $sv = $pad[$ix];
    if ($sv and $$sv) {
      my $name = padop_name($op, $B::C::curcv);
      if ($skip_defined and $name !~ /^DynaLoader::/) {
	warn "skip saving defined(&$name)\n" if $debug{gv}; # defer to run-time
      } else {
	$sv->save("padop ". ($name ? $name : ''));
      }
    }
  }
  $padopsect->comment("$opsect_common, padix");
  $padopsect->add( sprintf( "%s, %d", $op->_save_common, $op->padix ) );
  $padopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $padopsect->index;
  $init->add( sprintf( "padop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  savesym( $op, "(OP*)&padop_list[$ix]" );
}

sub B::COP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;

  if ($optimize_cop and !$op->label) { # XXX very unsafe!
    my $sym = savesym( $op, $op->next->save );
    warn sprintf( "Skip COP (0x%x) => %s (0x%x), line %d file %s\n",
                  $$op, $sym, $op->next, $op->line, $op->file ) if $debug{cops};
    return $sym;
  }

  # TODO: if it is a nullified COP we must save it with all cop fields!
  warn sprintf( "COP: line %d file %s\n", $op->line, $op->file )
    if $debug{cops};

  # shameless cut'n'paste from B::Deparse
  my $warn_sv;
  my $warnings   = $op->warnings;
  my $is_special = ref($warnings) eq 'B::SPECIAL';
  my $warnsvcast = $PERL510 ? "STRLEN*" : "SV*";
  if ( $is_special && $$warnings == 4 ) {
    # use warnings 'all';
    $warn_sv =
      $B::C::optimize_warn_sv
      ? "INT2PTR($warnsvcast,1)".($verbose ?' /*pWARN_ALL*/':'')
      : 'pWARN_ALL';
  }
  elsif ( $is_special && $$warnings == 5 ) {
    # no warnings 'all';
    $warn_sv =
      $B::C::optimize_warn_sv
      ? "INT2PTR($warnsvcast,2)".($verbose ?' /*pWARN_NONE*/':'')
      : 'pWARN_NONE';
  }
  elsif ($is_special) {
    # use warnings;
    $warn_sv =
      $B::C::optimize_warn_sv
      ? "INT2PTR($warnsvcast,3)".($verbose ?' /*pWARN_STD*/':'')
      : 'pWARN_STD';
  }
  else {
    # LEXWARN_on: Original $warnings->save from 5.8.9 was wrong,
    # DUP_WARNINGS copied length PVX bytes.
    $warnings = bless $warnings, "B::LEXWARN";
    $warn_sv = $warnings->save;
    my $ix = $copsect->index + 1;
    # XXX No idea how a &sv_list[] came up here, a re-used object. Anyway.
    $warn_sv = substr($warn_sv,1) if substr($warn_sv,0,3) eq '&sv';
    $warn_sv = "($warnsvcast)&".$warn_sv;
    $free->add( sprintf( "    cop_list[%d].cop_warnings = NULL;", $ix ) );
    #push @B::C::static_free, sprintf("cop_list[%d]", $ix);
  }

  # Trim the .pl extension, to print the executable name only.
  my $file = $op->file;
  # $file =~ s/\.pl$/.c/;
  if ($PERL512) {
    if ($ITHREADS and $] >= 5.017) {
      $copsect->comment(
	      "$opsect_common, line, stashoff, file, hints, seq, warnings, hints_hash");
      $copsect->add(
	sprintf(
		"%s, %u, " . "%d, %s, %u, " . "%s, %s, NULL",
		$op->_save_common, $op->line,
		$op->stashoff, "(char*)".constpv( $file ), #hints=0
                $op->hints,
		ivx($op->cop_seq), $B::C::optimize_warn_sv ? $warn_sv : 'NULL'
	       ));
    } elsif ($ITHREADS and $] >= 5.016) {
      # [perl #113034] [PATCH] 2d8d7b1 replace B::COP::stashflags by B::COP::stashlen (5.16.0 only)
      $copsect->comment(
	      "$opsect_common, line, stashpv, file, stashlen, hints, seq, warnings, hints_hash");
      $copsect->add(
	sprintf(
		"%s, %u, " . "%s, %s, %d, %u, " . "%s, %s, NULL",
		$op->_save_common, $op->line,
		"(char*)".constpv( $op->stashpv ), # we can store this static
		"(char*)".constpv( $file ),
		# XXX at broken 5.16.0 with B-1.34 we do non-utf8, non-null only (=> negative len),
		# 5.16.0 B-1.35 has stashlen, 5.16.1 we will see.
		$op->can('stashlen') ? $op->stashlen : length($op->stashpv),
                $op->hints,
		ivx($op->cop_seq), $B::C::optimize_warn_sv ? $warn_sv : 'NULL'
	       ));
    } elsif ($ITHREADS and $] >= 5.015004 and $] < 5.016) {
      $copsect->comment(
	      "$opsect_common, line, stashpv, file, stashflags, hints, seq, warnings, hints_hash");
      $copsect->add(
	sprintf(
                "%s, %u, " . "%s, %s, %d, %u, " . "%s, %s, NULL",
                $op->_save_common, $op->line,
                "(char*)".constpv( $op->stashpv ), # we can store this static
                "(char*)".constpv( $file ),
                $op->stashflags, $op->hints,
                ivx($op->cop_seq),
                $B::C::optimize_warn_sv ? $warn_sv : 'NULL'
	       ));
    } else {
      # cop_label now in hints_hash (Change #33656)
      $copsect->comment(
	      "$opsect_common, line, stash, file, hints, seq, warn_sv, hints_hash");
      $copsect->add(
	sprintf(
              "%s, %u, " . "%s, %s, %u, " . "%s, %s, NULL",
              $op->_save_common, $op->line,
	      $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "Nullhv",# we can store this static
	      $ITHREADS ? "(char*)".constpv( $file ) : "Nullgv",
              $op->hints, ivx($op->cop_seq),
              ( $B::C::optimize_warn_sv ? $warn_sv : 'NULL' )
	       ));
    }
    if ( $op->label ) {
      # test 29 and 15,16,21. 44,45
      if ($] >= 5.015001) { # officially added with 5.15.1 aebc0cbee
	$init->add(
	  sprintf("Perl_cop_store_label(aTHX_ &cop_list[%d], %s, %d, %d);",
		  $copsect->index, cstring( $op->label ),
		  length $op->label, 0));
      } elsif ($] > 5.013004) {
	$init->add(
	  sprintf("Perl_store_cop_label(aTHX_ &cop_list[%d], %s, %d, %d);",
		  $copsect->index, cstring( $op->label ),
		  length $op->label, 0));
      } elsif (!($^O =~ /^(MSWin32|AIX)$/ or $ENV{PERL_DL_NONLAZY})) {
        $init->add(
	  sprintf("cop_list[%d].cop_hints_hash = Perl_store_cop_label(aTHX_ NULL, %s);",
		  $copsect->index, cstring( $op->label )));
      }
    }
  }
  elsif ($PERL510) {
    $copsect->comment("$opsect_common, line, label, stash, file, hints, seq, warnings, hints_hash");
    $copsect->add(sprintf("%s, %u, %s, " . "%s, %s, %u, " . "%u, %s, NULL",
			  $op->_save_common,     $op->line, 'NULL',
			  $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "NULL", # we can store this static
			  $ITHREADS ? "(char*)".constpv( $file ) : "NULL",
                          $op->hints, $op->cop_seq,
			  ( $B::C::optimize_warn_sv ? $warn_sv : 'NULL' )));
    if ($op->label) {
      $init->add(sprintf( "CopLABEL_set(&cop_list[%d], CopLABEL_alloc(%s));",
			  $copsect->index, cstring( $op->label ) ));
    }
  }
  else {
    # 5.8 misses cop_io
    $copsect->comment("$opsect_common, label, stash, file, seq, arybase, line, warn_sv, io");
    $copsect->add(
      sprintf(
	      "%s, %s, %s, %s, %s, %d, %u, %s %s",
	      $op->_save_common, cstring( $op->label ),
	      $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "NULL", # we can store this static
	      $ITHREADS ? "(char*)".constpv( $file ) : "NULL",
	      ivx($op->cop_seq), $op->arybase,
	      $op->line, ( $B::C::optimize_warn_sv ? $warn_sv : 'NULL' ),
	      ( $PERL56 ? "" : ", 0" )
	     )
    );
  }
  $copsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $copsect->index;
  $init->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  $init->add( sprintf( "cop_list[$ix].cop_warnings = %s;", $warn_sv ) )
    unless $B::C::optimize_warn_sv;

  push @B::C::static_free, "cop_list[$ix]" if $ITHREADS;
  if (!$ITHREADS) {
    $init->add(
      sprintf( "CopFILE_set(&cop_list[$ix], %s);", constpv( $file ) )
    ) if !$B::C::optimize_cop;
    my $stpv = constpv( $op->stashpv );
    my $stlen = "";
    if ($] >= 5.016 and $] <= 5.017) {
      $stlen = ", ".length($op->stashpv);
    }
    $init->add(sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", $stpv));
  }

  # our root: store all packages from this file
  if (!$mainfile) {
    $mainfile = $op->file if $op->stashpv eq 'main';
  } else {
    mark_package($op->stashpv) if $mainfile eq $op->file and $op->stashpv ne 'main';
  }
  savesym( $op, "(OP*)&cop_list[$ix]" );
}

sub B::PMOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  # 5.8.5-thr crashes here (7) at pushre
  if ($] < 5.008008 and $ITHREADS and $$op < 256) { # B bug. split->first->pmreplroot = 0x1
    die "Internal B::walkoptree error: invalid PMOP for pushre\n";
    return;
  }
  my $replroot  = $op->pmreplroot;
  my $replstart = $op->pmreplstart;
  my $replrootfield;
  my $replstartfield = sprintf( "s\\_%x", $$replstart );
  my $gvsym;
  my $ppaddr = $op->ppaddr;

  # under ithreads, OP_PUSHRE.op_replroot is an integer. multi not.
  $replrootfield = sprintf( "s\\_%x", $$replroot ) if ref $replroot;
  if ( $ITHREADS && $op->name eq "pushre" ) {
    warn "PMOP::save saving a pp_pushre as int ${replroot}\n" if $debug{gv};
    $replrootfield = "INT2PTR(OP*,${replroot})";
  }
  elsif ($$replroot) {
    # OP_PUSHRE (a mutated version of OP_MATCH for the regexp
    # argument to a split) stores a GV in op_pmreplroot instead
    # of a substitution syntax tree. We don't want to walk that...
    if ( $op->name eq "pushre" ) {
      warn "PMOP::save saving a pp_pushre with GV $gvsym\n" if $debug{gv};
      $gvsym = $replroot->save;
      $replrootfield = 0;
    }
    else {
      $replstartfield = saveoptree( "*ignore*", $replroot, $replstart );
    }
  }

  # pmnext handling is broken in perl itself, we think. Bad op_pmnext
  # fields aren't noticed in perl's runtime (unless you try reset) but we
  # segfault when trying to dereference it to find op->op_pmnext->op_type
  if ($PERL510) {
    $pmopsect->comment(
      "$opsect_common, first, last, pmoffset, pmflags, pmreplroot, pmreplstart"
    );
    $pmopsect->add(
      sprintf(
        "%s, s\\_%x, s\\_%x, %u, 0x%x, {%s}, {%s}",
        $op->_save_common, ${ $op->first },
        ${ $op->last }, ( $ITHREADS ? $op->pmoffset : 0 ),
        $op->pmflags, $replrootfield, 'NULL'
      )
    );
    $init->add(sprintf("pmop_list[%d].op_pmstashstartu.op_pmreplstart = (OP*)$replstartfield;",
                       $pmopsect->index));
  }
  elsif ($PERL56) {
    # pmdynflags does not exist as B method. It is only used for PMdf_UTF8 dynamically,
    # if static we set this already in pmflags.
    $pmopsect->comment(
"$opsect_common, first, last, pmreplroot, pmreplstart, pmnext, pmregexp, pmflags, pmpermflags, pmdynflags"
    );
    $pmopsect->add(
      sprintf(
        "%s, s\\_%x, s\\_%x, %s, %s, 0, 0, 0x%x, 0x%x",
        $op->_save_common,
	${ $op->first }, ${ $op->last },
	$replrootfield,  $replstartfield,
	$op->pmflags, $op->pmpermflags, 0 # XXX original 5.6 B::C misses pmdynflags
      )
    );
  } else { # perl5.8.x
    $pmopsect->comment(
"$opsect_common, first, last, pmreplroot, pmreplstart, pmoffset, pmflags, pmpermflags, pmdynflags, pmstash"
    );
    $pmopsect->add(
      sprintf(
        "%s, s\\_%x, s\\_%x, %s, %s, 0, %u, 0x%x, 0x%x, 0x%x, %s",
        $op->_save_common, ${ $op->first },
        ${ $op->last },    $replrootfield,
        $replstartfield,   $ITHREADS ? $op->pmoffset : 0,
        $op->pmflags,      $op->pmpermflags,
        $op->pmdynflags,   $MULTI ? cstring($op->pmstashpv) : "0"
      )
    );
    if (!$MULTI and $op->pmstash) {
      my $stash = $op->pmstash->save;
      $init->add( sprintf( "pmop_list[%d].op_pmstash = %s;", $pmopsect->index, $stash ) );
    }
  }
  $pmopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $pm = sprintf( "pmop_list[%d]", $pmopsect->index );
  $init->add( sprintf( "$pm.op_ppaddr = %s;", $ppaddr ) )
    unless $B::C::optimize_ppaddr;
  my $re;
  if ($] >= 5.010 and $] < 5.011 and $ITHREADS) { # XXX lots of module fails with 5.10.1d
    if (ref($op) eq 'B::PMOP') {
      eval { $re = $op->precomp; } #out of memory: Module::Pluggable, Carp::Clan - threaded
    }
  } else {
    $re = $op->precomp;
  }
  if ( defined($re) ) {
    $Regexp{$$op} = $op;
    if ($PERL510) {
      # TODO minor optim: fix savere( $re ) to avoid newSVpvn;
      my $resym = cstring($re);
      my $relen = length($re);
      my $pmflags = $op->pmflags;
      # Since 5.13.10 with PMf_FOLD (i) we need to swash_init("utf8::Cased").
      if ($] >= 5.013009 and $pmflags & 4) {
        # Note: in CORE utf8::SWASHNEW is demand-loaded from utf8 with Perl_load_module()
        require "utf8_heavy.pl" unless $INC{"utf8_heavy.pl"}; # bypass AUTOLOAD
        svref_2object( \&{"utf8\::SWASHNEW"} )->save; # for swash_init(), defined in lib/utf8_heavy.pl
      }
      $init->add( # XXX Modification of a read-only value attempted. use DateTime - threaded
        "PM_SETRE(&$pm, CALLREGCOMP(newSVpvn($resym, $relen), ".sprintf("0x%x));", $pmflags),
        sprintf("RX_EXTFLAGS(PM_GETRE(&$pm)) = 0x%x;", $op->reflags )
      );
      # See toke.c:8964
      # set in the stash the PERL_MAGIC_symtab PTR to the PMOP: ((PMOP**)mg->mg_ptr) [elements++] = pm;
      if ($PERL510 and $op->pmflags & PMf_ONCE()) {
        my $stash = $MULTI ? $op->pmstashpv
          : ref $op->pmstash eq 'B::HV' ? $op->pmstash->NAME : '__ANON__';
        $Regexp{$$op} = $op; #188: restore PMf_ONCE, set PERL_MAGIC_symtab in $stash
      }
    }
    elsif ($PERL56) {
      my ( $resym, $relen ) = savere( $re, 0 );
      $init->add(
        "$pm.op_pmregexp = pregcomp((char*)$resym, (char*)$resym + $relen, &$pm);"
      );
    }
    else { # 5.8
      my ( $resym, $relen ) = savere( $re, 0 );
      $init->add(
          "PM_SETRE(&$pm, CALLREGCOMP(aTHX_ (char*)$resym, (char*)$resym + $relen, &$pm));"
      );
    }
  }
  if ( $gvsym ) {
    if ($PERL510) {
      # XXX need that for subst
      $init->add("$pm.op_pmreplrootu.op_pmreplroot = (OP*)$gvsym;");
    } else {
      $init->add("$pm.op_pmreplroot = (OP*)$gvsym;");
    }
  }
  savesym( $op, "(OP*)&$pm" );
}

sub B::SPECIAL::save {
  my ($sv, $fullname) = @_;
  # special case: $$sv is not the address but an index into specialsv_list
  #   warn "SPECIAL::save specialsv $$sv\n"; # debug
  @specialsv_name = qw(Nullsv &PL_sv_undef &PL_sv_yes &PL_sv_no pWARN_ALL pWARN_NONE)
    unless @specialsv_name; # 5.6.2 Exporter quirks. pWARN_STD was added to B with 5.8.9
  my $sym = $specialsv_name[$$sv];
  if ( !defined($sym) ) {
    warn "unknown specialsv index $$sv passed to B::SPECIAL::save";
  }
  return $sym;
}

sub B::OBJECT::save { }

sub B::NULL::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;

  # debug
  if ( $$sv == 0 ) {
    warn "NULL::save for sv = 0 called from @{[(caller(1))[3]]}\n" if $verbose;
    return savesym( $sv, "(void*)Nullsv /* XXX */" );
  }

  my $i = $svsect->index + 1;
  warn "Saving SVt_NULL sv_list[$i]\n" if $debug{sv};
  $svsect->add( sprintf( "0, %lu, 0x%x".
                         ($PERL510?", {0}":''),
                         $sv->REFCNT, $sv->FLAGS ) );
  #$svsect->debug( $fullname, $sv->flagspv ) if $debug{flags}; # XXX where is this possible?
  if ($debug{flags} and (!$ITHREADS or $]>=5.014) and $DEBUG_LEAKING_SCALARS) { # add index to sv_debug_file to easily find the Nullsv
    # $svsect->debug( "ix added to sv_debug_file" );
    $init->add(sprintf(qq(sv_list[%d].sv_debug_file = savepv("NULL sv_list[%d] 0x%x");),
		       $svsect->index, $svsect->index, $sv->FLAGS));
  }
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::UV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $uvuformat = $Config{uvuformat};
  $uvuformat =~ s/"//g; #" poor editor
  if ($PERL514) {
    # issue 145 warn $sv->UVX, " ", sprintf("%Lu", $sv->UVX);
    $xpvuvsect->add( sprintf( "Nullhv, {0}, 0, 0, {%".$uvuformat."U}", $sv->UVX ) );
  } elsif ($PERL510) {
    $xpvuvsect->add( sprintf( "{0}, 0, 0, {%".$uvuformat."U}", $sv->UVX ) );
  } else {
    $xpvuvsect->add( sprintf( "0, 0, 0, %".$uvuformat."U", $sv->UVX ) );
  }
  $svsect->add(
    sprintf(
      "&xpvuv_list[%d], %lu, 0x%x".($PERL510?', {'.($C99?".svu_pv=":"").'NULL}':''),
      $xpvuvsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  warn sprintf( "Saving IV(UV) 0x%x to xpvuv_list[%d], sv_list[%d], called from %s:%s\n",
    $sv->UVX, $xpvuvsect->index, $svsect->index, @{[(caller(1))[3]]}, @{[(caller(0))[2]]} )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::IV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  # Since 5.11 the RV is no special SV object anymore, just a IV (test 16)
  my $svflags = $sv->FLAGS;
  if ($PERL512 and $svflags & SVf_ROK) {
    return $sv->B::RV::save($fullname);
  }
  if ($svflags & SVf_IVisUV) {
    return $sv->B::UV::save;
  }
  my $i = $svsect->index + 1;
  if ($svflags & 0xff and !($svflags & (SVf_IOK|SVp_IOK))) { # Not nullified
    unless (($PERL510 and $svflags & 0x00010000) # PADSTALE - out of scope lexical is !IOK
	    or (!$PERL510 and $svflags & 0x00000100) # PADBUSY
	    or ($] > 5.015002 and $svflags & 0x60002)) { # 5.15.3 changed PAD bits
      warn sprintf("Internal warning: IV !IOK $fullname sv_list[$i] 0x%x\n",$svflags);
    }
  }
  if ($PERL514) {
    $xpvivsect->add( sprintf( "Nullhv, {0}, 0, 0, {%s}", ivx($sv->IVX) ) );
  } elsif ($PERL510) {
    $xpvivsect->add( sprintf( "{0}, 0, 0, {%s}", ivx($sv->IVX) ) );
  } else {
    $xpvivsect->add( sprintf( "0, 0, 0, %s", ivx($sv->IVX) ) );
  }
  $svsect->add(
    sprintf(
      "&xpviv_list[%d], %lu, 0x%x".($PERL510?', {'.($C99?".svu_pv=":"").'NULL}':''),
      $xpvivsect->index, $sv->REFCNT, $svflags
    )
  );
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  warn sprintf( "Saving IV 0x%x to xpviv_list[%d], sv_list[%d], called from %s:%s\n",
    $sv->IVX, $xpvivsect->index, $svsect->index, @{[(caller(1))[3]]}, @{[(caller(0))[2]]} )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::NV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $nv = nvx($sv->NV);
  $nv .= '.00' if $nv =~ /^-?\d+$/;
  # IVX is invalid in B.xs and unused
  my $iv = $sv->FLAGS & SVf_IOK ? $sv->IVX : 0;
  if ($PERL514) {
    $xpvnvsect->comment('STASH, MAGIC, cur, len, IVX, NVX');
    $xpvnvsect->add( sprintf( "Nullhv, {0}, 0, 0, {%ld}, {%s}", $iv, $nv ) );
  } elsif ($PERL510) { # not fixed by NV isa IV >= 5.8
    $xpvnvsect->comment('NVX, cur, len, IVX');
    $xpvnvsect->add( sprintf( "{%s}, 0, 0, {%ld}", $nv, $iv ) );
  }
  else {
    $xpvnvsect->comment('PVX, cur, len, IVX, NVX');
    $xpvnvsect->add( sprintf( "0, 0, 0, %ld, %s", $iv, $nv ) );
  }
  $svsect->add(
    sprintf(
      "&xpvnv_list[%d], %lu, 0x%x %s",
      $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS, $PERL510 ? ', {0}' : ''
    )
  );
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  warn sprintf( "Saving NV %s to xpvnv_list[%d], sv_list[%d]\n",
    $nv, $xpvnvsect->index, $svsect->index )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
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
        sprintf( "Copy(%s,$dest+$offset,%u,char);",
        cstring($str), length($str) );
      $offset += length $str;
    }
    push @init, sprintf( "%s[%u] = '\\0';", $dest, $offset );
    warn sprintf( "Copying overlong PV %s to %s\n", cstring($pv), $dest )
      if $debug{sv} or $debug{pv};
  }
  else {
    # If READONLY and FAKE use newSVpvn_share instead. (test 75)
    if ($PERL510 and $sv and (($sv->FLAGS & 0x09000000) == 0x09000000)) {
      warn sprintf( "Saving shared HEK %s to %s\n", cstring($pv), $dest ) if $debug{sv};
      my $hek = save_hek($pv);
      push @init, sprintf( "%s = HEK_KEY($hek);", $dest ) unless $hek eq 'NULL';
      if ($DEBUGGING) { # we have to bypass a wrong HE->HEK assert in hv.c
	push @B::C::static_free, $dest;
      }
    } else {
      my $cstr = cstring($pv);
      my $cur = $cur ? $cur
        : ($sv and ref($sv) and $sv->can('CUR') and ref($sv) ne 'B::GV')
          ? $sv->CUR : length(pack "a*", $pv);
      if ($sv and IsCOW($sv)) {
        $pv .= "\0\001";
        $cstr = cstring($pv);
        $cur += 2;
      }
      warn sprintf( "Saving PV %s:%d to %s\n", $cstr, $cur, $dest ) if $debug{sv};
      push @init, sprintf( "%s = savepvn(%s, %u);", $dest, $cstr, $cur );
    }
  }
  return @init;
}

sub B::PVLV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @B::C::static_free = grep {!/$sym/} @B::C::static_free;
    }
    return $sym;
  }
  my ($pvsym, $cur, $len, $pv, $static) = save_pv_or_rv ($sv, $fullname);
  my ( $lvtarg, $lvtarg_sym ); # XXX missing
  if ($PERL514) {
    $xpvlvsect->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %s, %u, %u, Nullsv, %s",
	       $cur, $len, nvx($sv->NVX),
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {(char*)%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS, $pvsym));
  } elsif ($PERL510) {
    $xpvlvsect->comment('xnv_u, CUR, LEN, GvNAME, MAGIC, STASH, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("%s, %u, %d, 0/*GvNAME later*/, 0, Nullhv, %u, %u, Nullsv, %s",
	       nvx($sv->NVX), $cur, $len,
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS,
                         ($C99?".svu_pv = (char*)":"(char*)").$pvsym));
  } else {
    $xpvlvsect->comment('PVX, CUR, LEN, IVX, NVX, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("(char*)%s, %u, %u, %s, %s, 0, 0, %u, %u, Nullsv, %s",
	       $pvsym, $cur, $len, ivx($sv->IVX), nvx($sv->NVX),
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( !$static ) {
    if ($PERL510) {
      $init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    }
    else {
      $init->add( savepvn( sprintf( "xpvlv_list[%d].xpv_pv", $xpvlvsect->index ), $pv, $cur ) );
    }
  }
  $sv->save_magic($fullname);
  savesym( $sv, "&".$s );
}

sub B::PVIV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @B::C::static_free = grep {!/$sym/} @B::C::static_free;
    }
    return $sym;
  }
  my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv($sv, $fullname);
  if ($PERL514) {
    $xpvivsect->comment('STASH, MAGIC, cur, len, IVX');
    $xpvivsect->add( sprintf( "Nullhv, {0}, %u, %u, {%s}", $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  } elsif ($PERL510) {
    $xpvivsect->comment('xnv_u, cur, len, IVX');
    $xpvivsect->add( sprintf( "{0}, %u, %u, {%s}", $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  } else {
    #$iv = 0 if $sv->FLAGS & (SVf_IOK|SVp_IOK);
    $xpvivsect->comment('PVX, cur, len, IVX');
    $xpvivsect->add( sprintf( "(char*)%s, %u, %u, %s",
			      $savesym, $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  }
  $svsect->add(
    sprintf("&xpviv_list[%d], %u, 0x%x %s",
            $xpvivsect->index, $sv->REFCNT, $sv->FLAGS,
	    $PERL510 ? ", {".($C99?".svu_pv=":"")."(char*)$savesym}" : '' ) );
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$static ) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
      } else {
	$init->add( savepvn( sprintf( "xpviv_list[%d].xpv_pv", $xpvivsect->index ), $pv, $cur ) );
      }
    }
  }
  savesym( $sv, "&".$s );
}

sub B::PVNV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @B::C::static_free = grep {!/$sym/} @B::C::static_free;
    }
    return $sym;
  }
  my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv($sv, $fullname);
  my $nvx;
  my $ivx = ivx($sv->IVX); # here must be IVX!
  if ($sv->FLAGS & (SVf_NOK|SVp_NOK)) {
    # it could be a double, or it could be 2 ints - union xpad_cop_seq
    $nvx = nvx($sv->NV);
  } else {
    if ($PERL510 and $C99) {
      $nvx = sprintf(".xpad_cop_seq.xlow = %s, .xpad_cop_seq.xhigh = %s",
                     ivx($sv->COP_SEQ_RANGE_LOW), ivx($sv->COP_SEQ_RANGE_HIGH),
		    );
    } else {
      $nvx = nvx($sv->NVX);
    }
  }
  if ($PERL510) {
    # For some time the stringification works of NVX double to two ints worked ok.
    if ($PERL514) {
      $xpvnvsect->comment('STASH, MAGIC, cur, len, IVX, NVX');
      $xpvnvsect->add(sprintf( "Nullhv, {0}, %u, %u, {%s}, {%s}", $cur, $len, $ivx, $nvx) );
    } else {
      $xpvnvsect->comment('NVX, cur, len, IVX');
      $xpvnvsect->add(sprintf( "{%s}, %u, %u, {%s}", $nvx, $cur, $len, $ivx ) );
    }
    unless ($C99 or $sv->FLAGS & (SVf_NOK|SVp_NOK)) {
      warn "NV => run-time union xpad_cop_seq init\n" if $debug{sv};
      $init->add(sprintf("xpvnv_list[%d].xnv_u.xpad_cop_seq.xlow = %s;",
                         $xpvnvsect->index, ivx($sv->COP_SEQ_RANGE_LOW)),
                 # pad.c: PAD_MAX = I32_MAX (4294967295)
                 # U suffix <= "warning: this decimal constant is unsigned only in ISO C90"
                 sprintf("xpvnv_list[%d].xnv_u.xpad_cop_seq.xhigh = %s;",
                         $xpvnvsect->index, ivx($sv->COP_SEQ_RANGE_HIGH)));
    }
  }
  else {
    $xpvnvsect->comment('PVX, cur, len, IVX, NVX');
    $xpvnvsect->add(sprintf( "(char*)%s, %u, %u, %s, %s", $savesym, $cur, $len, $ivx, $nvx ) );
  }
  $svsect->add(
    sprintf("&xpvnv_list[%d], %lu, 0x%x %s",
            $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS,
            $PERL510 ? ", {".($C99?".svu_pv=":"")."(char*)$savesym}" : '' ) );
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$static ) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
      }
      else {
        $init->add( savepvn( sprintf( "xpvnv_list[%d].xpv_pv", $xpvnvsect->index ), $pv, $cur ) );
      }
    }
  }
  savesym( $sv, "&".$s );
}

sub B::BM::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if !$PERL510 and defined $sym;
  $sv = bless $sv, "B::BM" if $PERL510;
  my $pv  = pack "a*", ( $sv->PV . "\0" . $sv->TABLE );
  my $cur = $sv->CUR;
  my $len = $cur + length($sv->TABLE) + 1;
  my $s;
  if ($PERL510) {
    warn "Saving FBM for GV $sym\n" if $debug{gv};
    $init->add( sprintf( "$sym = (GV*)newSV_type(SVt_PVGV);" ),
		sprintf( "SvFLAGS($sym) = 0x%x;", $sv->FLAGS),
		sprintf( "SvREFCNT($sym) = %u;", $sv->REFCNT + 1 ),
		sprintf( "SvPVX($sym) = %s;", cstring($pv) ),
		sprintf( "SvCUR_set($sym, %d);", $cur ),
		sprintf( "SvLEN_set($sym, %d);", $len ),
                sprintf( "BmRARE($sym) = %d;", $sv->RARE ),
                sprintf( "BmPREVIOUS($sym) = %d;", $sv->PREVIOUS ),
                sprintf( "BmUSEFUL($sym) = %d;", $sv->USEFUL )
              );
  } else {
    my $static;
    $xpvbmsect->comment('pvx,cur,len(+258),IVX,NVX,MAGIC,STASH,USEFUL,PREVIOUS,RARE');
    $xpvbmsect->add(
       sprintf("%s, %u, %u, %s, %s, 0, 0, %d, %u, 0x%x",
	       defined($pv) && $static ? cstring($pv) : "NULL",
	       $cur, $len, ivx($sv->IVX), nvx($sv->NVX),
	       $sv->USEFUL, $sv->PREVIOUS, $sv->RARE
	      ));
    $svsect->add(sprintf("&xpvbm_list[%d], %lu, 0x%x",
                         $xpvbmsect->index, $sv->REFCNT, $sv->FLAGS));
    $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
    $s = "sv_list[".$svsect->index."]";
    if (!$static) {
      $init->add(savepvn( sprintf( "xpvbm_list[%d].xpv_pv", $xpvbmsect->index ), $pv, 0, $len ) );
    } else {
      push @B::C::static_free, $s if defined($pv) and !$in_endav;
    }
  }
  # Restore possible additional magic. fbm_compile adds just 'B'.
  $sv->save_magic($fullname);

  if ($PERL510) {
    return $sym;
  } else {
    if ($] == 5.008009) { # XXX 5.8.9 needs more. TODO test 5.8.0 - 5.8.7
      $init->add( sprintf( "fbm_compile(&sv_list[%d], 0);", $svsect->index ) );
    }
    # cur+len was broken on all B::C versions
    #$init->add(sprintf( "xpvbm_list[%d].xpv_cur = %u;", $xpvbmsect->index, $len ) );
    return savesym( $sv, "&".$s );
  }
}

sub B::PV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @B::C::static_free = grep {!/$sym/} @B::C::static_free;
    }
    return $sym;
  }
  my $flags = $sv->FLAGS;
  my $shared_hek = $PERL510 ? (($flags & 0x09000000) == 0x09000000) : undef;
  $shared_hek = $shared_hek ? 1 : IsCOW_hek($sv);
  my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv($sv, $fullname);
  $static = 0 if !($flags & SVf_ROK) and $sv->PV and $sv->PV =~ /::bootstrap$/;
  my $refcnt = $sv->REFCNT;
  # static pv, do not destruct. test 13 with pv0 "3".
  if ($PERL510) {
    if ($B::C::const_strings and !$shared_hek and $flags & SVf_READONLY and !$len) {
      $flags &= ~0x01000000;
      warn sprintf("constpv turn off SVf_FAKE %s %s %s\n", $sym, cstring($pv), $fullname)
        if $debug{pv};
    }
    $xpvsect->add( sprintf( "%s{0}, %u, %u", $PERL514 ? "Nullhv, " : "", $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], %lu, 0x%x, {%s}",
                           $xpvsect->index, $refcnt, $flags,
			   $savesym eq 'NULL' ? '0' :
                             ($C99?".svu_pv=(char*)":"(char*)").$savesym ));
    if ( defined($pv) and !$static ) {
      if ($shared_hek) {
        my $hek = save_hek($pv);
        $init->add( sprintf( "sv_list[%d].sv_u.svu_pv = HEK_KEY(%s);", $svsect->index, $hek ))
                    unless $hek eq 'NULL';
      } else {
        $init->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv, $sv, $cur ) );
      }
    }
    if ($debug{flags} and (!$ITHREADS or $]>=5.014) and $DEBUG_LEAKING_SCALARS) { # add sv_debug_file
      $init->add(sprintf(qq(sv_list[%d].sv_debug_file = %s" sv_list[%d] 0x%x";),
			 $svsect->index, cstring($pv) eq '0' ? '"NULL"' : cstring($pv),
			 $svsect->index, $sv->FLAGS));
    }
  }
  else {
    $xpvsect->add( sprintf( "%s, %u, %u", "(char*)$savesym", $cur, $len ) );
    $svsect->add(sprintf("&xpv_list[%d], %lu, 0x%x",
			 $xpvsect->index, $refcnt, $flags));
    if ( defined($pv) and !$static ) {
      $init->add( savepvn( sprintf( "xpv_list[%d].xpv_pv", $xpvsect->index ), $pv, 0, $cur ) );
    }
  }
  my $s = "sv_list[".$svsect->index."]";
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  savesym( $sv, "&".$s );
}

sub lexwarnsym {
  my $pv = shift;
  if ($lexwarnsym{$pv}) {
    return $lexwarnsym{$pv};
  } else {
    my $sym = sprintf( "lexwarn%d", $pv_index++ );
    if ($] < 5.009) {
      $decl->add( sprintf( "Static const STRLEN %s = %d;", $sym, $pv ));
    }
    else {
      # if 8 use UVSIZE, if 4 use LONGSIZE
      my $t = ($Config{longsize} == 8) ? "J" : "L";
      my ($iv) = unpack($t, $pv); # unsigned longsize
      if ($iv >= 0 and $iv <= 2) { # specialWARN: single STRLEN
        $decl->add( sprintf( "Static const STRLEN %s = %d;", $sym, $iv ));
      } else { # sizeof(STRLEN) + (WARNsize)
        my $packedpv = pack("$t a*",length($pv), $pv);
        $decl->add( sprintf( "Static char %s[] = %s;", $sym, cstring($packedpv) ));
      }
    }
    $lexwarnsym{$pv} = $sym;
    return $sym;
  }
}

# pre vs. post 5.8.9/5.9.4 logic for lexical warnings
@B::LEXWARN::ISA = qw(B::PV B::IV);
sub B::LEXWARN::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $pv = $] >= 5.008009 ? $sv->PV : $sv->IV;
  my $ivsym = lexwarnsym($pv); # look for shared const int's
  return savesym($sv, $ivsym);
}

# post 5.11: When called from save_rv not from PMOP::save precomp
sub B::REGEXP::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $pv = $sv->PV;
  my $cur = $sv->CUR;
  # construct original PV
  $pv =~ s/^(\(\?\^[adluimsx-]*\:)(.*)\)$/$2/;
  $cur -= length($sv->PV) - length($pv);
  my $cstr = cstring($pv);
  # Unfortunately this XPV is needed temp. Later replaced by struct regexp.
  $xpvsect->add( sprintf( "%s{0}, %u, %u", $PERL514 ? "Nullhv, " : "", $cur, 0 ) );
  $svsect->add(sprintf("&xpv_list[%d], %lu, 0x%x, {%s}",
		       $xpvsect->index, $sv->REFCNT, $sv->FLAGS, $] > 5.017006 ? "NULL" : $cstr));
  my $ix = $svsect->index;
  warn "Saving RX $cstr to sv_list[$ix]\n" if $debug{rx} or $debug{sv};
  if ($] > 5.011) {
    $init->add(# replace sv_any->XPV with struct regexp. need pv and extflags
               sprintf("SvANY(&sv_list[$ix]) = SvANY(CALLREGCOMP(newSVpvn(%s, %d), 0x%x));",
                       $cstr, $cur, $sv->EXTFLAGS));
  }
  if ($] < 5.017006) {
    # since 5.17.6 the SvLEN stores RX_WRAPPED(rx)
    $init->add(sprintf("SvCUR(&sv_list[$ix]) = %d;", $cur),
               "SvLEN(&sv_list[$ix]) = 0;");
  } else {
    $init->add("sv_list[$ix].sv_u.svu_rx = (struct regexp*)sv_list[$ix].sv_any;");
  }
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  $sym = savesym( $sv, sprintf( "&sv_list[%d]", $ix ) );
  $sv->save_magic($fullname);
  return $sym;
}

sub B::PVMG::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @B::C::static_free = grep {!/$sym/} @B::C::static_free;
    }
    return $sym;
  }
  my ( $savesym, $cur, $len, $pv, $static ) = save_pv_or_rv($sv, $fullname);
  if ($] > 5.017 and $static) { # 242: e.g. $1
    $static = 0;
    $len = $cur+1 unless $len;
  }
  #warn sprintf( "PVMG %s (0x%x) $savesym, $len, $cur, $pv\n", $sym, $$sv ) if $debug{mg};

  if ($PERL510) {
    if ($sv->FLAGS & SVf_ROK) {  # sv => sv->RV cannot be initialized static.
      $init->add(sprintf("SvRV_set(&sv_list[%d], (SV*)%s);", $svsect->index+1, $savesym))
	if $savesym ne '';
      $savesym = 'NULL';
      $static = 1;
    }
    my ($ivx,$nvx) = (0, "0");
    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    if ($] >= 5.011 and ref($sv) eq 'B::REGEXP') {
      return B::REGEXP::save($sv, $fullname);
    }
    else {
      $ivx = ivx($sv->IVX); # XXX How to detect HEK* namehek?
      $nvx = nvx($sv->NVX); # it cannot be xnv_u.xgv_stash ptr (BTW set by GvSTASH later)
    }
    if ($PERL514) {
      $xpvmgsect->comment("STASH, MAGIC, cur, len, xiv_u, xnv_u");
      $xpvmgsect->add(sprintf("Nullhv, {0}, %u, %u, {%s}, {%s}",
			      $cur, $len, $ivx, $nvx));
    } else {
      $xpvmgsect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash");
      $xpvmgsect->add(sprintf("{%s}, %u, %u, {%s}, {0}, Nullhv",
			    $nvx, $cur, $len, $ivx));
    }
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x, {%s}",
                         $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS,
			 $savesym eq 'NULL' ? '0' :
                           ($C99?".svu_pv=(char*)":"(char*)").$savesym));
  }
  else {
    if ($savesym =~ /PL_sv_undef/ and $ITHREADS) {
      $savesym = 'NULL'; # Moose 5.8.9d
    }
    $xpvmgsect->add(sprintf("(char*)%s, %u, %u, %s, %s, 0, 0",
                            $savesym, $cur, $len, ivx($sv->IVX), nvx($sv->NVX)));
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x",
			 $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( !$static ) { # do not overwrite RV slot (#273)
    # XXX comppadnames need &PL_sv_undef instead of 0 (?? which testcase?)
    if ($PERL510) {
      $init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv, $cur ) );
    } else {
      $init->add( savepvn( sprintf( "xpvmg_list[%d].xpv_pv", $xpvmgsect->index ),
                          $pv, $sv, $cur ) );
    }
  }
  $sym = savesym( $sv, "&".$s );
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
  } else {
    warn "ignore to mark threads for 'P' magic\n" if $debug{mg};
  }
  if ( $INC{'threads/shared.pm'} ) {
    my $stash = 'threads::shared';
    mark_package($stash);
    # XXX why is this needed? threads::shared should be initialized automatically
    $use_xsloader = 1; # ensure threads::shared is initialized
    $xsub{$stash} = 'Dynamic-' . $INC{'threads/shared.pm'};
    warn "mark threads::shared for 'P' magic\n" if $debug{mg};
  } else {
    warn "ignore to mark threads::shared for 'P' magic\n" if $debug{mg};
  }
}

sub B::PVMG::save_magic {
  my ($sv, $fullname) = @_;
  my $sv_flags = $sv->FLAGS;
  if ($debug{mg}) {
    my $flagspv = "";
    $fullname = '' unless $fullname;
    $flagspv = $sv->flagspv if $debug{flags} and $PERL510 and !$sv->MAGICAL;
    warn sprintf( "saving magic for %s $fullname (0x%x) flags=0x%x%s  - called from %s:%s\n",
		class($sv), $$sv, $sv_flags, $debug{flags} ? "(".$flagspv.")" : "",
		@{[(caller(1))[3]]}, @{[(caller(1))[2]]});
  }

  # crashes on STASH=0x18 with HV PERL_MAGIC_overload_table stash %version:: flags=0x3280000c
  # issue267 GetOpt::Long SVf_AMAGIC|SVs_RMG|SVf_OOK
  # crashes with %Class::MOP::Instance:: flags=0x2280000c also
  if (ref($sv) eq 'B::HV' and $] > 5.018 and $sv->MAGICAL and $fullname =~ /::$/) {
    warn sprintf("skip SvSTASH for overloaded HV $fullname flags=0x%x\n", $sv->FLAGS)
      if $verbose;
  } else {
    my $pkg = $sv->SvSTASH;
    if ($$pkg) {
      warn sprintf("stash isa class(\"%s\") 0x%x\n", $pkg->NAME, $$pkg)
        if $debug{mg} or $debug{gv};

      $pkg->save($fullname);

      no strict 'refs';
      warn sprintf( "xmg_stash = \"%s\" (0x%x)\n", $pkg->NAME, $$pkg )
        if $debug{mg} or $debug{gv};
      # Q: Who is initializing our stash from XS? ->save is missing that.
      # A: We only need to init it when we need a CV
      $init->add( sprintf( "SvSTASH_set(s\\_%x, (HV*)s\\_%x);", $$sv, $$pkg ) );
      $init->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
      # XXX
      #push_package($pkg->NAME);  # correct code, but adds lots of new stashes
    }
  }
  # Protect our SVs against non-magic or SvPAD_OUR. Fixes tests 16 and 14 + 23
  if ($PERL510 and !$sv->MAGICAL) {
    warn sprintf("Skipping non-magical PVMG type=%d, flags=0x%x%s\n",
                 $sv_flags && 0xff, $sv_flags, $debug{flags} ? "(".$sv->flagspv.")" : "")
      if $debug{mg};
    return '';
  }
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

    unless ( $type =~ /^[rDn]$/ ) { # r - test 23 / D - Getopt::Long
      # 5.10: Can't call method "save" on unblessed reference
      #warn "Save MG ". $obj . "\n" if $PERL510;
      # 5.11 'P' fix in B::IV::save, IV => RV
      $obj = $mg->OBJ;
      $obj->save($fullname)
        unless $PERL510 and ref $obj eq 'SCALAR';
      mark_threads if $type eq 'P';
    }

    if ( $len == HEf_SVKEY ) {
      # The pointer is an SV* ('s' sigelem e.g.)
      # XXX On 5.6 ptr might be a SCALAR ref to the PV, which was fixed later
      if (ref($ptr) eq 'SCALAR') {
	$ptrsv = svref_2object($ptr)->save($fullname);
      } else {
	$ptrsv = $ptr->save($fullname);
      }
      warn "MG->PTR is an SV*\n" if $debug{mg};
      $init->add(
        sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, (char *)%s, %d);",
          $$sv, $$obj, cchar($type), $ptrsv, $len
        )
      );
    }
    # coverage $Template::Stash::PRIVATE
    elsif ( $type eq 'r' ) { # qr magic, for 5.6 done in C.xs. test 20
      my $rx   = $PERL56 ? ${$mg->OBJ} : $mg->REGEX;
      # stored by some PMOP *pm = cLOGOP->op_other (pp_ctl.c) in C.xs
      my $pmop = $Regexp{$rx};
      if (!$pmop) {
	warn "Warning: C.xs PMOP missing for QR\n";
      } else {
	my ($resym, $relen);
	if ($PERL56) {
	  ($resym, $relen) = savere( $pmop->precomp ); # 5.6 has precomp only in PMOP
	  ($resym, $relen) = savere( $mg->precomp ) unless $relen;
	} else {
	  ($resym, $relen) = savere( $mg->precomp );
	}
	my $pmsym = $pmop->save($fullname);
	if ($PERL510) {
          push @B::C::static_free, $resym;
	  $init->add( split /\n/,
		    sprintf <<CODE1, $pmop->pmflags, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = CALLREGCOMP((SV* const)$resym, %d);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE1
	}
	else {
	  $pmsym =~ s/\(OP\*\)\&pmop_list/&pmop_list/;
	  $init->add( split /\n/,
		      sprintf <<CODE2, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = pregcomp((char*)$resym,(char*)($resym + $relen), (PMOP*)$pmsym);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE2
        }
      }
    }
    elsif ( $type eq 'D' ) { # XXX regdata AV - coverage? i95, 903
      if ($sv_flags & SVf_READONLY) {
        $init->add(sprintf("SvREADONLY_off((SV*)s\\_%x);", $$sv));
      }
      # see Perl_mg_copy() in mg.c
      $init->add(sprintf("sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
                         $$sv, $$sv, "'D'", cstring($ptr), $len ));
      if ($sv_flags & SVf_READONLY) {
        $init->add(sprintf("SvREADONLY_on((SV*)s\\_%x);", $$sv));
      }
    }
    elsif ( $type eq 'n' ) { # shared_scalar is from XS dist/threads-shared
      # XXX check if threads is loaded also? otherwise it is only stubbed
      mark_threads;
      $init->add(sprintf("sv_magic((SV*)s\\_%x, Nullsv, %s, %s, %d);",
			   $$sv, "'n'", cstring($ptr), $len ));
    }
    elsif ( $type eq 'c' ) {
      $init->add(sprintf(
          "/* AMT overload table for the stash s\\_%x is generated dynamically */",
          $$sv ));
    }
    elsif ( $type eq ':' ) { # symtab magic
      # search $ptr in list of pmops and replace it. e.g. (char*)&pmop_list[0]
      my $pmop_ptr = unpack("J", $mg->PTR);
      my $pmop = $Regexp{$pmop_ptr};
      warn sprintf("pmop 0x%x not found in \%Regexp", $pmop_ptr) unless $pmop;
      my $pmsym = $pmop ? $pmop->save($fullname) : '&pmop_list[0]';
      $init->add("{\tU32 elements;", # toke.c: PL_multi_open == '?'
                 sprintf("\tMAGIC *mg = sv_magicext((SV*)s\\_%x, 0, ':', 0, 0, 0);", $$sv),
                 "\telements = mg->mg_len / sizeof(PMOP**);",
                 "\tRenewc(mg->mg_ptr, elements + 1, PMOP*, char);",
                 sprintf("\t((OP**)mg->mg_ptr) [elements++] = %s;", $pmsym),
                 "\tmg->mg_len = elements * sizeof(PMOP**);", "}");
    }
    else {
      $init->add(sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
          $$sv, $$obj, cchar($type), cstring($ptr), $len))
    }
  }
  $magic;
}

# Since 5.11 also called by IV::save (SV -> IV)
sub B::RV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  warn sprintf( "Saving RV %s (0x%x) - called from %s:%s\n",
		class($sv), $$sv, @{[(caller(1))[3]]}, @{[(caller(1))[2]]})
    if $debug{sv};
  my $rv = save_rv($sv, $fullname);
  return '0' unless $rv;
  if ($PERL510) {
    # 5.10 has no struct xrv anymore, just sv_u.svu_rv. static or dynamic?
    # initializer element is computable at load time
    $svsect->add( sprintf( "ptr_undef, %lu, 0x%x, {0}", $sv->REFCNT, $sv->FLAGS ) );
    $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
    my $s = "sv_list[".$svsect->index."]";
    $init->add( "$s.sv_u.svu_rv = (SV*)$rv;" );
    return savesym( $sv, "&".$s );
  }
  else {
    # GVs need to be handled at runtime
    if ( ref( $sv->RV ) eq 'B::GV' or $rv =~ /^gv_list/) {
      $xrvsect->add("(SV*)Nullsv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;", $xrvsect->index, $rv ) );
    }
    # and stashes, too
    elsif ( $sv->RV->isa('B::HV') && $sv->RV->NAME ) {
      $xrvsect->add("(SV*)Nullsv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;", $xrvsect->index, $rv ) );
    }
    # one more: bootstrapped XS CVs (test Class::MOP, no simple testcase yet)
    elsif ( $rv =~ /(\(char\*\))?get_cv\(/ ) {
      $xrvsect->add("(SV*)Nullsv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;", $xrvsect->index, $rv ) );
    }
    else {
      #$xrvsect->add($rv); # not static initializable (e.g. cv160 for ExtUtils::Install)
      $xrvsect->add("(SV*)Nullsv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;", $xrvsect->index, $rv ) );
    }
    $svsect->add(sprintf("&xrv_list[%d], %lu, 0x%x",
			 $xrvsect->index, $sv->REFCNT, $sv->FLAGS));
    $svsect->debug( $fullname, $sv->flagspv ) if $debug{flags};
    my $s = "sv_list[".$svsect->index."]";
    return savesym( $sv, "&".$s );
  }
}

sub get_isa ($) {
  no strict 'refs';
  return $PERL510 ? @{mro::get_linear_isa($_[0])} : @{ $_[0] . '::ISA' };
}

# try_isa($pkg,$name) returns the found $pkg for the method $pkg::$name
# If a method can be called (via UNIVERSAL::can) search the ISA's. No AUTOLOAD needed.
# XXX issue 64, empty @ISA if a package has no subs. in Bytecode ok
sub try_isa {
  my ( $cvstashname, $cvname ) = @_;
  return 0 unless defined $cvstashname;
  if (my $found = $isa_cache{"$cvstashname\::$cvname"}) {
    return $found;
  }
  no strict 'refs';
  # XXX theoretically a valid shortcut. In reality it fails when $cvstashname is not loaded.
  # return 0 unless $cvstashname->can($cvname);
  my @isa = get_isa($cvstashname);
  warn sprintf( "No definition for sub %s::%s. Try \@%s::ISA=(%s)\n",
		$cvstashname, $cvname, $cvstashname, join(",",@isa))
    if $debug{cv};
  for (@isa) { # global @ISA or in pad
    next if $_ eq $cvstashname;
    warn sprintf( "Try &%s::%s\n", $_, $cvname ) if $debug{cv};
    if (defined(&{$_ .'::'. $cvname})) {
      svref_2object( \@{$cvstashname . '::ISA'} )->save("$cvstashname\::ISA");
      $isa_cache{"$cvstashname\::$cvname"} = $_;
      mark_package($_, 1); # force
      return $_;
    } else {
      $isa_cache{"$_\::$cvname"} = 0;
      if (get_isa($_)) {
	my $parent = try_isa($_, $cvname);
	if ($parent) {
	  $isa_cache{"$_\::$cvname"} = $parent;
	  $isa_cache{"$cvstashname\::$cvname"} = $parent;
	  warn sprintf( "Found &%s::%s\n", $parent, $cvname ) if $debug{meth};
	  warn "save \@$parent\::ISA\n" if $debug{pkg};
	  svref_2object( \@{$parent . '::ISA'} )->save("$parent\::ISA");
	  warn "save \@$_\::ISA\n" if $debug{pkg};
	  svref_2object( \@{$_ . '::ISA'} )->save("$_\::ISA");
	  return $parent;
	}
      }
    }
  }
  return 0; # not found
}

# If the sub or method is not found:
# 1. try @ISA, mark_package and return.
# 2. try UNIVERSAL::method
# 3. try compile-time expansion of AUTOLOAD to get the goto &sub addresses
sub try_autoload {
  my ( $cvstashname, $cvname ) = @_;
  no strict 'refs';
  return 1 if try_isa($cvstashname, $cvname);

  no strict 'refs';
  if (defined(*{'UNIVERSAL::'. $cvname}{CODE})) {
    warn "Found UNIVERSAL::$cvname\n" if $debug{cv};
    return svref_2object( \&{'UNIVERSAL::'.$cvname} );
  }
  my $fullname = $cvstashname . '::' . $cvname;
  warn sprintf( "No definition for sub %s. Try %s::AUTOLOAD\n",
		$fullname, $cvstashname ) if $debug{cv};
  # First some exceptions, fooled by goto
  if ($cvstashname eq 'Config') {
    return svref_2object( \&{'Config::launcher'} );
  }
  if ($fullname eq 'utf8::SWASHNEW') {
    # utf8_heavy was loaded so far, so defer to a demand-loading stub
    my $stub = sub { require 'utf8_heavy.pl' unless $INC{"utf8_heavy.pl"}; goto &utf8::SWASHNEW; };
    return svref_2object( $stub );
  }

  # Handle AutoLoader classes. Any more general AUTOLOAD
  # use should be handled by the class itself.
  my @isa = $PERL510 ? @{mro::get_linear_isa($cvstashname)} : @{ $cvstashname . '::ISA' };
  if ( $cvstashname =~ /^POSIX|Storable|DynaLoader|Net::SSLeay|Class::MethodMaker$/
    or (exists ${$cvstashname.'::'}{AUTOLOAD} and grep( $_ eq "AutoLoader", @isa ) ) )
  {
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

  # XXX Still not found, now it's getting dangerous (until 5.10 only)
  # Search and call ::AUTOLOAD (=> ROOT and XSUB) (test 27, 5.8)
  # Since 5.10 AUTOLOAD xsubs are already resolved
  if (exists ${$cvstashname.'::'}{AUTOLOAD} and !$PERL510) {
    my $auto = \&{$cvstashname.'::AUTOLOAD'};
    # Tweaked version of __PACKAGE__::AUTOLOAD
    $AutoLoader::AUTOLOAD = ${$cvstashname.'::AUTOLOAD'} = "$cvstashname\::$cvname";

    # Prevent eval from polluting STDOUT,STDERR and our c code.
    # With a debugging perl STDERR is written
    local *REALSTDOUT;
    local *REALSTDERR unless $DEBUGGING;
    open(REALSTDOUT,">&STDOUT");
    open(REALSTDERR,">&STDERR") unless $DEBUGGING;
    open(STDOUT,">","/dev/null");
    open(STDERR,">","/dev/null") unless $DEBUGGING;
    warn "eval \&$cvstashname\::AUTOLOAD\n" if $debug{cv};
    eval { &$auto };
    open(STDOUT,">&REALSTDOUT");
    open(STDERR,">&REALSTDERR") unless $DEBUGGING;

    unless ($@) {
      # we need just the empty auto GV, $cvname->ROOT and $cvname->XSUB,
      # but not the whole CV optree. XXX This still fails with 5.8
      my $cv = svref_2object( \&{$cvstashname.'::'.$cvname} );
      return $cv;
    }
  }

  # XXX TODO Check Selfloader (test 31?)
  svref_2object( \*{$cvstashname.'::AUTOLOAD'} )->save
    if $cvstashname and exists ${"$cvstashname\::"}{AUTOLOAD};
  svref_2object( \*{$cvstashname.'::CLONE'} )->save
    if $cvstashname and exists ${$cvstashname.'::'}{CLONE};
}
sub Dummy_initxs { }

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
  if ($gv and $$gv) {
    $cvstashname = $gv->STASH->NAME;
    $cvname      = $gv->NAME;
    $fullname    = $cvstashname.'::'.$cvname;
    warn sprintf( "CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
                  $$cv, $$gv, $fullname, $CvFLAGS )
      if $debug{cv};
    # XXX not needed, we already loaded utf8_heavy
    #return if $fullname eq 'utf8::AUTOLOAD';
    return '0' if $all_bc_subs{$fullname} or $skip_package{$cvstashname};
    mark_package($cvstashname, 1) unless $include_package{$cvstashname};
  }
  elsif ((!$gv or ref($gv) eq 'B::SPECIAL') and $cv->can('NAME_HEK')) {
    $fullname = $cv->NAME_HEK;
    warn sprintf( "CV NAME_HEK $fullname\n") if $debug{cv};
    if ($fullname =~ /^(.*)::(.*?)$/) {
      $cvstashname = $1;
      $cvname      = $2;
    }
  }

  # XXX TODO need to save the gv stash::AUTOLOAD if exists
  my $root    = $cv->ROOT;
  my $cvxsub  = $cv->XSUB;
  my $isconst;
  { no strict 'subs';
    $isconst = $PERL56 ? 0 : $CvFLAGS & CVf_CONST;
  }

  if ( !$isconst && $cvxsub && ( $cvname ne "INIT" ) ) {
    my $egv       = $gv->EGV;
    my $stashname = $egv->STASH->NAME;
    $fullname = $stashname.'::'.$cvname;
    if ( $cvname eq "bootstrap" and !$xsub{$stashname} ) {
      my $file = $gv->FILE;
      $decl->add("/* bootstrap $file */");
      warn "Bootstrap $stashname $file\n" if $verbose;
      mark_package($stashname);

      # Without DynaLoader we must boot and link static
      if ( !$Config{usedl} ) {
        $xsub{$stashname} = 'Static';
      }
      # if it not isa('DynaLoader'), it should hopefully be XSLoaded
      # ( attributes being an exception, of course )
      elsif ( !UNIVERSAL::isa( $stashname, 'DynaLoader' )
              and ($stashname ne 'attributes' || $] >= 5.011))
      {
	my $stashfile = $stashname;
        $stashfile =~ s/::/\//g;
	if ($file =~ /XSLoader\.pm$/) { # almost always the case
	  $file = $INC{$stashfile . ".pm"};
	}
	unless ($file) { # do the reverse as DynaLoader: soname => pm
          my ($laststash) = $stashname =~ /::([^:]+)$/;
          $laststash = $stashname unless $laststash;
          my $sofile = "auto/" . $stashfile . '/' . $laststash . '\.' . $Config{dlext};
	  for (@DynaLoader::dl_shared_objects) {
	    if (m{^(.+/)$sofile$}) {
	      $file = $1. $stashfile.".pm"; last;
	    }
	  }
	}
	$xsub{$stashname} = 'Dynamic-'.$file;
        $use_xsloader = 1;
      }
      else {
        $xsub{$stashname} = 'Dynamic';
      }

      # INIT is removed from the symbol table, so this call must come
      # from PL_initav->save. Re-bootstrapping  will push INIT back in,
      # so nullop should be sent.
      warn $fullname."\n" if $debug{sub};
      return qq/NULL/;
    }
    else {
      # XSUBs for IO::File, IO::Handle, IO::Socket, IO::Seekable and IO::Poll
      # are defined in IO.xs, so let's bootstrap it
      my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
      if (grep { $stashname eq $_ } @IO) {
	# mark_package('IO', 1);
	# $xsub{IO} = 'Dynamic-'. $INC{'IO.pm'}; # XSLoader (issue59)
	svref_2object( \&IO::bootstrap )->save;
	mark_package('IO::Handle', 1);
	mark_package('SelectSaver', 1);
	#for (@IO) { # mark all IO packages
	#  mark_package($_, 1);
	#}
      }
    }
    warn $fullname."\n" if $debug{sub};
    unless ( in_static_core($stashname, $cvname) ) {
      no strict 'refs';
      warn sprintf( "XSUB $fullname CV 0x%x\n", $$cv )
    	if $debug{cv};
      svref_2object( \*{"$stashname\::bootstrap"} )->save
        if $stashname;# and defined ${"$stashname\::bootstrap"};
      # delsym($cv);
      return qq/get_cv("$fullname", 0)/;
    } else {  # Those cvs are already booted. Reuse their GP.
      # Esp. on windows it is impossible to get at the XS function ptr
      warn sprintf( "core XSUB $fullname CV 0x%x\n", $$cv ) if $debug{cv};
      return qq/get_cv("$fullname", 0)/;
    }
  }
  if ( $cvxsub && $cvname eq "INIT" ) {
    no strict 'refs';
    warn $fullname."\n" if $debug{sub};
    return svref_2object( \&Dummy_initxs )->save;
  }

  if ($isconst and !($CvFLAGS & CVf_ANON)) {
    my $stash = $gv->STASH;
    warn sprintf( "CV CONST 0x%x %s::%s\n", $$gv, $cvstashname, $cvname )
      if $debug{cv};
    # warn sprintf( "%s::%s\n", $cvstashname, $cvname) if $debug{sub};
    my $stsym = $stash->save;
    my $name  = cstring($cvname);
    my $vsym  = $cv->XSUBANY->save;
    my $cvi = "cv".$cv_index;
    $decl->add("Static CV* $cvi;");
    $init->add("$cvi = newCONSTSUB( $stsym, $name, (SV*)$vsym );");
    my $sym = savesym( $cv, $cvi );
    $cv_index++;
    return $sym;
  }

  # This define is forwarded to the real sv below
  # The new method, which saves a SV only works since 5.10 (? Does not work in newer perls)
  my $sv_ix = $svsect->index + 1;
  my $xpvcv_ix;
  my $new_cv_fw = 0;#$PERL510; # XXX this does not work yet
  if ($new_cv_fw) {
    $sym = savesym( $cv, "CVIX$sv_ix" );
  } else {
    $svsect->add("CVIX$sv_ix");
    $xpvcv_ix = $xpvcvsect->index + 1;
    $xpvcvsect->add("XPVCVIX$xpvcv_ix");
    # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
    $sym = savesym( $cv, "&sv_list[$sv_ix]" );
  }

  warn sprintf( "saving $fullname CV 0x%x as $sym\n", $$cv )
    if $debug{cv};
  if (!$$root and $] < 5.010) {
    $package_pv = $cvstashname;
    push_package($package_pv);
  }
  if ($fullname eq 'utf8::SWASHNEW') { # bypass utf8::AUTOLOAD, a new 5.13.9 mess
    require "utf8_heavy.pl" unless $INC{"utf8_heavy.pl"};
    # sub utf8::AUTOLOAD {}; # How to ignore &utf8::AUTOLOAD with Carp? The symbol table is
    # already polluted. See issue 61 and force_heavy()
    svref_2object( \&{"utf8\::SWASHNEW"} )->save;
  }
  if (!$$root && !$cvxsub and $cvstashname =~ /^(bytes|utf8)$/) { # no autoload, force compile-time
    force_heavy($cvstashname);
    $cv = svref_2object( \&{"$cvstashname\::$cvname"} );
    $gv = $cv->GV;
    warn sprintf( "Redefined CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
                  $$cv, $$gv, $fullname, $CvFLAGS ) if $debug{cv};
    $sym = savesym( $cv, $sym );
    $root    = $cv->ROOT;
    $cvxsub  = $cv->XSUB;
  }
  if ( !$$root && !$cvxsub ) {
    if ( my $auto = try_autoload( $cvstashname, $cvname ) ) {
      if (ref $auto eq 'B::CV') { # explicit goto or UNIVERSAL
        $root   = $auto->ROOT;
        $cvxsub = $auto->XSUB;
	if ($$auto) {
	  # XXX This has now created a wrong GV name!
	  my $oldcv = $cv;
	  $cv  = $auto ; # This is new. i.e. via AUTOLOAD or UNIVERSAL, in another stash
	  my $gvnew = $cv->GV;
	  if ($$gvnew) {
	    if ($cvstashname ne $gvnew->STASH->NAME or $cvname ne $gvnew->NAME) { # UNIVERSAL or AUTOLOAD
	      my $newname = $gvnew->STASH->NAME."::".$gvnew->NAME;
	      warn " New $newname autoloaded. remove old cv\n" if $debug{sub}; # and wrong GV?
	      unless ($new_cv_fw) {
		$svsect->remove;
		$xpvcvsect->remove;
	      }
	      delsym($oldcv);
	      return $cv->save($newname) if !$PERL510;

	      no strict 'refs';
	      my $newsym = svref_2object( \*{$newname} )->save;
	      my $cvsym = defined objsym($cv) ? objsym($cv) : $cv->save($newname);
	      if (my $oldsym = objsym($gv)) {
		warn "Alias polluted $oldsym to $newsym\n" if $debug{gv};
		$init->add("$oldsym = $newsym;");
		delsym($gv);
	      }# else {
		#$init->add("GvCV_set(gv_fetchpv(\"$fullname\", GV_ADD, SVt_PV), (CV*)NULL);");
	      #}
	      return $cvsym;
	    }
	  }
	  $sym = savesym( $cv, "&sv_list[$sv_ix]" ); # GOTO
	  warn "$fullname GOTO\n" if $verbose;
	}
      } else {
        # Recalculated root and xsub
        $root   = $cv->ROOT;
        $cvxsub = $cv->XSUB;
	my $gv = $cv->GV;
	if ($$gv) {
	  if ($cvstashname ne $gv->STASH->NAME or $cvname ne $gv->NAME) { # UNIVERSAL or AUTOLOAD
	    my $newname = $gv->STASH->NAME."::".$gv->NAME;
	    warn "Recalculated root and xsub $newname. remove old cv\n" if $verbose;
	    $svsect->remove;
	    $xpvcvsect->remove;
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
  if (!$$root) {
    if ($fullname ne 'threads::tid'
        and $fullname ne 'main::main::'
        and ($PERL510 and !defined(&{"$cvstashname\::AUTOLOAD"})))
    {
    }
    if (exists &$fullname) {
      warn "Warning: Empty &".$fullname."\n" if $debug{sub};
      $init->add( "/* empty CV $fullname */" ) if $verbose or $debug{sub};
    } else {
      warn "Warning: &".$fullname." not found\n" if $debug{sub};
      $init->add( "/* CV $fullname not found */" ) if $verbose or $debug{sub};
      # This block broke test 15, disabled
      if ($sv_ix == $svsect->index and !$new_cv_fw) { # can delete, is the last SV
        warn "No definition for sub $fullname (unable to autoload), skip CV[$sv_ix]\n"
          if $debug{cv};
        $svsect->remove;
        $xpvcvsect->remove;
        delsym( $cv );
        # Empty CV (methods) must be skipped not to disturb method resolution
        # (e.g. t/testm.sh POSIX)
        return '0';
      } else {
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
    warn sprintf( "saving op tree for CV 0x%x, root=0x%x\n",
                  $$cv, $$root )
      if $debug{cv} and $debug{gv};
    my $ppname = "";
    if ((!$gv or ref($gv) eq 'B::SPECIAL') and $cv->can('NAME_HEK')) {
      my $gvname    = $cv->NAME_HEK;
      $ppname = "pp_lexsub_";
      $fullname = "<lex>".$gvname;
    }
    elsif ($gv and $$gv) {
      my ($stashname, $gvname);
      $stashname = $gv->STASH->NAME;
      $gvname    = $gv->NAME;
      $fullname = $stashname.'::'.$gvname;
      $ppname = ( ${ $gv->FORM } == $$cv ) ? "pp_form_" : "pp_sub_";
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
    $startfield = objsym($root->next) unless $startfield; # 5.8 autoload has only root
    $startfield = "0" unless $startfield;
    if ($$padlist) {
      # XXX readonly comppad names and symbols invalid
      #local $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
      warn sprintf( "saving PADLIST 0x%x for CV 0x%x\n", $$padlist, $$cv )
        if $debug{cv} and $debug{gv};
      # XXX avlen 2
      $padlistsym = $padlist->save($fullname.' :pad');
      warn sprintf( "done saving %s 0x%x for CV 0x%x\n",
		    $padlistsym, $$padlist, $$cv )
        if $debug{cv} and $debug{gv};
      # do not record a forward for the pad only
      $init->add( "CvPADLIST($sym) = $padlistsym;" );
    }
    warn $fullname."\n" if $debug{sub};
  }
  elsif (!exists &$fullname) {
    warn $fullname." not found\n" if $debug{sub};
    warn "No definition for sub $fullname (unable to autoload)\n"
      if $debug{cv};
    $init->add( "/* $fullname not found */" ) if $verbose or $debug{sub};
    # XXX empty CV should not be saved. #159, #235
    # $svsect->remove( $sv_ix );
    # $xpvcvsect->remove( $xpvcv_ix );
    # delsym( $cv );
    if (!$new_cv_fw) {
      $symsect->add("XPVCVIX$xpvcv_ix\t0");
    }
    $CvFLAGS &= ~0x1000 if $PERL514; # CVf_DYNFILE
    $CvFLAGS &= ~0x400 if $gv and $$gv and $PERL514; #CVf_CVGV_RC
    $symsect->add(sprintf(
      "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x".($PERL510?", {0}":''),
      $sv_ix, $xpvcv_ix, $cv->REFCNT + ($PERL510 ? 1 : 0), $CvFLAGS));
    return qq/get_cv("$fullname", 0)/;
  }

  # Now it is time to record the CV
  if ($new_cv_fw) {
    $sv_ix = $svsect->index + 1;
    if (!$cvforward{$sym}) { # avoid duplicates
      $symsect->add
	(sprintf("$sym\t&sv_list[%d]", $sv_ix )); # forward the old CVIX to the new CV
      $cvforward{$sym}++;
    }
    $sym = savesym( $cv, "&sv_list[$sv_ix]" );
  }

  # $pv = '' unless defined $pv;    # Avoid use of undef warnings
  warn sprintf( "CV prototype %s for CV 0x%x\n", $pv, $$cv )
    if $debug{cv};
  my $proto = defined $pv ? cstring($pv) : 'NULL';
  my $pvsym = 'NULL';
  my $cur = defined $pv ? $cv->CUR : 0;
  my $len = $cur + 1;
  $len++ if IsCOW($cv);
  $len = 0 if $B::C::const_strings;
  # GV cannot be initialized statically
  my $xcv_outside = ${ $cv->OUTSIDE };
  if ($xcv_outside == ${ main_cv() } and !$MULTI) {
    # Provide a temp. debugging hack for CvOUTSIDE. The address of the symbol &PL_main_cv
    # is known to the linker, the address of the value PL_main_cv not. This is set later
    # (below) at run-time.
    $xcv_outside = '&PL_main_cv';
  } elsif (ref($cv->OUTSIDE) eq 'B::CV') {
    $xcv_outside = 0; # just a placeholder for a run-time GV
  }
  if ($PERL510) {
    $pvsym = save_hek($pv);
    # XXX issue 84: we need to check the cv->PV ptr not the value.
    # "" is different to NULL for prototypes
    $len = $cur ? $cur+1 : 0;
    # TODO:
    # my $ourstash = "0";  # TODO stash name to bless it (test 16: "main::")
    if ($PERL514) {
      # cv_undef wants to free it when CvDYNFILE(cv) is true.
      # E.g. DateTime: boot_POSIX. newXS reuses cv if autoloaded. So turn it off globally.
      $CvFLAGS = $cv->CvFLAGS & ~0x1000; # CVf_DYNFILE
      my $xpvc = sprintf
	# stash magic cur len cvstash start root cvgv cvfile cvpadlist     outside outside_seq cvflags cvdepth
	("Nullhv, {0}, %u, %u, %s, {%s}, {s\\_%x}, %s, %s, %s, (CV*)%s, %s, 0x%x, %d",
	 $cur, $len, "Nullhv",#CvSTASH later
	 $startfield, $$root,
	 "0",    #GV later
	 "NULL", #cvfile later (now a HEK)
	 $padlistsym,
	 $xcv_outside, #if main_cv set later
	 ivx($cv->OUTSIDE_SEQ),
	 ($gv and $$gv and $CvFLAGS & 0x400) ? 0 : $CvFLAGS, # no CVf_CVGV_RC otherwise we cannot set the GV
	 $cv->DEPTH);
      # repro only with 5.15.* threaded -q (70c0620) Encode::Alias::define_alias
      warn "lexwarnsym in XPVCV OUTSIDE: $xpvc" if $xpvc =~ /, \(CV\*\)iv\d/; # t/testc.sh -q -O3 227
      if (!$new_cv_fw) {
	$symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
	#$symsect->add
	#  (sprintf("CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}"),
	#	   $sv_ix, $xpvcv_ix, $cv->REFCNT + 1 * 0, $cv->FLAGS
	#	  ));
      } else {
	$xpvcvsect->comment('STASH mg_u cur len CV_STASH START_U ROOT_U GV file PADLIST OUTSIDE outside_seq flags depth');
	$xpvcvsect->add($xpvc);
	$svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x, {0}",
			     $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS));
	$svsect->debug( $fullname, $cv->flagspv ) if $debug{flags};
      }
    } else {
      my $xpvc = sprintf
	("{%d}, %u, %u, {%s}, {%s}, %s,"
	 ." %s, {%s}, {s\\_%x}, %s, %s, %s,"
	 ." (CV*)%s, %s, 0x%x",
	 0, # GvSTASH later. test 29 or Test::Harness
	 $cur, $len,
	 $cv->DEPTH,
	 "NULL", "Nullhv", #MAGIC + STASH later
	 "Nullhv",#CvSTASH later
	 $startfield,
	 $$root,
	 "0",    #GV later
	 "NULL", #cv_file later (now a HEK)
	 $padlistsym,
	 $xcv_outside, #if main_cv set later
	 $cv->OUTSIDE_SEQ,
	 $cv->CvFLAGS
	);
      if (!$new_cv_fw) {
	$symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
	#$symsect->add
	#  (sprintf("CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
	#	   $sv_ix, $xpvcv_ix, $cv->REFCNT + 1 * 0, $cv->FLAGS
	#	  ));
      } else {
	$xpvcvsect->comment('GvSTASH cur len  depth mg_u MG_STASH CV_STASH START_U ROOT_U CV_GV cv_file PADLIST OUTSIDE outside_seq cv_flags');
	$xpvcvsect->add($xpvc);
	$svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x, {0}",
			     $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS));
	$svsect->debug( $fullname, $cv->flagspv ) if $debug{flags};
      }
    }
    if ($$cv) {
      if (!$gv or ref($gv) eq 'B::SPECIAL') {
        my $lexsub  = $cv->can('NAME_HEK') ? $cv->NAME_HEK : "_anonlex_";
        warn "lexsub name $lexsub" if $debug{gv};
        $init->add( sprintf( "CvNAME_HEK_set(s\\_%x, %s);", $$cv, save_hek($lexsub) ));
      } else {
        my $gvstash = $gv->STASH;
        # defer GvSTASH because with DEBUGGING it checks for GP but
        # there's no GP yet.
        $init->add( sprintf( "GvXPVGV(s\\_%x)->xnv_u.xgv_stash = s\\_%x;",
                             $$cv, $$gvstash ) ) if $gvstash;
        warn sprintf( "done saving GvSTASH 0x%x for CV 0x%x\n", $$gvstash, $$cv )
          if $gvstash and $debug{cv} and $debug{gv};
      }
    }
    if ( $cv->OUTSIDE_SEQ ) {
      my $cop = $symtable{ sprintf( "s\\_%x", $cv->OUTSIDE_SEQ ) };
      $init->add( sprintf( "CvOUTSIDE_SEQ(%s) = %s;", $sym, $cop ) ) if $cop;
    }
  }
  elsif ($PERL56) {
    my $xpvc = sprintf("%s, %u, %u, %s, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub, "
		       ."$xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)%s, 0x%x",
	       $proto, $cur, $len, ivx($cv->IVX),
	       nvx($cv->NVX),  $startfield,       $$root, $cv->DEPTH,
	       $$padlist, $xcv_outside, $cv->CvFLAGS
	      );
    if ($new_cv_fw) {
      $xpvcvsect->comment('pv cur len off nv magic mg_stash cv_stash start root xsub '
                          .'xsubany cv_gv cv_file cv_depth cv_padlist cv_outside cv_flags');
      $xpvcvsect->add($xpvc);
      $svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x"),
		   $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS);
      $svsect->debug( $fullname, $cv->flagspv ) if $debug{flags};
    } else {
      $symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
    }
  }
  else { #5.8
    my $xpvc = sprintf("%s, %u, %u, %s, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub,"
		       ." $xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)s\\_%x, 0x%x, 0x%x",
	       $proto, $cur, $len, ivx($cv->IVX),
	       nvx($cv->NVX),  $startfield,       $$root, $cv->DEPTH,
	       $$padlist, $xcv_outside, $cv->CvFLAGS, $cv->OUTSIDE_SEQ
	      );
    if ($new_cv_fw) {
      $xpvcvsect->comment('pv cur len off nv           magic mg_stash cv_stash '
                         .'start root xsub xsubany cv_gv cv_file cv_depth cv_padlist '
                         .'cv_outside cv_flags outside_seq');
      $xpvcvsect->add($xpvc);
      $svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x"),
		   $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS);
      $svsect->debug( $fullname, $cv->flagspv ) if $debug{flags};
    } else {
      $symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
    }
  }

  $xcv_outside = ${ $cv->OUTSIDE };
  if ($xcv_outside == ${ main_cv() } or ref($cv->OUTSIDE) eq 'B::CV') {
    # patch CvOUTSIDE at run-time
    if ( $xcv_outside == ${ main_cv() } ) {
      $init->add( "CvOUTSIDE($sym) = PL_main_cv;",
                  "SvREFCNT_inc(PL_main_cv);" );
      if ($] >= 5.017005) {
        $init->add( "CvPADLIST($sym)->xpadl_outid = PadlistNAMES(CvPADLIST(PL_main_cv));");
      }
    } else {
      $init->add( sprintf("CvOUTSIDE($sym) = (CV*)s\\_%x;", $xcv_outside) );
    }
  }
  elsif ($] >= 5.017005 and $xcv_outside) {
    # Make sure that the outer padlist is allocated before PadlistNAMES is accessed.
    my $padl = $cv->OUTSIDE->PADLIST->save;
    # This needs to be postponed (test 227)
    $init2->add( sprintf( "CvPADLIST($sym)->xpadl_outid = PadlistNAMES($padl);") );
  }
  if ($gv and $$gv) {
    #test 16: Can't call method "FETCH" on unblessed reference. gdb > b S_method_common
    warn sprintf( "Saving GV 0x%x for CV 0x%x\n", $$gv, $$cv ) if $debug{cv} and $debug{gv};
    $gv->save;
    if ($PERL514) { # FIXME 5.18.0 with lexsubs
      # XXX gvcv might be PVMG
      $init->add( sprintf( "CvGV_set((CV*)%s, (GV*)%s);", $sym, objsym($gv) ) );
      # since 5.13.3 and CvGV_set there are checks that the CV is not RC (refcounted)
      # assertion "!CvCVGV_RC(cv)" failed: file "gv.c", line 219, function: Perl_cvgv_set
      # we init with CvFLAGS = 0 and set it later, as successfully done in the Bytecode compiler
      if ($CvFLAGS & 0x0400) { # CVf_CVGV_RC
        warn sprintf( "CvCVGV_RC turned off. CV flags=0x%x %s CvFLAGS=0x%x \n",
                      $cv->FLAGS, $debug{flags}?$cv->flagspv:"", $CvFLAGS & ~0x400)
          if $debug{cv};
        $init->add( sprintf( "CvFLAGS((CV*)%s) = 0x%x; %s", $sym, $CvFLAGS,
                             $debug{flags}?"/* ".$cv->flagspv." */":"" ) );
      }
      # XXX TODO someone is overwriting CvSTART also
      $init->add("CvSTART($sym) = $startfield;");
    } else {
      $init->add( sprintf( "CvGV(%s) = %s;", $sym, objsym($gv) ) );
    }
    warn sprintf("done saving GV 0x%x for CV 0x%x\n",
		 $$gv, $$cv) if $debug{cv} and $debug{gv};
  }
  unless ($optimize_cop) {
    if ($MULTI) {
      $init->add( savepvn( "CvFILE($sym)", $cv->FILE ) );
    } else {
      $init->add( sprintf( "CvFILE(%s) = %s;", $sym, cstring( $cv->FILE ) ) );
    }
  }
  my $stash = $cv->STASH;
  if ($$stash and ref($stash)) {
    # $init->add("/* saving STASH $fullname */\n" if $debug{cv};
    $stash->save($fullname);
    # $sym fixed test 27
    $init->add( sprintf( "CvSTASH_set((CV*)$sym, s\\_%x);", $$stash ) );
    warn sprintf( "done saving STASH 0x%x for CV 0x%x\n", $$stash, $$cv )
      if $debug{cv} and $debug{gv};
  }
  my $magic = $cv->MAGIC;
  if ($magic and $$magic) {
    $cv->save_magic($fullname); # XXX will this work?
  }
  if (!$new_cv_fw) {
    $symsect->add(sprintf(
      "CVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x".($PERL510?", {0}":''),
      $sv_ix, $xpvcv_ix, $cv->REFCNT + ($PERL510 ? 1 : 0), $cv->FLAGS
      )
    );
  }
  if ($cur) {
    warn sprintf( "Saving CV proto %s for CV 0x%x\n", $pv, $$cv ) if $debug{cv};
  }
  # issue 84: empty prototypes sub xx(){} vs sub xx{}
  if ($PERL510 and defined $pv) {
    if ($cur) {
      $init->add( sprintf("SvPVX(&sv_list[%d]) = HEK_KEY(%s);", $sv_ix, $pvsym));
    } elsif (!$B::C::const_strings) { # not static, they are freed when redefined
      $init->add( sprintf("SvPVX(&sv_list[%d]) = savepvn(%s, %u);",
			  $sv_ix, $proto, $cur));
    } else {
      $init->add( sprintf("SvPVX(&sv_list[%d]) = %s;",
			  $sv_ix, $proto));
    }
  }
  return $sym;
}

package B::C;
my @_v = Internals::V() if $] >= 5.011;
sub __ANON__::_V { @_v };

sub B::GV::save {
  my ($gv, $filter) = @_;
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
  warn sprintf( "  GV $sym type=%d, flags=0x%x %s\n", B::SV::SvTYPE($gv), $gv->FLAGS)
    if $debug{gv} and !$PERL56; # B::SV::SvTYPE not with 5.6
  if ($PERL510 and $gv->FLAGS & 0x40000000) { # SVpbm_VALID
    warn sprintf( "  GV $sym isa FBM\n") if $debug{gv};
    return B::BM::save($gv);
  }

  my $gvname   = $gv->NAME;
  my $package;
  if (ref($gv->STASH) eq 'B::SPECIAL') {
    $package = '__ANON__';
    warn sprintf( "GV STASH = SPECIAL $gvname\n") if $debug{gv};
  } else {
    $package = $gv->STASH->NAME;
  }
  return $sym if $skip_package{$package};

  my $fullname = $package . "::" . $gvname;
  my $fancyname;
  if ( $filter and $filter =~ / :pad/ ) {
    $fancyname = cstring($filter);
    $filter = 0;
  } else {
    $fancyname = cstring($fullname);
  }
  # checked for defined'ness in Carp. So the GV must exist, the CV not
  if ($fullname =~ /^threads::(tid|AUTOLOAD)$/ and !$ITHREADS) {
    $filter = 8;
  }

  my $is_empty = $gv->is_empty;
  if (!defined $gvname and $is_empty) { # 5.8 curpad name
    return q/(SV*)&PL_sv_undef/;
  }
  my $name     = $package eq 'main' ? cstring($gvname) : cstring($fullname);
  my $notqual  = ($] >= 5.008009 and $package eq 'main') ? 'GV_NOTQUAL' : '0';
  warn "  GV name is $fancyname\n" if $debug{gv};
  my $egvsym;
  my $is_special = ref($gv) eq 'B::SPECIAL';

  if ($fullname =~ /^(bytes|utf8)::AUTOLOAD$/) {
    $gv = force_heavy($package); # defer to run-time autoload, or compile it in?
    $sym = savesym( $gv, $sym ); # override new gv ptr to sym
  }
  if ( !$is_empty ) {
    my $egv = $gv->EGV;
    unless (ref($egv) eq 'B::SPECIAL' or ref($egv->STASH) eq 'B::SPECIAL') {
      my $estash = $egv->STASH->NAME;
      if ( $$gv != $$egv ) {
        warn(sprintf( "EGV name is %s, saving it now\n",
                      $estash . "::" . $egv->NAME )
            ) if $debug{gv};
        $egvsym = $egv->save;
      }
    }
  }
  #if ($fullname eq 'threads::tid' and !$ITHREADS) { # checked for defined'ness in Carp
  #  $init->add(qq[$sym = (GV*)&PL_sv_undef;]);
  #  return $sym;
  #}
  my $core_syms = {ENV    => 'PL_envgv',
                   ARGV   => 'PL_argvgv',
                   INC    => 'PL_incgv',
                   STDIN  => 'PL_stdingv',
                   STDERR => 'PL_stderrgv',
                   "\010" => 'PL_hintgv',  # ^H
                   "_"    => 'PL_defgv',
                   "@"    => 'PL_errgv',
                   "\022" => 'PL_replgv',  # ^R
                  };
  my $is_coresym;
  # those are already initialized in init_predump_symbols()
  # and init_main_stash()
  for my $s (keys %$core_syms) {
    if ($fullname eq 'main::'.$s) {
      $sym = savesym( $gv, $core_syms->{$s} );
      # $init->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
      # return $sym;
      $is_coresym++;
    }
  }
  if ($fullname =~ /^main::std(in|out|err)$/) {
    $init->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
    $init->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    return $sym;
  }
  elsif ($fullname eq 'main::0') { # dollar_0 already handled before, so don't overwrite it
    $init->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PV);]);
    $init->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
    return $sym;
  }
  # gv_fetchpv loads Errno resp. Tie::Hash::NamedCapture, but needs *INC #90
  #elsif ( $fullname eq 'main::!' or $fullname eq 'main::+' or $fullname eq 'main::-') {
  #  $init2->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PVGV);]); # defer until INC is setup
  #  $init2->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
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
  if ( $PERL510 and $gv->isGV_with_GP and !$is_coresym) {
    $gp = $gv->GP;    # B limitation
    # warn "XXX EGV='$egvsym' for IMPORTED_HV" if $gv->GvFLAGS & 0x40;
    if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
      warn(sprintf("Shared GV alias for *$fullname 0x%x%s %s to $egvsym\n",
                   $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                  )) if $debug{gv};
      # Shared glob *foo = *bar
      $init->add(qq[$sym = gv_fetchpv($name, $gvadd|GV_ADDMULTI, SVt_PVGV);]);
      $init->add( "GvGP_set($sym, GvGP($egvsym));" );
      $is_empty = 1;
    }
    elsif ( $gp and exists $gptable{0+$gp} ) {
      warn(sprintf("Shared GvGP for *$fullname 0x%x%s %s GP:0x%x\n",
                   $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                   $gv->FILE, $gp
                  )) if $debug{gv};
      $init->add(qq[$sym = gv_fetchpv($name, $notqual, SVt_PVGV);]);
      $init->add( sprintf("GvGP_set($sym, %s);", $gptable{0+$gp}) );
      $is_empty = 1;
    }
    elsif ( $gp and !$is_empty and $gvname =~ /::$/) {
      warn(sprintf("Shared GvGP for stash %$fullname 0x%x%s %s GP:0x%x\n",
                   $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                   $gv->FILE, $gp
                  )) if $debug{gv};
      $init->add(qq[$sym = gv_fetchpv($name, GV_ADD, SVt_PVHV);]);
      $gptable{0+$gp} = "GvGP($sym)" if 0+$gp;
    }
    elsif ( $gp and !$is_empty ) {
      warn(sprintf("New GV for *$fullname 0x%x%s %s GP:0x%x\n",
                   $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                   $gv->FILE, $gp
                  )) if $debug{gv};
      # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
      $init->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
      $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
      $gptable{0+$gp} = "GvGP($sym)";
    }
    else {
      $init->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PVGV);]);
    }
  } elsif (!$is_coresym) {
    $init->add(qq[$sym = gv_fetchpv($name, $gvadd, SVt_PV);]);
  }
  my $gvflags = $gv->GvFLAGS;
  if ($gvflags > 256 and !$PERL510) { # $gv->GvFLAGS as U8 single byte only
    $gvflags = $gvflags & 255;
  }
  $init->add( sprintf( "SvFLAGS($sym) = 0x%x;%s", $svflags,
                     $debug{flags}?" /* ".$gv->flagspv." */":"" ),
	           sprintf( "GvFLAGS($sym) = 0x%x; %s", $gvflags,
                     $debug{flags}?"/* ".$gv->flagspv(SVt_PVGV)." */":"" ));
  $init->add( sprintf( "GvLINE($sym) = %d;",
		       ($gv->LINE > 2147483647  # S32 INT_MAX
			? 4294967294 - $gv->LINE
			: $gv->LINE )))
	      unless $is_empty;

  # XXX hack for when Perl accesses PVX of GVs, only if SvPOK
  #if (!($svflags && 0x400)) { # defer to run-time (0x400 -> SvPOK) for convenience
  # XXX also empty "main::" destruction accesses a PVX, so do not check if_empty
  if ( !$PERL510 ) {
    $init->add("if (SvPOK($sym) && !SvPVX($sym)) SvPVX($sym) = (char*)emptystring;");
  }

  # Will always be > 1
  $init->add( sprintf( "SvREFCNT($sym) = %u;", $gv->REFCNT ) );
  return $sym if $is_empty;

  # B::walksymtable creates an extra reference to the GV
  my $gvrefcnt = $gv->GvREFCNT;
  if ( $gvrefcnt > 1 ) {
    $init->add( sprintf( "GvREFCNT($sym) += %u;", $gvrefcnt - 1 ) );
  }

  warn "check which savefields for \"$gvname\"\n" if $debug{gv};
  # some non-alphabetic globs require some parts to be saved
  # ( ex. %!, but not $! )
  if ( $gvname !~ /^([^A-Za-z]|STDIN|STDOUT|STDERR|ARGV|SIG|ENV)$/ ) {
    $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
  }
  elsif ( $fullname eq 'main::!' ) { #Errno
    $savefields = Save_HV | Save_SV | Save_CV;
  }
  elsif ( $fullname eq 'main::ENV' or $fullname eq 'main::SIG' ) {
    $savefields = Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
  }
  elsif ( $fullname eq 'main::ARGV' ) {
    $savefields = Save_HV | Save_SV | Save_CV | Save_FORM | Save_IO;
  }
  elsif ( $fullname =~ /^main::STD(OUT|ERR)$/ ) {
    $savefields = Save_FORM | Save_IO;
  }
  $savefields &= ~$filter if ($filter and $filter !~ / :pad/
                              and $filter =~ /^\d+$/ and $filter > 0 and $filter < 64);
  # issue 79: Only save stashes for stashes.
  # But not other values to avoid recursion into unneeded territory.
  # We walk via savecv, not via stashes.
  if (ref($gv) eq 'B::STASHGV' and $gvname !~ /::$/) {
    return $sym;
  }

  # attributes::bootstrap is created in perl_parse.
  # Saving it would overwrite it, because perl_init() is
  # called after perl_parse(). But we need to xsload it.
  if ($fullname eq 'attributes::bootstrap') {
    unless ( defined( &{ $package . '::bootstrap' } ) ) {
      warn "Forcing bootstrap of $package\n" if $verbose;
      eval { $package->bootstrap };
    }
    mark_package('attributes', 1);
    if ($] >= 5.011) {
      $savefields &= ~Save_CV;
      $xsub{attributes} = 'Dynamic-'. $INC{'attributes.pm'}; # XSLoader
      $use_xsloader = 1;
    } else {
      $xsub{attributes} = 'Static';
    }
  }

  if ($savefields) {
    # Don't save subfields of special GVs (*_, *1, *# and so on)
    warn "GV::save saving subfields $savefields\n" if $debug{gv};
    my $gvsv = $gv->SV;
    if ( $$gvsv && $savefields & Save_SV ) {
      warn "GV::save \$".$sym." $gvsv\n" if $debug{gv};
      if ($fullname eq 'main::@') { # $@ = PL_errors
	$init->add( "GvSVn($sym) = (SV*)PL_errors;" );
      }
      elsif ($gvname eq 'VERSION' and $xsub{$package} and $gvsv->FLAGS & SVf_ROK and !$PERL56) {
	warn "Strip overload from $package\::VERSION, fails to xs boot (issue 91)\n" if $debug{gv};
	my $rv = $gvsv->object_2svref();
	my $origsv = $$rv;
	no strict 'refs';
	${$fullname} = "$origsv";
	svref_2object(\${$fullname})->save($fullname);
	$init->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
      } else {
	$gvsv->save($fullname); #mostly NULL. $gvsv->isa("B::NULL");
	$init->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
      }
      if ($fullname eq 'main::$') { # $$ = PerlProc_getpid() issue #108
        warn sprintf( "  GV $sym \$\$ perlpid\n") if $debug{gv};
        $init->add( "sv_setiv(GvSV($sym), (IV)PerlProc_getpid());" );
      }
      warn "GV::save \$$fullname\n" if $debug{gv};
    }
    my $gvav = $gv->AV;
    if ( $$gvav && $savefields & Save_AV ) {
      warn "GV::save \@$fullname\n" if $debug{gv};
      if ($fullname eq 'main::+' or $fullname eq 'main::-') {
        $init->add("/* \@$gvname force saving of Tie::Hash::NamedCapture */");
        if ($] >= 5.014) {
          mark_package('Config', 1);  # DynaLoader needs Config to set the EGV
          walk_syms('Config');
          svref_2object(\&{'Tie::Hash::NamedCapture::bootstrap'})->save;
        }
        mark_package('Tie::Hash::NamedCapture', 1);
      }
      $gvav->save($fullname);
      $init->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
    }
    my $gvhv = $gv->HV;
    if ( $$gvhv && $savefields & Save_HV ) {
      if ($fullname ne 'main::ENV') {
	warn "GV::save \%$fullname\n" if $debug{gv};
	if ($fullname eq 'main::!') { # force loading Errno
	  $init->add("/* \%! force saving of Errno */");
	  mark_package('Config', 1);  # Errno needs Config to set the EGV
          walk_syms('Config');
	  mark_package('Errno', 1);   # B::C needs Errno but does not import $!
	} elsif ($fullname eq 'main::+' or $fullname eq 'main::-') {
	  $init->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");
          if ($] >= 5.014) {
            mark_package('Config', 1);  # DynaLoader needs Config to set the EGV
            walk_syms('Config');
            svref_2object(\&{'Tie::Hash::NamedCapture::bootstrap'})->save;
          }
	  mark_package('Tie::Hash::NamedCapture', 1);
        }
	# XXX TODO 49: crash at BEGIN { %warnings::Bits = ... }
	if ($fullname ne 'main::INC') {
	  $gvhv->save($fullname);
	  $init->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
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
      $gvcv = $gv->CV; # try again
    }
    if ( $$gvcv and $savefields & Save_CV
         and ref($gvcv->GV->EGV) ne 'B::SPECIAL'
         and !$skip_package{$package} )
    {
      my $origname = $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME;
      if ( $gvcv->XSUB and $fullname ne $origname ) {    #XSUB CONSTSUB alias
	my $package = $gvcv->GV->EGV->STASH->NAME;
        $origname = cstring( $origname );
        warn "Boot $package, XS CONSTSUB alias of $fullname to $origname\n" if $debug{pkg};
        mark_package($package, 1);
        {
          no strict 'refs';
          svref_2object( \&{"$package\::bootstrap"} )->save
            if $package and defined &{"$package\::bootstrap"};
        }
        # XXX issue 57: incomplete xs dependency detection
        my %hack_xs_detect =
          ('Scalar::Util'  => 'List::Util',
           'Sub::Exporter' => 'Params::Util',
          );
        if (my $dep = $hack_xs_detect{$package}) {
          svref_2object( \&{"$dep\::bootstrap"} )->save;
        }
        # must save as a 'stub' so newXS() has a CV to populate
	$init2->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
      }
      elsif (!$PERL510 or $gp) {
        $origname = cstring( $origname );
	if ($fullname eq 'Internals::V') { # local_patches if $] >= 5.011
	  $gvcv = svref_2object( \&__ANON__::_V );
	}
	# TODO: may need fix CvGEN if >0 to re-validate the CV methods
	# on PERL510 (>0 + <subgeneration)
	warn "GV::save &$fullname...\n" if $debug{gv};
        my $cvsym = $gvcv->save($fullname);
        # backpatch "$sym = gv_fetchpv($name, GV_ADD, SVt_PV)" to SVt_PVCV
        if ($cvsym =~ /(\(char\*\))?get_cv\("/) {
	  if (!$xsub{$package} and in_static_core($package, $gvname)) {
	    my $in_gv;
	    for (@{ $init->[-1]{current} }) {
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
	    $init->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
	  }
	  elsif ($xsub{$package}) {
            # must save as a 'stub' so newXS() has a CV to populate later in dl_init()
            warn "save stub CvGV for $sym GP assignments $origname (XS CV)\n" if $debug{gv};
            $init2->add("GvCV_set($sym, (CV*)SvREFCNT_inc_simple_NN(get_cv($origname, GV_ADD)));");
	  }
	  else {
            $init2->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
	  }
	}
	else {
          $init->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $cvsym ) );
	}
      }
    }
    if (!$PERL510 or $gp) {
      if ( $] > 5.009 ) {
	# TODO implement heksect to place all heks at the beginning
	#$heksect->add($gv->FILE);
	#$init->add(sprintf("GvFILE_HEK($sym) = hek_list[%d];", $heksect->index));
	$init->add(sprintf("GvFILE_HEK($sym) = %s;", save_hek($gv->FILE)))
	  unless $optimize_cop;
	# $init->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;
      } else {
	# XXX ifdef USE_ITHREADS and PL_curcop->op_flags & OPf_COP_TEMP
	# GvFILE is at gp+1
	$init->add( sprintf( "GvFILE($sym) = %s;", cstring( $gv->FILE ) ))
	  unless $optimize_cop;
	warn "GV::save GvFILE(*$fullname) " . cstring( $gv->FILE ) . "\n"
	  if $debug{gv} and !$ITHREADS;
      }
      my $gvform = $gv->FORM;
      if ( $$gvform && $savefields & Save_FORM ) {
	warn "GV::save GvFORM(*$fullname) ...\n" if $debug{gv};
	$gvform->save($fullname);
	$init->add( sprintf( "GvFORM($sym) = (CV*)s\\_%x;", $$gvform ) );
	warn "GV::save GvFORM(*$fullname) done\n" if $debug{gv};
      }
      my $gvio = $gv->IO;
      if ( $$gvio && $savefields & Save_IO ) {
	warn "GV::save GvIO(*$fullname)...\n" if $debug{gv};
	$gvio->save($fullname);
	$init->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
	if ( $fullname =~ m/::DATA$/ &&
	     ( $fullname eq 'main::DATA' or $B::C::save_data_fh) ) # -O2 or 5.8
	{
	  no strict 'refs';
	  my $fh = *{$fullname}{IO};
	  use strict 'refs';
	  warn "GV::save_data $sym, $fullname ...\n" if $debug{gv};
	  $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
	} elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
	  warn "Warning: __DATA__ handle $fullname not stored. Need -O2 or -fsave-data.\n";
	}
	warn "GV::save GvIO(*$fullname) done\n" if $debug{gv};
      }
      $init->add("");
    }
  }
  # Shouldn't need to do save_magic since gv_fetchpv handles that. Esp. < not
  # $gv->save_magic($fullname) if $PERL510;
  warn "GV::save *$fullname done\n" if $debug{gv};
  return $sym;
}

sub B::AV::save {
  my ($av, $fullname) = @_;
  my $sym = objsym($av);
  return $sym if defined $sym;

  $fullname = '' unless $fullname;
  my ($fill, $avreal, $max);
  # cornercase: tied array without FETCHSIZE
  eval { $fill = $av->FILL; };
  $fill = -1 if $@;    # catch error in tie magic
  my $ispadlist = ref($av) eq 'B::PADLIST';
  $max = $fill;
  my $svpcast = $ispadlist ? "(PAD*)" : "(SV*)";

  if ($] >= 5.017006 and $ispadlist) {
    $padlistsect->comment("xpadl_max, xpadl_alloc, xpadl_outid");
    my @array = $av->ARRAY;
    $fill = scalar @array;
    $padlistsect->add("$fill, NULL, 0"); # Perl_pad_new(0)
    # $init->add("pad_list[$padlist_index] = Perl_pad_new(0);");
    $padlist_index = $padlistsect->index;
    $sym = savesym( $av, "&padlist_list[$padlist_index]" );
  }
  elsif ($] >= 5.017004 and $ispadlist) {
    $padlistsect->comment("xpadl_max, xpadl_alloc, xpadl_id, xpadl_outid");
    my @array = $av->ARRAY;
    $fill = scalar @array;
    $padlistsect->add("$fill, NULL, 0, 0"); # Perl_pad_new(0)
    # $init->add("pad_list[$padlist_index] = Perl_pad_new(0);");
    $padlist_index = $padlistsect->index;
    $sym = savesym( $av, "&padlist_list[$padlist_index]" );
  }
  elsif ($PERL514) {
    # 5.13.3: STASH, MAGIC, fill max ALLOC
    my $line = "Nullhv, {0}, -1, -1, 0";
    $line = "Nullhv, {0}, $fill, $max, 0" if $B::C::av_init or $B::C::av_init2;
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x, {%s}",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS,
                         '0'));
    #$avreal = $av->FLAGS & 0x40000000; # SVpav_REAL (unused)
  }
  elsif ($PERL510) {
    # 5.9.4+: nvu fill max iv MG STASH
    my $line = "{0}, -1, -1, {0}, {0}, Nullhv";
    $line = "{0}, $fill, $max, {0}, {0}, Nullhv" if $B::C::av_init or $B::C::av_init2;
    $line = "Nullhv, {0}, $fill, $max, NULL" if $PERL514;
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x, {%s}",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS,
                         '0'));
    #$avreal = $av->FLAGS & 0x40000000; # SVpav_REAL (unused)
  }
  else {
    # 5.8: ARRAY fill max off nv MG STASH ALLOC arylen flags
    my $line = "0, -1, -1, 0, 0.0, 0, Nullhv, 0, 0";
    $line = "0, $fill, $max, 0, 0.0, 0, Nullhv, 0, 0" if $B::C::av_init or $B::C::av_init2;
    $line .= sprintf( ", 0x%x", $av->AvFLAGS ) if $] < 5.009;
    #$avreal = $av->AvFLAGS & 1; # AVf_REAL
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS));
  }

  my ($av_index, $magic);
  if (!$ispadlist) {
    $svsect->debug($fullname, $av->flagspv) if $debug{flags};
    my $sv_ix = $svsect->index;
    $av_index = $xpvavsect->index;
    # protect against recursive self-references (Getopt::Long)
    $sym = savesym( $av, "(AV*)&sv_list[$sv_ix]" );
    $magic = $av->save_magic($fullname);
  }

  if ( $debug{av} ) {
    my $line = sprintf( "saving AV $fullname 0x%x [%s] FILL=$fill", $$av, class($av));
    $line .= sprintf( " AvFLAGS=0x%x", $av->AvFLAGS ) if $] < 5.009;
    warn "$line\n";
  }

  # XXX AVf_REAL is wrong test: need to save comppadlist but not stack
  if ($fill > -1 and $magic !~ /D/) {
    my @array = $av->ARRAY; # crashes with D magic (Getopt::Long)
    if ( $debug{av} ) {
      my $i = 0;
      foreach my $el (@array) {
	my $val = '';
	# if SvIOK print iv, POK pv
	if ($el->can('FLAGS')) {
	  $val = $el->IVX if $el->FLAGS & SVf_IOK;
	  $val = cstring($el->PV) if $el->FLAGS & SVf_POK;
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
    my ($count, @values);
    {
      local $B::C::const_strings = $B::C::const_strings;
      if ($PERL510 and !$ispadlist) { # force dynamic PADNAME strings
        if ($] < 5.016) { $B::C::const_strings = 0 if $av->FLAGS & 0x40000000; }      # SVpad_NAME
        else { $B::C::const_strings = 0 if ($av->FLAGS & 0x40008000 == 0x40008000); } # SVp_SCREAM|SVpbm_VALID
      }
      @values = map { $_->save($fullname."[".$count++."]") || () } @array;
    }
    $count = 0;
    for (my $i=0;$i<=$#array;$i++) {
      if ( $use_svpop_speedup
           && defined $values[$i]
           && defined $values[$i+1]
           && defined $values[$i+2]
	   && $values[$i] =~ /^\&sv_list\[(\d+)\]/
	   && $values[$i+1] eq "&sv_list[" . ($1+1) . "]"
	   && $values[$i+2] eq "&sv_list[" . ($1+2) . "]" )
      {
	$count=0;
	while (defined($values[$i+$count+1]) and $values[$i+$count+1] eq "&sv_list[" . ($1+$count+1) . "]") {
	  $count++;
	}
	$acc .= "\tfor (gcount=" . $1 . "; gcount<" . ($1+$count+1) . "; gcount++) {"
	  ." *svp++ = $svpcast&sv_list[gcount]; };\n\t";
	$i += $count;
      } elsif ($use_av_undef_speedup
	       && defined $values[$i]
	       && defined $values[$i+1]
	       && defined $values[$i+2]
	       && $values[$i]   =~ /^ptr_undef|&PL_sv_undef$/
	       && $values[$i+1] =~ /^ptr_undef|&PL_sv_undef$/
	       && $values[$i+2] =~ /^ptr_undef|&PL_sv_undef$/)
      {
	$count=0;
	while (defined $values[$i+$count+1] and $values[$i+$count+1] =~ /^ptr_undef|&PL_sv_undef$/) {
	  $count++;
	}
	$acc .= "\tfor (gcount=0; gcount<" . ($count+1) . "; gcount++) {"
	  ." *svp++ = $svpcast&PL_sv_undef; };\n\t";
	$i += $count;
      } else { # XXX 5.8.9d Test::NoWarnings has empty values
	$acc .= "\t*svp++ = $svpcast" . ($values[$i] ? $values[$i] : '&PL_sv_undef') . ";\n\t";
      }
    }
    $init->no_split;

    if (ref $av eq 'B::PADLIST') {
      my $fill1 = $fill+1;
      $init->add("{", "\tPAD **svp;");
      $init->add("\tregister int gcount;") if $count;
      $init->add(
                 "\tPADLIST *padl = $sym;",
                 sprintf("\tNewxz(svp, %d, PAD *);", $fill+1),
                 "\tPadlistARRAY(padl) = svp;",
                );
      $init->add( substr( $acc, 0, -2 ) );
      $init->add("}");
    }
    # With -fav-init2 use independent_comalloc()
    elsif ($B::C::av_init2) {
      my $i = $av_index;
      $xpvav_sizes[$i] = $fill;
      my $init_add = "{ SV **svp = avchunks[$i]; AV *av = $sym;\n";
      $init_add .= "\tregister int gcount;\n" if $count;
      if ($fill > -1) {
        if ($PERL510) {
          $init_add .= "\tAvALLOC(av) = svp;\n".
                       "\tAvARRAY(av) = svp;\n";
        } else {
          $init_add .= "\tAvALLOC(av) = svp;\n" .
                       # XXX Dirty hack from av.c:Perl_av_extend()
                       "\tSvPVX(av) = (char*)svp;";
        }
      }
      $init_add .= substr( $acc, 0, -2 );
      $init->add( $init_add . "}" );
    }
    # With -fav-init faster initialize the array as the initial av_extend()
    # is very expensive.
    # The problem was calloc, not av_extend.
    # Since we are always initializing every single element we don't need
    # calloc, only malloc. wmemset'ting the pointer to PL_sv_undef
    # might be faster also.
    elsif ($B::C::av_init) {
      $init->add(
                 "{", "\tSV **svp;",
                 "\tAV *av = $sym;");
      $init->add("\tregister int gcount;") if $count;
      my $fill1 = $fill < 3 ? 3 : $fill+1;
      if ($fill > -1) {
        # Perl_safesysmalloc (= calloc => malloc) or Perl_malloc (= mymalloc)?
	if ($MYMALLOC) {
          $init->add(sprintf("\tNewx(svp, %d, SV*);", $fill1),
                     "\tAvALLOC(av) = svp;");
        } else {
	  # Bypassing Perl_safesysmalloc on darwin fails with "free from wrong pool", test 25.
	  # So with DEBUGGING perls we have to track memory and use calloc.
	  $init->add("#ifdef PERL_TRACK_MEMPOOL",
		     sprintf("\tsvp = (SV**)Perl_safesysmalloc(%d * sizeof(SV*));", $fill1),
		     "#else",
		     sprintf("\tsvp = (SV**)malloc(%d * sizeof(SV*));", $fill1),
		     "#endif",
          	     "\tAvALLOC(av) = svp;");
	}
        if ($PERL510) {
	  $init->add("\tAvARRAY(av) = svp;");
        } else { # read-only AvARRAY macro
	  # XXX Dirty hack from av.c:Perl_av_extend()
          $init->add("\tSvPVX(av) = (char*)svp;");
        }
      }
      $init->add( substr( $acc, 0, -2 ) ); # AvFILLp already in XPVAV
      $init->add( "}" );
    }
    else { # unoptimized with the full av_extend()
      my $fill1 = $fill < 3 ? 3 : $fill+1;
      $init->add("{", "\tSV **svp;");
      $init->add("\tregister int gcount;") if $count;
      $init->add("\tAV *av = $sym;",
                 "\tav_extend(av, $fill1);",
                 "\tsvp = AvARRAY(av);");
      $init->add( substr( $acc, 0, -2 ) );
      $init->add( "\tAvFILLp(av) = $fill;", "}" );
    }
    $init->split;

    # we really added a lot of lines ( B::C::InitSection->add
    # should really scan for \n, but that would slow
    # it down
    $init->inc_count($#array);
  }
  else {
    my $max = $av->MAX;
    $init->add("av_extend($sym, $max);")
      if $max > -1;
  }
  return $sym;
}

sub B::PADLIST::save {
  return B::AV::save(@_);
}

sub B::HV::save {
  my ($hv, $fullname) = @_;
  $fullname = '' unless $fullname;
  my $sym = objsym($hv);
  return $sym if defined $sym;
  my $name = $hv->NAME;
  my $is_stash = $name;
  if ($name) {
    # It's a stash. See issue 79 + test 46
    warn sprintf( "Saving stash HV \"%s\" from \"$fullname\" 0x%x MAX=%d\n",
                  $name, $$hv, $hv->MAX ) if $debug{hv};

    # A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
    # the only symptom is that sv_reset tries to reset the PMf_USED flag of
    # a trashed op but we look at the trashed op_type and segfault.
    #my $adpmroot = ${$hv->PMROOT}; # XXX When was this fixed?
    my $adpmroot = 0;
    $decl->add("Static HV *hv$hv_index;");

    my $cname = cstring($name);
    my $len = length(pack "a*", $name); # not yet 0-byte safe. HEK len really
    $init->add(qq[hv$hv_index = gv_stashpvn($cname, $len, TRUE);]);
    if ($adpmroot) {
      $init->add(sprintf( "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;",
			  $adpmroot ) );
    }
    $sym = savesym( $hv, "hv$hv_index" );
    $hv_index++;

    # issue 79, test 46: save stashes to check for packages.
    # and via B::STASHGV we only save stashes for stashes.
    # For efficiency we skip most stash symbols unless -fstash.
    # However it should be now safe to save all stash symbols.
    # $fullname !~ /::$/ or
    if (!$B::C::stash) {
      $hv->save_magic('%'.$name.'::'); #symtab magic set in PMOP #188 (#267)
      return $sym;
    }
    return $sym if skip_pkg($name);
    $init->add( "SvREFCNT_inc($sym);" );
    warn "Saving stash keys for HV \"$name\" from \"$fullname\"\n" if $debug{hv};
  }

  # Ordinary HV or Stash
  # KEYS = 0, inc. dynamically below with hv_store
  if ($PERL510) {
    if ($PERL514) { # fill removed with 5.13.1
      $xpvhvsect->comment( "stash mgu max keys" );
      $xpvhvsect->add(sprintf( "Nullhv, {0}, %d, %d",
			       $hv->MAX, 0 ));
    } else {
      $xpvhvsect->comment( "GVSTASH fill max keys MG STASH" );
      $xpvhvsect->add(sprintf( "{0}, %d, %d, {%d}, {0}, Nullhv",
			       0, $hv->MAX, 0 ));
    }
    $svsect->add(sprintf("&xpvhv_list[%d], %lu, 0x%x, {0}",
			 $xpvhvsect->index, $hv->REFCNT,
			 $hv->FLAGS & ~SVf_READONLY));
    # XXX failed at 16 (tied magic) for %main::
    if (!$is_stash and ($] >= 5.010 and $hv->FLAGS & SVf_OOK)) {
      $sym = sprintf("&sv_list[%d]", $svsect->index);
      my $hv_max = $hv->MAX + 1;
      # riter required, new _aux struct at the end of the HvARRAY. allocate ARRAY also.
      $init->add("{\tHE **a; struct xpvhv_aux *aux;",
                 "#ifdef PERL_USE_LARGE_HV_ALLOC",
                 sprintf("\tNewxz(a, PERL_HV_ARRAY_ALLOC_BYTES(%d) + sizeof(struct xpvhv_aux), HE*);",
                         $hv_max),
                 "#else",
                 sprintf("\tNewxz(a, %d + sizeof(struct xpvhv_aux), HE*);", $hv_max),
                 "#endif",
		 "\tHvARRAY($sym) = a;",
		 sprintf("\tHvRITER_set($sym, %d);", $hv->RITER),"}");
    }
  } # !5.10
  else {
    $xpvhvsect->comment( "array fill max keys nv mg stash riter eiter pmroot name" );
    $xpvhvsect->add(sprintf( "0, 0, %d, 0, 0.0, 0, Nullhv, %d, 0, 0, 0",
			     $hv->MAX, $hv->RITER));
    $svsect->add(sprintf( "&xpvhv_list[%d], %lu, 0x%x",
			  $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS));
  }
  $svsect->debug($fullname, $hv->flagspv) if $debug{flags};
  my $sv_list_index = $svsect->index;
  warn sprintf( "saving HV %".$fullname." &sv_list[$sv_list_index] 0x%x MAX=%d KEYS=%d\n",
                $$hv, $hv->MAX, $hv->KEYS ) if $debug{hv};
  # XXX B does not keep the UTF8 flag [RT 120535] #200
  # shared heks only since 5.10, our fixed C.xs variant
  my @contents = ($PERL510 && $hv->can('ARRAY_utf8')) ? $hv->ARRAY_utf8 : $hv->ARRAY;    # protect against recursive self-reference
  # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
  # value => rv => cv => ... => rv => same hash
  $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
  if (@contents) {
    local $B::C::const_strings = $B::C::const_strings;
    my ($i, $length);
    $length = scalar(@contents);
    for ( $i = 1 ; $i < @contents ; $i += 2 ) {
      my $key = $contents[$i - 1]; # string only
      my $sv = $contents[$i];
      warn sprintf("HV recursion? with $fullname\{$key\} -> %s\n", $sv->RV)
        if ref($sv) eq 'B::RV'
          #and $sv->RV->isa('B::CV')
          and defined objsym($sv)
          and $debug{hv};
      if ($is_stash) {
	if (ref($sv) eq "B::GV" and $sv->NAME =~ /::$/) {
	  $sv = bless $sv, "B::STASHGV"; # do not expand stash GV's only other stashes
	  warn "saving STASH $fullname".'{'.$key."}\n" if $debug{hv};
	  $contents[$i] = $sv->save($fullname.'{'.$key.'}');
	} else {
	  warn "skip STASH symbol *",$fullname.$key,"\n" if $debug{hv};
	  $contents[$i] = undef;
	  $length -= 2;
	  # warn "(length=$length)\n" if $debug{hv};
	}
      } else {
	warn "saving HV \$".$fullname.'{'.$key."}\n" if $debug{hv};
	$contents[$i] = $sv->save($fullname.'{'.$key.'}');
	#if ($key eq "" and $] >= 5.010) {
	#  warn "  turn off HvSHAREKEYS with empty keysv\n" if $debug{hv};
	#  $init->add("HvSHAREKEYS_off(&sv_list[$sv_list_index]);");
	#}
      }
    }
    if ($length) { # there may be skipped STASH symbols
      $init->no_split;
      $init->add( "{",
		  sprintf("\tHV *hv = %s$sym;", $sym=~/^hv|\(HV/ ? '' : '(HV*)' ));
      while (@contents) {
	my ( $key, $value ) = splice( @contents, 0, 2 );
	if ($value) {
          $value = "(SV*)$value" if $value !~ /^&sv_list/ or ($PERL510 and $] < 5.012);
          my $cur = length( pack "a*", $key );
          if (!$PERL56) {
            if (utf8::is_utf8($key)) {
              my $pv = $key;
              utf8::encode($pv);
              $cur = 0 - length($pv);
            }
          }
	  # issue 272: if SvIsCOW(sv) && SvLEN(sv) == 0 => sharedhek (key == "")
	  # >= 5.10: SvSHARED_HASH: PV offset to hek_hash
	  $init->add(sprintf( "\thv_store(hv, %s, %d, %s, %s);",
			      cstring($key), $cur, $value, 0 )); # !! randomized hash keys
	  warn sprintf( "  HV key \"%s\" = %s\n", $key, $value) if $debug{hv};
	}
      }
      $init->add("}");
      $init->split;
      $init->add( sprintf("HvTOTALKEYS($sym) = %d;", $length / 2)) if !$PERL56;
      $init->add( "SvREADONLY_on($sym);") if $hv->FLAGS & SVf_READONLY;
    }
  } elsif ($] >= 5.014) { # empty contents still needs to set keys=0
    # test 36, 140
    $init->add( "HvTOTALKEYS($sym) = 0;");
    $init->add( "SvREADONLY_on($sym);") if $hv->FLAGS & SVf_READONLY;
  }
  $hv->save_magic($fullname);
  return $sym;
}

sub B::IO::save_data {
  my ( $io, $sym, $globname, @data ) = @_;
  my $data = join '', @data;
  # XXX using $DATA might clobber it!
  my $ref = svref_2object( \\$data )->save;
  $init->add("/* save $globname in RV ($ref) */") if $verbose;
  $init->add( "GvSVn( $sym ) = (SV*)$ref;");

  if ($PERL56) {
    # Pseudo FileHandle
    $init->add_eval( sprintf 'open(%s, \'<\', $%s)', $globname, $globname );
  } else { # force inclusion of PerlIO::scalar as it was loaded in BEGIN.
    $init->add_eval( sprintf 'open(%s, \'<:scalar\', $%s)', $globname, $globname );
    # => eval_pv("open(main::DATA, '<:scalar', $main::DATA)",1); DATA being a ref to $data
    $use_xsloader = 1; # layers are not detected as XSUB CV, so force it
    require PerlIO;
    require PerlIO::scalar;
    $savINC{'PerlIO.pm'} = $INC{'PerlIO.pm'};  # as it was loaded from BEGIN
    mark_package("PerlIO", 1);
    $savINC{'PerlIO/scalar.pm'} = $INC{'PerlIO/scalar.pm'};
    $xsub{'PerlIO::scalar'} = 'Dynamic-'.$INC{'PerlIO/scalar.pm'}; # force dl_init boot
    mark_package("PerlIO::scalar", 1);
  }
}

sub B::IO::save {
  my ($io, $fullname) = @_;
  my $sym = objsym($io);
  return $sym if defined $sym;
  my $pv = $io->PV;
  $pv = '' unless defined $pv;
  my ( $pvsym, $len, $cur );
  if ($pv) {
    $pvsym = savepv($pv);
    $cur = $io->CUR;
  } else {
    $pvsym = 'NULL';
    $cur = 0;
  }
  if ($cur) {
    $len = $cur + 1;
    $len++ if IsCOW($io);
  } else {
    $len = 0;
  }
  warn sprintf( "IO $fullname sv_list[%d] 0x%x (%s) = '%s'\n", $svsect->index+1, $$io, $io->SvTYPE, $pv ) if $debug{sv};
  if ($PERL514) {
    # IFP in sv.sv_u.svu_fp
    $xpviosect->comment("STASH, xmg_u, cur, len, xiv_u, xio_ofp, xio_dirpu, page, page_len, ..., type, flags");
    my $tmpl = "Nullhv, /*STASH later*/\n\t{0}, /*MAGIC later*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%d}, /*LINES*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $cur,                     $len,
	$io->LINES, 		  # moved to IVX with 5.11.1
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          "NULL",
        "NULL",                   "NULL",
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x, {%s}",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS,
			 $B::C::pv_copy_on_grow ? $pvsym : 0));
  }
  elsif ($] > 5.011000) {
    $xpviosect->comment("xnv_u, cur, len, lines, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, ..., type, flags");
    my $tmpl = "{0}, /*xnv_u*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%d}, /*LINES*/\n\t{0}, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $cur,                     $len,
	$io->LINES, 		  # moved to IVX with 5.11.1
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          "NULL",
        "NULL",                   "NULL",
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x, {%s}",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS,
			 $B::C::pv_copy_on_grow ? $pvsym : 0));
  }
  elsif ($PERL510) {
    $xpviosect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, lines, ..., type, flags");
    my $tmpl = "{0}, /*xnv_u*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%ld}, /*IVX*/\n\t{0}, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*LINES*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*[^\*]+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $cur,                     $len,
        $io->IVX,
	$io->LINES,
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          "NULL",
        "NULL",                   "NULL",
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x, {%s}",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS,
			 $B::C::pv_copy_on_grow ? $pvsym : 0));
  }
  else { # 5.6 and 5.8
    $xpviosect->comment("xpv_pv, cur, len, iv, nv, magic, stash, xio_ifp, xio_ofp, xio_dirpu, ..., subprocess, type, flags");
    $xpviosect->add(
      sprintf("%s, %u, %u, %ld, %s, 0, 0, 0, 0, {0}, %d, %d, %d, %d, %s, Nullgv, %s, Nullgv, %s, Nullgv, %d, %s, 0x%x",
              $pvsym, 			   $cur, $len,
              $io->IVX,                    $io->NVX,
              $io->LINES,                  $io->PAGE,
              $io->PAGE_LEN,               $io->LINES_LEFT,
              "NULL",                      "NULL",
              "NULL",                      $io->SUBPROCESS,
              cchar( $io->IoTYPE ),        $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS));
  }
  $svsect->debug($fullname, $io->flagspv) if $debug{flags};
  $sym = savesym( $io, sprintf( "(IO*)&sv_list[%d]", $svsect->index ) );

  if ($PERL510 and !$B::C::pv_copy_on_grow and $cur) {
    $init->add(sprintf("SvPVX(sv_list[%d]) = $pvsym;", $svsect->index));
  }
  my ( $field );
  foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
    my $fsym = $io->$field();
    if ($$fsym) {
      $init->add( sprintf( "Io$field($sym) = (GV*)s\\_%x;", $$fsym ) );
      $fsym->save;
    }
  }
  foreach $field (qw(TOP_NAME FMT_NAME BOTTOM_NAME)) {
    my $fsym = $io->$field;
    $init->add(sprintf("Io$field($sym) = savepvn(%s, %u);",
                       cstring( $fsym ), length $fsym)) if $fsym;
  }
  $io->save_magic($fullname); # This handle the stash also (we need to inc the refcnt)
  if (!$PERL56 and $fullname ne 'main::DATA') { # PerlIO
    # deal with $x = *STDIN/STDOUT/STDERR{IO} and aliases
    my $perlio_func;
    # Note: all single-direction fp use IFP, just bi-directional pipes and
    # sockets use OFP also. But we need to set both, pp_print checks OFP.
    my $o = $io->object_2svref();
    eval "require ".ref($o).";";
    my $fd = $o->fileno();
    # use IO::Handle ();
    # my $fd = IO::Handle::fileno($o);
    my $i = 0;
    foreach (qw(stdin stdout stderr)) {
      if ($io->IsSTD($_) or (defined($fd) and $fd == -$i)) {
	$perlio_func = $_;
      }
      $i++;
    }
    if ($perlio_func) {
      $init->add("IoIFP(${sym}) = IoOFP(${sym}) = PerlIO_${perlio_func}();");
      #if ($fd < 0) { # fd=-1 signals an error
	# XXX print may fail at flush == EOF, wrong init-time?
      #}
    } else {
      my $iotype = $io->IoTYPE;
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
      if ($iotype eq "\c@" or $iotype eq " ") {
	warn sprintf("Ignore closed IO Handle %s %s (%d)\n",
		     cstring($iotype), $fullname, $ioflags)
	  if $debug{gv};
      }
      elsif ($iotype =~ /[a>]/) { # write-only
	warn "Warning: Write BEGIN-block $fullname to FileHandle $iotype \&$fd\n"
	  if $fd >= 3 or $verbose;
	my $mode = $iotype eq '>' ? 'w' : 'a';
	#$init->add( sprintf("IoIFP($sym) = IoOFP($sym) = PerlIO_openn(aTHX_ NULL,%s,%d,0,0,NULL,0,NULL);",
	#		    cstring($mode), $fd));
	$init->add(sprintf( "%sIoIFP($sym) = IoOFP($sym) = PerlIO_fdopen(%d, %s);%s",
			    $fd<3?'':'/*',$fd,cstring($mode),$fd<3?'':'*/'));
      }
      elsif ($iotype =~ /[<#\+]/) {
	warn "Warning: Read BEGIN-block $fullname from FileHandle $iotype \&$fd\n"
	  if $fd >= 3 or $verbose; # need to setup it up before
	$init->add("/* XXX WARNING: Read BEGIN-block $fullname from FileHandle */",
		   "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"r\");");
	if (my $tell = $o->tell()) {
	  $init->add("PerlIO_seek(IoIFP($sym), $tell, SEEK_SET);")
	}
      } else {
	# XXX We should really die here
	warn sprintf("ERROR: Unhandled BEGIN-block IO Handle %s\&%d (%d) from %s\n",
		     cstring($iotype), $fd, $ioflags, $fullname);
	$init->add("/* XXX WARNING: Unhandled BEGIN-block IO Handle ",
		   "IoTYPE=$iotype SYMBOL=$fullname, IoFLAGS=$ioflags */",
		   "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"$iotype\");");
      }
    }
  }

  #my $stash = $io->SvSTASH;
  #if ($$stash) {
  #  $init->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$stash ) );
    #  $stash->save;
    #  $init->add( sprintf( "IoSTASH(s\\_%x) = s\\_%x;", $$io, $$stash ) );
    #  warn sprintf( "done saving STASH 0x%x for IO 0x%x\n", $$stash, $$io )
    #    if $debug{gv};
  #}

  return $sym;
}

sub B::SV::save {
  my $sv = shift;

  # This is where we catch an honest-to-goodness Nullsv (which gets
  # blessed into B::SV explicitly) and any stray erroneous SVs.
  return 0 unless $$sv;
  warn sprintf( "cannot save that type of SV: %s (0x%x)\n", class($sv), $$sv );
}

sub output_all {
  my $init_name = shift;
  my $section;
  return if $check;

  my @sections = (
    $copsect,    $opsect,     $unopsect,  $binopsect, $logopsect, $condopsect,
    $listopsect, $pmopsect,   $svopsect,  $padopsect, $pvopsect,  $loopsect,
    $xpvsect,    $xpvavsect,  $xpvhvsect, $xpvcvsect, $padlistsect,
    $xpvivsect,  $xpvuvsect,  $xpvnvsect, $xpvmgsect, $xpvlvsect,
    $xrvsect,    $xpvbmsect,  $xpviosect, $svsect
  );
  printf "\t/* %s */", $symsect->comment if $symsect->comment and $verbose;
  $symsect->output( \*STDOUT, "#define %s\n" );
  print "\n";
  output_declarations();
  # XXX add debug versions with ix=opindex if $debug{flags}
  foreach $section (@sections) {
    my $lines = $section->index + 1;
    if ($lines) {
      my $name = $section->name;
      my $typename = $section->typename;
      print "Static $typename ${name}_list[$lines];\n";
    }
  }

  # hack for when Perl accesses PVX of GVs
  print 'Static const char emptystring[] = "\0";',"\n";
  # newXS for core XS needs a filename
  print 'Static const char xsfile[] = "universal.c";',"\n";
  if ($MULTI) {
    print "#define ptr_undef 0\n";
  } else {
    if ($] > 5.01903) {
      print "#define ptr_undef NULL\n";
    } else {
      print "#define ptr_undef &PL_sv_undef\n";
    }
    if ($PERL510) { # XXX const sv SIGSEGV
      print "#undef CopFILE_set\n";
      print "#define CopFILE_set(c,pv)  CopFILEGV_set((c), gv_fetchfile(pv))\n";
    }
  }
  # print "#define MyPVX(sv) ".($] < 5.010 ? "SvPVX(sv)" : "((sv)->sv_u.svu_pv)")."\n";
  if ($] < 5.008008 ) {
    print <<'EOT';
#ifndef SvSTASH_set
#  define SvSTASH_set(sv,hv) SvSTASH((sv)) = (hv)
#endif
#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif
EOT
  }
  if ($] < 5.008009 ) {
    print <<'EOT';
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv)     (++SvREFCNT(sv), (SV*)(sv))
#endif
EOT
  }
  if ($] < 5.013007 ) {
    print <<'EOT';
#ifndef CvSTASH_set
#  define CvSTASH_set(cv,hv) CvSTASH((cv)) = (hv)
#endif
EOT
  }
  if ($] < 5.013010 ) { # added with c43ae56ff9cd before 5.13.10 at 2011-01-21
    print <<'EOT';
#ifndef GvCV_set
#  define GvCV_set(gv,cv)   (GvCV(gv) = (cv))
#endif
#ifndef GvGP_set
#  define GvGP_set(gv,gp)   (GvGP(gv) = (gp))
#endif
EOT
  }
  printf "\t/* %s */\n", $decl->comment if $decl->comment and $verbose;
  $decl->output( \*STDOUT, "%s\n" );
  print "\n";
  foreach $section (@sections) {
    my $lines = $section->index + 1;
    if ($lines) {
      printf "Static %s %s_list[%u] = {\n", $section->typename, $section->name, $lines;
      printf "\t/* %s */\n", $section->comment
        if $section->comment and $verbose;
      $section->output( \*STDOUT, "\t{ %s }, /* %s_list[%d] %s */%s\n" );
      print "};\n\n";
    }
  }
  printf "\t/* %s */\n", $init->comment if $init->comment and $verbose;
  $init->output( \*STDOUT, "\t%s\n", $init_name );
  my $init2_name = 'perl_init2';
  printf "\t/* %s */\n", $init2->comment if $init2->comment and $verbose;
  $init2->output( \*STDOUT, "\t%s\n", $init2_name );
  if ($verbose) {
    my $caller = caller;
    warn $caller eq 'B::CC' ? B::CC::compile_stats() : compile_stats();
    warn "NULLOP count: $nullop_count\n";
  }
}

sub output_declarations {
  print <<'EOT';
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
  if ($PERL510 and $] < 5.012 and !$C99) {
    print <<'EOT0';
typedef struct svpv {
    void *	sv_any;
    U32		sv_refcnt;
    U32		sv_flags;
    union {
	char*   svu_pv;
	IV      svu_iv;
	UV      svu_uv;
	SV*     svu_rv;
	SV**    svu_array;
	HE**	svu_hash;
	GP*	svu_gp;
    } sv_u;
#ifdef DEBUG_LEAKING_SCALARS
    PERL_BITFIELD32 sv_debug_optype:9;
    PERL_BITFIELD32 sv_debug_inpad:1;
    PERL_BITFIELD32 sv_debug_cloned:1;
    PERL_BITFIELD32 sv_debug_line:16;
# if PERL_VERSION < 11
    U32		sv_debug_serial;	/* 5.10 only */
# endif
# if PERL_VERSION > 8
    char *	sv_debug_file;
# endif
#endif
} SVPV;
EOT0

  }
  if ($PERL512) {
    print "typedef struct p5rx RE;\n";
  }
  elsif ($PERL510) {
    print "typedef SV * RE;\n";
  }
  else {
    print "typedef char * RE;\n";
  }
  if ($] == 5.010000) {
    print "#ifndef RX_EXTFLAGS\n";
    print "# define RX_EXTFLAGS(rx) ((rx)->extflags)\n";
    print "#endif\n";
  }
  print "Static GV *gv_list[$gv_index];\n" if $gv_index;

  # Need fresh re-hash of strtab. share_hek does not allow hash = 0
  if ( $PERL510 ) {
    print <<'_EOT0';
HEK *my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );
#undef share_hek
#define share_hek(str, len, hash) my_share_hek( aTHX_ str, len, hash );
_EOT0

  }
  print "\n";
}

sub output_boilerplate {
  # Store the sv_list index in sv_debug_file when debugging
  print "#define DEBUG_LEAKING_SCALARS 1\n" if $debug{flags} and $DEBUG_LEAKING_SCALARS;
  if ($B::C::Flags::have_independent_comalloc) {
    print <<'_EOT1';
#ifdef NEED_MALLOC_283
# include "malloc-2.8.3.h"
#endif
_EOT1

  }
  print <<'_EOT2';
#define PERL_CORE
#include "EXTERN.h"
#include "perl.h"
#ifdef NO_DYNAMIC_LOADING
# undef USE_DYNAMIC_LOADING
#endif
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

  if ($] < 5.008008) {
    print "#define GvSVn(s) GvSV(s)\n";
  }
  if ($B::C::av_init2 and $B::C::Flags::use_declare_independent_comalloc) {
    print "void** dlindependent_comalloc(size_t, size_t*, void**);\n";
  }
  if ($B::C::av_init2) {
    my $last = $xpvavsect->index;
    my $size = $last + 1;
    if ($last) {
      $decl->add("Static void* avchunks[$size];");
      $decl->add("Static size_t avsizes[$size] = ");
      my $ptrsize = $Config{ptrsize};
      my $acc = "";
      for (0..$last) {
	if ($xpvav_sizes[$_] > 0) {
	  $acc .= $xpvav_sizes[$_] * $ptrsize;
	} else {
	  $acc .= 3 * $ptrsize;
	}
	$acc .= "," if $_ != $last;
	$acc .= "\n\t" unless ($_+1) % 30;
      }
      $decl->add("\t{$acc};");
      $init->add_initav("if (!independent_comalloc( $size, avsizes, avchunks ))");
      $init->add_initav("    Perl_die(aTHX_ \"panic: AV alloc failed\");");
    }
  }
}

sub init_op_addr {
  my ( $op_type, $num ) = @_;
  my $op_list = $op_type . "_list";

  $init->add( split /\n/, <<_EOT3 );
{
    register int i;
    for( i = 0; i < ${num}; ++i ) {
        ${op_list}\[i].op_ppaddr = PL_ppaddr[PTR2IV(${op_list}\[i].op_ppaddr)];
    }
}
_EOT3

}

sub init_op_warn {
  my ( $op_type, $num ) = @_;
  my $op_list = $op_type . "_list";

  # for reasons beyond imagination, MSVC5 considers pWARN_ALL non-const
  $init->add( split /\n/, <<_EOT4 );
{
    register int i;
    for( i = 0; i < ${num}; ++i )
    {
        switch( PTR2IV(${op_list}\[i].cop_warnings) )
        {
        case 1:
            ${op_list}\[i].cop_warnings = pWARN_ALL;
            break;
        case 2:
            ${op_list}\[i].cop_warnings = pWARN_NONE;
            break;
        case 3:
            ${op_list}\[i].cop_warnings = pWARN_STD;
            break;
        default:
            break;
        }
    }
}
_EOT4

}

sub output_main_rest {

  if ( $PERL510 ) {
    print <<'_EOT5';
HEK *
my_share_hek( pTHX_ const char *str, I32 len, register U32 hash ) {
    if (!hash) {
      PERL_HASH(hash, str, abs(len));
    }
    return Perl_share_hek(aTHX_ str, len, hash);
}

_EOT5
  }

  # -fno-destruct only >5.8
  if ( !$B::C::destruct and $^O ne 'MSWin32') {
    print <<'_EOT6';
int fast_perl_destruct( PerlInterpreter *my_perl );

#ifndef dVAR
# ifdef PERL_GLOBAL_STRUCT
#  define dVAR		pVAR    = (struct perl_vars*)PERL_GET_VARS()
# else
#  define dVAR		dNOOP
# endif
#endif

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
	    if (destruct_level < i)
		destruct_level = i;
	}
    }
#endif

    if (PL_exit_flags & PERL_EXIT_DESTRUCT_END) {
        dJMPENV;
        int x = 0;

        JMPENV_PUSH(x);
	PERL_UNUSED_VAR(x);
        if (PL_endav && !PL_minus_c)
            call_list(PL_scopestack_ix, PL_endav);
        JMPENV_POP;
    }
    LEAVE;
    FREETMPS;
    assert(PL_scopestack_ix == 0);

    /* Need to flush since END blocks can produce output */
    my_fflush_all();
#if PERL_VERSION >= 11 && defined(PERL_PHASE_DESTRUCT)
    PL_phase = PERL_PHASE_DESTRUCT;
#endif

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
#if defined(PERLIO_LAYERS)
    PerlIO_cleanup(aTHX);
#endif
    return 0;
}
_EOT6

  }
  # special COW handling for 5.10 because of S_unshare_hek_or_pvn limitations
  # XXX This fails in S_doeval SAVEFREEOP(PL_eval_root): test 15
  elsif ( $PERL510 and (@B::C::static_free or $free->index > -1)) {
    print <<'_EOT7';
int my_perl_destruct( PerlInterpreter *my_perl );
int my_perl_destruct( PerlInterpreter *my_perl ) {
    /* set all our static pv and hek to &PL_sv_undef so perl_destruct() will not cry */
_EOT7

    for (0 .. $#B::C::static_free) {
      # set the sv/xpv to &PL_sv_undef, not the pv itself. 
      # If set to NULL pad_undef will fail in SvPVX_const(namesv) == '&'
      # XXX Another idea >5.10 is SvFLAGS(pv) = SVTYPEMASK
      my $s = $B::C::static_free[$_];
      if ($s =~ /^sv_list\[\d+\]\./) { # pv directly (unused)
	print "    $s = NULL;\n";
      } elsif ($s =~ /^sv_list/) {
       print "    SvLEN(&$s) = 0;\n";
       print "    SvPV_set(&$s, (char*)&PL_sv_undef);\n";
      } elsif ($s =~ /^&sv_list/) {
       print "    SvLEN($s) = 0;\n";
       print "    SvPV_set($s, (char*)&PL_sv_undef);\n";
      } elsif ($s =~ /^cop_list/) {
	if ($ITHREADS or !$MULTI) {
	  print "    CopFILE_set(&$s, NULL);";
        }
        if ($] >= 5.017) {
          print " CopSTASH_set(&$s, NULL);\n";
        } elsif ($] < 5.016 and $ITHREADS) {
          print " CopSTASHPV(&$s) = NULL;\n";
        } elsif ($] < 5.016 and !$ITHREADS) {
          print " CopSTASH(&$s) = NULL;\n";
        } else { # 5.16 experiment
          print " CopSTASHPV_set(&$s, NULL, 0);\n";
        }
      } elsif ($s ne 'ptr_undef') {
	warn("unknown static_free: $s at index $_");
      }
    }
    $free->output( \*STDOUT, "%s\n" );
    print "\n    return perl_destruct( my_perl );\n}\n\n";
  }

  print <<'_EOT8';

/* yanked from perl.c */
static void
xs_init(pTHX)
{
	char *file = __FILE__;
	dTARG; dSP;
_EOT8

  #if ($staticxs) { #FIXME!
  #  print "\n#undef USE_DYNAMIC_LOADING
  #}
  print "\n#ifdef USE_DYNAMIC_LOADING";
  print "\n\tnewXS(\"DynaLoader::boot_DynaLoader\", boot_DynaLoader, file);";
  print "\n#endif\n";

  delete $xsub{'DynaLoader'};
  delete $xsub{'UNIVERSAL'};
  print("/* XS bootstrapping code*/\n");
  print("\tSAVETMPS;\n");
  print("\ttarg=sv_newmortal();\n");
  foreach my $stashname ( keys %static_ext ) {
    my $stashxsub = $stashname;
    $stashxsub =~ s/::/__/g;
    #if ($stashxsub =~ m/\/(\w+)\.\w+$/ {$stashxsub = $1;}
    # cygwin has Win32CORE in static_ext
    warn "bootstrapping static $stashname added to xs_init\n" if $verbose;
    print "\tnewXS(\"$stashname\::bootstrap\", boot_$stashxsub, file);\n";
  }
  print "#ifdef USE_DYNAMIC_LOADING\n";
  print "\tPUSHMARK(sp);\n";
  printf "\tXPUSHp(\"DynaLoader\", %d);\n", length("DynaLoader");
  print "\tPUTBACK;\n";
  warn "bootstrapping DynaLoader added to xs_init\n" if $verbose;
  print "\tboot_DynaLoader(aTHX_ NULL);\n";
  print "\tSPAGAIN;\n";
  print "#endif\n";

  # my %core = map{$_ => 1} core_packages();
  foreach my $stashname ( keys %xsub ) {
    my $incpack = inc_packname($stashname);
    unless (exists $INC{$incpack}) { # skip deleted packages
      warn "skip xs_init for $stashname !\$INC{$incpack}\n" if $debug{pkg};
      delete $xsub{$stashname} unless $static_ext{$stashname};
      next;
    }
    if ( $xsub{$stashname} !~ m/^Dynamic/ and !$static_ext{$stashname}) {
      my $stashxsub = $stashname;
      warn "bootstrapping $stashname added to xs_init\n" if $verbose;
      $stashxsub =~ s/::/__/g;
      print "\tPUSHMARK(sp);\n";
      printf "\tXPUSHp(\"%s\", %d);\n", # "::bootstrap" gets appended, TODO
	0 ? "strdup($stashname)" : $stashname, length($stashname);
      print "\tPUTBACK;\n";
      print "\tboot_$stashxsub(aTHX_ NULL);\n";
      print "\tSPAGAIN;\n";
    }
  }
  print "\tFREETMPS;\n/* end XS bootstrapping code */\n";
  print "}\n";

  print <<'_EOT9';

static void
dl_init(pTHX)
{
	char *file = __FILE__;
_EOT9

  my ($dl, $xs);
  my @dl_modules = @DynaLoader::dl_modules;
  my @PERLMODS = split(/\,/, $ENV{'PERLMODS'}) if $ENV{'PERLMODS'}; # from cpanel
  foreach my $perlmod (@PERLMODS) {
    warn "Extra module ${perlmod}\n";
    push @dl_modules, $perlmod unless grep { $_ ne $perlmod } @dl_modules;
  }
  # filter out unused dynaloaded B modules, used within the compiler only.
  for my $c (qw(B B::C)) {
    if (!$xsub{$c} and !$include_package{$c}) {
      # (hopefully, see test 103)
      warn "no dl_init for $c, not marked\n" if $verbose and !$skip_package{$c};
      # RT81332 pollute
      @dl_modules = grep { $_ ne $c } @dl_modules;
      # XXX Be sure to store the new @dl_modules
    }
  }
  for my $c (keys %skip_package) {
    warn "no dl_init for $c, skipped\n" if $verbose and $xsub{$c};
    delete $xsub{$c};
    $include_package{$c} = undef;
    @dl_modules = grep { $_ ne $c } @dl_modules;
  }
  @DynaLoader::dl_modules = @dl_modules;
  warn "\@dl_modules: ",join(" ",@dl_modules),"\n" if $verbose;
  foreach my $stashname (@dl_modules) {
    my $incpack = inc_packname($stashname);
    #unless (exists $INC{$incpack}) { # skip deleted packages
    #  warn "XXX skip dl_init for $stashname !\$INC{$incpack}\n" if $debug{pkg};
    #  delete $xsub{$stashname};
    #  @dl_modules = grep { $_ ne $stashname } @dl_modules;
    #}
    if ($stashname eq 'attributes' and $] > 5.011) {
      $xsub{$stashname} = 'Dynamic-' . $INC{'attributes.pm'};
    }
    if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/^Dynamic/ ) {
      # XSLoader.pm: $modlibname = (caller())[1]; needs a path at caller[1] to find auto,
      # otherwise we only have -e
      $xs++ if $xsub{$stashname} ne 'Dynamic';
      $dl++;
    }
  }
  warn "\%xsub: ",join(" ",keys %xsub),"\n" if $verbose and $debug{cv};
  force_saving_xsloader() if $use_xsloader and ($dl or $xs);
  if ($dl) {
    if (grep {$_ eq 'attributes'} @dl_modules) {
      # enforce attributes at the front of dl_init, #259
      @dl_modules = grep { $_ ne 'attributes' } @dl_modules;
      unshift @dl_modules, 'attributes';
    }
    if ($staticxs) {open( XS, ">", $outfile.".lst" ) or return "$outfile.lst: $!\n"}
    print "\tdTARG; dSP;\n";
    print "/* DynaLoader bootstrapping */\n";
    print "\tENTER;\n";
    print "\t++cxstack_ix; cxstack[cxstack_ix].blk_oldcop = PL_curcop;\n" if $xs;
    print "\t/* assert(cxstack_ix == 0); */\n" if $xs;
    print "\tSAVETMPS;\n";
    print "\ttarg = sv_newmortal();\n" if $] < 5.008008;
    foreach my $stashname (@dl_modules) {
      if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/^Dynamic/ ) {
	$use_xsloader = 1;
        print "\n\tPUSHMARK(sp);\n";
	# XXX -O1 or -O2 needs XPUSHs with dynamic pv
	printf "\t%s(%s, %d);\n", # "::bootstrap" gets appended
	  $] < 5.008008 ? "XPUSHp" : "mXPUSHp", "\"$stashname\"", length($stashname);
        if ( $xsub{$stashname} eq 'Dynamic' ) {
          warn "dl_init $stashname\n" if $verbose;
	  print "#ifdef USE_DYNAMIC_LOADING\n";
	  print "\tPUTBACK;\n";
          print qq/\tcall_method("DynaLoader::bootstrap_inherit", G_VOID|G_DISCARD);\n/;
        }
        else { # XS: need to fix cx for caller[1] to find auto/...
	  my ($stashfile) = $xsub{$stashname} =~ /^Dynamic-(.+)$/;
	  print "#ifdef USE_DYNAMIC_LOADING\n";
	  if ($] >= 5.015003) {
	    printf "\tmXPUSHp(\"%s\", %d);\n", $stashfile, length($stashfile) if $stashfile;
	  }
	  print "\tPUTBACK;\n";
	  warn "bootstrapping $stashname added to XSLoader dl_init\n" if $verbose;
	  # XSLoader has the 2nd insanest API in whole Perl, right after make_warnings_object()
	  # 5.15.3 workaround for [perl #101336]
	  if ($] >= 5.015003) {
	    no strict 'refs';
	    unless (grep /^DynaLoader$/, @{$stashname."::ISA"}) {
	      push @{$stashname."::ISA"}, 'DynaLoader';
	      B::svref_2object( \@{$stashname."::ISA"} ) ->save;
	    }
	    warn '@',$stashname,"::ISA=(",join(",",@{$stashname."::ISA"}),")\n" if $debug{gv};
	    print qq/\tcall_pv("XSLoader::load_file", G_VOID|G_DISCARD);\n/;
	  } else {
	    printf qq/\tCopFILE_set(cxstack[cxstack_ix].blk_oldcop, "%s");\n/,
	      $stashfile if $stashfile;
	    print qq/\tcall_pv("XSLoader::load", G_VOID|G_DISCARD);\n/;
	  }
        }
        if ($staticxs) {
          my ($laststash) = $stashname =~ /::([^:]+)$/;
          my $path = $stashname;
          $path =~ s/::/\//g;
          $path .= "/" if $path; # can be empty
          $laststash = $stashname unless $laststash; # without ::
          my $sofile = "auto/" . $path . $laststash . '\.' . $Config{dlext};
          #warn "staticxs search $sofile in @DynaLoader::dl_shared_objects\n"
          #  if $verbose and $debug{pkg};
          for (@DynaLoader::dl_shared_objects) {
            if (m{^(.+/)$sofile$}) {
              print XS $stashname,"\t",$_,"\n";
              warn "staticxs $stashname\t$_\n" if $verbose;
              $sofile = '';
              last;
            }
          }
          print XS $stashname,"\n" if $sofile; # error case
          warn "staticxs $stashname\t - $sofile not loaded\n" if $sofile and $verbose;
        }
        print "#else\n";
        print "\tPUTBACK;\n";
        my $stashxsub = $stashname;
        $stashxsub =~ s/::/__/g;
        if ($staticxs) {
	  # CvSTASH(CvGV(cv)) is invalid without (issue 86)
	  print "\tboot_$stashxsub(aTHX_ get_cv(\"$stashname\::bootstrap\", GV_ADD));\n";
	} else {
	  print "\tboot_$stashxsub(aTHX_ NULL);\n";
	}
        print "#endif\n";
        print "\tSPAGAIN;\n";
        #print "\tPUTBACK;\n";
      } else {
        warn "no dl_init for $stashname, ".
          (!$xsub{$stashname} ? "not marked\n" : "marked as $xsub{$stashname}\n")
	    if $verbose;
	# XXX Too late. This might fool run-time DynaLoading.
	# We really should remove this via init from @DynaLoader::dl_modules
	@DynaLoader::dl_modules = grep { $_ ne $stashname } @DynaLoader::dl_modules;

      }
    }
    print "\tFREETMPS;\n";
    print "\tcxstack_ix--;\n" if $xs;  	# i.e. POPBLOCK
    print "\tLEAVE;\n";
    print "/* end DynaLoader bootstrapping */\n";
    close XS if $staticxs;
  }
  print "}\n";
}

sub output_main {
  if (!defined($module)) {
    print <<'_EOT10';

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
    GV* tmpgv;
    SV* tmpsv;
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
    if ($ITHREADS and $] > 5.007) {
      # XXX init free elems!
      my $pad_len = regex_padav->FILL;    # first is an empty avref
      print <<_EOT11;
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
    print "    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;\n" unless $PERL56;
    if (!$PERL510) {
      print <<'_EOT12';
#if defined(CSH)
    if (!PL_cshlen)
      PL_cshlen = strlen(PL_cshname);
#endif
_EOT12
    }

    # XXX With -e "" we need to fake parse_body() scriptname = BIT_BUCKET
    print <<'_EOT13';
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
    if (!$PERL56 and ${^TAINT}) {
      print <<'_EOT14';
    fakeargv[options_count] = "-T";
    ++options_count;
_EOT14

    }
    print <<'_EOT15';
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

    if ($use_perl_script_name) {
      my $dollar_0 = cstring($0);
      print sprintf(qq{    sv_setpv_mg(get_sv("0", GV_ADD|GV_NOTQUAL), %s);\n}, $dollar_0);
      print sprintf(qq{    CopFILE_set(&PL_compiling, %s);\n}, $dollar_0);
    }
    else {
      print qq{    sv_setpv_mg(get_sv("0", GV_ADD|GV_NOTQUAL), argv[0]);\n};
      print qq{    CopFILE_set(&PL_compiling, argv[0]);\n};
    }
    # more global vars
    print "    PL_hints = $^H;\n" if $^H;
    print "    PL_unicode = ${^UNICODE};\n" if ${^UNICODE};
    # nomg
    print sprintf(qq{    sv_setpv(get_sv(";", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($;)) if $; ne "\34";
    print sprintf(qq{    sv_setpv(get_sv("\"", GV_NOTQUAL), %s);\n}, cstring($")) if $" ne " ";
    # global IO vars
    print sprintf(qq{    sv_setpv_mg(GvSVn(PL_ofsgv), %s);\n}, cstring($,)) if $,;
    print sprintf(qq{    sv_setpv_mg(get_sv("/", GV_NOTQUAL), %s);\n}, cstring($/)) if $/ ne "\n"; #RS
    print sprintf(qq{    sv_setpv_mg(get_sv("\\", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($\)) if $\; #ORS
    print         qq{    sv_setiv_mg(get_sv("|", GV_ADD|GV_NOTQUAL), $|);\n} if $|; #OUTPUT_AUTOFLUSH
    # global format vars
    print sprintf(qq{    sv_setpv_mg(get_sv("^A", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($^A)) if $^A; #ACCUMULATOR
    print sprintf(qq{    sv_setpv_mg(get_sv("^L", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($^L)) if $^L ne "\f"; #FORMFEED
    print sprintf(qq{    sv_setpv_mg(get_sv(":", GV_ADD|GV_NOTQUAL), %s);\n}, cstring($:)) if $: ne " \n-"; #LINE_BREAK_CHARACTERS
    print sprintf(qq/    sv_setpv_mg(get_sv("^", GV_ADD|GV_NOTQUAL), savepvn(%s, %u));\n/, cstring($^), length($^))
      if $^ ne "STDOUT_TOP";
    print sprintf(qq/    sv_setpv_mg(get_sv("~", GV_ADD|GV_NOTQUAL), savepvn(%s, %u));\n/, cstring($~), length($~))
      if $~ ne "STDOUT";
    print         qq{    sv_setiv_mg(get_sv("%", GV_ADD|GV_NOTQUAL), $%);\n} if $%; #PAGE_NUMBER
    print         qq{    sv_setiv_mg(get_sv("-", GV_ADD|GV_NOTQUAL), $-);\n} unless ($- == 0 or $- == 60); #LINES_LEFT
    print         qq{    sv_setiv_mg(get_sv("=", GV_ADD|GV_NOTQUAL), $=);\n} if $= != 60; #LINES_PER_PAGE

    # deprecated global vars
    print qq{    {SV* s = get_sv("[",GV_NOTQUAL); sv_setiv(s, $[); mg_set(s);}\n} if $[; #ARRAY_BASE
    if ($] < 5.010) { # OFMT and multiline matching
      eval q[
            print sprintf(qq{    sv_setpv(GvSVn(gv_fetchpv("\$#", GV_ADD|GV_NOTQUAL, SVt_PV)), %s);\n},
                          cstring($#)) if $#;
            print sprintf(qq{    sv_setiv(GvSVn(gv_fetchpv("\$*", GV_ADD|GV_NOTQUAL, SVt_IV)), %d);\n}, $*) if $*;
           ];
    }

    print sprintf(qq{    sv_setpv_mg(get_sv("\030", GV_ADD|GV_NOTQUAL), %s); /* \$^X */\n}, cstring($^X));
    print <<"EOT";
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

    print $B::C::eval_pvs if $B::C::eval_pvs;
    print "    exitstatus = perl_run( my_perl );\n";

    if ( !$B::C::destruct and $^O ne 'MSWin32' ) {
      warn "fast_perl_destruct (-fno-destruct)\n" if $verbose;
      print "    fast_perl_destruct( my_perl );\n";
    } elsif ( $PERL510 and (@B::C::static_free or $free->index > -1) ) {
      warn "my_perl_destruct static strings\n" if $verbose;
      print "    my_perl_destruct( my_perl );\n";
    } elsif ( $] >= 5.007003 ) {
      print "    perl_destruct( my_perl );\n";
    }
    # XXX endav is called via call_list and so it is freed right after usage. Setting dirty here is useless
    #print "    PL_dirty = 1;\n" unless $B::C::pv_copy_on_grow; # protect against pad undef in END block
    print <<'EOT1';
    perl_free( my_perl );

    PERL_SYS_TERM();

    exit( exitstatus );
}
EOT1

  } # module
}

sub dump_symtable {
  # For debugging
  my ( $sym, $val );
  warn "----Symbol table:\n";
  #while ( ( $sym, $val ) = each %symtable )
  for $sym (keys %symtable) {
    $val = $symtable{$sym};
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

sub Dummy_BootStrap { }

#ignore nullified cv
sub B::SPECIAL::savecv {}

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
  return if ( $package eq 'main' and
	      $name =~ /^([^_A-Za-z0-9].*|_\<.*|INC|ARGV|SIG|ENV|BEGIN|main::|!)$/ );

  warn sprintf( "Used GV \*$fullname 0x%x\n", $$gv ) if $debug{gv};
  return unless ( $$cv || $$av || $$sv || $$hv || $gv->IO || $gv->FORM );
  if ($$cv and $name eq 'bootstrap' and $cv->XSUB) {
    #return $cv->save($fullname);
    warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
    return;
  }
  if ( $$cv and in_static_core($package, $name) and $cv->XSUB ) {
    warn("Skip internal XS $fullname\n") if $debug{gv};
    return;
  }
  if ($package eq 'B::C') {
    warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
    return;
  }
  if ($fullname =~ /^(bytes|utf8)::AUTOLOAD$/) {
    $gv = force_heavy($package);
  }
  # we should not delete already saved packages
  $saved{$package}++;
  return if $fullname eq 'B::walksymtable'; # XXX fails and should not be needed
  # Config is marked on any Config symbol. TIE and DESTROY are exceptions,
  # used by the compiler itself
  if ($name eq 'Config') {
    mark_package('Config', 1) if !$include_package{'Config'};
  }
  warn sprintf( "Saving GV \*$fullname 0x%x\n", $$gv ) if $debug{gv};
  $gv->save($fullname);
}

sub walk_syms {
  my $package = shift;
  no strict 'refs';
  walksymtable( \%{$package.'::'}, "savecv",
                sub { should_save( $_[0] ); return 1 },
                $package.'::' );
}

# simplified walk_syms
# needed to populate @B::C::Flags::deps from Makefile.PL from within this %INC context
sub walk_stashes {
  my ($symref, $prefix) = @_;
  no strict 'refs';
  $prefix = '' unless defined $prefix;
  foreach my $sym ( sort keys %$symref ) {
    if ($sym =~ /::$/) {
      $sym = $prefix . $sym;
      $B::C::deps{ substr($sym,0,-2) }++;
      if ($sym ne "main::" && $sym ne "<none>::") {
        walk_stashes(\%$sym, $sym);
      }
    }
  }
}

sub collect_deps {
  %B::C::deps = ();
  walk_stashes(\%main::);
  print join " ",(sort keys %B::C::deps);
}

sub mark_package {
  my $package = shift;
  my $force = shift;
  $force = 0 if $] < 5.010;
  return if $skip_package{$package}; # or $package =~ /^B::C(C?)::/;
  if ( !$include_package{$package} or $force ) {
    no strict 'refs';
    my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
    mark_package('IO') if grep { $package eq $_ } @IO;
    $use_xsloader = 1 if $package =~ /^B|Carp$/; # to help CC a bit (49)
    # i.e. if force
    if (exists $include_package{$package}
	and !$include_package{$package}
	and $savINC{inc_packname($package)})
    {
      warn sprintf("$package previously deleted, save now%s\n",
		   $force?" (forced)":"") if $verbose;
      # $include_package{$package} = 1;
      add_hashINC( $package );
      walk_syms( $package );
    } else {
      warn sprintf("mark $package%s\n", $force?" (forced)":"")
	if !$include_package{$package} and $verbose and $debug{pkg};
      $include_package{$package} = 1;
      push_package($package) if $] < 5.010;
    }
    my @isa = $PERL510 ? @{mro::get_linear_isa($package)} : @{ $package . '::ISA' };
    if ( @isa ) {
      # XXX walking the ISA is often not enough.
      # we should really check all new packages since the last full scan.
      foreach my $isa ( @isa ) {
	next if $isa eq $package;
        if ( $isa eq 'DynaLoader' ) {
          unless ( defined( &{ $package . '::bootstrap' } ) ) {
            warn "Forcing bootstrap of $package\n" if $verbose;
            eval { $package->bootstrap };
          }
        }
	if ( !$include_package{$isa} and !$skip_package{$isa} ) {
	  warn "$isa saved (it is in $package\'s \@ISA)\n" if $verbose;
	  if (exists $include_package{$isa} ) {
	    warn "$isa previously deleted, save now\n" if $verbose; # e.g. Sub::Name
	    mark_package($isa);
            walk_syms($isa);
          } else {
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
  my ($stashname, $cvname) = @_;
  if ($stashname eq 'UNIVERSAL') {
    return $cvname =~ /^(isa|can|DOES|VERSION)$/;
  }
  %static_core_pkg = map {$_ => 1} static_core_packages()
    unless %static_core_pkg;
  return 1 if $static_core_pkg{$stashname};
  if ($stashname eq 'mro') {
    return $cvname eq 'method_changed_in';
  }
  if ($stashname eq 're') {
    return $cvname =~ /^(is_regexp|regname|regnames|regnames_count|regexp_pattern)$/;;
  }
  if ($stashname eq 'PerlIO') {
    return $cvname eq 'get_layers';
  }
  if ($stashname eq 'PerlIO::Layer') {
    return $cvname =~ /^(find|NoWarnings)$/;
  }
  return 0;
}

# XS modules in CORE. Reserved namespaces.
# Note: mro,re,UNIVERSAL have both, static core and dynamic/static XS
# version has an external ::vxs
sub static_core_packages {
  my @pkg  = qw(Internals utf8 UNIVERSAL);
  push @pkg, 'attributes'             if $] <  5.011; # partially static and dynamic
  push @pkg, 'version'                if $] >= 5.010; # partially static and dynamic
  push @pkg, 'Tie::Hash::NamedCapture' if $] < 5.014; # dynamic since 5.14
  #push @pkg, 'DynaLoader'	      if $Config{usedl};
  # Win32CORE only in official cygwin pkg. And it needs to be bootstrapped,
  # handled by static_ext.
  push @pkg, 'Cygwin'		if $^O eq 'cygwin';
  push @pkg, 'NetWare'		if $^O eq 'NetWare';
  push @pkg, 'OS2'		if $^O eq 'os2';
  push @pkg, qw(VMS VMS::Filespec vmsish) if $^O eq 'VMS';
  #push @pkg, 'PerlIO' if $] >= 5.008006; # get_layers only
  push @pkg, split(/ /,$Config{static_ext});
  return @pkg;
}

sub skip_pkg {
  my $package = shift;
  if ( $package =~ /^(mro)$/
       or $package =~ /^(main::)?(B|Internals|O)::/
       or $package =~ /::::/
       or index($package, " ") != -1 # XXX skip invalid package names
       or index($package, "(") != -1 # XXX this causes the compiler to abort
       or index($package, ")") != -1 # XXX this causes the compiler to abort
       or ($DB::deep and $package =~ /^(DB|Term::ReadLine)/)) {
    return 1;
  }
  return 0;
}

# Do not delete/ignore packages which were brought in from the script,
# i.e. not defined in B::C or O. Just to be on the safe side.
sub can_delete {
  my $pkg = shift;
  if (exists $all_bc_deps{$pkg} and $B::C::can_delete_pkg) { return 1 };
  return undef;
}

sub should_save {
  no strict qw(vars refs);
  my $package = shift;
  $package =~ s/::$//;
  return $include_package{$package} = 0
    if ( $package =~ /::::/ );    # skip ::::ISA::CACHE etc.
  warn "Considering $package\n" if $debug{pkg}; #$include_package{$package}
  return if index($package, " ") != -1; # XXX skip invalid package names
  return if index($package, "(") != -1; # XXX this causes the compiler to abort
  return if index($package, ")") != -1; # XXX this causes the compiler to abort
  # core static mro has exactly one member, ext/mro has more
  if ($package eq 'mro') {
    if (keys %{mro::} == 1) { # core or ext?
      warn "ext/mro not loaded - skip\n" if $debug{pkg};
      return;
    } else {
      warn "ext/mro already loaded\n" if $debug{pkg};
    }
  }
  if ($package eq 'attributes' and $] > 5.011 and grep /attributes/, @DynaLoader::dl_modules) {
    mark_package($package, 1);
    return 1;
  }
  foreach my $u ( grep( $include_package{$_}, keys %include_package ) )
  {
    # If this package is a prefix to something we are saving, traverse it
    # but do not mark it for saving if it is not already
    # e.g. to get to Getopt::Long we need to traverse Getopt but need
    # not save Getopt
    my $p = $package;
    $p =~ s/(\W)/\\$1/g;
    return 1 if ( $u =~ /^$p\:\:/ );
  }
  # Needed since 5.12.2: Check already if deleted
  if ( $] > 5.015001 and
       !exists $INC{inc_packname($package)} and $savINC{inc_packname($package)} ) {
    $include_package{$package} = 0;
    warn "Cached $package not in \%INC, already deleted (early)\n" if $debug{pkg};
    return 0;
  }
  return 1 if $package =~ /^DynaLoader|XSLoader$/ and $use_xsloader;
  # If this package is in the same file as main:: or our source, save it. (72, 73)
  if ($mainfile) {
    # Find the first cv in this package for CV->FILE
    no strict 'refs';
    for my $sym (keys %{$package.'::'}) {
      if (defined &{$package.'::'.$sym}) {
	# compare cv->FILE to $mainfile
	my $cv = svref_2object(\&{$package.'::'.$sym});
	if ($cv and $cv->FILE) {
	  $include_package{$package} = 1 if $mainfile eq $cv->FILE;
	  last;
	}
      }
    }
  }
  # add overloaded but otherwise empty packages (#172)
  if ($savINC{'overload.pm'} and exists ${$package.'::'}{OVERLOAD} and exists ${$package.'::'}{'()'}) {
    mark_package($package, 1);
    mark_package('overload', 1);
    return 1;
  }
  # Omit the packages which we use (and which cause grief
  # because of fancy "goto &$AUTOLOAD" stuff).
  # XXX Surely there must be a nicer way to do this.
  if (skip_pkg($package) and can_delete($package) ) {
    delete_unsaved_hashINC($package);
    return; # $include_package{$package} = 0;
  }

  if ( exists $include_package{$package} ) {
    if (! exists $all_bc_deps{$package}) {
      $include_package{$package} = 1;
      warn "Cached new $package is kept\n" if $debug{pkg};
    }
    elsif (!$include_package{$package}) {
      delete_unsaved_hashINC($package);
      warn "Cached $package is already deleted\n" if $debug{pkg};
    } else {
      warn "Cached $package is cached\n" if $debug{pkg};
    }
    return $include_package{$package};
  }

  # Now see if current package looks like an OO class. This is probably too strong.
  foreach my $m (qw(new DESTROY TIESCALAR TIEARRAY TIEHASH TIEHANDLE)) {
    # 5.10 introduced version and Regexp::DESTROY, which we dont want automatically.
    # XXX TODO This logic here is wrong and unstable. Fixes lead to more failures.
    # The walker deserves a rewrite.
    if ( UNIVERSAL::can( $package, $m ) and $package !~ /^(B::C|version|Regexp|utf8|SelectSaver)$/ ) {
      next if $package eq 'utf8' and $m eq 'DESTROY'; # utf8::DESTROY is empty
      # we load Errno by ourself to avoid double Config warnings [perl #]
      next if $package eq 'Errno' and $m eq 'TIEHASH';
      # XXX Config and FileHandle should not just return. If unneeded skip em.
      return 0 if $package eq 'Config' and $m =~ /DESTROY|TIEHASH/; # Config detected in GV
      return 0 if $package eq 'FileHandle' and $m eq 'new';
      warn "$package has method $m: saving package\n" if $debug{pkg};
      return mark_package($package);
    }
  }
  if ($package !~ /^PerlIO/ and can_delete($package)) {
    delete_unsaved_hashINC($package);
  }
  if (can_delete($package)) {
    warn "Delete $package\n" if $debug{pkg};
    return $include_package{$package} = 0;
  } elsif (! exists $all_bc_deps{$package}) { # and not in @deps
    warn "Keep $package\n" if $debug{pkg};
    return $include_package{$package} = 1;
  } else { # in @deps
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
  if ($package =~ /^(Config_git\.pl|Config_heavy.pl)$/) {
    return 'Config';
  }
  if ($package eq 'utf8_heavy.pl') {
    return 'utf8';
  }
  $package =~ s/\.p[lm]$//;
  return $package;
}

sub delete_unsaved_hashINC {
  my $package = shift;
  my $incpack = inc_packname($package);
  # Not already saved package, so it is not loaded again at run-time.
  return if $saved{$package};
  return if $package =~ /^DynaLoader|XSLoader$/
    and defined $use_xsloader
    and $use_xsloader == 0;
  return if $^O eq 'MSWin32' and $package =~ /^Carp|File::Basename$/;
  $include_package{$package} = 0;
  if ($INC{$incpack}) {
    warn "Deleting $package from \%INC\n" if $debug{pkg};
    $savINC{$incpack} = $INC{$incpack} if !$savINC{$incpack};
    $INC{$incpack} = undef;
    delete $INC{$incpack};
  }
}

sub add_hashINC {
  my $package = shift;
  my $incpack = inc_packname($package);
  $include_package{$package} = 1;
  unless ($INC{$incpack}) {
    if ($savINC{$incpack}) {
      warn "Adding $package to \%INC (again)\n" if $debug{pkg};
      $INC{$incpack} = $savINC{$incpack};
      # need to check xsub
      $use_xsloader = 1 if $package =~ /^DynaLoader|XSLoader$/;
    } else {
      warn "Adding $package to \%INC\n" if $debug{pkg};
      for (@INC) {
        my $p = $_.'/'.$incpack;
        if (-e $p) { $INC{$incpack} = $p; last; }
      }
      $INC{$incpack} = $incpack unless $INC{$incpack};
    }
  }
}

sub walkpackages {
  my ( $symref, $recurse, $prefix ) = @_;
  no strict 'vars';
  my $sym;
  $prefix = '' unless defined $prefix;
  # check if already deleted - failed since 5.15.2
  return if $savINC{inc_packname(substr($prefix,0,-2))};
  #while ( ( $sym, $ref ) = each %$symref )
  for $sym (keys %$symref) {
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
    %debug = ();
  }
  my $main = $module ? $module."::" : "main::";
  if ($verbose) {
    warn "Prescan for unused subs in $main" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  # XXX TODO better strategy for compile-time added and required packages:
  # loop savecv and check pkg cache for new pkgs.
  # if so loop again with those new pkgs only, until the list of new pkgs is empty
  descend_marked_unused();
  walkpackages( \%{$main},
                sub { should_save( $_[0] ); return 1 },
                $main eq 'main::' ? undef : $main );
  if ($verbose) {
    warn "Saving unused subs in $main" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  walksymtable( \%{$main}, "savecv", \&should_save );

  if ( $sav_debug{unused} ) {
    %debug = %sav_debug;
  }

  # If any m//i is run-time loaded we'll get a "Undefined subroutine utf8::SWASHNEW"
  # With -fno-fold we don't insist on loading utf8_heavy and Carp.
  # Until it is compile-time required.
  if (exists($INC{'unicore/To/Title.pl'})
      or exists($INC{'unicore/To/Tc.pl'}) #242
      or exists($INC{'unicore/Heavy.pl'}) #242
      or ($savINC{'utf8_heavy.pl'} and ($B::C::fold or exists($savINC{'utf8.pm'})))) {
    require "utf8.pm" unless $INC{"utf8.pm"};
    mark_package('utf8');
    require "utf8_heavy.pl" unless $INC{"utf8_heavy.pl"}; # bypass AUTOLOAD
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
  if ($] >= 5.013005 and ($B::C::warnings or exists($INC{'Carp.pm'}))) {
    svref_2object( \&{"warnings\::register_categories"} )->save; # 68Kb 32bit
    add_hashINC("warnings");
    add_hashINC("warnings::register");
  }
  if ($use_xsloader) {
    force_saving_xsloader();
    mark_package('Config', 1); # required by Dynaloader and special cased previously
  }
}

sub inc_cleanup {
  # %INC sanity check issue 89:
  # omit unused, unsaved packages, so that at least run-time require will pull them in.
  for my $package (keys %INC) {
    my $pkg = packname_inc($package);
    if ($package =~ /^(Config_git\.pl|Config_heavy.pl)$/ and !$include_package{'Config'}) {
      delete $INC{$package};
    } elsif ($package eq 'utf8_heavy.pl' and !$include_package{'utf8'}) {
      delete $INC{$package};
      delete_unsaved_hashINC('utf8');
    } else {
      delete_unsaved_hashINC($pkg) unless $include_package{$pkg};
    }
  }
  if ($debug{pkg} and $verbose) {
    warn "\%include_package: ".join(" ",grep{$include_package{$_}} sort keys %include_package)."\n";
    my @inc = grep !/auto\/.+\.(al|ix)$/, sort keys %INC;
    warn "\%INC: ".join(" ",@inc)."\n";
  }
}

sub save_context {
  # forbid run-time extends of curpad syms, names and INC
  warn "save context:\n" if $verbose;

  if ($PERL510) {
    # Tie::Hash::NamedCapture is added for *+ *-, Errno for *!
    no strict 'refs';
    if ( defined(objsym(svref_2object(\*{'main::+'}))) or defined(objsym(svref_2object(\*{'main::-'}))) ) {
      use strict 'refs';
      if (!$include_package{'Tie::Hash::NamedCapture'}) {
	$init->add("/* force saving of Tie::Hash::NamedCapture */");
        if ($] >= 5.014) {
          mark_package('Config', 1);  # DynaLoader needs Config to set the EGV
          walk_syms('Config');
          svref_2object(\&{'Tie::Hash::NamedCapture::bootstrap'})->save;
        }
	mark_package('Tie::Hash::NamedCapture', 1);
      } # else already included
    } else {
      use strict 'refs';
      delete_unsaved_hashINC('Tie::Hash::NamedCapture');
    }
    no strict 'refs';
    if ( defined(objsym(svref_2object(\*{'main::!'}))) ) {
      use strict 'refs';
      if (!$include_package{'Errno'}) {
	$init->add("/* force saving of Errno */");
	mark_package('Config', 1);
        walk_syms('Config');
	mark_package('Errno', 1);
        svref_2object(\&{'Errno::bootstrap'})->save;
      } # else already included
    } else {
      use strict 'refs';
      delete_unsaved_hashINC('Errno');
    }
  }

  my ($curpad_nam, $curpad_sym);
  {
    # Record comppad sv's names, may not be static
    local $B::C::const_strings = 0;
    $init->add("/* curpad names */");
    warn "curpad names:\n" if $verbose;
    $curpad_nam      = ( comppadlist->ARRAY )[0]->save('curpad_name');
    warn "curpad syms:\n" if $verbose;
    $init->add("/* curpad syms */");
    $curpad_sym      = ( comppadlist->ARRAY )[1]->save('curpad_syms');
  }
  my ($inc_hv, $inc_av);
  {
    local $B::C::const_strings = 1 if $B::C::ro_inc;
    warn "\%INC and \@INC:\n" if $verbose;
    $init->add('/* %INC */');
    inc_cleanup();
    my $inc_gv = svref_2object( \*main::INC );
    $inc_hv    = $inc_gv->HV->save('main::INC');
    $init->add('/* @INC */');
    $inc_av    = $inc_gv->AV->save('main::INC');
  }
  $init->add(
    "GvHV(PL_incgv) = $inc_hv;",
    "GvAV(PL_incgv) = $inc_av;",
    "PL_curpad = AvARRAY($curpad_sym);",
    "PL_comppad = $curpad_sym;",    # fixed "panic: illegal pad"
  );
  if ($] < 5.017005) {
    $init->add(
      "av_store((AV*)CvPADLIST(PL_main_cv), 0, SvREFCNT_inc($curpad_nam)); /* namepad */",
      "av_store((AV*)CvPADLIST(PL_main_cv), 1, SvREFCNT_inc($curpad_sym)); /* curpad */");
  } elsif ($] < 5.019003) {
    $init->add(
      "PadlistARRAY(CvPADLIST(PL_main_cv))[0] = PL_comppad_name = (PAD*)SvREFCNT_inc($curpad_nam); /* namepad */",
      "PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)SvREFCNT_inc($curpad_sym); /* curpad */");
  } else {
    $init->add(
      "PadlistARRAY(CvPADLIST(PL_main_cv))[0] = PL_comppad_name = (PAD*)SvREFCNT_inc($curpad_nam); /* namepad */",
      "PadnamelistMAXNAMED(PL_comppad_name) = AvFILL($curpad_nam);",
      "PadlistARRAY(CvPADLIST(PL_main_cv))[1] = (PAD*)SvREFCNT_inc($curpad_sym); /* curpad */");
  }
  if ($] < 5.017) {
    my $amagic_generate = B::amagic_generation();
    warn "amagic_generation = $amagic_generate\n" if $verbose;
    $init->add("PL_amagic_generation = $amagic_generate;");
  };
}

sub descend_marked_unused {
  warn "\%skip_package: ".join(" ",keys %skip_package)."\n" if $debug{pkg};
  warn "descend_marked_unused: "
    .join(" ",grep{!$skip_package{$_}} keys %include_package)."\n" if $debug{pkg};
  foreach my $pack ( keys %include_package ) {
    mark_package($pack) unless $skip_package{$pack};
  }
}

sub save_main {
  warn "Starting compile\n" if $verbose;
  warn "Walking tree\n"     if $verbose;
  $B::C::curcv = B::main_cv;
  seek( STDOUT, 0, 0 );    #exclude print statements in BEGIN{} into output
  $verbose
    ? walkoptree_slow( main_root, "save" )
    : walkoptree( main_root, "save" );
  save_main_rest();
}

sub fixup_ppaddr {
  # init op addrs must be the last action, otherwise
  # some ops might not be initialized
  if ($B::C::optimize_ppaddr) {
    foreach my $i (@op_sections) {
      my $section = $$i;
      next unless $section->index >= 0;
      init_op_addr( $section->name, $section->index + 1 );
    }
  }

  init_op_warn( $copsect->name, $copsect->index + 1 )
    if $B::C::optimize_warn_sv && $copsect->index >= 0;
}

# save %SIG ( in case it was set in a BEGIN block )
sub save_sig {
  # local $SIG{__WARN__} = shift;
  $init->no_split;
  my @save_sig;
  foreach my $k ( keys %SIG ) {
    next unless ref $SIG{$k};
    my $cvref = svref_2object( \$SIG{$k} );
    next if ref($cvref) eq 'B::CV' and $cvref->FILE =~ m|B/C\.pm$|; # ignore B::C SIG warn handler
    push @save_sig, [$k, $cvref];
  }
  unless (@save_sig) {
    $init->add( "/* no %SIG in BEGIN block */" ) if $verbose;
    warn "no %SIG in BEGIN block\n" if $verbose;
    return;
  }
  $init->add( "/* save %SIG */" ) if $verbose;
  warn "save %SIG\n" if $verbose;
  $init->add( "{", "\tHV* hv = get_hv(\"main::SIG\",GV_ADD);" );
  foreach my $x ( @save_sig ) {
    my ($k, $cvref) = @$x;
    my $sv = $cvref->save;
    $init->add( '{', sprintf "\t".'SV* sv = (SV*)%s;', $sv );
    $init->add( sprintf("\thv_store(hv, %s, %u, %s, %s);",
                        cstring($k), length( pack "a*", $k ),
                        'sv', 0 ) ); # XXX randomized hash keys!
    $init->add( "\t".'mg_set(sv);', '}' );
  }
  $init->add('}');
  $init->split;
}

sub force_saving_xsloader {
  if ($] < 5.015003) {
    $init->add("/* force saving of XSLoader::load */");
    eval { XSLoader::load; };
    svref_2object( \&XSLoader::load )->save;
  } else {
    $init->add("/* custom XSLoader::load_file */");
    svref_2object( \&XSLoader::load_file )->save;
    svref_2object( \&DynaLoader::dl_load_flags )->save; # not saved as XSUB constant?
  }
  add_hashINC("XSLoader") if $] < 5.015003;
  add_hashINC("DynaLoader");
  $use_xsloader = 0; # do not load again
}

sub save_main_rest {
  # this is mainly for the test suite
  my $warner = $SIG{__WARN__};
  # local $SIG{__WARN__} = sub { print STDERR @_ } unless $debug{runtime};

  warn "done main optree, walking symtable for extras\n"
    if $verbose or $debug{cv};
  $init->add("");
  $init->add("/* done main optree, extra subs which might be unused */");
  save_unused_subs();
  $init->add("/* done extras */");

  save_sig($warner) if $B::C::save_sig;

  # honour -w
  $init->add( "/* honor -w */",
    sprintf "PL_dowarn = ( %s ) ? G_WARN_ON : G_WARN_OFF;", $^W );
  if ($^{TAINT}) {
    $init->add( "/* honor -Tt */",
                "PL_tainting = TRUE;",
                "PL_taint_warn = ".($^{TAINT} < 0 ? "FALSE" : "TRUE").";"); # -T -1 false, -t 1 true
  }

  # startpoints: XXX TODO push BEGIN/END blocks to modules code.
  warn "Writing initav\n" if $debug{av};
  my $init_av = init_av->save;
  my $end_av;
  {
    # >=5.10 need to defer nullifying of all vars in END, not only new ones.
    local ($B::C::pv_copy_on_grow, $B::C::const_strings);
    $in_endav = 1;
    warn "Writing endav\n" if $debug{av};
    $init->add("/* END block */");
    $end_av  = end_av->save;
    $in_endav = 0;
  }
  if ( !defined($module) ) {
    $init->add(
      "/* startpoints */",
      sprintf( "PL_main_root = s\\_%x;",  ${ main_root() } ),
      sprintf( "PL_main_start = s\\_%x;", ${ main_start() } ),
    );
    $init->add(index($init_av,'(AV*)')>=0
             ? "PL_initav = $init_av;"
             : "PL_initav = (AV*)$init_av;");
    $init->add(index($end_av,'(AV*)')>=0
             ? "PL_endav = $end_av;"
             : "PL_endav = (AV*)$end_av;");
  }
  save_context() unless defined($module);
  # warn "use_xsloader=$use_xsloader\n" if $verbose;
  # If XSLoader was forced later, e.g. in curpad, INIT or END block
  force_saving_xsloader() if $use_xsloader;
  fixup_ppaddr();

  return if $check;
  warn "Writing output\n" if $verbose;
  output_boilerplate();

  # add static modules like " Win32CORE"
  foreach my $stashname ( split /\s+/, $Config{static_ext} ) {
    next if $stashname =~ /^\s*$/;    # often a leading space
    $static_ext{$stashname}++;
    my $stashxsub = $stashname;
    $stashxsub =~ s/::/__/g;
    print "EXTERN_C void boot_$stashxsub (pTHX_ CV* cv);\n";
  }
  print "\n";
  output_all($init_name || "perl_init");
  print "\n";
  output_main_rest();

  if ( defined($module) ) {
    my $cmodule = $module ? $module : "main";
    $cmodule =~ s/::/__/g;

    my $start = "op_list[0]";
    warn "curpad syms:\n" if $verbose;
    $init->add("/* curpad syms */");
    my $curpad_sym = ( comppadlist->ARRAY )[1]->save;

    print <<"EOT";

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

  } else {
    output_main();
  }
}

sub init_sections {
  my @sections = (
    decl   => \$decl,
    free   => \$free,
    sym    => \$symsect,
    hek    => \$heksect,
    binop  => \$binopsect,
    condop => \$condopsect,
    cop    => \$copsect,
    padop  => \$padopsect,
    listop => \$listopsect,
    logop  => \$logopsect,
    loop   => \$loopsect,
    op     => \$opsect,
    pmop   => \$pmopsect,
    pvop   => \$pvopsect,
    svop   => \$svopsect,
    unop   => \$unopsect,
    sv     => \$svsect,
    xpv    => \$xpvsect,
    xpvav  => \$xpvavsect,
    xpvhv  => \$xpvhvsect,
    xpvcv  => \$xpvcvsect,
    xpviv  => \$xpvivsect,
    xpvuv  => \$xpvuvsect,
    xpvnv  => \$xpvnvsect,
    xpvmg  => \$xpvmgsect,
    xpvlv  => \$xpvlvsect,
    xrv    => \$xrvsect,
    xpvbm  => \$xpvbmsect,
    xpvio  => \$xpviosect,
    padlist => \$padlistsect,
  );
  my ( $name, $sectref );
  while ( ( $name, $sectref ) = splice( @sections, 0, 2 ) ) {
    $$sectref = new B::C::Section $name, \%symtable, 0;
  }
  $init = new B::C::InitSection 'init', \%symtable, 0;
  $init2 = new B::C::InitSection 'init2', \%symtable, 0;
}

sub mark_unused {
  my ( $pkg, $val ) = @_;
  $include_package{$pkg} = $val;
}

sub mark_skip {
  for (@_) {
    delete_unsaved_hashINC($_);
    # $include_package{$_} = 0;
    $skip_package{$_} = 1;
  }
}

sub compile {
  my @options = @_;
  # Allow debugging in CHECK blocks without Od
  $DB::single = 1 if defined &DB::DB;
  my ( $option, $opt, $arg );
  my @eval_at_startup;
  $B::C::can_delete_pkg = 1;
  $B::C::destruct = 1;
  $B::C::save_sig = 1;
  $B::C::stash    = 0;
  $B::C::fold     = 1 if $] >= 5.013009; # always include utf8::Cased tables
  $B::C::warnings = 1 if $] >= 5.013005; # always include Carp warnings categories and B
  mark_skip qw(B::C B::C::Flags B::CC B::Asmdata B::FAKEOP O
	       B::Section B::Pseudoreg B::Shadow);
  #mark_skip('DB', 'Term::ReadLine') if $DB::deep;

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
      if ($arg eq 'full') {
        $arg = 'OcAHCMGSPpsWF';
      }
      elsif ($arg eq 'ufull') {
        $arg = 'uOcAHCMGSPpsWF';
      }
      foreach my $arg ( split( //, $arg ) ) {
        if (exists $debug_map{$arg}) {
          $debug{ $debug_map{$arg} }++;
        }
        elsif ( $arg eq "o" ) {
	  $verbose++;
	  B->debug(1);
        }
        elsif ( $arg eq "F" ) {
          $debug{flags}++ if $] > 5.008 and eval "require B::Flags;";
          # $debug{flags}++ if require B::Flags;
        }
        elsif ( $arg eq "r" ) {
          $debug{runtime}++;
	  $SIG{__WARN__} = sub {
	    warn @_; 
	    my $s = join(" ", @_);
	    chomp $s;
	    $init->add("/* ".$s." */") if $init;
	  };
        }
        else {
          warn "ignoring unknown debug option: $arg\n";
        }
      }
    }
    elsif ( $opt eq "o" ) {
      $arg ||= shift @options;
      $outfile = $arg;
      if ($check) {
	warn "Warning: -o argument ignored with -c\n";
      } else {
	open( STDOUT, ">", $arg ) or return "$arg: $!\n";
      }
    }
    elsif ( $opt eq "s" and $arg eq "taticxs" ) {
      $outfile = "perlcc" unless $outfile;
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
      if ($arg =~ /\.p[lm]$/) {
	eval "require(\"$arg\");";  # path as string
      } else {
	eval "require $arg;";      # package as bareword with ::
      }
      mark_unused( $arg, 1 );
    }
    elsif ( $opt eq "U" ) {
      $arg ||= shift @options;
      mark_skip( $arg );
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
      warn "options : ".(join " ",@opt)."\n" if $verbose;
    }
    elsif ( $opt eq "e" ) {
      push @eval_at_startup, $arg;
    }
    elsif ( $opt eq "l" ) {
      $max_string_len = $arg;
    }
  }
  if (!$B::C::Flags::have_independent_comalloc) {
    if ($B::C::av_init2) {
      $B::C::av_init = 1;
      $B::C::av_init2 = 0;
    } elsif ($B::C::av_init) {
      $B::C::av_init2 = 0;
    }
  } elsif ($B::C::av_init2 and $B::C::av_init) {
    $B::C::av_init = 0;
  }
  $B::C::save_data_fh = 1 if $] >= 5.008 and (($] < 5.009004) or $MULTI);
  $B::C::destruct = 1 if $] < 5.008 or $^O eq 'MSWin32';

  init_sections();
  foreach my $i (@eval_at_startup) {
    $init->add_eval($i);
  }
  if (@options) { # modules or main?
    return sub {
      my $objname;
      foreach $objname (@options) {
        eval "save_object(\\$objname)";
      }
      output_all($init_name || "init_module");
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

Optimize the initialization of cop_warnings.

Enabled with C<-O1>.

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

Enable B<-O3> plus B<-fcop>. Very unsafe, rarely works,
10% faster, 10% smaller.

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
    package destruction
    handling of empty functions, esp. sig handlers: $SIG{__WARN__}=sub{}

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
