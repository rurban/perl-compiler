#      C.pm
#
#      Copyright (c) 1996, 1997, 1998 Malcolm Beattie
#      Copyright (c) 2008, 2009, 2010, 2011 Reini Urban
#      Copyright (c) 2010 Nick Koston
#      Copyright (c) 2011, 2012 cPanel Inc
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#

package B::C;

our $VERSION = '1.39';
my %debug;

package B::C::Section;

use B ();
use base B::Section;

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
  if (@_) {
    splice @{ $section->[-1]{values} }, shift, 1;
  } else {
    pop  @{ $section->[-1]{values} };
  }
}

sub index {
  my $section = shift;
  return scalar( @{ $section->[-1]{values} } ) - 1;
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
  my $i = 0;
  my $dodbg = 1 if $debug{flags} and $section->[-1]{dbg};
  foreach ( @{ $section->[-1]{values} } ) {
    my $dbg = "";
    s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
    if ($dodbg and $section->[-1]{dbg}->[$i]) {
      $dbg = " /* ".$section->[-1]{dbg}->[$i]." */";
    }
    printf $fh $format, $_, $section->name, $i, $dbg;
    ++$i;
  }
}

package B::C::InitSection;

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
  push @{ $section->[-1]{chunks} }, $section->[-1]{current};

  my $name = "aaaa";
  foreach my $i ( @{ $section->[-1]{chunks} } ) {
    # dTARG and dSP unused -nt
    print $fh <<"EOT";
static int perl_init_${name}(pTHX)
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

    $section->SUPER::add("perl_init_${name}(aTHX);");
    ++$name;
  }
  foreach my $i ( @{ $section->[-1]{evals} } ) {
    $section->SUPER::add( sprintf q{eval_pv("%s",1);}, $i );
  }

  print $fh <<"EOT";
static int ${init_name}(pTHX)
{
EOT
  $section->SUPER::output( $fh, $format );
  print $fh "\treturn 0;\n}\n";
}

package B::C;
use Exporter ();
use Errno (); #needed since 5.14
our %Regexp;

{ # block necessary for caller to work
  my $caller = caller;
  if ( $caller eq 'O' or $caller eq 'Od' ) {
    require XSLoader;
    XSLoader::load('B::C'); # for r-magic only
  }
}

@ISA        = qw(Exporter);
@EXPORT_OK =
  qw(output_all output_boilerplate output_main output_main_rest mark_unused mark_skip
     init_sections set_callback save_unused_subs objsym save_context fixup_ppaddr
     save_sig svop_or_padop_pv inc_cleanup);
# for 5.6 better use the native B::C
# 5.6.2 works fine though.
use B
  qw(minus_c sv_undef walkoptree walkoptree_slow walksymtable main_root main_start peekop
  class cchar svref_2object compile_stats comppadlist hash
  threadsv_names main_cv init_av end_av opnumber amagic_generation cstring
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
     ];
    @B::PVMG::ISA = qw(B::PVNV B::RV);
  }
  if ($] >= 5.010) {require mro; mro->import;}
}
use B::Asmdata qw(@specialsv_name);

use B::C::Flags;
use FileHandle;
#use Carp;
use strict;
use Config;

my $hv_index      = 0;
my $gv_index      = 0;
my $re_index      = 0;
my $pv_index      = 0;
my $cv_index      = 0;
my $hek_index     = 0;
my $anonsub_index = 0;
my $initsub_index = 0;

# exclude all not B::C:: prefixed subs
my %all_bc_subs = map {$_=>1}
  qw(B::AV::save B::BINOP::save B::BM::save B::COP::save B::CV::save
     B::FAKEOP::fake_ppaddr B::FAKEOP::flags B::FAKEOP::new B::FAKEOP::next
     B::FAKEOP::ppaddr B::FAKEOP::private B::FAKEOP::save B::FAKEOP::sibling
     B::FAKEOP::targ B::FAKEOP::type B::GV::save B::GV::savecv B::HV::save
     B::IO::save B::IO::save_data B::IV::save B::LISTOP::save B::LOGOP::save
     B::LOOP::save B::NULL::save B::NV::save B::OBJECT::save
     B::OP::_save_common B::OP::fake_ppaddr B::OP::isa B::OP::save
     B::PADOP::save B::PMOP::save B::PV::save B::PVIV::save B::PVLV::save
     B::PVMG::save B::PVMG::save_magic B::PVNV::save B::PVOP::save
     B::REGEXP::save B::RV::save B::SPECIAL::save B::SPECIAL::savecv
     B::SV::save B::SVOP::save B::UNOP::save B::UV::save B::REGEXP::EXTFLAGS);
#
my ($prev_op, $package_pv, @package_pv); # global stash for methods since 5.13
my (%symtable, %cvforward, %lexwarnsym);
my (%strtable, %hektable, @static_free);
my %xsub;
my $warn_undefined_syms;
my ($staticxs, $outfile);
my (%include_package, %skip_package);
my %static_ext;
my ($use_xsloader, $inc_cleanup);
my $nullop_count         = 0;
# options and optimizations shared with B::CC
our ($module, $init_name, %savINC, $mainfile);
our ($use_av_undef_speedup, $use_svpop_speedup) = (1, 1);
our ($pv_copy_on_grow, $optimize_ppaddr, $optimize_warn_sv, $use_perl_script_name,
    $save_data_fh, $save_sig, $optimize_cop, $av_init, $av_init2, $ro_inc, $destruct,
    $fold, $warnings, $const_strings, $stash);
our $verbose = 0;
our %option_map = (
    'cog'             => \$B::C::pv_copy_on_grow,
    'const-strings'   => \$B::C::const_strings,
    'save-data'       => \$B::C::save_data_fh,
    'ppaddr'          => \$B::C::optimize_ppaddr,
    'warn-sv'         => \$B::C::optimize_warn_sv,
    'av-init'         => \$B::C::av_init,
    'av-init2'        => \$B::C::av_init2,
    'ro-inc'          => \$B::C::ro_inc,
    'stash'           => \$B::C::stash,    # disable with -fno-stash
    'destruct'        => \$B::C::destruct, # disable with -fno-destruct
    'fold'            => \$B::C::fold,     # disable with -fno-fold
    'warnings'        => \$B::C::warnings, # disable with -fno-warnings
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => \$B::C::save_sig,
    'cop'             => \$optimize_cop, # XXX very unsafe!
					 # Better do it in CC, but get rid of
					 # NULL cops also there.
);

my @xpvav_sizes;
my ($max_string_len, $in_endav);
my %static_core_pkg; # = map {$_ => 1} static_core_packages();

my $MULTI = $Config{usemultiplicity};
my $ITHREADS = $Config{useithreads};
my $DEBUGGING = ($Config{ccflags} =~ m/-DDEBUGGING/);
my $PERL514  = ( $] >= 5.013002 );
my $PERL512  = ( $] >= 5.011 );
my $PERL510  = ( $] >= 5.009005 );
my $PERL56   = ( $] <  5.008001 ); # yes. 5.8.0 is a 5.6.x
# Thanks to Mattia Barbon for the C99 tip to init any union members
my $C99 = $Config{d_c99_variadic_macros}; # http://docs.sun.com/source/819-3688/c99.app.html#pgfId-1003962
my $MAD      = $Config{mad};
my $MYMALLOC = $Config{usemymalloc} eq 'define';
my @threadsv_names;

BEGIN {
  @threadsv_names = threadsv_names();
}

# 5.15.3 workaround [perl #101336]
sub XSLoader::load_file {
  #package DynaLoader;
  use Config;
  my $module = shift or die "missing module name";
  my $modlibname = shift or die "missing module filepath";
#print STDOUT "XSLoader::load_file(\"$module\", \"$modlibname\" @_)\n";

  push @_, $module;
  # works with static linking too
  my $boots = "$module\::bootstrap";
  goto &$boots if defined &$boots;

  my @modparts = split(/::/,$module);
  my $modfname = $modparts[-1];
  my $modpname = join('/',@modparts);
  my $c = @modparts;
  $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
  my $file = "$modlibname/auto/$modpname/$modfname.".$Config::Config->{dlext};

  # skip the .bs "bullshit" part, needed for some old solaris ages ago

  goto \&DynaLoader::bootstrap_inherit if not -f $file;
  my $bootname = "boot_$module";
  $bootname =~ s/\W/_/g;
  @DynaLoader::dl_require_symbols = ($bootname);

  my $boot_symbol_ref;
  if ($boot_symbol_ref = DynaLoader::dl_find_symbol(0, $bootname)) {
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
  push(@DynaLoader::dl_modules, $module); # record loaded module

 boot:
  my $xs = DynaLoader::dl_install_xsub($boots, $boot_symbol_ref, $file);
  # See comment block above
  push(@DynaLoader::dl_shared_objects, $file); # record files loaded
  return &$xs(@_);
}

# Code sections
my (
  $init,      $decl,      $symsect,    $binopsect, $condopsect,
  $copsect,   $padopsect, $listopsect, $logopsect, $loopsect,
  $opsect,    $pmopsect,  $pvopsect,   $svopsect,  $unopsect,
  $svsect,    $resect,    $xpvsect,    $xpvavsect, $xpvhvsect,
  $xpvcvsect, $xpvivsect, $xpvuvsect,  $xpvnvsect, $xpvmgsect, $xpvlvsect,
  $xrvsect,   $xpvbmsect, $xpviosect,  $heksect,   $orangesect,
  $free
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
  if ($$sv) {
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

sub savesym {
  my ( $obj, $value ) = @_;
  my $sym = sprintf( "s\\_%x", $$obj );
  $symtable{$sym} = $value;
  $value;
}

sub objsym {
  my $obj = shift;
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
  my $len = 0; # length( pack "a*", $pv ) + 1;
  if ($PERL514) {
    $xpvsect->add( sprintf( "Nullhv, {0}, %u, %u", $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {(char*)%s}", $xpvsect->index,
                           0x4405, savepv($pv) ) );
    $sym = sprintf( "&sv_list[%d]", $svsect->index );
  }
  elsif ( 0 and $PERL512 ) {
    # TODO Fill in at least the engine pointer? Or let CALLREGCOMP do that?
    $orangesect->add(
      sprintf(
              "0,%u,%u, 0,0,NULL, NULL,NULL,"
              . "0,0,0,0,NULL,0,0,NULL,0,0, NULL,NULL,NULL,0,0,0",
              $cur, $len
             )
    );
    $resect->add(sprintf("&orange_list[%d], 1, %d, %s",
                         $orangesect->index, $flags, cstring($re) ));
    $sym = sprintf( "re_list[%d]", $resect->index );
    warn sprintf( "Saving RE $sym->orangesect[%d] $re\n", $orangesect->index )
      if $debug{sv};
  }
  elsif ($PERL510) {
    # BUG! Should be the same as newSVpvn($resym, $relen) but is not
    #$sym = sprintf("re_list[%d]", $re_index++);
    #$resect->add(sprintf("0,0,0,%s", cstring($re)));
    my $s1 = ($PERL514 ? "NULL," : "") . "{0}, %u, %u";
    $xpvsect->add( sprintf( $s1, $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {(char*)%s}", $xpvsect->index,
                           0x4405, savepv($pv) ) );
    my $s = "sv_list[".$svsect->index."]";
    $sym = "&$s";
    push @static_free, $s if $len and $B::C::pv_copy_on_grow;
    # $resect->add(sprintf("&xpv_list[%d], %lu, 0x%x", $xpvsect->index, 1, 0x4405));
  }
  else {
    $sym = sprintf( "re%d", $re_index++ );
    $decl->add( sprintf( "Static const char *$sym = %s;", cstring($re) ) );
  }
  return ( $sym, length( pack "a*", $re ) );
}

sub constpv {
  my $pv    = pack "a*", shift;
  if (defined $strtable{$pv}) {
    return $strtable{$pv};
  }
  my $pvsym = sprintf( "pv%d", $pv_index++ );
  $strtable{$pv} = "$pvsym";
  my $const = ($B::C::pv_copy_on_grow and $B::C::const_strings) ? " const" : "";
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    my $chars = join ', ', map { cchar $_ } split //, $pv;
    $decl->add( sprintf( "Static$const char %s[] = { %s };", $pvsym, $chars ) );
  } else {
    my $cstring = cstring($pv);
    if ( $cstring ne "0" ) {    # sic
      $decl->add( sprintf( "Static$const char %s[] = %s;", $pvsym, $cstring ) );
    }
  }
  wantarray ? ( $pvsym, length( pack "a*", $pv ) ) : $pvsym;
}

sub savepv {
  return constpv($_[0]) if $B::C::const_strings and $B::C::pv_copy_on_grow; # or readonly
  my $pv    = pack "a*", shift;
  my $pvsym = sprintf( "pv%d", $pv_index++ );
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    my $chars = join ', ', map { cchar $_ } split //, $pv;
    $decl->add( sprintf( "Static char %s[] = { %s };", $pvsym, $chars ) );
  } else {
    my $cstring = cstring($pv);
    if ( $cstring ne "0" ) {    # sic
      $decl->add( sprintf( "Static char %s[] = %s;", $pvsym, $cstring ) );
    }
  }
  my $len = length( pack "a*", $pv ) + 1;
  return ( $pvsym, $len );
}

sub save_rv {
  my ($sv, $fullname) = @_;
  if (!$fullname) {
    $fullname = '(unknown)';
  }
  # confess "Can't save RV: not ROK" unless $sv->FLAGS & SVf_ROK;
  # 5.6: Can't locate object method "RV" via package "B::PVMG"
  my $rv = $sv->RV->save($fullname);

  $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

  return $rv;
}

# => savesym, cur, len, pv
sub save_pv_or_rv {
  my ($sv, $fullname) = @_;

  my $rok = $sv->FLAGS & SVf_ROK;
  my $pok = $sv->FLAGS & SVf_POK;
  my ( $cur, $len, $savesym, $pv ) = ( 0, 0 );
  # XXX overloaded VERSION symbols fail to xs boot: ExtUtils::CBuilder with Fcntl::VERSION
  # 5.6: Can't locate object method "RV" via package "B::PV" Carp::Clan
  if ($rok and !$PERL56) {
    # this returns us a SV*. 5.8 expects a char* in xpvmg.xpv_pv
    warn "save_pv_or_rv: save_rv(",$sv,")\n" if $debug{sv};
    $savesym = ($PERL510 ? "" : "(char*)") . save_rv($sv, $fullname);
  }
  else {
    $pv = $pok ? ( pack "a*", $sv->PV ) : undef;
    $cur = $pok ? length($pv) : 0;
    my $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
    local $B::C::pv_copy_on_grow if $shared_hek;
    if ($pok) {
      if ($B::C::pv_copy_on_grow) {
	( $savesym, $len ) = ($B::C::const_strings and $sv->FLAGS & SVf_READONLY)
	  ? constpv($pv) : savepv($pv);
      } else {
	( $savesym, $len ) = ( 'ptr_undef', $cur+1 );
      }
    } else {
      ( $savesym, $len ) = ( 'ptr_undef', 0 );
    }
  }
  return ( $savesym, $cur, $len, $pv );
}

# Shared global string in PL_strtab.
# Mostly GvNAME and GvFILE but also CV prototypes or bareword hash keys.
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
  my $sym = sprintf( "hek%d", $hek_index++ );
  $hektable{$str} = $sym;
  my $cstr = cstring($str);
  $decl->add(sprintf("Static HEK *%s;",$sym));
  # randomized global shared hash keys:
  #   share_hek needs a non-zero hash parameter, unlike hv_store.
  #   Vulnerable to oCERT-2011-003 style DOS attacks?
  #   user-input (object fields) does not affect strtab, it is pretty safe.
  # But we need to randomize them to avoid run-time conflicts
  #   e.g. "Prototype mismatch: sub bytes::length (_) vs (_)"
  $init->add(sprintf("%s = share_hek(%s, %u, %s);",
		     $sym, $cstr, $cur, '0'));
  wantarray ? ( $sym, $cur ) : $sym;
}

sub ivx ($) {
  my $ivx = shift;
  my $ivdformat = $Config{ivdformat};
  $ivdformat =~ s/"//g; #" poor editor
  my $intmax = (1 << ($Config{ivsize}*4-1)) - 1;
  # UL if > INT32_MAX = 2147483647
  my $sval = sprintf("%${ivdformat}%s", $ivx, $ivx > $intmax  ? "UL" : "");
  if ($ivx < -$intmax) {
    $sval = sprintf("%${ivdformat}%s", $ivx, "L"); # DateTime
  }
  $sval = '0' if $sval =~ /(NAN|inf)$/i;
  return $sval;
  #return $C99 ? ".xivu_uv = $sval" : $sval; # this is version dependent
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
sub B::OBJECT::name  { "" }           # B misses that

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
  my $static;
  if ( $] < 5.009004 ) {
    $static = sprintf "%u", 65535;
    $opsect_common .= "seq";
  }
  elsif ( $] < 5.010 ) {
    $static = '0, 1, 0';
    $opsect_common .= "opt, static, spare";
  }
  else {
    $static = '0, 1, 0, 0, 0';
    $opsect_common .= "opt, latefree, latefreed, attached, spare";
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
  if ($op->type > 0 and
      $op->name eq 'entersub' and $op->first and $op->first->can('name') and
      $op->first->name eq 'pushmark' and
      # Foo->bar()  compile-time lookup, 34 = BARE in all versions
      (($op->first->next->name eq 'const' and $op->first->next->flags == 34)
       or $op->first->next->name eq 'padsv')      # $foo->bar() run-time lookup
     ) {
    my $pkgop = $op->first->next;
    warn "check package_pv ".$pkgop->name." for method_name\n" if $debug{cv};
    my $pv = svop_or_padop_pv($pkgop); # XXX need to store away the pkg pv. Failed since 5.13
    if ($pv and $pv !~ /[! \(]/) {
      $package_pv = $pv;
      push_package($package_pv);
    } else {
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
    $init->add(
      sprintf( "(void)find_threadsv(%s);",
        cstring( $threadsv_names[ $op->targ ] ) )
    );
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
    if ($ITHREADS and $] >= 5.015004) {
      $copsect->comment(
        "$opsect_common, line, stash, file, hints, seq, warnings, hints_hash");
      $copsect->add(sprintf("%s, 0, (char *)NULL, NULL, 0, 0, 0, NULL, NULL",
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
  $pvopsect->add( sprintf( "%s, %s", $op->_save_common, cstring( $op->pv ) ) );
  $pvopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $pvopsect->index;
  $init->add( sprintf( "pvop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  savesym( $op, "(OP*)&pvop_list[$ix]" );
}

# XXX Until we know exactly the package name for a method_call
# we improve the method search heuristics by maintaining this mru list.
sub push_package ($) {
  my $p = shift or return;
  warn "save package_pv \"$package_pv\" for method_name\n"
    if $debug{cv} or $debug{pkg} and !grep { $p eq $_ } @package_pv;
  @package_pv = grep { $p ne $_ } @package_pv if @package_pv; # remove duplicates at the end
  unshift @package_pv, $p; 		       # prepend at the front
  mark_package($p);
}

# method_named is in 5.6.1
sub method_named {
  my $name = shift;
  return unless $name;
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
    $method = $_ . '::' . $name;
    if (defined(*{$method}{CODE})) {
      $include_package{$_} = 1; # issue59
      mark_package($_, 1);
      last;
    }
  }
  $method = $name unless $method;
  warn "save method_name \"$method\"\n" if $debug{cv};
  return svref_2object( \&{$method} );
}

sub B::SVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $svsym = 'Nullsv';
  my $sv;
  # XXX moose1 crash with 5.8.5-nt, Cwd::_perl_abs_path also
  if ($op->name eq 'aelemfast' and $op->flags & 128) { #OPf_SPECIAL
    $svsym = '&PL_sv_undef'; # pad does not need to be saved
    warn sprintf("SVOP->sv aelemfast pad %d\n", $op->flags) if $debug{sv};
  } else {
    my $sv    = $op->sv;
    $svsym  = '(SV*)' . $sv->save("svop ".$op->name);
  }
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op));
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
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op));
    $cv->save if $cv;
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
    $warn_sv = "($warnsvcast)&".$warn_sv.($verbose ?' /*lexwarn*/':'');
    $free->add( sprintf( "    cop_list[%d].cop_warnings = NULL;", $ix ) );
    #push @static_free, sprintf("cop_list[%d]", $ix);
  }

  # Trim the .pl extension, to print the executable name only.
  my $file = $op->file;
  $file =~ s/\.pl$/.c/;
  if ($PERL512) {
    if ($ITHREADS and $] >= 5.015004) {
      $copsect->comment(
	      "$opsect_common, line, stashpv, file, stashflags, hints, seq, warnings, hints_hash");
      $copsect->add(
	sprintf(
              "%s, %u, " . "%s, %s, %d, 0, " . "%u, %s, NULL",
              $op->_save_common, $op->line,
	      "(char*)".constpv( $op->stashpv ), # we can store this static
	      "(char*)".constpv( $file ), $op->stashflags,
              $op->cop_seq, $B::C::optimize_warn_sv ? $warn_sv : 'NULL'
	       ));
    } else {
      # cop_label now in hints_hash (Change #33656)
      $copsect->comment(
	      "$opsect_common, line, stash, file, hints, seq, warn_sv, hints_hash");
      $copsect->add(
	sprintf(
              "%s, %u, " . "%s, %s, 0, " . "%u, %s, NULL",
              $op->_save_common, $op->line,
	      $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "Nullhv",# we can store this static
	      $ITHREADS ? "(char*)".constpv( $file ) : "Nullgv",
              $op->cop_seq,
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
    $copsect->add(sprintf("%s, %u, %s, " . "%s, %s, 0, " . "%u, %s, NULL",
			  $op->_save_common,     $op->line, 'NULL',
			  $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "NULL", # we can store this static
			  $ITHREADS ? "(char*)".constpv( $file ) : "NULL",
			  $op->cop_seq,
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
	      "%s, %s, %s, %s, %u, %d, %u, %s %s",
	      $op->_save_common, cstring( $op->label ),
	      $ITHREADS ? "(char*)".constpv( $op->stashpv ) : "NULL", # we can store this static
	      $ITHREADS ? "(char*)".constpv( $file ) : "NULL",
	      $op->cop_seq,      $op->arybase,
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

  push @static_free, "cop_list[$ix]" if $ITHREADS;
  $init->add(
    sprintf( "CopFILE_set(&cop_list[$ix], %s);",    constpv( $file ) ),
  ) if !$optimize_cop and !$ITHREADS;
  $init->add(
    sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", constpv( $op->stashpv ) )
  ) if !$ITHREADS;

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
        $op->pmflags, $replrootfield,
        $replstartfield
      )
    );
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
  } else {
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
  my $re = $op->precomp; #out of memory: Module::Pluggable, Carp::Clan - threaded
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
        require "utf8_heavy.pl"; # bypass AUTOLOAD
        svref_2object( \&{"utf8\::SWASHNEW"} )->save; # for swash_init(), defined in lib/utf8_heavy.pl
      }
      $init->add( # XXX Modification of a read-only value attempted. use DateTime - threaded
        "PM_SETRE(&$pm, CALLREGCOMP(newSVpvn($resym, $relen), ".sprintf("0x%x));", $pmflags),
        sprintf("RX_EXTFLAGS(PM_GETRE(&$pm)) = 0x%x;", $op->reflags )
      );
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
  my ($sv) = @_;
  # special case: $$sv is not the address but an index into specialsv_list
  #   warn "SPECIAL::save specialsv $$sv\n"; # debug
  @specialsv_name = qw(Nullsv &PL_sv_undef &PL_sv_yes &PL_sv_no pWARN_ALL pWARN_NONE)
    unless @specialsv_name; # 5.6.2 Exporter quirks
  my $sym = $specialsv_name[$$sv];
  if ( !defined($sym) ) {
    warn "unknown specialsv index $$sv passed to B::SPECIAL::save";
  }
  return $sym;
}

sub B::OBJECT::save { }

sub B::NULL::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;

  # debug
  if ( $$sv == 0 ) {
    warn "NULL::save for sv = 0 called from @{[(caller(1))[3]]}\n" if $verbose;
    return savesym( $sv, "(void*)Nullsv /* XXX */" );
  }

  my $i = $svsect->index + 1;
  warn "Saving SVt_NULL sv_list[$i]\n" if $debug{sv};
  $svsect->add( sprintf( "0, %lu, 0x%x".($PERL510?', {(char*)ptr_undef}':''), $sv->REFCNT, $sv->FLAGS ) );
  #$svsect->debug( $sv->flagspv ) if $debug{flags}; # XXX where is this possible?
  if ($debug{flags} and $]>5.009 and $DEBUGGING) { # add index to sv_debug_file to easily find the Nullsv
    # $svsect->debug( "ix added to sv_debug_file" );
    $init->add(sprintf(qq(sv_list[%d].sv_debug_file = "NULL sv_list[%d] 0x%x";), 
		       $svsect->index, $svsect->index, $sv->FLAGS));
  }
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::UV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  if ($PERL514) {
    $xpvuvsect->add( sprintf( "Nullhv, {0}, 0, 0, {%luU}", $sv->UVX ) );
  } elsif ($PERL510) {
    $xpvuvsect->add( sprintf( "{0}, 0, 0, {%luU}", $sv->UVX ) );
  } else {
    $xpvuvsect->add( sprintf( "0, 0, 0, %luU", $sv->UVX ) );
  }
  $svsect->add(
    sprintf(
      "&xpvuv_list[%d], %lu, 0x%x".($PERL510?', {(char*)ptr_undef}':''),
      $xpvuvsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
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
      "&xpviv_list[%d], %lu, 0x%x".($PERL510?', {(char*)ptr_undef}':''),
      $xpvivsect->index, $sv->REFCNT, $svflags
    )
  );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  warn sprintf( "Saving IV 0x%x to xpviv_list[%d], sv_list[%d], called from %s:%s\n",
    $sv->IVX, $xpvivsect->index, $svsect->index, @{[(caller(1))[3]]}, @{[(caller(0))[2]]} )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::NV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $nv = $sv->NV;
  my $sval = sprintf("%g", $nv);
  $nv = '0' if $sval =~ /(NAN|inf)$/i; # windows msvcrt
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
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  warn sprintf( "Saving NV %s to xpvnv_list[%d], sv_list[%d]\n",
    $nv, $xpvnvsect->index, $svsect->index )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub savepvn {
  my ( $dest, $pv, $sv ) = @_;
  my @init;

  # work with byte offsets/lengths
  $pv = pack "a*", $pv;
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    push @init, sprintf( "New(0,%s,%u,char);", $dest, length($pv) + 1 );
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
      if $debug{sv};
  }
  else {
    # If READONLY and FAKE use newSVpvn_share instead. (test 75)
    if ($PERL510 and $sv and (($sv->FLAGS & 0x09000000) == 0x09000000)) {
      warn sprintf( "Saving shared HEK %s to %s\n", cstring($pv), $dest ) if $debug{sv};
      my $hek = save_hek($pv);
      push @init, sprintf( "%s = HEK_KEY($hek);", $dest ) unless $hek eq 'NULL';
      if ($DEBUGGING) { # we have to bypass a wrong HE->HEK assert in hv.c
	push @static_free, $dest;
      }
    } else {
      warn sprintf( "Saving PV %s to %s\n", cstring($pv), $dest ) if $debug{sv};
      push @init, sprintf( "%s = savepvn(%s, %u);", $dest, cstring($pv), length($pv) );
    }
  }
  return @init;
}

sub B::PVLV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my $pv  = $sv->PV;
  my $cur = length($pv);
  my $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
  my ( $pvsym, $len ) = ($B::C::const_strings and $sv->FLAGS & SVf_READONLY and !$shared_hek)
    ? constpv($pv) : savepv($pv);
  $len = 0 if $B::C::pv_copy_on_grow or $shared_hek;
  $pvsym = "(char*)$pvsym";# if $B::C::const_strings and $sv->FLAGS & SVf_READONLY;
  my ( $lvtarg, $lvtarg_sym ); # XXX missing
  if ($PERL514) {
    $xpvlvsect->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %u, %u, %u, Nullsv, %s",
	       $cur, $len, $sv->NVX,
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS, $pvsym));
  } elsif ($PERL510) {
    $xpvlvsect->comment('xnv_u, CUR, LEN, GvNAME, MAGIC, STASH, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("%u, %u, %d, 0/*GvNAME later*/, 0, Nullhv, %u, %u, Nullsv, %s",
	       $sv->NVX, $cur, $len,
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS, $pvsym));
  } else {
    $xpvlvsect->comment('PVX, CUR, LEN, IVX, NVX, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("%s, %u, %u, %ld, %s, 0, 0, %u, %u, Nullsv, %s",
	       $pvsym, $cur, $len, $sv->IVX,
	       $sv->NVX, $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( !$B::C::pv_copy_on_grow ) {
    if ($PERL510) {
      $init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv ) );
    }
    else {
      $init->add(
        savepvn( sprintf( "xpvlv_list[%d].xpv_pv", $xpvlvsect->index ), $pv ) );
    }
  } else {
    if ($shared_hek) { # avoid free of static hek's
      $free->add("    SvFAKE_off(&$s);");
    } else {
      push @static_free, $s if $len and !$in_endav;
    }
  }
  $sv->save_magic;
  savesym( $sv, "&".$s );
}

sub B::PVIV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
  local $B::C::pv_copy_on_grow;
  $B::C::pv_copy_on_grow = 1 if $B::C::const_strings and $sv->FLAGS & SVf_READONLY;
  my ( $savesym, $cur, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = "(char*)$savesym";
  $len = 0 if $B::C::pv_copy_on_grow or $shared_hek;
  if ($PERL514) {
    $xpvivsect->comment('STASH, MAGIC, cur, len, IVX');
    $xpvivsect->add( sprintf( "Nullhv, {0}, %u, %u, {%s}", $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  } elsif ($PERL510) {
    $xpvivsect->comment('xnv_u, cur, len, IVX');
    $xpvivsect->add( sprintf( "{0}, %u, %u, {%s}", $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  } else {
    #$iv = 0 if $sv->FLAGS & (SVf_IOK|SVp_IOK);
    $xpvivsect->comment('PVX, cur, len, IVX');
    $xpvivsect->add( sprintf( "%s, %u, %u, %s",
			      $savesym, $cur, $len, ivx($sv->IVX) ) ); # IVTYPE long
  }
  $svsect->add(
    sprintf("&xpviv_list[%d], %u, 0x%x %s",
            $xpvivsect->index, $sv->REFCNT, $sv->FLAGS, $PERL510 ? ', {(char*)ptr_undef}' : '' ) );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$B::C::pv_copy_on_grow ) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv ) );
      } else {
	$init->add
	  (savepvn( sprintf( "xpviv_list[%d].xpv_pv", $xpvivsect->index ), $pv ) );
      }
    } else {
      if ($shared_hek) { # avoid free of static hek's
	$free->add("    SvFAKE_off(&$s);");
      } else {
	push @static_free, $s if $len and !$in_endav;
      }
    }
  }
  savesym( $sv, "&".$s );
}

sub B::PVNV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
  local $B::C::pv_copy_on_grow;
  $B::C::pv_copy_on_grow = 1 if $B::C::const_strings
    and !$shared_hek
    and $sv->FLAGS & SVf_READONLY;
  my ( $savesym, $cur, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = substr($savesym,0,1) ne "(" ? "(char*)".$savesym : $savesym;
  $len = 0 if $B::C::pv_copy_on_grow or $shared_hek;
  my $nvx = $sv->NVX;
  my $ivx = $sv->IVX; # here must be IVX!
  my $uvuformat = $Config{uvuformat};
  $uvuformat =~ s/"//g;	#" poor editor
  if ($sv->FLAGS & (SVf_NOK|SVp_NOK)) {
    # it could be a double, or it could be 2 ints - union xpad_cop_seq
    my $sval = sprintf("%g", $nvx);
    $nvx = '0' if $sval =~ /(NAN|inf)$/i; # windows msvcrt (DateTime)
    $nvx .= '.00' if $nvx =~ /^-?\d+$/;
  } else {
    if ($PERL510 and $C99) {
      # U if > INT32_MAX = 2147483647
      my $intmax = (1 << ($Config{ivsize}*4-1)) - 1;
      $nvx = sprintf(".xpad_cop_seq.xlow = %${uvuformat}, .xpad_cop_seq.xhigh = %${uvuformat}%s",
                     $sv->COP_SEQ_RANGE_LOW, $sv->COP_SEQ_RANGE_HIGH,
		     $sv->COP_SEQ_RANGE_HIGH > $intmax  ? "U" : ""
		    );
    } else {
      my $sval = sprintf("%g", $nvx);
      $nvx = '0' if $sval =~ /(NAN|inf)$/i;
    }
  }
  if ($PERL510) {
    # For some time the stringification works of NVX double to two ints worked ok.
    if ($PERL514) {
      $xpvnvsect->comment('STASH, MAGIC, cur, len, IVX, NVX');
      $xpvnvsect->add(sprintf( "Nullhv, {0}, %u, %u, {%ld}, {%s}", $cur, $len, $ivx, $nvx) );
    } else {
      $xpvnvsect->comment('NVX, cur, len, IVX');
      $xpvnvsect->add(sprintf( "{%s}, %u, %u, {%ld}", $nvx, $cur, $len, $ivx ) );
    }
    unless ($C99 or $sv->FLAGS & (SVf_NOK|SVp_NOK)) {
      warn "NV => run-time union xpad_cop_seq init\n" if $debug{sv};
      my $intmax = (1 << ($Config{ivsize}*4-1)) - 1;
      $init->add(sprintf("xpvnv_list[%d].xnv_u.xpad_cop_seq.xlow = %${uvuformat};",
                         $xpvnvsect->index, $sv->COP_SEQ_RANGE_LOW),
                 # pad.c: PAD_MAX = I32_MAX (4294967295)
                 # U suffix <= "warning: this decimal constant is unsigned only in ISO C90"
                 sprintf("xpvnv_list[%d].xnv_u.xpad_cop_seq.xhigh = %${uvuformat}%s;",
                         $xpvnvsect->index, $sv->COP_SEQ_RANGE_HIGH,
			 $sv->COP_SEQ_RANGE_HIGH > $intmax  ? "U" : ""));
    }
  }
  else {
    $xpvnvsect->comment('PVX, cur, len, IVX, NVX');
    if ($savesym =~ /^\(char\*\)get_cv\("/) { # Moose 5.8.9d Moose::Util::TypeConstraints::OptimizedConstraints::RegexpRef
      $xpvnvsect->add(sprintf( "%s, %u, %u, %d, %s", 'NULL', $cur, $len, $ivx, $nvx ) );
      $init->add(sprintf("xpvnv_list[%d].xpv_pv = %s;", $xpvnvsect->index, $savesym));
    } else {
      $xpvnvsect->add(sprintf( "%s, %u, %u, %d, %s", $savesym, $cur, $len, $ivx, $nvx ) );
    }
  }
  $svsect->add(
    sprintf("&xpvnv_list[%d], %lu, 0x%x %s",
            $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS, $PERL510 ? ', {(char*)ptr_undef}' : '' ) );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$B::C::pv_copy_on_grow or $] < 5.010) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv, $sv ) );
      }
      else {
        $init->add(
          savepvn( sprintf( "xpvnv_list[%d].xpv_pv", $xpvnvsect->index ), $pv ) );
      }
    } else {
      if ($shared_hek) { # avoid free of static hek's
	$free->add("    SvFAKE_off(&$s);");
      } else {
	push @static_free, $s if $len and !$in_endav;
      }
    }
  }
  savesym( $sv, "&".$s );
}

sub B::BM::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if !$PERL510 and defined $sym;
  $sv = bless $sv, "B::BM" if $PERL510;
  my $pv  = pack "a*", ( $sv->PV . "\0" . $sv->TABLE );
  my $len = length($sv->PV);
  if ($PERL510) {
    warn "Saving FBM for GV $sym\n" if $debug{gv};
    $init->add( sprintf( "$sym = (GV*)newSV_type(SVt_PVGV);" ),
		sprintf( "SvFLAGS($sym) = 0x%x;", $sv->FLAGS),
		sprintf( "SvREFCNT($sym) = %u;", $sv->REFCNT + 1 ),
		sprintf( "SvPVX($sym) = %s;", cstring($pv) ),
		sprintf( "SvLEN_set($sym, %d);", $len ),
                sprintf( "BmRARE($sym) = %d;", $sv->RARE ),
                sprintf( "BmPREVIOUS($sym) = %d;", $sv->PREVIOUS ),
                sprintf( "BmUSEFUL($sym) = %d;", $sv->USEFUL )
              );
  } else {
    local $B::C::pv_copy_on_grow;
    $B::C::pv_copy_on_grow = 1
      if $B::C::const_strings and $sv->FLAGS & SVf_READONLY and $] != 5.008009;
    $xpvbmsect->comment('pvx,cur,len(+258),IVX,NVX,MAGIC,STASH,USEFUL,PREVIOUS,RARE');
    $xpvbmsect->add(
       sprintf("%s, %u, %u, %d, %s, 0, 0, %d, %u, 0x%x",
	       defined($pv) && $B::C::pv_copy_on_grow ? cstring($pv) : "(char*)ptr_undef",
	       $len,        $len + 258,    $sv->IVX, $sv->NVX,
	       $sv->USEFUL, $sv->PREVIOUS, $sv->RARE
	      ));
    $svsect->add(sprintf("&xpvbm_list[%d], %lu, 0x%x",
                         $xpvbmsect->index, $sv->REFCNT, $sv->FLAGS));
    $svsect->debug( $sv->flagspv ) if $debug{flags};
    my $s = "sv_list[".$svsect->index."]";
    if (!$B::C::pv_copy_on_grow) {
      $init->add(savepvn( sprintf( "xpvbm_list[%d].xpv_pv", $xpvbmsect->index ), $pv ) );
    } else {
      push @static_free, $s if defined($pv) and !$in_endav;
    }
  }
  # Restore possible additional magic. fbm_compile adds just 'B'.
  $sv->save_magic;

  if ($PERL510) {
    return $sym;
  } else {
    if ($] == 5.008009) { # XXX 5.8.9 needs more. TODO test 5.8.0 - 5.8.7
      $init->add( sprintf( "fbm_compile(&sv_list[%d], 0);", $svsect->index ) );
    }
    # cur+len was broken on all B::C versions
    #$init->add(sprintf( "xpvbm_list[%d].xpv_cur = %u;", $xpvbmsect->index, $len ) );
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
}

sub B::PV::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my $flags = $sv->FLAGS;
  my $shared_hek = $PERL510 ? (($flags & 0x09000000) == 0x09000000) : undef;
  local $B::C::pv_copy_on_grow;
  $B::C::pv_copy_on_grow = 1 if $B::C::const_strings
    and !$shared_hek
    and $flags & SVf_READONLY;
  # XSLoader reuses this SV, so it must be dynamic
  $B::C::pv_copy_on_grow = 0 if !($flags & SVf_ROK) and $sv->PV and $sv->PV =~ /::bootstrap$/;
  my ( $savesym, $cur, $len, $pv ) = save_pv_or_rv($sv, $fullname);
  my $refcnt = $sv->REFCNT;
  # $refcnt-- if $B::C::pv_copy_on_grow;
  # static pv, do not destruct. test 13 with pv0 "3".
  $len = 0 if $B::C::pv_copy_on_grow or $shared_hek;
  if ($PERL510) {
    if ($B::C::const_strings and $flags & SVf_READONLY and !$len) {
      #=> constpv: turnoff SVf_FAKE
      $flags &= ~0x01000000;
    }
    $xpvsect->add( sprintf( "%s{0}, %u, %u", $PERL514 ? "Nullhv, " : "", $cur, $len ) );
    $svsect->add( sprintf( "&xpv_list[%d], %lu, 0x%x, {%s}",
                           $xpvsect->index, $refcnt, $flags,
                           defined($pv) && $B::C::pv_copy_on_grow ? "(char*)$savesym" : "(char*)ptr_undef"));
    if ( defined($pv) and !$B::C::pv_copy_on_grow ) {
      $init->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv, $sv ) );
    }
    if ($debug{flags} and $DEBUGGING) { # add sv_debug_file
      $init->add(sprintf(qq(sv_list[%d].sv_debug_file = %s" sv_list[%d] 0x%x";),
			 $svsect->index, cstring($pv) eq '0' ? '"NULL"' : cstring($pv),
			 $svsect->index, $sv->FLAGS));
    }
  }
  else {
    $xpvsect->add( sprintf( "%s, %u, %u", "(char*)$savesym", $cur, $len ) );
    $svsect->add(sprintf("&xpv_list[%d], %lu, 0x%x",
			 $xpvsect->index, $refcnt, $flags));
    if ( defined($pv) and !$B::C::pv_copy_on_grow ) {
      $init->add( savepvn( sprintf( "xpv_list[%d].xpv_pv", $xpvsect->index ), $pv ) );
    }
  }
  my $s = "sv_list[".$svsect->index."]";
  if ( $B::C::pv_copy_on_grow ) {
    if ($shared_hek) { # avoid free of static hek's
      $free->add("    SvFAKE_off(&$s);");
    } else {
      push @static_free, $s if defined($pv) and !$in_endav;
    }
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  savesym( $sv, "&".$s );
}

sub lexwarnsym {
  my $iv = shift;
  if ($lexwarnsym{$iv}) {
    return $lexwarnsym{$iv};
  } else {
    warn "internal warning: lexwarn value $iv looks wrong\n" if $iv > 66000;
    my $sym = sprintf( "iv%d", $pv_index++ );
    $decl->add( sprintf( "Static const STRLEN %s = %d;", $sym, $iv ) );
    $lexwarnsym{$iv} = $sym;
    return $sym;
  }
}

# pre vs. post 5.8.9/5.9.4 logic for lexical warnings
@B::LEXWARN::ISA = qw(B::PV B::IV);
sub B::LEXWARN::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $iv = $] >= 5.008009 ? length($sv->PVX) : $sv->IV;
  if ($] < 5.009004 and $] >= 5.009) { $iv = length($sv->PVX); }
  my $ivsym = lexwarnsym($iv); # look for shared const int's
  return savesym($sv, $ivsym);
}

# post 5.11: When called from save_rv not from PMOP::save precomp
sub B::REGEXP::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $pv = $sv->PV;
  my $len = length(pack("a*", $pv));
  # Unfortunately this XPV is needed temp. Later replaced by struct regexp.
  $xpvsect->add( sprintf( "%s{0}, %u, %u", $PERL514 ? "Nullhv, " : "", $len, 0 ) );
  $svsect->add(sprintf("&xpv_list[%d], %lu, 0x%x, {%s}",
  		       $xpvsect->index, $sv->REFCNT, $sv->FLAGS, cstring($pv)));
  my $ix = $svsect->index;
  warn "Saving RX \"".$sv->PV."\" to sv_list[$ix], called from @{[(caller(1))[3]]}, "
    ."@{[(caller(2))[3]]}, @{[(caller(3))[3]]}, @{[(caller(4))[3]]}\n" if $debug{rx} or $debug{sv};
  if (0) {
    my $pkg = $sv->SvSTASH;
    if ($$pkg) {
      warn sprintf("stash isa class($pkg) 0x%x\n", $$pkg) if $debug{mg} or $debug{gv};
      $pkg->save;
      $init->add( sprintf( "SvSTASH_set(s\\_%x, s\\_%x);", $$sv, $$pkg ) );
      $init->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
    }
  }
  $init->add(# replace XVP with struct regexp. need pv and extflags
	     sprintf("SvANY(&sv_list[$ix]) = SvANY(CALLREGCOMP(&sv_list[$ix], 0x%x));",
		     $sv->EXTFLAGS));
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  $sym = savesym( $sv, sprintf( "&sv_list[%d]", $ix ) );
  $sv->save_magic;
  return $sym;
}

sub B::PVMG::save {
  my ($sv, $fullname) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  # local $B::C::pv_copy_on_grow = 1 if $B::C::const_strings and $flags & SVf_READONLY;
  my ( $savesym, $cur, $len, $pv ) = save_pv_or_rv($sv, $fullname);
  $savesym = "(char*)$savesym";
  my $shared_hek = $PERL510 ? (($sv->FLAGS & 0x09000000) == 0x09000000) : undef;
  $len = 0 if $B::C::pv_copy_on_grow or $shared_hek;
  #warn sprintf( "PVMG %s (0x%x) $savesym, $len, $cur, $pv\n", $sym, $$sv ) if $debug{mg};

  if ($PERL510) {
    if ($sv->FLAGS & SVf_ROK) {  # sv => sv->RV cannot be initialized static.
      $init->add(sprintf("SvRV_set(&sv_list[%d], (SV*)%s);", $svsect->index+1, substr($savesym,7)))
	if $savesym ne '(char*)';
      $savesym = '0';
    } else {
      if ( $B::C::pv_copy_on_grow ) {
        # comppadnames needs &PL_sv_undef instead of 0
	# But threaded PL_sv_undef => my_perl->Isv_undef, and my_perl is not available static
	if (!$pv or !$savesym or $savesym eq 'NULL') {
	  if ($MULTI) {
	    $savesym = "NULL";
	    $init->add( sprintf( "sv_list[%d].sv_u.svu_pv = (char*)&PL_sv_undef;",
				 $svsect->index+1 ) );
	  } else {
	    $savesym = '(char*)&PL_sv_undef';
	  }
	}
      }
    }
    my ($ivx,$nvx) = (0, "0");
    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    if ($] >= 5.011 and ref($sv) eq 'B::REGEXP') {
      return B::REGEXP::save($sv);
    }
    else {
      $ivx = $sv->IVX; # XXX How to detect HEK* namehek?
      $nvx = $sv->NVX; # it cannot be xnv_u.xgv_stash ptr (BTW set by GvSTASH later)
    }
    if ($PERL514) {
      $xpvmgsect->comment("STASH, MAGIC, cur, len, xiv_u, xnv_u");
      $xpvmgsect->add(sprintf("Nullhv, {0}, %u, %u, {%ld}, {%s}",
			      $cur, $len, $ivx, $nvx));
    } else {
      $xpvmgsect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash");
      $xpvmgsect->add(sprintf("{%s}, %u, %u, {%ld}, {0}, Nullhv",
			    $nvx, $cur, $len, $ivx));
    }
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x, {%s}",
                         $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS, $savesym));
    my $s = "sv_list[".$svsect->index."]";
    if ($shared_hek) { # avoid free of static hek's
      $free->add("    SvFAKE_off(&$s);");
    } else {
      push @static_free, $s if $len and $B::C::pv_copy_on_grow and !$in_endav;
    }
  }
  else {
    # cannot initialize this pointer static
    if ($savesym =~ /&(PL|sv)/) { # (char*)&PL_sv_undef | (char*)&sv_list[%d]
      $xpvmgsect->add(sprintf("%d, %u, %u, %ld, %s, 0, 0",
			      0, $cur, $len, $sv->IVX, $sv->NVX));
      $init->add( sprintf( "xpvmg_list[%d].xpv_pv = $savesym;",
			   $xpvmgsect->index ) );
    } else {
      $xpvmgsect->add(sprintf("%s, %u, %u, %ld, %s, 0, 0",
			      $savesym, $cur, $len, $sv->IVX, $sv->NVX));
      push @static_free, sprintf("sv_list[%d]", $svsect->index+1)
	if $len and $B::C::pv_copy_on_grow and !$in_endav;
    }
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x",
			 $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  if ( !$B::C::pv_copy_on_grow ) {
    # comppadnames need &PL_sv_undef instead of 0
    if ($PERL510) {
      if ($savesym) {
	if (!$pv or $savesym eq 'NULL') {
	  $init->add( sprintf( "sv_list[%d].sv_u.svu_pv = (char*)&PL_sv_undef;",
			       $svsect->index ) );
	} else {
	  $init->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv",
					$svsect->index ), $pv, $sv ) );
	}
      }
    } else {
      if (!$pv or !$savesym or $savesym eq 'NULL') {
        $init->add( sprintf( "xpvmg_list[%d].xpv_pv = (char*)&PL_sv_undef;",
			     $xpvmgsect->index ) );
      } else {
        $init->add(savepvn( sprintf( "xpvmg_list[%d].xpv_pv", $xpvmgsect->index ),
			    $pv ) );
      }
    }
  }
  $sym = savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  $sv->save_magic($fullname);
  return $sym;
}

# mark threads::shared to be xs-loaded
sub mark_threads {
  if ( $threads::VERSION ) {
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
    $init->add( sprintf( "SvSTASH_set(s\\_%x, s\\_%x);", $$sv, $$pkg ) );
    $init->add( sprintf( "SvREFCNT((SV*)s\\_%x) += 1;", $$pkg ) );
    # XXX
    #push_package($pkg->NAME);  # correct code, but adds lots of new stashes
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
      warn sprintf( "%s magic\n", cchar($type) );
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
	warn "C.xs Warning: PMOP missing for QR\n";
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
          push @static_free, $resym;
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
    elsif ( $type eq 'D' ) { # XXX regdata AV - coverage?
      if ($obj = $mg->OBJ) {
	# see Perl_mg_copy() in mg.c
	$init->add(sprintf("sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
			   $$sv, $$sv, "'D'", cstring($ptr), $len ));
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
    else {
      $init->add(sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
          $$sv, $$obj, cchar($type), cstring($ptr), $len
        )
      )
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
    $svsect->debug( $sv->flagspv ) if $debug{flags};
    $init->add( sprintf( "sv_list[%d].sv_u.svu_rv = (SV*)%s;", $svsect->index, $rv ) );
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
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
    elsif ( $rv =~ /get_cv\(/ ) {
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
    $svsect->debug( $sv->flagspv ) if $debug{flags};
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
}

# If a method can be called (via UNIVERSAL::can) search the ISA's. No AUTOLOAD needed.
# XXX issue 64, empty @ISA if a package has no subs. in Bytecode ok
sub try_isa {
  my ( $cvstashname, $cvname ) = @_;
  no strict 'refs';
  # XXX theoretically a valid shortcut. In reality it fails...
  # return 0 unless $cvstashname->can($cvname);
  my @isa = $PERL510 ? @{mro::get_linear_isa($cvstashname)} : @{ $cvstashname . '::ISA' };
  warn sprintf( "No definition for sub %s::%s. Try \@%s::ISA=(%s)\n",
		$cvstashname, $cvname, $cvstashname, join(",",@isa))
    if $debug{cv};
  for (@isa) { # global @ISA or in pad
    next if $_ eq $cvstashname;
    warn sprintf( "Try &%s::%s\n", $_, $cvname ) if $debug{cv};
    if (defined(*{$_ .'::'. $cvname}{CODE})) {
      mark_package($_, 1); # force
      return 1;
    } else {
      my @i = $PERL510 ? @{mro::get_linear_isa($_)} : @{ $_ . '::ISA' };
      if (@i) {
	try_isa($_, $cvname) and return 1;
      }
    }
  }
  return 0; # not found
}

# If the sub or method is not found:
# 1. try @ISA, mark_package and return.
# 2. try UNIVERSAL::method
# 2. try compile-time expansion of AUTOLOAD to get the goto &sub addresses
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
    my $stub = sub { require 'utf8_heavy.pl'; goto &utf8::SWASHNEW; };
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
    eval { local $SIG{__DIE__}; require "auto/$dir/$cvname.al" };
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
    warn sprintf( "CV 0x%x already saved as $sym\n", $$cv ) if $debug{cv};
    return $sym;
  }
  my $gv = $cv->GV;
  my ( $cvname, $cvstashname, $fullname );
  if ($$gv) {
    $cvstashname = $gv->STASH->NAME;
    $cvname      = $gv->NAME;
    $fullname    = $cvstashname.'::'.$cvname;
    warn sprintf( "CV 0x%x as PVGV 0x%x %s CvFLAGS=0x%x\n",
                  $$cv, $$gv, $fullname, $cv->CvFLAGS )
      if $debug{cv};
    # XXX not needed, we already loaded utf8_heavy
    #return if $fullname eq 'utf8::AUTOLOAD';
    return '0' if $all_bc_subs{$fullname} or $skip_package{$cvstashname};
    mark_package($cvstashname, 1) unless $include_package{$cvstashname};
  }

  # XXX TODO need to save the gv stash::AUTOLOAD if exists
  my $root    = $cv->ROOT;
  my $cvxsub  = $cv->XSUB;
  my $isconst;
  { no strict 'subs';
    $isconst = $PERL56 ? 0 : $cv->CvFLAGS & CVf_CONST;
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
      elsif ( $stashname ne 'attributes'
        && !UNIVERSAL::isa( $stashname, 'DynaLoader' ) )
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
      warn sprintf( "stub for XSUB $fullname CV 0x%x\n", $$cv )
    	if $debug{cv};
      svref_2object( \*{"$stashname\::bootstrap"} )->save
        if $stashname;# and defined ${"$stashname\::bootstrap"};
      #mark_package($stashname); # not needed
      return qq/get_cv("$fullname", TRUE)/;
    } else {
      my $xsstash = $stashname;
      $xsstash =~ s/::/_/g;
      my $xs = "XS_${xsstash}_${cvname}";
      if ($stashname eq 'version') { # exceptions see universal.c:struct xsub_details details[]
        my %vtrans = (
                      'parse' => 'new',
                      '(""'   => 'stringify',
                      '(0+'   => 'numify',
                      '(cmp'  => 'vcmp',
                      '(<=>'  => 'vcmp',
                      '(bool' => 'boolean',
                      'declare'   => 'qv',
                     );
        if ($vtrans{$cvname}) {
          $xs = "XS_version_".$vtrans{$cvname};
        } elsif ($cvname =~ /^\(/ ) {
          $xs = "XS_version_noop";
	}
      }
      elsif ($fullname eq 'Internals::hv_clear_placeholders') {
	$xs = 'XS_Internals_hv_clear_placehold';
      }
      elsif ($fullname eq 'Tie::Hash::NamedCapture::FIRSTKEY') {
	$xs = 'XS_Tie_Hash_NamedCapture_FIRSTK';
      }
      elsif ($fullname eq 'Tie::Hash::NamedCapture::NEXTKEY') {
	$xs = 'XS_Tie_Hash_NamedCapture_NEXTK';
      }
      warn sprintf( "core XSUB $xs CV 0x%x\n", $$cv )
    	if $debug{cv};
      if (!$ENV{DL_NOWARN} and $stashname eq 'DynaLoader' and $] >= 5.015002 and $] < 5.015004) {
	# [perl #100138] DynaLoader symbols are XS_INTERNAL since 5.15.2 (16,29,44,45).
	# Not die because the patched libperl is hard to detect (nm libperl|egrep "_XS_Dyna.* t "),
	# and we want to allow a patched libperl.
	warn "Warning: DynaLoader broken with 5.15.2-5.15.3.\n".
	  "  Use 0001-Export-DynaLoader-symbols-from-libperl-again.patch in [perl #100138]"
	    unless $B::C::DynaLoader_warn;
	$B::C::DynaLoader_warn++;
      }
      $decl->add("XS($xs);");
      return qq/newXS("$fullname", $xs, (char*)xsfile)/;
    }
  }
  if ( $cvxsub && $cvname eq "INIT" ) {
    no strict 'refs';
    warn $fullname."\n" if $debug{sub};
    return svref_2object( \&Dummy_initxs )->save;
  }

  if ($isconst and !($cv->CvFLAGS & CVf_ANON)) {
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
    $svsect->add("SVIX$sv_ix");
    $xpvcv_ix = $xpvcvsect->index + 1;
    $xpvcvsect->add("XPVCVIX$xpvcv_ix");
    # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
    $sym = savesym( $cv, "&sv_list[$sv_ix]" );
  }

  warn sprintf( "saving $fullname CV 0x%x as $sym\n", $$cv )
    if $debug{cv};
  # $package_pv = $cvstashname;
  # push_package($package_pv);
  if ($fullname eq 'utf8::SWASHNEW') { # bypass utf8::AUTOLOAD, a new 5.13.9 mess
    require "utf8_heavy.pl";
    # sub utf8::AUTOLOAD {}; # How to ignore &utf8::AUTOLOAD with Carp? The symbol table is
    # already polluted. See issue 61.
    svref_2object( \&{"utf8\::SWASHNEW"} )->save;
  }
  if ( !$$root && !$cvxsub ) {
    if ( my $auto = try_autoload( $cvstashname, $cvname ) ) {
      if (ref $auto eq 'B::CV') { # explicit goto or UNIVERSAL
        $root   = $auto->ROOT;
        $cvxsub = $auto->XSUB;
	if ($$auto) {
	  $cv  = $auto ; # This is new. i.e. via AUTOLOAD or UNIVERSAL, in another stash
	  my $gv = $cv->GV;
	  if ($$gv) {
	    if ($cvstashname ne $gv->STASH->NAME or $cvname ne $gv->NAME) { # UNIVERSAL or AUTOLOAD
	      warn "New ".$gv->STASH->NAME."::".$gv->NAME."\n" if $verbose;
	      $svsect->remove;
	      $xpvcvsect->remove;
	      delsym($cv);
	      return $cv->save($gv->STASH->NAME."::".$gv->NAME);
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
	    warn "Recalculated root and xsub $gv->STASH->NAME\::$gv->NAME\n" if $verbose;
	    $svsect->remove;
	    $xpvcvsect->remove;
	    delsym($cv);
	    return $cv->save;
	  }
	}
      }
      if ( $$root || $cvxsub ) {
        warn "Successful forced autoload\n" if $verbose;
      }
    }
  }

  my $startfield = 0;
  my $padlist    = $cv->PADLIST;
  my $padlistsym = 'NULL';
  my $pv         = $cv->PV;
  my $xsub       = 0;
  my $xsubany    = "Nullany";
  if ($$root) {
    warn sprintf( "saving op tree for CV 0x%x, root=0x%x\n",
                  $$cv, $$root )
      if $debug{cv};
    my $ppname = "";
    if ($$gv) {
      my $stashname = $gv->STASH->NAME;
      my $gvname    = $gv->NAME;
      $fullname = $stashname.'::'.$gvname;
      if ( $gvname ne "__ANON__" ) {
        $ppname = ( ${ $gv->FORM } == $$cv ) ? "pp_form_" : "pp_sub_";
        $ppname .= ( $stashname eq "main" ) ? $gvname : "$stashname\::$gvname";
        $ppname =~ s/::/__/g;
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
        if $debug{cv};
      # XXX avlen 2
      $padlistsym = $padlist->save($fullname.' :pad');
      warn sprintf( "done saving PADLIST %s 0x%x for CV 0x%x\n",
		    $padlistsym, $$padlist, $$cv )
        if $debug{cv};
      # do not record a forward for the pad only
      $init->add( "CvPADLIST($sym) = $padlistsym;" );
    }
    warn $fullname."\n" if $debug{sub};
  }
  else {
    warn $fullname." not found\n" if $debug{sub};
    warn "No definition for sub $fullname (unable to autoload)\n"
      if $debug{cv};
    $init->add( "/* $fullname not found */" ) if $verbose or $debug{sub};
    # XXX empty CV should not be saved
    # $svsect->remove( $sv_ix );
    # $xpvcvsect->remove( $xpvcv_ix );
    # delsym( $cv );
    # return '0';
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

  $pv = '' unless defined $pv;    # Avoid use of undef warnings
  my ( $pvsym, $cur, $len ) = ('NULL',0,0);
  if ($PERL510) {
    ( $pvsym, $cur ) = save_hek($pv);
    # XXX issue 84: we need to check the cv->PV ptr not the value.
    # "" is different to NULL for prototypes
    if ($cur) {
      $len = $B::C::pv_copy_on_grow ? 0 : $cur+1;
    }
    # TODO:
    # my $ourstash = "0";  # TODO stash name to bless it (test 16: "main::")
    if ($PERL514) {
      my $xpvc = sprintf
	# stash magic cur len cvstash start root cvgv cvfile cvpadlist     outside outside_seq cvflags cvdepth
	("Nullhv, {0}, %u, %u, %s, {%s}, {s\\_%x}, %s, %s, (PADLIST *)%s, (CV*)s\\_%x, %s, 0x%x, %d",
	 $cur, $len, "Nullhv",#CvSTASH later
	 $startfield, $$root,
	 "0",    #GV later
	 "NULL", #cvfile later (now a HEK)
	 $padlistsym,
	 ${ $cv->OUTSIDE }, #if main_cv set later
	 $cv->OUTSIDE_SEQ,
	 ($$gv and $cv->CvFLAGS & 0x400) ? 0 : $cv->CvFLAGS, # otherwise we cannot set the GV
	 $cv->DEPTH);
      if (!$new_cv_fw) {
	$symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
	#$symsect->add
	#  (sprintf("SVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}"),
	#	   $sv_ix, $xpvcv_ix, $cv->REFCNT + 1 * 0, $cv->FLAGS
	#	  ));
      } else {
	$xpvcvsect->comment('STASH mg_u cur len CV_STASH START_U ROOT_U GV file PADLIST OUTSIDE outside_seq flags depth');
	$xpvcvsect->add($xpvc);
	$svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x, {0}",
			     $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS));
	$svsect->debug( $cv->flagspv ) if $debug{flags};
      }
    } else {
      $cur = length ( pack "a*", $pv );
      if ($cur) {
	# XXX issue 84: we need to check the cv->PV ptr not the value.
	# "" is different to NULL for prototypes
	$len = $B::C::pv_copy_on_grow ? 0 : $cur+1;
      }
      my $xpvc = sprintf
	("{%d}, %u, %u, {%s}, {%s}, %s,"
	 ." %s, {%s}, {s\\_%x}, %s, %s, (PADLIST *)%s,"
	 ." (CV*)s\\_%x, %s, 0x%x",
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
	 ${ $cv->OUTSIDE }, #if main_cv set later
	 $cv->OUTSIDE_SEQ,
	 $cv->CvFLAGS
	);
      if (!$new_cv_fw) {
	$symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
	#$symsect->add
	#  (sprintf("SVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x, {0}",
	#	   $sv_ix, $xpvcv_ix, $cv->REFCNT + 1 * 0, $cv->FLAGS
	#	  ));
      } else {
	$xpvcvsect->comment('GvSTASH cur len  depth mg_u MG_STASH CV_STASH START_U ROOT_U CV_GV cv_file PADLIST OUTSIDE outside_seq cv_flags');
	$xpvcvsect->add($xpvc);
	$svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x, {0}",
			     $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS));
	$svsect->debug( $cv->flagspv ) if $debug{flags};
      }
    }
    my $gvstash = $gv->STASH;
    if ($$gvstash and $$cv) {
      # do not use GvSTASH because with DEBUGGING it checks for GP but
      # there's no GP yet.
      $init->add( sprintf( "GvXPVGV(s\\_%x)->xnv_u.xgv_stash = s\\_%x;",
			   $$cv, $$gvstash ) );
      warn sprintf( "done saving GvSTASH 0x%x for CV 0x%x\n", $$gvstash, $$cv )
	if $debug{cv};
    }
    if ( $cv->OUTSIDE_SEQ ) {
      my $cop = $symtable{ sprintf( "s\\_%x", $cv->OUTSIDE_SEQ ) };
      $init->add( sprintf( "CvOUTSIDE_SEQ(%s) = %s;", $sym, $cop ) ) if $cop;
    }
  }
  elsif ($PERL56) {
    $cur = length ( pack "a*", $pv );
    my $xpvc = sprintf("%s, %u, %u, %d, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub, $xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)s\\_%x, 0x%x",
	       cstring($pv), length($pv), length($pv), $cv->IVX,
	       $cv->NVX,  $startfield,       $$root, $cv->DEPTH,
	       $$padlist, ${ $cv->OUTSIDE }, $cv->CvFLAGS
	      );
    if ($new_cv_fw) {
      $xpvcvsect->comment('pv cur len off nv magic mg_stash cv_stash start root xsub xsubany cv_gv cv_file cv_depth cv_padlist cv_outside cv_flags');
      $xpvcvsect->add($xpvc);
      $svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x"),
		   $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS);
      $svsect->debug( $cv->flagspv ) if $debug{flags};
    } else {
      $symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
    }
  }
  else { #5.8
    $cur = length ( pack "a*", $pv );
    my $xpvc = sprintf("%s, %u, %u, %d, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub, $xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)s\\_%x, 0x%x, 0x%x",
	       cstring($pv),      length($pv), length($pv), $cv->IVX,
	       $cv->NVX,  $startfield,       $$root, $cv->DEPTH,
	       $$padlist, ${ $cv->OUTSIDE }, $cv->CvFLAGS,   $cv->OUTSIDE_SEQ
	      );
    if ($new_cv_fw) {
      $xpvcvsect->comment('pv cur len off nv           magic mg_stash cv_stash start root xsub xsubany cv_gv cv_file cv_depth cv_padlist cv_outside cv_flags outside_seq');
      $xpvcvsect->add($xpvc);
      $svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x"),
		   $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS);
      $svsect->debug( $cv->flagspv ) if $debug{flags};
    } else {
      $symsect->add("XPVCVIX$xpvcv_ix\t$xpvc");
    }
  }

  if ( ${ $cv->OUTSIDE } == ${ main_cv() } ) {
    $init->add( sprintf( "CvOUTSIDE(s\\_%x) = PL_main_cv;", $$cv ) );
    $init->add( sprintf( "SvREFCNT_inc(PL_main_cv);") );
  }
  if ($$gv) {
    #test 16: Can't call method "FETCH" on unblessed reference. gdb > b S_method_common
    warn sprintf( "Saving GV 0x%x for CV 0x%x\n", $$gv, $$cv ) if $debug{cv};
    $gv->save;
    if ($PERL514) {
      # XXX gvcv might be PVMG
      $init->add( sprintf( "CvGV_set((CV*)%s, (GV*)%s);", $sym, objsym($gv) ) );
      # since 5.13.3 and CvGV_set there are checks that the CV is not RC (refcounted)
      # assertion "!CvCVGV_RC(cv)" failed: file "gv.c", line 219, function: Perl_cvgv_set
      # we init with CvFLAGS = 0 and set it later, as successfully done in the Bytecode compiler
      if ($cv->CvFLAGS & 0x0400) { # CVf_CVGV_RC
        warn sprintf( "CvCVGV_RC turned off. CV flags=0x%x %s CvFLAGS=0x%x \n",
                      $cv->FLAGS, $debug{flags}?$cv->flagspv:"", $cv->CvFLAGS & ~0x400)
          if $debug{cv};
        $init->add( sprintf( "CvFLAGS((CV*)%s) = %u;", $sym, $cv->CvFLAGS ) );
      }
      # XXX TODO someone is overwriting CvSTART also
      $init->add("CvSTART($sym) = $startfield;");
    } else {
      $init->add( sprintf( "CvGV(%s) = %s;", $sym, objsym($gv) ) );
    }
    warn sprintf("done saving GV 0x%x for CV 0x%x\n",
    		  $$gv, $$cv) if $debug{cv};
  }
  unless ($optimize_cop) {
    if ($MULTI) {
      $init->add( savepvn( "CvFILE($sym)", $cv->FILE, $gv ) );
    }
    else {
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
      if $debug{cv};
  }
  my $magic = $cv->MAGIC;
  if ($magic and $$magic) {
    $cv->save_magic; # XXX will this work?
  }
  if (!$new_cv_fw) {
    $symsect->add(sprintf(
      "SVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x".($PERL510?", {0}":''),
      $sv_ix, $xpvcv_ix, $cv->REFCNT + ($PERL510 ? 1 : 0), $cv->FLAGS
      )
    );
  }
  if ($cur) {
    warn sprintf( "Saving CV proto %s for CV 0x%x\n", $pv, $$cv ) if $debug{cv};
  }
  # issue 84: empty prototypes sub xx(){} vs sub xx{}
  if ($PERL510) {
    if ($cur) {
      $init->add( sprintf("SvPVX(&sv_list[%d]) = HEK_KEY(%s);", $sv_ix, $pvsym));
    } elsif (!$B::C::pv_copy_on_grow) { # not static, they are freed when redefined
      $init->add( sprintf("SvPVX(&sv_list[%d]) = savepvn(%s, %u);",
			  $sv_ix, cstring($pv), $cur));
    } else {
      $init->add( sprintf("SvPVX(&sv_list[%d]) = %s;",
			  $sv_ix, cstring($pv)));
    }
  }
  return $sym;
}

my @_v = Internals::V() if $] >= 5.011;
sub B::_V { @_v };

sub B::GV::save {
  my ($gv) = @_;
  my $sym = objsym($gv);
  if ( defined($sym) ) {
    warn sprintf( "GV 0x%x already saved as $sym\n", $$gv ) if $debug{gv};
    return $sym; # unless $_[1] eq 'main::INC' and $_[2];
  }
  else {
    my $ix = $gv_index++;
    $sym = savesym( $gv, "gv_list[$ix]" );
    warn sprintf( "Saving GV 0x%x as $sym\n", $$gv ) if $debug{gv};
  }
  warn sprintf( "  GV $sym type=%d, flags=0x%x\n", B::SV::SvTYPE($gv), $gv->FLAGS )
    if $debug{gv} and !$PERL56; # B::SV::SvTYPE not with 5.6
  if ($PERL510 and $gv->FLAGS & 0x40000000) { # SVpbm_VALID
    warn sprintf( "  GV $sym isa FBM\n") if $debug{gv};
    return B::BM::save($gv);
  }
if (0) {
  if ($PERL512 and $gv->FLAGS & 0x2) { # IV
    warn sprintf( "  Skip GV $sym isa IV (RV)\n") if $debug{gv};
    return $sym;
  }
  elsif (!$PERL510 and $gv->FLAGS & 0x3) { # RV
    warn sprintf( "  Skip GV $sym isa RV\n") if $debug{gv};
    return $sym;
  }
  elsif ($PERL510 and $]< 5.012 and $gv->FLAGS & 0x4) { # 510 RV
    warn sprintf( "  Skip GV $sym isa RV\n") if $debug{gv};
    return $sym;
  }
}
  my $gvname   = $gv->NAME;
  my $package  = $gv->STASH->NAME;
  return $sym if $skip_package{$package} or $package =~ /^B::C(C?)::/;

  my $is_empty = $gv->is_empty;
  my $fullname = $package . "::" . $gvname;
  my $name     = cstring($fullname);
  warn "  GV name is $name\n" if $debug{gv};
  my $egvsym;
  my $is_special = ref($gv) eq 'B::SPECIAL';

  if ( !$is_empty ) {
    my $egv = $gv->EGV;
    unless (ref($egv) eq 'B::SPECIAL') {
      my $estash = $egv->STASH->NAME;
      if ( $$gv != $$egv ) {
        warn(sprintf( "EGV name is %s, saving it now\n",
                      $estash . "::" . $egv->NAME )
            ) if $debug{gv};
        $egvsym = $egv->save;
        #{
          #no strict 'refs';
          # catch imported AUTOLOAD (unused)
          #svref_2object( \*{"$estash\::AUTOLOAD"} )->save
          #  if $estash and defined ${"$estash\::"}{AUTOLOAD};
          #svref_2object( \*{"$estash\::CLONE"} )->save
          #  if $estash and defined ${"$estash\::"}{CLONE};
        #}
      }
    }
  }
  if ($fullname eq 'main::ENV') {
    $init->add(qq[$sym = PL_envgv;]);
    return $sym;
  }
  # defer to the end because we remove compiler-internal and skipped stuff
  #if ($fullname eq 'main::INC' and !$_[2]) {
  #  return $sym;
  #}
  $init->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PV);]);
  my $svflags    = $gv->FLAGS;
  my $savefields = 0;
  sub Save_HV()   { 1 }
  sub Save_AV()   { 2 }
  sub Save_SV()   { 4 }
  sub Save_CV()   { 8 }
  sub Save_FORM() { 16 }
  sub Save_IO()   { 32 }

  my $gp;
  if ( $PERL510 and $gv->isGV_with_GP ) {
    if ($fullname eq 'main::ARGV') {
      warn "Skip overwriting main::ARGV GP\n" if $debug{gv};
    } else {
      $gp = $gv->GP;    # B limitation
      if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
	# Shared glob *foo = *bar
	$init->add( "GvGP_set($sym, GvGP($egvsym));" );
	$is_empty = 1;
      }
      elsif ( $gp and !$is_empty ) {
        warn(sprintf(
                     "New GvGP for *$fullname 0x%x%s %s GP:0x%x\n",
                     $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                     $gv->FILE, $gp
                    )) if $debug{gv};
        # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
        $init->add( sprintf("GvGP_set($sym, Perl_newGP(aTHX_ $sym));") );
        $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
      }
      else {
        $init->add( sprintf("GvGP_set($sym, Perl_newGP(aTHX_ $sym));") );
      }
    }
  }
  $init->add( sprintf( "SvFLAGS($sym) = 0x%x;%s", $svflags,
                       $debug{flags}?" /* ".$gv->flagspv." */":"" ));
  my $gvflags = $gv->GvFLAGS;
  if ($gvflags > 256) { $gvflags = $gvflags && 256 }; # $gv->GvFLAGS as U8
  $init->add( sprintf( "GvFLAGS($sym) = %d;",   $gvflags ));
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

  # Shouldn't need to do save_magic since gv_fetchpv handles that
  #$gv->save_magic if $PERL510;
  # Will always be > 1
  my $refcnt = $gv->REFCNT;
  $init->add( sprintf( "SvREFCNT($sym) += %u;", $refcnt ) ) if $refcnt > 0;

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
    $savefields = Save_HV;
  }
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
      warn "GV::save \$$fullname\n" if $debug{gv};
    }
    my $gvav = $gv->AV;
    if ( $$gvav && $savefields & Save_AV ) {
      if ($PERL510 and $fullname eq 'main::ARGV') {
        $init->add( '/* Skip overwriting @main::ARGV */' );
        warn "Skipping GV::save \@$fullname\n" if $debug{gv};
      } else {
        warn "GV::save \@$fullname\n" if $debug{gv};
	if ($fullname eq 'main::+' or $fullname eq 'main::-') {
	  $init->add("/* \@$gvname force saving of Tie::Hash::NamedCapture */");
	  mark_package('Tie::Hash::NamedCapture', 1);
	}
        $gvav->save($fullname);
        $init->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
      }
    }
    my $gvhv = $gv->HV;
    if ( $$gvhv && $savefields & Save_HV ) {
      if ($fullname eq 'main::INC') {
	inc_cleanup();
      }
      if ($fullname ne 'main::ENV') {
	warn "GV::save \%$fullname\n" if $debug{gv};
	if ($fullname eq 'main::!') { # force loading Errno
	  $init->add("/* \%! force saving of Errno */");
	  mark_package('Errno', 1);   # B::C needs Errno but does not import $!
	} elsif ($fullname eq 'main::+' or $fullname eq 'main::-') {
	  $init->add("/* \%$gvname force saving of Tie::Hash::NamedCapture */");
	  mark_package('Tie::Hash::NamedCapture', 1);
	}
	# XXX TODO 49: crash at BEGIN { %warnings::Bits = ... }
	$gvhv->save($fullname);
	$init->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
      }
    }
    my $gvcv = $gv->CV;
    if ( !$$gvcv && $savefields & Save_CV ) {
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
    if ( $$gvcv && $savefields & Save_CV and ref($gvcv->GV->EGV) ne 'B::SPECIAL') {
      my $origname =
        cstring( $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME );
      if ( $gvcv->XSUB and $name ne $origname ) {    #XSUB CONSTSUB alias
	my $package = $gvcv->GV->EGV->STASH->NAME;
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
        $init->add("{\tCV *cv;
		cv = get_cv($origname,TRUE);
		GvCV_set($sym, cv);
		SvREFCNT_inc((SV *)cv);","}");
      }
      elsif (!$PERL510 or $gp) {
	if ($fullname eq 'Internals::V') { # local_patches if $] >= 5.011
	  $gvcv = svref_2object( \&B::_V );
	}
	# TODO: may need fix CvGEN if >0 to re-validate the CV methods
	# on PERL510 (>0 + <subgeneration)
	warn "GV::save &$fullname...\n" if $debug{gv};
	$init->add( sprintf( "GvCV_set($sym, (CV*)(%s));", $gvcv->save($fullname) ) );
      }
    }
    if (!$PERL510 or $gp) {
      if ( $] > 5.009 ) {
	# TODO implement heksect to place all heks at the beginning
	#$heksect->add($gv->FILE);
	#$init->add(sprintf("GvFILE_HEK($sym) = hek_list[%d];", $heksect->index));
	$init->add(sprintf("GvFILE_HEK($sym) = %s;", save_hek($gv->FILE)))
	  unless $optimize_cop;
	$init->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;
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
  warn "GV::save *$fullname done\n" if $debug{gv};
  return $sym;
}

sub B::AV::save {
  my ($av, $fullname) = @_;
  my $sym = objsym($av);
  return $sym if defined $sym;

  $fullname = '' unless $fullname;
  my ($fill, $avreal);
  # cornercase: tied array without FETCHSIZE
  eval { $fill = $av->FILL; };
  $fill = -1 if $@;    # catch error in tie magic

  if ($PERL514) {
    # 5.13.3: STASH, MAGIC, fill max ALLOC
    my $line = "Nullhv, {0}, -1, -1, 0";
    $line = "Nullhv, {0}, $fill, $fill, 0" if $B::C::av_init or $B::C::av_init2;
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x, {%s}",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS,
                         '0'));
    #$avreal = $av->FLAGS & 0x40000000; # SVpav_REAL (unused)
  }
  elsif ($PERL510) {
    # 5.9.4+: nvu fill max iv MG STASH
    my $line = "{0}, -1, -1, {0}, {0}, Nullhv";
    $line = "{0}, $fill, $fill, {0}, {0}, Nullhv" if $B::C::av_init or $B::C::av_init2;
    $line = "Nullhv, {0}, $fill, $fill, NULL" if $PERL514;
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x, {%s}",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS,
                         '0'));
    #$avreal = $av->FLAGS & 0x40000000; # SVpav_REAL (unused)
  }
  else {
    # 5.8: ARRAY fill max off nv MG STASH ALLOC arylen flags
    my $line = "0, -1, -1, 0, 0.0, 0, Nullhv, 0, 0";
    $line = "0, $fill, $fill, 0, 0.0, 0, Nullhv, 0, 0" if $B::C::av_init or $B::C::av_init2;
    $line .= sprintf( ", 0x%x", $av->AvFLAGS ) if $] < 5.009;
    #$avreal = $av->AvFLAGS & 1; # AVf_REAL
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS));
  }
  $svsect->debug($av->flagspv) if $debug{flags};
  my $sv_list_index = $svsect->index;
  my $av_index = $xpvavsect->index;
  # protect against recursive self-references (Getopt::Long)
  $sym = savesym( $av, "(AV*)&sv_list[$sv_list_index]" );
  my $magic = $av->save_magic;

  if ( $debug{av} ) {
    my $line = sprintf( "saving AV 0x%x [%s] FILL=$fill", $$av, class($av));
    $line .= sprintf( " AvFLAGS=0x%x", $av->AvFLAGS ) if $] < 5.009;
    warn "$line\n";
  }

  # XXX AVf_REAL is wrong test: need to save comppadlist but not stack
  if ($fill > -1 and $magic !~ /D/) {
    my @array = $av->ARRAY; # crashes with D magic (Getopt::Long)
    if ( $debug{av} ) {
      my $el;
      my $i = 0;
      foreach $el (@array) {
        warn sprintf( "AV 0x%x[%d] = %s 0x%x\n", $$av, $i++, class($el), $$el );
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
    my $count;
    my @values = map { $_->save($fullname."[".$count++."]") || () } @array;
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
	  ." *svp++ = (SV*)&sv_list[gcount]; };\n\t";
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
	  ." *svp++ = (SV*)&PL_sv_undef; };\n\t";
	$i += $count;
      } else { # XXX 5.8.9d Test::NoWarnings has empty values
	$acc .= "\t*svp++ = (SV*)" . ($values[$i] ? $values[$i] : '&PL_sv_undef') . ";\n\t";
      }
    }
    $init->no_split;

    # With -fav-init2 use independent_comalloc()
    if ($B::C::av_init2) {
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
      $init->add(
                 "\tAV *av = $sym;",
                 "\tav_extend(av, $fill1);",
                 "\tsvp = AvARRAY(av);"
                );
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

    # Fix weird package names containing double-quotes, \n analog to gv_fetchpv
    my $cname = cstring($name);
    $init->add(qq[hv$hv_index = gv_stashpv($cname, TRUE);]);
    if ($adpmroot) {
      $init->add(sprintf( "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;",
			  $adpmroot ) );
    }
    $sym = savesym( $hv, "hv$hv_index" );
    $hv_index++;

    # issue 79: save stashes to check for packages.
    # and via B::STASHGV we only save stashes for stashes.
    # For efficiency we skip most stash symbols unless -fstash.
    # However it should be now safe to save all stash symbols.
    # $fullname !~ /::$/ or
    return $sym if !$B::C::stash or skip_pkg($name);
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
			 $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS & ~SVf_READONLY));
    # XXX failed at 16 (tied magic) for %main::
    if ($hv->MAGICAL and !$is_stash) { # riter,eiter only for magic required
      $sym = sprintf("&sv_list[%d]", $svsect->index);
      my $hv_max = $hv->MAX + 1;
      # riter required, new _aux struct at the end of the HvARRAY. allocate ARRAY also.
      $init->add("{\tHE **a; struct xpvhv_aux *aux;",
		 sprintf("\tNewx(a, %d, HE*);", $hv_max+1),
		 "\tHvARRAY($sym) = a;",
		 sprintf("\tZero(HvARRAY($sym), %d, HE*);", $hv_max+1),
		 "\tNewx(aux, 1, struct xpvhv_aux);",
		 sprintf("\tHvARRAY($sym)[%d] = (HE*)aux;", $hv_max),
		 sprintf("\tHvRITER_set($sym, %d);", $hv->RITER),
		 "\tHvEITER_set($sym, NULL); }");
    }
  } # !5.10
  else {
    $xpvhvsect->comment( "array fill max keys nv mg stash riter eiter pmroot name" );
    $xpvhvsect->add(sprintf( "0, 0, %d, 0, 0.0, 0, Nullhv, %d, 0, 0, 0",
			     $hv->MAX, $hv->RITER));
    $svsect->add(sprintf( "&xpvhv_list[%d], %lu, 0x%x",
			  $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS));
  }
  $svsect->debug($hv->flagspv) if $debug{flags};
  my $sv_list_index = $svsect->index;
  warn sprintf( "saving HV $fullname &sv_list[$sv_list_index] 0x%x MAX=%d\n",
                $$hv, $hv->MAX ) if $debug{hv};
  my @contents     = $hv->ARRAY;
  # protect against recursive self-reference
  # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
  # value => rv => cv => ... => rv => same hash
  $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" ) unless $is_stash;
  if (@contents) {
    my ($i, $length);
    $length = scalar(@contents);
    for ( $i = 1 ; $i < @contents ; $i += 2 ) {
      my $key = $contents[$i - 1];
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
	warn "saving HV $fullname".'{'.$key."}\n" if $debug{hv};
	$contents[$i] = $sv->save($fullname.'{'.$key.'}');
      }
    }
    if ($length) { # there may be skipped STASH symbols
      $init->no_split;
      $init->add( "{",
		  sprintf("\tHV *hv = %s$sym;", $sym=~/^hv|\(HV/ ? '' : '(HV*)' ));
      while (@contents) {
	my ( $key, $value ) = splice( @contents, 0, 2 );
	if ($value) {
	  $init->add(sprintf( "\thv_store(hv, %s, %u, %s, %s);",
			      cstring($key), length( pack "a*", $key ),
			      "(SV*)$value", 0 )); # !! randomized hash keys
	  warn sprintf( "  HV key \"%s\" = %s\n", $key, $value) if $debug{hv};
	}
      }
      $init->add("}");
      $init->split;
    }
  } elsif ($] >= 5.015) { # empty contents still needs to set keys=0
    # test 36
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

  # XXX 5.10 non-threaded crashes at this eval_pv. 5.11 crashes threaded. test 15
  #if (!$PERL510 or $MULTI) {   # or ($PERL510 and !$PERL512)
  $use_xsloader = 1 if !$PERL56; # for PerlIO::scalar
  $init->add_eval( sprintf 'open(%s, "<", $%s)', $globname, $globname );
  #}
  mark_package("IO::Handle", 1);
}

sub B::IO::save {
  my ($io, $fullname) = @_;
  my $sym = objsym($io);
  return $sym if defined $sym;
  my $pv = $io->PV;
  $pv = '' unless defined $pv;
  my ( $pvsym, $len );
  if ($pv) {
    ( $pvsym, $len ) = savepv($pv);
  } else {
    $pvsym = 'NULL';
    $len = 0;
  }
  if ($PERL514) {
    warn sprintf( "IO 0x%x (%s) = '%s'\n", $$io, $io->SvTYPE, $pv ) if $debug{sv};
    # IFP in sv.sv_u.svu_fp
    $xpviosect->comment("STASH, xmg_u, cur, len, xiv_u, xio_ofp, xio_dirpu, page, page_len, ..., type, flags");
    my $tmpl = "Nullhv, /*STASH later*/\n\t{0}, /*MAGIC later*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%d}, /*LINES*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $len,                     $len + 1,
	$io->LINES, 		  # moved to IVX with 5.11.1
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          cstring( $io->TOP_NAME ),
        cstring( $io->FMT_NAME ), cstring( $io->BOTTOM_NAME ),
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x, {%s}",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS,
			 $B::C::pv_copy_on_grow ? $pvsym : 0));
  }
  elsif ($] > 5.011000) {
    warn sprintf( "IO 0x%x (%s) = '%s'\n", $$io, $io->SvTYPE, $pv ) if $debug{sv};
    $xpviosect->comment("xnv_u, cur, len, lines, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, ..., type, flags");
    my $tmpl = "{0}, /*xnv_u*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%d}, /*LINES*/\n\t{0}, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $len,                     $len + 1,
	$io->LINES, 		  # moved to IVX with 5.11.1
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          cstring( $io->TOP_NAME ),
        cstring( $io->FMT_NAME ), cstring( $io->BOTTOM_NAME ),
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x, {%s}",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS,
			 $B::C::pv_copy_on_grow ? $pvsym : 0));
  }
  elsif ($PERL510) {
    warn sprintf( "IO 0x%x (%s) = '%s'\n", $$io, $io->SvTYPE, $pv ) if $debug{sv};
    $xpviosect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, lines, ..., type, flags");
    my $tmpl = "{0}, /*xnv_u*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t{%ld}, /*IVX*/\n\t{0}, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*LINES*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*[^\*]+?\*/\n\t}{}g unless $verbose;
    $tmpl =~ s{ /\*flags\*/$}{} unless $verbose;
    $xpviosect->add(
      sprintf($tmpl,
        $len,                     $len + 1,
        $io->IVX,
	$io->LINES,
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          cstring( $io->TOP_NAME ),
        cstring( $io->FMT_NAME ), cstring( $io->BOTTOM_NAME ),
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
              $pvsym, 			   $len, $len + 1,
              $io->IVX,                    $io->NVX,
              $io->LINES,                  $io->PAGE,
              $io->PAGE_LEN,               $io->LINES_LEFT,
              cstring( $io->TOP_NAME ),    cstring( $io->FMT_NAME ),
              cstring( $io->BOTTOM_NAME ), $io->SUBPROCESS,
              cchar( $io->IoTYPE ),        $io->IoFLAGS
      )
    );
    $svsect->add(sprintf("&xpvio_list[%d], %lu, 0x%x",
                         $xpviosect->index, $io->REFCNT, $io->FLAGS));
  }
  $svsect->debug($io->flagspv) if $debug{flags};
  $sym = savesym( $io, sprintf( "(IO*)&sv_list[%d]", $svsect->index ) );

  if ($PERL510 and !$B::C::pv_copy_on_grow and $len) {
    $init->add(sprintf("SvPVX(sv_list[%d]) = $pvsym;", $svsect->index));
  }
  my ( $field, $fsym );
  foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
    $fsym = $io->$field();
    if ($$fsym) {
      $init->add( sprintf( "Io$field($sym) = (GV*)s\\_%x;", $$fsym ) );
      $fsym->save;
    }
  }
  $io->save_magic($fullname); # This handle the stash also (we need to inc the refcnt)
  if (!$PERL56 and $fullname ne 'main::DATA') { # PerlIO
    # deal with $x = *STDIN/STDOUT/STDERR{IO} and aliases
    my $perlio_func;
    # Note: all single-direction fp use IFP, just bi-directional pipes and sockets use OFP also.
    # But we need to set both.
    my $o = $io->object_2svref();
    my $fd =  ref($o) eq 'IO::Handle' ? undef : $o->fileno();
    my $i = 0;
    foreach (qw(stdin stdout stderr)) {
      if ($io->IsSTD($_) or $fd == -$i) {
	$perlio_func = $_;
      }
      $i++;
    }
    if ($perlio_func) {
      $init->add("IoIFP(${sym}) = IoOFP(${sym}) = PerlIO_${perlio_func}();");
      if ($fd < 0) {
	# XXX print may fail at flush == EOF, wrong init-time?
      }
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
			    $fd<3?'':'/*',$fd,$mode,$fd<3?'':'*/'));
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

  my @sections = (
    $opsect,     $unopsect,  $binopsect, $logopsect, $condopsect,
    $listopsect, $pmopsect,  $svopsect,  $padopsect, $pvopsect,
    $loopsect,   $copsect,   $svsect,    $xpvsect,   $orangesect,
    $resect,     $xpvavsect, $xpvhvsect, $xpvcvsect, $xpvivsect,
    $xpvuvsect,  $xpvnvsect, $xpvmgsect, $xpvlvsect, $xrvsect,
    $xpvbmsect,  $xpviosect
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
      my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);
      # -fcog hack to statically initialize PVs (SVPV for 5.10-5.11 only)
      $typename = 'SVPV' if $typename eq 'SV' and $PERL510 and $] < 5.012;
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
    print "#define ptr_undef &PL_sv_undef\n";
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
      my $name = $section->name;
      my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);
      $typename = 'SVPV' if $typename eq 'SV' and $PERL510 and $] < 5.012;
      printf "Static %s %s_list[%u] = {\n", $typename, $name, $lines;
      printf "\t/* %s */\n", $section->comment
        if $section->comment and $verbose;
      $section->output( \*STDOUT, "\t{ %s }, /* %s_list[%d] */%s\n" );
      print "};\n\n";
    }
  }
  printf "\t/* %s */\n", $init->comment if $init->comment and $verbose;
  $init->output( \*STDOUT, "\t%s\n", $init_name );
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

  # Tricky hack for -fcog since 5.10 required. We need a char* as
  # *first* sv_u element to be able to statically initialize it. A int does not allow it.
  # gcc error: initializer element is not computable at load time
  # We introduce a SVPV as SV.
  # In core since 5.12
  if ($PERL510 and $] < 5.012) {
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
  if ($PERL510 and $^O eq 'MSWin32') {
    # mingw and msvc does not export newGP
    print << '__EOGP';

#ifndef newGP
PERL_CALLCONV GP * Perl_newGP(pTHX_ GV *const gv);

GP *
Perl_newGP(pTHX_ GV *const gv)
{
    GP *gp;
    U32 hash;
#ifdef USE_ITHREADS
    const char *const file
	= (PL_curcop && CopFILE(PL_curcop)) ? CopFILE(PL_curcop) : "";
    const STRLEN len = strlen(file);
#else
    SV *const temp_sv = CopFILESV(PL_curcop);
    const char *file;
    STRLEN len;

    PERL_ARGS_ASSERT_NEWGP;

    if (temp_sv) {
	file = SvPVX(temp_sv);
	len = SvCUR(temp_sv);
    } else {
	file = "";
	len = 0;
    }
#endif

    PERL_HASH(hash, file, len);

    Newxz(gp, 1, GP);

#ifndef PERL_DONT_CREATE_GVSV
    gp->gp_sv = newSV(0);
#endif

    gp->gp_line = PL_curcop ? CopLINE(PL_curcop) : 0;
    /* XXX Ideally this cast would be replaced with a change to const char*
       in the struct.  */
    gp->gp_file_hek = share_hek(file, len, hash);
    gp->gp_egv = gv;
    gp->gp_refcnt = 1;

    return gp;
}
#endif
__EOGP

  }

  # Need fresh re-hash of strtab. share_hek does not allow hash = 0
  if ( $PERL510 ) {
    print <<'_EOT0';
HEK *
my_share_hek( pTHX_ const char *str, I32 len, register U32 hash );

#undef share_hek
#define share_hek(str,len,hash) my_share_hek( aTHX_ str,len,hash );
_EOT0

  }
  print "\n";
}

sub output_boilerplate {
  # Store the sv_list index in sv_debug_file when debugging
  print "#define DEBUG_LEAKING_SCALARS 1\n" if $debug{flags} and $DEBUGGING;
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
      register HE* he;
      /* XXX use hv_common_key_len if we start supporting UTF8 */
      if (!(he = (HE *) hv_common(PL_strtab, NULL, str, len, 0, 0, NULL, 0))) {
	/* Does not work with DEBUGGING as there is an artifical assert in hv.c
	   which checks that a HE is allocated before the HEK. */
        HvSHAREKEYS_on(PL_strtab); /* XXX This is a hack! */
        he = (HE *) hv_common(PL_strtab, NULL, str, len, 0, HV_FETCH_ISSTORE, NULL, 0);
        HvSHAREKEYS_off(PL_strtab);
      }
      return HeKEY_hek(he);
    } else {
      return Perl_share_hek(aTHX_ str, len, hash);
    }
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
    return 0;
}
_EOT6

  }
  # special COW handling for 5.10 because of S_unshare_hek_or_pvn limitations
  # XXX This fails in S_doeval SAVEFREEOP(PL_eval_root): test 15
  elsif ( $PERL510 and (%strtable or $B::C::pv_copy_on_grow)) {
    print <<'_EOT7';
int my_perl_destruct( PerlInterpreter *my_perl );
int my_perl_destruct( PerlInterpreter *my_perl ) {
    /* set all our static pv and hek to &PL_sv_undef so perl_destruct() will not cry */
_EOT7

    for (0 .. $#static_free) {
      # set the sv/xpv to &PL_sv_undef, not the pv itself. 
      # If set to NULL pad_undef will fail in SvPVX_const(namesv) == '&'
      # XXX Another idea >5.10 is SvFLAGS(pv) = SVTYPEMASK
      my $s = $static_free[$_];
      if ($s =~ /^sv_list\[\d+\]\./) { # pv directly (unused)
	print "    $s = NULL;\n";
      } elsif ($s =~ /^sv_list/) {
       print "    SvPV_set(&$s, (char*)&PL_sv_undef);\n";
      } elsif ($s =~ /^&sv_list/) {
       print "    SvPV_set($s, (char*)&PL_sv_undef);\n";
      } elsif ($s =~ /^cop_list/) {
	print "    CopFILE_set(&$s, NULL); CopSTASHPV_set(&$s, NULL);\n"
	  if $ITHREADS or !$MULTI;
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
  #print "#ifdef USE_DYNAMIC_LOADING\n";
  foreach my $stashname ( keys %static_ext ) {
    my $stashxsub = $stashname;
    $stashxsub =~ s/::/__/g;
    #if ($stashxsub =~ m/\/(\w+)\.\w+$/ {$stashxsub = $1;}
    # cygwin has Win32CORE in static_ext
    warn "bootstrapping static $stashname added to xs_init\n" if $verbose;
    print "\tnewXS(\"$stashname\::bootstrap\", boot_$stashxsub, file);\n";
  }
  #print "#endif\n";
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
    #my $incpack = inc_packname($stashname);
    #unless ($INC{$incpack}) { # skip deleted packages
    #  warn "skip xs_init for $stashname !\$INC{$incpack}\n" if $debug{pkg};
    #  next;
    #}
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
    delete $xsub{$c};
    $include_package{$c} = undef;
    @dl_modules = grep { $_ ne $c } @dl_modules;
  }
  @DynaLoader::dl_modules = @dl_modules;
  foreach my $stashname (@dl_modules) {
    #my $incpack = inc_packname($stashname);
    #unless ($INC{$incpack}) { # skip deleted packages
    #  warn "skip dl_init for $stashname !\$INC{$incpack}\n" if $debug{pkg};
    #  delete $xsub{$stashname};
    #}
    if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/^Dynamic/ ) {
      # XSLoader.pm: $modlibname = (caller())[1]; needs a path at caller[1] to find auto,
      # otherwise we only have -e
      $xs++ if $xsub{$stashname} ne 'Dynamic';
      $dl++;
    }
  }
  if ($dl) {
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
        warn "dl_init $stashname\n" if $verbose;
        print "\tPUSHMARK(sp);\n";
	# XXX -O1 or -O2 needs XPUSHs with dynamic pv
	printf "\t%s(%s, %d);\n", # "::bootstrap" gets appended
	  $] < 5.008008 ? "XPUSHp" : "mXPUSHp", "\"$stashname\"", length($stashname);
        if ( $xsub{$stashname} eq 'Dynamic' ) {
	  print "\tPUTBACK;\n";
	  print "#ifdef USE_DYNAMIC_LOADING\n";
          print qq/\tcall_method("DynaLoader::bootstrap_inherit", G_VOID|G_DISCARD);\n/;
        }
        else { # XS: need to fix cx for caller[1] to find auto/...
	  my ($stashfile) = $xsub{$stashname} =~ /^Dynamic-(.+)$/;
	  if ($] >= 5.015003) {
	    printf "\tmXPUSHp(\"%s\", %d);\n", $stashfile, length($stashfile) if $stashfile;
	  }
	  print "\tPUTBACK;\n";
	  print "#ifdef USE_DYNAMIC_LOADING\n";
	  warn "bootstrapping $stashname added to dl_init\n" if $verbose;
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
          warn "staticxs search $sofile in @DynaLoader::dl_shared_objects\n"
            if $verbose and $debug{pkg};
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
        my $stashxsub = $stashname;
        $stashxsub =~ s/::/__/g;
        if ($staticxs) {
	  # CvSTASH(CvGV(cv)) is invalid without (issue 86)
	  print "\tboot_$stashxsub(aTHX_ get_cv(\"$stashname\::bootstrap\", TRUE));\n";
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
      my $dollar_0 = $0;
      $dollar_0 =~ s/\\/\\\\/g;
      $dollar_0 = '"' . $dollar_0 . '"';

      print <<"EOT";
    if ((tmpgv = gv_fetchpv("0", TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, ${dollar_0});
        SvSETMAGIC(tmpsv);
    }
EOT

    }
    else {
      print <<"EOT";
    if ((tmpgv = gv_fetchpv("0", TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, argv[0]);
        SvSETMAGIC(tmpsv);
        CopFILE_set(&PL_compiling, argv[0]);
    }
EOT

    }

    print <<"EOT";
    if ((tmpgv = gv_fetchpv("\030", TRUE, SVt_PV))) {/* $^X */
        tmpsv = GvSVn(tmpgv);
#ifdef WIN32
        sv_setpv(tmpsv,"perl.exe");
#else
        sv_setpv(tmpsv,"perl");
#endif
        SvSETMAGIC(tmpsv);
    }

    TAINT_NOT;

    #if PERL_VERSION < 10
      PL_compcv = 0;
    #else
      PL_compcv = MUTABLE_CV(newSV_type(SVt_PVCV));
      CvUNIQUE_on(PL_compcv);
      CvPADLIST(PL_compcv) = pad_new(0);
    #endif
    #if PERL_VERSION > 7
      boot_core_PerlIO();
    #endif
    boot_core_UNIVERSAL();
    #if PERL_VERSION > 9
      boot_core_mro();
    #endif
    #if PERL_VERSION < 11
      boot_core_xsutils(); /* attributes::bootstrap */
    #endif

    /* our special compiled init */
    exitstatus = perl_init(aTHX);
    if (exitstatus)
	exit( exitstatus );
    dl_init(aTHX);

    exitstatus = perl_run( my_perl );
EOT

    if ( !$B::C::destruct and $^O ne 'MSWin32' ) {
      warn "fast_perl_destruct (-fno-destruct)\n" if $verbose;
      print "    fast_perl_destruct( my_perl );\n";
    } elsif ( $PERL510 and (%strtable or $B::C::pv_copy_on_grow) ) {
      warn "my_perl_destruct (-fcog)\n" if $verbose;
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
  while ( ( $sym, $val ) = each %symtable ) {
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
  warn sprintf( "Checking GV &%s 0x%x\n", cstring($fullname), $$gv )
    if $debug{gv};

  # We may be looking at this package just because it is a branch in the
  # symbol table which is on the path to a package which we need to save
  # e.g. this is 'Getopt' and we need to save 'Getopt::Long'
  #
  return if ( $package ne 'main' and !$include_package{$package} );
  return if ( $package eq 'main' and
  	      $name =~ /^([^_A-Za-z0-9].*|_\<.*|INC|STDIN|STDOUT|STDERR|ARGV|SIG|ENV|BEGIN|main::|!)$/ );

  warn sprintf( "Used GV \&$fullname 0x%x\n", $$gv ) if $debug{gv};
  return unless ( $$cv || $$av || $$sv || $$hv );
  if ($$cv and $name eq 'bootstrap' and $cv->XSUB) {
    warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
    return;
  }
  if ($package eq 'B::C') {
    warn sprintf( "Skip XS \&$fullname 0x%x\n", $$cv ) if $debug{gv};
    return;
  }
  return if $fullname eq 'B::walksymtable'; # XXX fails and should not be needed
  # Config is marked on any Config symbol. TIE and DESTROY are exceptions,
  # used by the compiler itself
  if ($name eq 'Config') {
    mark_package('Config', 1) if !$include_package{'Config'};
  }
  warn sprintf( "Saving GV &$fullname 0x%x\n", $$gv ) if $debug{gv};
  $gv->save($fullname);
}

sub mark_package {
  my $package = shift;
  my $force = shift;
  $force = 0 if $] < 5.010;
  return if $skip_package{$package} or $package =~ /^B::C(C?)::/;
  if ( !$include_package{$package} or $force ) {
    no strict 'refs';
    my @IO = qw(IO::File IO::Handle IO::Socket IO::Seekable IO::Poll);
    mark_package('IO') if grep { $package eq $_ } @IO;
    # i.e. if force
    if (exists $include_package{$package}
	and !$include_package{$package}
	and $savINC{inc_packname($package)})
    {
      warn sprintf("$package previously deleted, save now%s\n",
		   $force?" (forced)":"") if $verbose;
      # $include_package{$package} = 1;
      add_hashINC( $package );
      walksymtable( \%{$package.'::'}, "savecv",
		    sub { should_save( $_[0] ); return 1 },
		    $package.'::' );
    } else {
      warn sprintf("mark $package%s\n", $force?" (forced)":"")
	if !$include_package{$package} and $verbose and $debug{pkg};
      $include_package{$package} = 1;
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
	    walksymtable( \%{$isa.'::'}, "savecv", \&should_save, $isa.'::' );
          } else {
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
    return $cvname =~ /^(is_regexp|regname|regnames_count|regexp_pattern)$/;;
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
  push @pkg, 'DynaLoader'		if $Config{usedl};
  # Win32CORE only in official cygwin pkg. And it needs to be bootstrapped,
  # handled by static_ext.
  push @pkg, 'Cygwin'			if $^O eq 'cygwin';
  push @pkg, 'NetWare'		if $^O eq 'NetWare';
  push @pkg, 'OS2'			if $^O eq 'os2';
  push @pkg, qw(VMS VMS::Filespec vmsish) if $^O eq 'VMS';
  #push @pkg, 'PerlIO' if $] >= 5.008006; # get_layers only
  return @pkg;
}

sub skip_pkg {
  my $package = shift;
  if ( $package =~ /^(mro)$/
       or $package =~ /^(main::)?(B|PerlIO|Internals|O)::/
       or $package =~ /::::/
       or index($package, " ") != -1 # XXX skip invalid package names
       or index($package, "(") != -1 # XXX this causes the compiler to abort
       or index($package, ")") != -1 # XXX this causes the compiler to abort
       or ($DB::deep and $package =~ /^(DB|Term::ReadLine)/)) {
    return 1;
  }
  return 0;
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

  # Omit the packages which we use (and which cause grief
  # because of fancy "goto &$AUTOLOAD" stuff).
  # XXX Surely there must be a nicer way to do this.
  if (skip_pkg($package)) {
    delete_unsaved_hashINC($package);
    return $include_package{$package} = 0;
  }

  if ( exists $include_package{$package} ) {
    if ($debug{pkg}) {
      if (exists $include_package{$package} and $include_package{$package}) {
        warn "$package is cached\n";
      } else {
        warn "Cached $package is already deleted\n";
      }
    }
    delete_unsaved_hashINC($package) unless $include_package{$package};
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
  delete_unsaved_hashINC($package);
  return $include_package{$package} = 0;
}

sub inc_packname {
  my $packname = shift;
  # See below at the reverse packname_inc: utf8 => utf8.pm + utf8_heavy.pl
  $packname =~ s/\:\:/\//g;
  $packname .= '.pm';
  return $packname;
}

sub packname_inc {
  my $packname = shift;
  $packname =~ s/\//::/g;
  if ($packname =~ /^(Config_git\.pl|Config_heavy.pl)$/) {
    return 'Config';
  }
  if ($packname eq 'utf8_heavy.pl') {
    return 'utf8';
  }
  $packname =~ s/\.p[lm]$//;
  return $packname;
}

sub delete_unsaved_hashINC {
  my $packname = shift;
  my $incpack = inc_packname($packname);
  if ($INC{$incpack}) {
    warn "Deleting $packname from \%INC\n" if $debug{pkg};
    $savINC{$incpack} = $INC{$incpack} if !$savINC{$incpack};
    $INC{$incpack} = undef;
    delete $INC{$incpack};
    $include_package{$packname} = 0;
  }
}

sub add_hashINC {
  my $packname = shift;
  my $incpack = inc_packname($packname);
  $include_package{$packname} = 1;
  unless ($INC{$incpack}) {
    if ($savINC{$incpack}) {
      warn "Adding $packname to \%INC (again)\n" if $debug{pkg};
      $INC{$incpack} = $savINC{$incpack};
    } else {
      warn "Adding $packname to \%INC\n" if $debug{pkg};
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
  my ($sym, $ref);
  no strict 'vars';
  $prefix = '' unless defined $prefix;
  # check if already deleted - failed since 5.15.2
  return if $savINC{inc_packname(substr($prefix,0,-2))};
  while ( ( $sym, $ref ) = each %$symref ) {
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
  if ($] >= 5.013009 and $INC{'utf8_heavy.pl'} and ($B::C::fold or exists($INC{'utf8.pm'}))) {
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
  # XSLoader was used, force saving of XSLoader::load
  if ($use_xsloader) {
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
    # mark_package("XSLoader", 1);
    $use_xsloader = 0;
    mark_package('Config', 1); # required by Dynaloader and special cased previously
  }
}

sub inc_cleanup {
  return if $inc_cleanup;
  # %INC sanity check issue 89:
  # omit unused, unsaved packages, so that at least run-time require will pull them in.
  for my $packname (keys %INC) {
    my $pkg = packname_inc($packname);
    if ($packname =~ /^(Config_git\.pl|Config_heavy.pl)$/ and !$include_package{'Config'}) {
      delete $INC{$packname};
    } elsif ($packname eq 'utf8_heavy.pl' and !$include_package{'utf8'}) {
      delete $INC{$packname};
      delete_unsaved_hashINC('utf8');
    } else {
      delete_unsaved_hashINC($pkg) unless $include_package{$pkg};
    }
  }
  if ($debug{pkg} and $verbose) {
    warn "\%INC: ".join(" ",keys %INC)."\n";
    warn "\%include_package: ".join(" ",grep{$include_package{$_}} keys %include_package)."\n";
  }
  $inc_cleanup++;
}

sub save_context {
  # forbid run-time extends of curpad syms, names and INC
  warn "save context:\n" if $verbose;

  if ($PERL510) {
    # Tie::Hash::NamedCapture is added for *main::+ or *main::-
    # Errno is added for *main::!
    no strict 'refs';
    if ( defined(objsym(svref_2object(\*{'main::+'}))) or defined(objsym(svref_2object(\*{'main::-'}))) ) {
      use strict 'refs';
      if (!$include_package{'Tie::Hash::NamedCapture'}) {
	$init->add("/* force saving of Tie::Hash::NamedCapture */");
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
	mark_package('Errno', 1);
      } # else already included
    } else {
      use strict 'refs';
      delete_unsaved_hashINC('Errno');
    }
  }

  $init->add("/* curpad names */");
  warn "curpad names:\n" if $verbose;
  # Record comppad sv's names, may not be static
  local $B::C::pv_copy_on_grow;
  #my $svi = $svsect->index;
  my $curpad_nam      = ( comppadlist->ARRAY )[0]->save('curpad_name');
  # XXX from $svi to $svsect->index we have new sv's
  warn "curpad syms:\n" if $verbose;
  $init->add("/* curpad syms */");
  my $curpad_sym      = ( comppadlist->ARRAY )[1]->save('curpad_syms');
  my ($inc_hv, $inc_av);
  {
    local $B::C::pv_copy_on_grow;
    $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
    local $B::C::const_strings;
    $B::C::const_strings = 1 if $B::C::ro_inc;
    warn "\%INC and \@INC:\n" if $verbose;
    $init->add('/* %INC */');
    inc_cleanup();
    # svref_2object( \*main::INC )->save('main::INC', 'now');
    $inc_hv          = svref_2object( \%INC )->save('main::INC');
    $init->add('/* @INC */');
    $inc_av          = svref_2object( \@INC )->save('main::INC');
  }
  my $amagic_generate = amagic_generation;
  warn "amagic_generation = $amagic_generate\n" if $verbose;
  $init->add(
    "GvHV(PL_incgv) = $inc_hv;",
    "GvAV(PL_incgv) = $inc_av;",
    "PL_curpad = AvARRAY($curpad_sym);",
    "PL_comppad = $curpad_sym;",    # fixed "panic: illegal pad"
    "av_store(CvPADLIST(PL_main_cv), 0, SvREFCNT_inc($curpad_nam)); /* namepad */",
    "av_store(CvPADLIST(PL_main_cv), 1, SvREFCNT_inc($curpad_sym)); /* curpad */",
    "PL_amagic_generation = $amagic_generate;"
  );
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
    save_context();
  }

  # If XSLoader is used later (e.g. in INIT or END block)
  if ($use_xsloader) {
    $init->add("/* force saving of XSLoader::load */");
    if ($] < 5.015003) {
      eval { XSLoader::load; };
      svref_2object( \&XSLoader::load )->save;
    } else {
      svref_2object( \&XSLoader::load_file )->save;
    }
    add_hashINC("XSLoader") if $] < 5.015003;
    add_hashINC("DynaLoader");
    $use_xsloader = 0;
  }

  fixup_ppaddr();

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
    orange => \$orangesect,
    re     => \$resect,
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
    xpvio  => \$xpviosect
  );
  my ( $name, $sectref );
  while ( ( $name, $sectref ) = splice( @sections, 0, 2 ) ) {
    $$sectref = new B::C::Section $name, \%symtable, 0;
  }
  $init = new B::C::InitSection 'init', \%symtable, 0;
}

sub mark_unused {
  my ( $pkg, $val ) = @_;
  $include_package{$pkg} = $val;
}

sub mark_skip {
  for (@_) {
    delete_unsaved_hashINC($_);
    $include_package{$_} = 0;
    $skip_package{$_} = 1;
  }
}

sub compile {
  my @options = @_;
  # Allow debugging in CHECK blocks without Od
  $DB::single=1 if defined &DB::DB;
  my ( $option, $opt, $arg );
  my @eval_at_startup;
  $B::C::destruct = 1;
  $B::C::stash    = 1;
  $B::C::save_sig = 1;
  $B::C::stash    = 0;
  $B::C::fold     = 1 if $] >= 5.013009; # always include utf8::Cased tables
  $B::C::warnings = 1 if $] >= 5.013005; # always include Carp warnings categories and B
  my %optimization_map = (
    0 => [qw()],                # special case
    1 => [qw(-fcog -fppaddr -fwarn-sv -fav-init2)], # falls back to -fav-init
    2 => [qw(-fro-inc -fsave-data)],
    3 => [qw(-fno-destruct -fconst-strings -fno-fold -fno-warnings)],
    4 => [qw(-fcop)],
  );
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
    elsif ( $opt eq "D" ) {
      $arg ||= shift @options;
      if ($arg eq 'full') {
        $arg = 'OcAHCMGSpWF';
      }
      elsif ($arg eq 'ufull') {
        $arg = 'uOcAHCMGSpWF';
      }
      foreach $arg ( split( //, $arg ) ) {
        if ( $arg eq "o" ) {
	  $verbose++;
	  B->debug(1);
        }
        elsif ( $arg eq "O" ) {
          $debug{op}++;
        }
        elsif ( $arg eq "A" ) {
          $debug{av}++;
        }
        elsif ( $arg eq "H" ) {
          $debug{hv}++;
        }
        elsif ( $arg eq "C" ) {
          $debug{cv}++;
        }
        elsif ( $arg eq "M" ) {
          $debug{mg}++;
        }
        elsif ( $arg eq "R" ) {
          $debug{rx}++;
        }
        elsif ( $arg eq "G" ) {
          $debug{gv}++;
        }
        elsif ( $arg eq "S" ) {
          $debug{sv}++;
        }
        elsif ( $arg eq "F" ) {
          $debug{flags}++ if eval "require B::Flags;";
        }
        elsif ( $arg eq "W" ) {
          $debug{walk}++;
        }
        elsif ( $arg eq "c" ) {
          $debug{cops}++;
        }
        elsif ( $arg eq "s" ) {
          $debug{sub}++;
        }
        elsif ( $arg eq "p" ) {
          $debug{pkg}++;
        }
        elsif ( $arg eq "u" ) {
          $debug{unused}++;
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
      open( STDOUT, ">", $arg ) or return "$arg: $!\n";
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
      eval "require $arg;";
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

=item B<-fcog>

Copy-on-grow: PVs declared and initialised statically.
Does not work yet with Perl 5.10 and higher unless
C<-fno-destruct> is added.

Enabled with C<-O1>.

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

Declares readonly strings as const. Enables C<-fcog>.
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

C<-fno-stash> is the default.

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

Enable B<-O3> plus B<-fcop>. Very unsafe, 10% faster, 10% smaller.

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

=head1 BUGS

Current status: A few known bugs.

5.6:
    reading from __DATA__ handles (15)
    AUTOLOAD xsubs (27)

>=5.10:
    &XSLoader::load sometimes missing
    reading from __DATA__ handles (15) non-threaded
    handling npP magic for shared threaded variables (41-43)
    destruction of variables in END blocks

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
