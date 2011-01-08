#      C.pm
#
#      Copyright (c) 1996, 1997, 1998 Malcolm Beattie
#      Copyright (c) 2008, 2009, 2010, 2011 Reini Urban
#      Copyright (c) 2010 Nick Koston
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#

package B::C;

our $VERSION = '1.29';
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
    if ($dodbg) {
      if ($section->[-1]{dbg}->[$i]) {
	$dbg = " /* ".$section->[-1]{dbg}->[$i]." */";
      }
    }
    printf $fh $format, $_, $i, $dbg;
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
	/* dTARG;
	   dSP; */
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
	/* dTARG;
	   dSP; */
EOT
  $section->SUPER::output( $fh, $format );
  print $fh "\treturn 0;\n}\n";
}

package B::C;
use Exporter ();
our %REGEXP;

{ # block necessary for caller to work
  my $caller = caller;
  if ( $caller eq 'O' ) {
    require XSLoader;
    XSLoader::load('B::C'); # for r-magic only
  }
}

@ISA        = qw(Exporter);
@EXPORT_OK =
  qw(output_all output_boilerplate output_main mark_unused
     init_sections set_callback save_unused_subs objsym save_context fixup_ppaddr
     save_sig svop_or_padop_pv);
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
}
use B::Asmdata qw(@specialsv_name);

use B::C::Flags;
use FileHandle;
use Carp;
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

my $package_pv; # global stash for methods since 5.13
my (%symtable, %cvforward);
my (%strtable, %hektable, @static_free);
my %xsub;
my $warn_undefined_syms;
my $verbose = 0;
my %unused_sub_packages;
my %static_ext;
my $use_xsloader;
my $nullop_count         = 0;
# optimizations:
my ($pv_copy_on_grow, $optimize_ppaddr, $optimize_warn_sv, $use_perl_script_name,
    $save_data_fh, $save_sig, $optimize_cop, $av_init, $av_init2, $ro_inc, $destruct,
    $const_strings);
my ($use_av_undef_speedup, $use_svpop_speedup) = (1, 1);

my @xpvav_sizes;
my ($max_string_len, $in_endav);
my %static_core_pkg; #= map {$_ => 1} static_core_packages();

my $ITHREADS = $Config{useithreads};
my $PERL513  = ( $] >= 5.013002 );
my $PERL511  = ( $] >= 5.011 );
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

# Code sections
my (
  $init,      $decl,      $symsect,    $binopsect, $condopsect,
  $copsect,   $padopsect, $listopsect, $logopsect, $loopsect,
  $opsect,    $pmopsect,  $pvopsect,   $svopsect,  $unopsect,
  $svsect,    $resect,    $xpvsect,    $xpvavsect, $xpvhvsect,
  $xpvcvsect, $xpvivsect, $xpvuvsect,  $xpvnvsect, $xpvmgsect, $xpvlvsect,
  $xrvsect,   $xpvbmsect, $xpviosect,  $heksect,   $orangesect
);
my @op_sections = \(
  $binopsect,  $condopsect, $copsect,  $padopsect,
  $listopsect, $logopsect,  $loopsect, $opsect,
  $pmopsect,   $pvopsect,   $svopsect, $unopsect
);
# push @op_sections, ($resect) if $PERL511;
sub walk_and_save_optree;
my $saveoptree_callback = \&walk_and_save_optree;
sub set_callback { $saveoptree_callback = shift }
sub saveoptree { &$saveoptree_callback(@_) }
sub save_main_rest;

sub walk_and_save_optree {
  my ( $name, $root, $start ) = @_;
  $verbose ? walkoptree_slow( $root, "save" ) : walkoptree( $root, "save" );
  return objsym($start);
}

# Look this up here so we can do just a number compare
# rather than looking up the name of every BASEOP in B::OP
my $OP_THREADSV = opnumber('threadsv');

# special handling for nullified COP's.
my %OP_COP = ( opnumber('nextstate') => 1 );
$OP_COP{ opnumber('setstate') } = 1 if $] > 5.005003 and $] < 5.005062;
$OP_COP{ opnumber('dbstate') }  = 1 unless $PERL511;
warn %OP_COP if $debug{cops};

# always called from method_named, so hashp should be defined
sub svop_or_padop_pv {
  my $op = shift;
  my $sv;
  if (!$op->can("sv")) {
    if ($op->can("pmreplroot") and $op->pmreplroot->can("sv")) {
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
    if ($sv->isa("B::SPECIAL")) { # DateTime::TimeZone
      warn "NYI op->sv==B::SPECIAL S_method_common not fully implemented yet";
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
      warn sprintf("NYI S_method_common not fully implemented yet sv=$sv flags=0x%x",
		   $sv->FLAGS);
      return $package_pv;
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

sub savere {
  my $re = shift;
  my $flags = shift || 0;
  my $sym;
  my $pv    = $re;
  my $len   = length $pv;
  my $pvmax = length( pack "a*", $pv ) + 1;
  if ($PERL513) {
    $xpvsect->add( sprintf( "Nullhv, {0}, %u, %u", $len, $pvmax ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {(char*)%s}", $xpvsect->index,
                           0x4405, savepv($pv) ) );
    $sym = sprintf( "&sv_list[%d]", $svsect->index );
  }
  elsif ( 0 and $PERL511 ) {
    # TODO Fill in at least the engine pointer? Or let CALLREGCOMP do that?
    $orangesect->add(
      sprintf(
              "0,%u,%u, 0,0,NULL, NULL,NULL,"
              . "0,0,0,0,NULL,0,0,NULL,0,0, NULL,NULL,NULL,0,0,0",
              $len, $pvmax
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
    my $s1 = ($PERL513 ? "NULL," : "") . "{0}, %u, %u";
    $xpvsect->add( sprintf( $s1, $len, $pvmax ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x, {(char*)%s}", $xpvsect->index,
                           0x4405, savepv($pv) ) );
    my $s = "sv_list[".$svsect->index."]";
    $sym = "&$s";
    push @static_free, $s if $pvmax and $B::C::pv_copy_on_grow;
    # $resect->add(sprintf("&xpv_list[%d], %lu, 0x%x", $xpvsect->index, 1, 0x4405));
  }
  else {
    $sym = sprintf( "re%d", $re_index++ );
    $decl->add( sprintf( "static const char *$sym = %s;", cstring($re) ) );
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
  #my $const = ($B::C::pv_copy_on_grow and $B::C::const_strings) ? "const" : "";
  my $const = "const";
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    my $chars = join ', ', map { cchar $_ } split //, $pv;
    $decl->add( sprintf( "static $const char %s[] = { %s };", $pvsym, $chars ) );
  } else {
    my $cstring = cstring($pv);
    if ( $cstring ne "0" ) {    # sic
      $decl->add( sprintf( "static $const char %s[] = %s;", $pvsym, $cstring ) );
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
    $decl->add( sprintf( "static char %s[] = { %s };", $pvsym, $chars ) );
  } else {
    my $cstring = cstring($pv);
    if ( $cstring ne "0" ) {    # sic
      $decl->add( sprintf( "static char %s[] = %s;", $pvsym, $cstring ) );
    }
  }
  my $pvmax = length( pack "a*", $pv ) + 1;
  return ( $pvsym, $pvmax );
}

sub save_rv {
  my $sv = shift;

  # confess "Can't save RV: not ROK" unless $sv->FLAGS & SVf_ROK;
  # 5.6: Can't locate object method "RV" via package "B::PVMG"
  my $rv = $sv->RV->save;

  $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

  return $rv;
}

# => savesym, pvmax, len, pv
sub save_pv_or_rv {
  my $sv = shift;

  my $rok = $sv->FLAGS & SVf_ROK;
  my $pok = $sv->FLAGS & SVf_POK;
  my ( $len, $pvmax, $savesym, $pv ) = ( 0, 0 );
  # 5.6: Can't locate object method "RV" via package "B::PV" Carp::Clan
  if ($rok and !$PERL56) {
    # this returns us a SV*. 5.8 expects a char* in xpvmg.xpv_pv
    $savesym = ($PERL510 ? "" : "(char*)") . save_rv($sv);
  }
  else {
    $pv = $pok ? ( pack "a*", $sv->PV ) : undef;
    $len = $pok ? length($pv) : 0;
    if ($pok) {
      if ($B::C::pv_copy_on_grow) {
	( $savesym, $pvmax ) = ($B::C::const_strings and $sv->FLAGS & SVf_READONLY)
	  ? constpv($pv) : savepv($pv);
      } else {
	( $savesym, $pvmax ) = ( 'ptr_undef', $len+1 );
      }
    } else {
      ( $savesym, $pvmax ) = ( 'ptr_undef', 0 );
    }
  }

  return ( $savesym, $pvmax, $len, $pv );
}

# shared global string
sub save_hek {
  my $str = shift; # not cstring'ed
  my $len = length $str;
  unless ($len) { wantarray ? return ( "NULL", 0 ) : return "NULL"; }
  if (defined $hektable{$str}) {
    return wantarray ? ($hektable{$str}, length( pack "a*", $hektable{$str} ))
      : $hektable{$str};
  }
  my $sym = sprintf( "hek%d", $hek_index++ );
  $hektable{$str} = "(HEK *)$sym";
  my $cstr = cstring($str);
  if ($B::C::pv_copy_on_grow) {
    $decl->add(sprintf("HEK *%s;",$sym));
    # XXX we can optimize this call also to static
    $init->add(sprintf("%s = share_hek(%s, %u, %s);",
		       $sym, $cstr, length($cstr)-2, B::hash($str)));
  } else {
    $decl->add(sprintf("Static HEK *%s;",$sym));
    $init->add(sprintf("%s = share_hek(%s, %u, %s);",
		       $sym, $cstr, length($cstr)-2, B::hash($str)));
  }
  # (HEK*)ptr_table_fetch(PL_ptr_table, source);
  # $heksect->add("hv_store(PL_strtab, \"$str\", $len, NULL, hash($str));");
  wantarray ? ( "$sym", length( pack "a*", $str ) ) : "$sym";
}


sub ivx ($) {
  my $ivx = shift;
  my $ivdformat = $Config{ivdformat};
  $ivdformat =~ s/"//g;
  my $intmax = (1 << ($Config{ivsize}*4-1)) - 1;
  # UL if > INT32_MAX = 2147483647
  my $sval = sprintf("%${ivdformat}%s", $ivx, $ivx > $intmax  ? "UL" : "");
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
    sprintf( "%s,%s %u, %u, $static, 0x%x, 0x%x",
      $op->fake_ppaddr, $madprop, $op->targ, $op->type, $op->flags, $op->private );
  }
  $opsect_common .= ", flags, private";
}

sub B::OP::_save_common {
  my $op = shift;
  if ($op->next
      and $op->next->can('name')
      and $op->next->name eq 'method_named'
     ) {
    # XXX HACK! need to store away the pkg pv. Fails since 5.13
    my $pv = svop_or_padop_pv($op);
    if ($pv and $pv !~ /[! \(]/) {
      $package_pv = $pv;
      warn "save package_pv \"$package_pv\" for method_name\n" if $debug{cv};
    }
  }
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
    if ($PERL511) {
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

# save alternate ops if defined, and also add labels (need for B::CC)
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

# method_named is in 5.6.1
sub method_named {
  my $name = shift;
  return unless $name;
  # Note: the pkg PV is at PL_stack_base+TOPMARK+1,
  # the previous op->sv->PVX. We store it away globally in op->_save_common.
  my $stash = $package_pv ? $package_pv."::" : "main::";
  $name = $stash . $name;
  warn "save method_name \"$name\"\n" if $debug{cv};
  return svref_2object( \&{$name} );
}

sub B::SVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $sv    = $op->sv;
  my $svsym = 'Nullsv';
  if ($op->name eq 'aelemfast' and $op->flags & 128) { #OPf_SPECIAL
    # pad does not need to be saved
    warn sprintf("SVOP->sv aelemfast pad %d\n", $op->flags) if $debug{sv};
  } else {
    $svsym  = '(SV*)' . $sv->save;
  }
  my $is_const_addr = $svsym =~ m/Null|\&/;
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
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op));
    $cv->save if $cv;
  }
  savesym( $op, "(OP*)&svop_list[$ix]" );
}

sub B::PADOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $padopsect->comment("$opsect_common, padix");
  $padopsect->add( sprintf( "%s, %d", $op->_save_common, $op->padix ) );
  $padopsect->debug( $op->name, $op->flagspv ) if $debug{flags};
  my $ix = $padopsect->index;
  $init->add( sprintf( "padop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $B::C::optimize_ppaddr;
  if ($op->name eq 'method_named') {
    my $cv = method_named(svop_or_padop_pv($op));
    $cv->save if $cv;
  }
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
  my $is_special = $warnings->isa("B::SPECIAL");
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
    # something else
    $warn_sv = $PERL510 ? "(STRLEN*)".$warnings->save : $warnings->save;
  }

  # Trim the .pl extension, to print the executable name only.
  my $file = $op->file;
  $file =~ s/\.pl$/.c/;
  if ($PERL511) {
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
              ( $B::C::optimize_warn_sv ? $warn_sv : 'NULL' ),
      )
    );
    if ( $op->label ) {
      # test 29
      if ($] > 5.013004) {
	$init->add(
	  sprintf("Perl_store_cop_label(aTHX_ &cop_list[%d], %s, %d, %d);",
		  $copsect->index, cstring( $op->label ),
		  length $op->label, 0));
      } elsif ($^O !~ /^MSWin32|AIX$/ or !$ENV{PERL_DL_NONLAZY}) {
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

  savesym( $op, "(OP*)&cop_list[$ix]" );
}

sub B::PMOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $replroot  = $op->pmreplroot;
  my $replstart = $op->pmreplstart;
  my $replrootfield;
  my $replstartfield = sprintf( "s\\_%x", $$replstart );
  my $gvsym;
  my $ppaddr = $op->ppaddr;

  # under ithreads, OP_PUSHRE.op_replroot is an integer
  $replrootfield = sprintf( "s\\_%x", $$replroot ) if ref $replroot;
  if ( $ITHREADS && $op->name eq "pushre" ) {
    $replrootfield = "INT2PTR(OP*,${replroot})";
  }
  elsif ($$replroot) {
    # OP_PUSHRE (a mutated version of OP_MATCH for the regexp
    # argument to a split) stores a GV in op_pmreplroot instead
    # of a substitution syntax tree. We don't want to walk that...
    if ( $op->name eq "pushre" ) {
      $gvsym = $replroot->save;
      warn "PMOP::save saving a pp_pushre with GV $gvsym\n" if $debug{gv};
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
        $op->pmdynflags,   $ITHREADS ? cstring($op->pmstashpv) : "0"
      )
    );
    if (!$ITHREADS and $op->pmstash) {
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
    $REGEXP{$$op} = $op;
    if ($PERL510) {
      # TODO minor optim: fix savere( $re ) to avoid newSVpvn;
      my $resym = "(char*)".cstring($re);
      my $relen = length($re);
      $init->add( # Modification of a read-only value attempted. use DateTime - threaded
        "PM_SETRE(&$pm, CALLREGCOMP(newSVpvn($resym, $relen),".sprintf("%u));",$op->pmflags),
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
  my $sym = $specialsv_name[$$sv];
  if ( !defined($sym) ) {
    confess "unknown specialsv index $$sv passed to B::SPECIAL::save";
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
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::UV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  if ($PERL513) {
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
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  # Since 5.11 the RV is no special SV object anymore, just a IV (test 16)
  my $svflags = $sv->FLAGS;
  if ($PERL511 and $svflags & SVf_ROK) {
    return $sv->B::RV::save;
  }
  if ($svflags & SVf_IVisUV) {
    return $sv->B::UV::save;
  }
  my $i = $svsect->index + 1;
  if ($svflags & 0xff and !($svflags & (SVf_IOK|SVp_IOK))) { # Not nullified
    unless (($PERL510 and $svflags & 0x00010000) # PADSTALE - out of scope lexical is !IOK
	    or (!$PERL510 and $svflags & 0x00000100)) { # PADBUSY
      warn "warning: IV !IOK sv_list[$i]";
    }
  }
  if ($PERL513) {
    $xpvivsect->add( sprintf( "Nullhv, {0}, 0, 0, {%s}", ivx $sv->IVX ) );
  } elsif ($PERL510) {
    $xpvivsect->add( sprintf( "{0}, 0, 0, {%s}", ivx $sv->IVX ) );
  } else {
    $xpvivsect->add( sprintf( "0, 0, 0, %s", ivx $sv->IVX ) );
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
  if ($PERL513) {
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
  my ( $dest, $pv ) = @_;
  my @res;

  # work with byte offsets/lengths
  $pv = pack "a*", $pv;
  if ( defined $max_string_len && length($pv) > $max_string_len ) {
    push @res, sprintf( "New(0,%s,%u,char);", $dest, length($pv) + 1 );
    my $offset = 0;
    while ( length $pv ) {
      my $str = substr $pv, 0, $max_string_len, '';
      push @res,
        sprintf( "Copy(%s,$dest+$offset,%u,char);",
        cstring($str), length($str) );
      $offset += length $str;
    }
    push @res, sprintf( "%s[%u] = '\\0';", $dest, $offset );
    warn sprintf( "Copying overlong PV %s to %s\n", cstring($pv), $dest )
      if $debug{sv};
  }
  else {
    warn sprintf( "Saving PV %s to %s\n", cstring($pv), $dest ) if $debug{sv};
    push @res,
      sprintf( "%s = savepvn(%s, %u);", $dest, cstring($pv), length($pv) );
  }
  return @res;
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
  my $len = length($pv);
  my ( $pvsym, $pvmax );
  #{
  ( $pvsym, $pvmax ) = ($B::C::const_strings and $sv->FLAGS & SVf_READONLY) ? constpv($pv) : savepv($pv);
  #}
  $pvsym = "(char*)$pvsym";# if $B::C::const_strings and $sv->FLAGS & SVf_READONLY;
  my ( $lvtarg, $lvtarg_sym ); # XXX missing
  if ($PERL513) {
    $xpvlvsect->comment('STASH, MAGIC, CUR, LEN, GvNAME, xnv_u, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("Nullhv, {0}, %u, %d, 0/*GvNAME later*/, %u, %u, %u, Nullsv, %s",
	       $len, $pvmax, $sv->NVX,
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS, $pvsym));
  } elsif ($PERL510) {
    $xpvlvsect->comment('xnv_u, CUR, LEN, GvNAME, MAGIC, STASH, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("%u, %u, %d, 0/*GvNAME later*/, 0, Nullhv, %u, %u, Nullsv, %s",
	       $sv->NVX, $len, $pvmax,
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x, {%s}",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS, $pvsym));
  } else {
    $xpvlvsect->comment('PVX, CUR, LEN, IVX, NVX, TARGOFF, TARGLEN, TARG, TYPE');
    $xpvlvsect->add(
       sprintf("%s, %u, %u, %ld, %s, 0, 0, %u, %u, Nullsv, %s",
	       $pvsym,   $len,         $pvmax,       $sv->IVX,
	       $sv->NVX, $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE ) ));
    $svsect->add(sprintf("&xpvlv_list[%d], %lu, 0x%x",
                         $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( !$B::C::pv_copy_on_grow ) {
    if ($PERL510) {
      $init->add( savepvn( "$s.sv_u.svu_pv", $pv ) );
    }
    else {
      $init->add(
        savepvn( sprintf( "xpvlv_list[%d].xpv_pv", $xpvlvsect->index ), $pv ) );
    }
  } else {
    push @static_free, $s if $pvmax and !$in_endav;
  }
  $sv->save_magic;
  savesym( $sv, "&$s" );
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
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = "(char*)$savesym";
  if ($PERL513) {
    $xpvivsect->comment('STASH, MAGIC, cur, len, IVX');
    $xpvivsect->add( sprintf( "Nullhv, {0}, %u, %u, {%s}", $len, $pvmax, ivx($sv->IVX) ) ); # IVTYPE long
  } elsif ($PERL510) {
    $xpvivsect->comment('xnv_u, cur, len, IVX');
    $xpvivsect->add( sprintf( "{0}, %u, %u, {%s}", $len, $pvmax, ivx($sv->IVX) ) ); # IVTYPE long
  } else {
    #$iv = 0 if $sv->FLAGS & (SVf_IOK|SVp_IOK);
    $xpvivsect->comment('PVX, cur, len, IVX');
    $xpvivsect->add( sprintf( "%s, %u, %u, %s",
			      $savesym, $len, $pvmax, ivx($sv->IVX) ) ); # IVTYPE long
  }
  $svsect->add(
    sprintf("&xpviv_list[%d], %u, 0x%x %s",
            $xpvivsect->index, $sv->REFCNT, $sv->FLAGS, $PERL510 ? ', {(char*)ptr_undef}' : '' ) );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$B::C::pv_copy_on_grow ) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv ) );
      } else {
	$init->add
	  (savepvn( sprintf( "xpviv_list[%d].xpv_pv", $xpvivsect->index ), $pv ) );
      }
    } else {
      push @static_free, $s if $pvmax and !$in_endav;
    }
  }
  savesym( $sv, "&$s" );
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
  local $B::C::pv_copy_on_grow = 1 if $B::C::const_strings and $sv->FLAGS & SVf_READONLY;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = "(char*)$savesym";
  my $nvx = $sv->NVX;
  my $ivx = $sv->IVX; # here must be IVX!
  my $uvuformat = $Config{uvuformat};
  $uvuformat =~ s/"//g;
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
    if ($PERL513) {
      $xpvnvsect->comment('STASH, MAGIC, cur, len, IVX, NVX');
      $xpvnvsect->add(sprintf( "Nullhv, {0}, %u, %u, {%ld}, {%s}", $len, $pvmax, $ivx, $nvx) );
    } else {
      $xpvnvsect->comment('NVX, cur, len, IVX');
      $xpvnvsect->add(sprintf( "{%s}, %u, %u, {%ld}", $nvx, $len, $pvmax, $ivx ) );
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
    $xpvnvsect->add(
      sprintf( "%s, %u, %u, %d, %s", $savesym, $len, $pvmax, $ivx, $nvx ) );
  }
  $svsect->add(
    sprintf("&xpvnv_list[%d], %lu, 0x%x %s",
            $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS, $PERL510 ? ', {(char*)ptr_undef}' : '' ) );
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  my $s = "sv_list[".$svsect->index."]";
  if ( defined($pv) ) {
    if ( !$B::C::pv_copy_on_grow ) {
      if ($PERL510) {
	$init->add( savepvn( "$s.sv_u.svu_pv", $pv ) );
      }
      else {
        $init->add(
          savepvn( sprintf( "xpvnv_list[%d].xpv_pv", $xpvnvsect->index ), $pv ) );
      }
    } else {
      push @static_free, $s if $pvmax and !$in_endav;
    }
  }
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
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
    local $B::C::pv_copy_on_grow = 1
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
  my ($sv) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my $flags = $sv->FLAGS;
  local $B::C::pv_copy_on_grow = 1 if $B::C::const_strings and $flags & SVf_READONLY;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = "(char*)$savesym";
  my $refcnt = $sv->REFCNT;
  # $refcnt-- if $B::C::pv_copy_on_grow;
  # static pv, do not destruct. test 13 with pv0 "3"
  if ($PERL510) {
    # XXX If READONLY and FAKE use newSVpvn_share instead
    #if (($sv->FLAGS & 0x01000000|0x08000000) == 0x01000000|0x08000000) {
    #  $init->add( sprintf( "$sym = (GV*)newSVpvn_share();" ));
    #}
    $xpvsect->add( sprintf( "%s{0}, %u, %u", $PERL513 ? "Nullhv, " : "", $len, $pvmax ) );
    $svsect->add( sprintf( "&xpv_list[%d], %lu, 0x%x, {%s}",
                           $xpvsect->index, $refcnt, $flags,
                           defined($pv) && $B::C::pv_copy_on_grow ? $savesym : "(char*)ptr_undef"));
    if ( defined($pv) and !$B::C::pv_copy_on_grow ) {
      $init->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    }
  }
  else {
    $xpvsect->add( sprintf( "%s, %u, %u", $savesym, $len, $pvmax ) );
    $svsect->add(sprintf("&xpv_list[%d], %lu, 0x%x",
			 $xpvsect->index, $refcnt, $flags));
    if ( defined($pv) and !$B::C::pv_copy_on_grow ) {
      $init->add( savepvn( sprintf( "xpv_list[%d].xpv_pv", $xpvsect->index ), $pv ) );
    }
  }
  if ( $B::C::pv_copy_on_grow ) {
    push @static_free, ("sv_list[".$svsect->index."]") if defined($pv) and !$in_endav;
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::PVMG::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  if (defined $sym) {
    if ($in_endav) {
      warn "in_endav: static_free without $sym\n" if $debug{av};
      @static_free = grep {!/$sym/} @static_free;
    }
    return $sym;
  }
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  $savesym = "(char*)$savesym";
  warn sprintf( "PVMG %s (0x%x) $savesym, $pvmax, $len, $pv\n", $sym, $$sv ) if $debug{mg};

  if ($PERL510) {
    if ($sv->FLAGS & SVf_ROK) {  # sv => sv->RV cannot be initialized static.
      $init->add(sprintf("SvRV_set(&sv_list[%d], (SV*)%s);", $svsect->index+1, $savesym));
      $savesym = '0';
    } else {
      if ( $B::C::pv_copy_on_grow ) {
        # comppadnames needs &PL_sv_undef instead of 0
	# But threaded PL_sv_undef => my_perl->Isv_undef, and my_perl is not available static
	if (!$pv or !$savesym or $savesym eq 'NULL') {
	  if ($ITHREADS) {
	    $savesym = "NULL";
	    $init->add( sprintf( "sv_list[%d].sv_u.svu_pv = (char*)&PL_sv_undef;",
				 $svsect->index ) );
	  } else {
	    $savesym = '(char*)&PL_sv_undef';
	  }
	}
      }
    }
    my ($ivx,$nvx) = (0, "0");
    # since 5.11 REGEXP isa PVMG, but has no IVX and NVX methods
    unless ($] >= 5.011 and $sv->isa('B::REGEXP')) {
      $ivx = $sv->IVX; # both apparently unused
      $nvx = $sv->NVX;
    }
    if ($PERL513) {
      $xpvmgsect->comment("STASH, MAGIC, cur, len, xiv_u, xnv_u");
      $xpvmgsect->add(sprintf("Nullhv, {0}, %u, %u, {%ld}, {%s}",
			      $len, $pvmax, $ivx, $nvx));
    } else {
      $xpvmgsect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash");
      $xpvmgsect->add(sprintf("{%s}, %u, %u, {%ld}, {0}, Nullhv",
			    $nvx, $len, $pvmax, $ivx));
    }
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x, {%s}",
                         $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS, $savesym));
    my $s = "sv_list[".$svsect->index."]";
    push @static_free, $s if $pvmax and $B::C::pv_copy_on_grow and !$in_endav;
  }
  else {
    # cannot initialize this pointer static
    if ($savesym =~ /&(PL|sv)/) { # (char*)&PL_sv_undef | (char*)&sv_list[%d]
      $xpvmgsect->add(sprintf("%d, %u, %u, %ld, %s, 0, 0",
			      0, $len, $pvmax, $sv->IVX, $sv->NVX));
      $init->add( sprintf( "xpvmg_list[%d].xpv_pv = $savesym;",
			   $xpvmgsect->index ) );
    } else {
      $xpvmgsect->add(sprintf("%s, %u, %u, %ld, %s, 0, 0",
			      $savesym, $len, $pvmax, $sv->IVX, $sv->NVX));
      push @static_free, sprintf("sv_list[%d]", $svsect->index+1)
	if $pvmax and $B::C::pv_copy_on_grow and !$in_endav;
    }
    $svsect->add(sprintf("&xpvmg_list[%d], %lu, 0x%x",
			 $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS));
  }
  $svsect->debug( $sv->flagspv ) if $debug{flags};
  if ( !$B::C::pv_copy_on_grow ) {
    # comppadnames need &PL_sv_undef instead of 0
    if ($PERL510) {
      if (!$pv or !$savesym or $savesym eq 'NULL') {
        $init->add( sprintf( "sv_list[%d].sv_u.svu_pv = (char*)&PL_sv_undef;",
			     $svsect->index ) );
      } else {
        $init->add( savepvn( sprintf( "sv_list[%d].sv_u.svu_pv",
				      $svsect->index ), $pv ) );
      }
    } else {
      if (!$pv or !$savesym or $savesym eq 'NULL') {
        $init->add( sprintf( "xpv_list[%d].xpv_pv = (char*)&PL_sv_undef;",
			     $xpvsect->index ) );
      } else {
        $init->add(savepvn( sprintf( "xpv_list[%d].xpv_pv", $xpvsect->index ),
			    $pv ) );
      }
    }
  }
  $sym = savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  $sv->save_magic;
  return $sym;
}

# mark threads::shared to be xs-loaded
sub mark_threads {
  if ( $threads::VERSION ) {
    my $stash = 'threads';
    mark_package($stash);
    $use_xsloader = 1;
    $xsub{$stash} = 'Dynamic-' . $INC{'threads.pm'};
  }
  my $stash = 'threads::shared';
  mark_package($stash);
  # XXX why is this needed? threads::shared should be initialized automatically
  $use_xsloader = 1; # ensure threads::shared is initialized
  $xsub{$stash} = 'Dynamic-' . $INC{'threads/shared.pm'};
  warn "mark threads and threads::shared for 'P' magic\n" if $debug{mg};
}

sub B::PVMG::save_magic {
  my ($sv) = @_;
  my $sv_flags = $sv->FLAGS;
  if ($debug{mg}) {
    my $flagspv = "";
    $flagspv = $sv->flagspv if $debug{flags} and $PERL510 and !$sv->MAGICAL;
    warn sprintf( "saving magic for %s (0x%x) flags=0x%x%s  - called from %s:%s\n",
		class($sv), $$sv, $sv_flags, $debug{flags} ? "(".$flagspv.")" : "",
		@{[(caller(1))[3]]}, @{[(caller(1))[2]]});
  }
  my $pkg = $sv->SvSTASH;
  if ($$pkg) {
    warn sprintf("stash isa class($pkg) 0x%x\n", $$pkg) if $debug{mg} or $debug{gv};
  }
  $pkg->save;
  if ($$pkg) {
    no strict 'refs';
    warn sprintf( "xmg_stash = %s (0x%x)\n", $pkg->NAME, $$pkg )
      if $debug{mg} or $debug{gv};
    # Q: Who is initializing our stash from XS? ->save is missing that.
    # A: We only need to init it when we need a CV
    $init->add( sprintf( "SvSTASH(s\\_%x) = s\\_%x;", $$sv, $$pkg ) );
    # better default for method names
    $package_pv = $pkg->NAME;
    # XXX Let's see if this helps
    #svref_2object( \&IO::bootstrap )->save
    #  if $pkg->NAME =~ /^FileHandle|IO::Handle$/;
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

    unless ( $type eq 'r' or $type eq 'D' or $type eq 'n' ) { # r - test 23 / D - Getopt::Long
      # 5.10: Can't call method "save" on unblessed reference
      #warn "Save MG ". $obj . "\n" if $PERL510;
      # 5.11 'P' fix in B::IV::save, IV => RV
      $obj = $mg->OBJ;
      $obj->save
        unless $PERL510 and ref $obj eq 'SCALAR';
      mark_threads if $type eq 'P';
    }

    if ( $len == HEf_SVKEY ) {
      #The pointer is an SV*
      $ptrsv = svref_2object($ptr)->save;
      warn "MG->PTR is an SV*\n" if $debug{mg};
      $init->add(
        sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, (char *)%s, %d);",
          $$sv, $$obj, cchar($type), $ptrsv, $len
        )
      );
    }
    elsif ( $type eq 'r' ) { # qr magic, for 5.6 done in C.xs. test 20
      my $rx   = $PERL56 ? ${$mg->OBJ} : $mg->REGEX;
      # stored by some PMOP *pm = cLOGOP->op_other (pp_ctl.c) in C.xs
      my $pmop = $REGEXP{$rx};
      if (!$pmop) {
	warn "C.xs Warning: PMOP missing for QR\n";
      } else {
	my ($resym, $relen);
	if ($PERL56) {
	  ($resym, $relen) = savere( $pmop->precomp ); # 5.6 has precomp only in PMOP
	} else {
	  ($resym, $relen) = savere( $mg->precomp );
	}
	my $pmsym = $pmop->save;
	if ($PERL510) {
          push @static_free, $resym;
	  $init->add( split /\n/,
		    sprintf <<CODE, $pmop->pmflags, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = CALLREGCOMP((SV* const)$resym, %d);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE
	}
	else {
	  $pmsym =~ s/\(OP\*\)\&pmop_list/&pmop_list/;
	  $init->add( split /\n/,
		      sprintf <<CODE, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = pregcomp((char*)$resym,(char*)($resym + $relen), (PMOP*)$pmsym);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE
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
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  warn sprintf( "Saving RV %s (0x%x) - called from %s:%s\n",
		class($sv), $$sv, @{[(caller(1))[3]]}, @{[(caller(1))[2]]})
    if $debug{sv};
  my $rv = save_rv($sv);
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

# compile-time expansion of AUTOLOAD to get the goto &sub addresses
sub try_autoload {
  my ( $cvstashname, $cvname ) = @_;
  warn sprintf( "No definition for sub %s::%s. Try Autoload\n", $cvstashname, $cvname )
    if $verbose;

  # XXX Search and call ::AUTOLOAD (=> ROOT and XSUB) (test 27, 5.8)
  no strict 'refs';
  # Since 5.10 AUTOLOAD xsubs are already resolved
  if (exists ${"$cvstashname\::"}{AUTOLOAD}) {
    my $auto = \&{"$cvstashname\::AUTOLOAD"};
    # Tweaked version of __PACKAGE__::AUTOLOAD
    ${"AutoLoader\::AUTOLOAD"} = ${"$cvstashname\::AUTOLOAD"} = "$cvstashname\::$cvname";

    # Prevent eval from polluting STDOUT and our c code
    local *REALSTDOUT;
    open(REALSTDOUT,">&STDOUT");
    open(STDOUT,">","/dev/null");
    eval { &$auto };
    open(STDOUT,">&REALSTDOUT");

    unless ($@) {
      # we need just the empty auto GV, $cvname->ROOT and $cvname->XSUB,
      # but not the whole CV optree. XXX This still fails with 5.8
      my $cv = svref_2object( \&{"$cvstashname\::$cvname"} );
      return $cv;
    }
  }

  # XXX TODO Check Selfloader (test 31?)

  # Handle AutoLoader classes explicitly. Any more general AUTOLOAD
  # use should be handled by the class itself.
  my $isa = \@{"$cvstashname\::ISA"};
  if ( grep( $_ eq "AutoLoader", @$isa ) ) {
    warn "Forcing immediate load of sub derived from AutoLoader\n" if $verbose;

    # Tweaked version of AutoLoader::AUTOLOAD
    my $dir = $cvstashname;
    $dir =~ s(::)(/)g;
    eval { require "auto/$dir/$cvname.al" };
    if ($@) {
      warn qq(failed require "auto/$dir/$cvname.al": $@\n);
      return 0;
    }
    else {
      return 1;
    }
  }

  svref_2object( \*{"$cvstashname\::AUTOLOAD"} )->save
    if $cvstashname and exists ${"$cvstashname\::"}{AUTOLOAD};
  svref_2object( \*{"$cvstashname\::CLONE"} )->save
    if $cvstashname and exists ${"$cvstashname\::"}{CLONE};
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
  my ( $cvname, $cvstashname );
  if ($$gv) {
    $cvstashname = $gv->STASH->NAME;
    $cvname      = $gv->NAME;
    warn sprintf( "CV 0x%x as PVGV 0x%x %s::%s CvFLAGS=0x%x\n",
                  $$cv, $$gv, $cvstashname, $cvname, $cv->CvFLAGS )
      if $debug{cv};
  }
  # XXX TODO need to save the gv stash::AUTOLOAD if exists
  my $root    = $cv->ROOT;
  my $cvxsub  = $cv->XSUB;
  my $isconst;
  { no strict 'subs';
    $isconst = $PERL56 ? 0 : $cv->CvFLAGS & CVf_CONST;
  }
  if ($isconst and !($cv->CvFLAGS & CVf_ANON)) {
    my $stash = $gv->STASH;
    warn sprintf( "CV CONST 0x%x %s::%s\n", $$gv, $cvstashname, $cvname )
      if $debug{cv};
    my $stsym = $stash->save;
    my $name  = cstring($cvname);
    my $vsym  = $cv->XSUBANY->save;
    $decl->add("static CV* cv$cv_index;");
    $init->add("cv$cv_index = newCONSTSUB( $stsym, $name, (SV*)$vsym );");
    my $sym = savesym( $cv, "cv$cv_index" );
    $cv_index++;
    return $sym;
  }

  if ( !$isconst && $cvxsub && ( $cvname ne "INIT" ) ) {
    my $egv       = $gv->EGV;
    my $stashname = $egv->STASH->NAME;
    if ( $cvname eq "bootstrap" and !$xsub{$stashname} ) {
      my $file = $gv->FILE;
      $decl->add("/* bootstrap $file */");
      warn "Bootstrap $stashname $file\n" if $verbose;

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
      return qq/NULL/;
    }
    else {
      # XSUBs for IO::File, IO::Handle, IO::Socket,
      # IO::Seekable and IO::Poll
      # are defined in IO.xs, so let's bootstrap it
      svref_2object( \&IO::bootstrap )->save
        if grep { $stashname eq $_ }
          qw(IO::File IO::Handle IO::Socket
          IO::Seekable IO::Poll);
    }
    unless ( in_static_core($stashname,$cvname) ) {
      no strict 'refs';
      warn sprintf( "stub for XSUB $stashname\:\:$cvname CV 0x%x\n", $$cv )
    	if $debug{cv};
      svref_2object( \*{"$stashname\::bootstrap"} )->save
        if $stashname;# and defined ${"$stashname\::bootstrap"};
      #mark_package($stashname); # not needed
      return qq/get_cv("$stashname\::$cvname",TRUE)/;
    } else {
      my $xsstash = $stashname;
      $xsstash =~ s/::/_/g;
      my $xs = "XS_${xsstash}_${cvname}";
      if ($stashname eq 'version') {
        my %vtrans = ('()'   => 'noop',
                      'parse' => 'new',
                      '(""'   => 'stringify',
                      '(0+'   => 'numify',
                      '(cmp'  => 'vcmp',
                      '(<=>'  => 'vcmp',
                      '(bool' => 'boolean',
                      '(nomethod' => 'noop',
                      'declare'   => 'qv',
                     );
        if ($vtrans{$cvname}) {
          $xs = "XS_${xsstash}_".$vtrans{$cvname};
        }
      }
      warn sprintf( "core XSUB $xs CV 0x%x\n", $$cv )
    	if $debug{cv};
      $decl->add("XS($xs);");
      return qq/newXS("$stashname\:\:$cvname", $xs, (char*)xsfile)/;
    }
  }
  if ( $cvxsub && $cvname eq "INIT" ) {
    no strict 'refs';
    return svref_2object( \&Dummy_initxs )->save;
  }

  # This define is forwarded to the real sv below
  # The new method, which saves a SV only works since 5.10 (?)
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

  warn sprintf( "saving $cvstashname\:\:$cvname CV 0x%x as $sym\n", $$cv )
    if $debug{cv};
  $package_pv = $cvstashname;
  if ( !$$root && !$cvxsub ) {
    if ( my $auto = try_autoload( $cvstashname, $cvname ) ) {
      if (ref $auto eq 'B::CV') { # explicit goto
        $root   = $auto->ROOT;
        $cvxsub = $auto->XSUB;
	if ($$auto) {
	  $cv  = $auto ; # This is new
	  $sym = savesym( $cv, "&sv_list[$sv_ix]" );
	}
      } else {
        # Recalculated root and xsub
        $root   = $cv->ROOT;
        $cvxsub = $cv->XSUB;
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
    warn sprintf( "done saving op tree for CV 0x%x, flags (%s), name %s, root=0x%x => start=%s\n",
      $$cv, $debug{flags}?$cv->flagspv:sprintf("0x%x",$cv->FLAGS), $ppname, $$root, $startfield )
      if $debug{cv};
    # XXX missing cv_start for AUTOLOAD on 5.8
    $startfield = objsym($root->next) unless $startfield; # 5.8 autoload has only root
    $startfield = "0" unless $startfield;
    if ($$padlist) {
      # readonly comppad names and symbols
      local $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
      warn sprintf( "saving PADLIST 0x%x for CV 0x%x\n", $$padlist, $$cv )
        if $debug{cv};
      # XXX avlen 2
      $padlistsym = $padlist->save;
      warn sprintf( "done saving PADLIST %s 0x%x for CV 0x%x\n",
		    $padlistsym, $$padlist, $$cv )
        if $debug{cv};
      # do not record a forward for the pad only
      $init->add( "CvPADLIST($sym) = $padlistsym;" );
    }
  }
  else {
    warn sprintf( "No definition for sub %s::%s (unable to autoload)\n",
      $cvstashname, $cvname ) if $verbose;
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
  if ($PERL510) {
    my ( $pvsym, $len ) = save_hek($pv);
    # TODO:
    # my $ourstash = "0";  # TODO stash name to bless it (test 16: "main::")
    if ($PERL513) {
      my $xpvc = sprintf
	# stash magic cur len cvstash
	("Nullhv, {0}, %u, %u, %s, "
	 # start root cvgv cvfile cvpadlist
	 ." {%s}, {s\\_%x}, %s, %s, (PADLIST *)%s,"
	 # outside outside_seq cvflags cvdepth
	 ." (CV*)s\\_%x, %s, 0x%x, %d",
	 $len, $len, "Nullhv",#CvSTASH later
	 $startfield, $$root, "0",  #GV later
	 "NULL", #cv_file later (now a HEK)
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
	$xpvcvsect->comment('STASH mg_u cur len cv_stash start_u root_u gv file padlist outside outside_seq flags depth');
	$xpvcvsect->add($xpvc);
	$svsect->add(sprintf("&xpvcv_list[%d], %lu, 0x%x, {0}",
			     $xpvcvsect->index, $cv->REFCNT, $cv->FLAGS));
	$svsect->debug( $cv->flagspv ) if $debug{flags};
      }
    } else {
      my $xpvc = sprintf
	("{%d}, %u, %u, {%s}, {%s}, %s,"
	 ." %s, {%s}, {s\\_%x}, %s, %s, (PADLIST *)%s,"
	 ." (CV*)s\\_%x, %s, 0x%x",
	 0, # GvSTASH later. test 29 or Test::Harness
	 $len, $len,
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
	$xpvcvsect->comment('GvSTASH cur len  depth mg_u mg_stash cv_stash start_u root_u cv_gv cv_file cv_padlist cv_outside outside_seq cv_flags');
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
    if ($PERL513) {
      $init->add( sprintf( "CvGV_set((CV*)%s, %s);", $sym, objsym($gv) ) );
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
    if ($ITHREADS) {
      $init->add( savepvn( "CvFILE($sym)", $cv->FILE ) );
    }
    else {
      $init->add( sprintf( "CvFILE(%s) = %s;", $sym, cstring( $cv->FILE ) ) );
    }
  }
  my $stash = $cv->STASH;
  if ($$stash) {
    $stash->save;
    # $sym fixed test 27
    $init->add( sprintf( "CvSTASH_set((CV*)$sym, (HV*)s\\_%x);", $$stash ) );
    warn sprintf( "done saving STASH 0x%x for CV 0x%x\n", $$stash, $$cv )
      if $debug{cv};
  }
  my $magic = $cv->MAGIC;
  if ($magic and $$magic) {
    $cv->save_magic; # XXX will this work?
  }
  if (!$new_cv_fw) {
    $symsect->add(sprintf(
      "SVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x".($PERL510?', {0}':''),
      $sv_ix, $xpvcv_ix, $cv->REFCNT + ($PERL510 ? 1 : 0), $cv->FLAGS
      )
    );
  }
  return $sym;
}

sub B::GV::save {
  my ($gv) = @_;
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
  warn sprintf( "  GV $sym type=%d, flags=0x%x\n", B::SV::SvTYPE($gv), $gv->FLAGS )
    if $debug{gv} and !$PERL56; # B::SV::SvTYPE not with 5.6
  if ($PERL510 and $gv->FLAGS & 0x40000000) { # SVpbm_VALID
    warn sprintf( "  GV $sym isa FBM\n") if $debug{gv};
    return B::BM::save($gv);
  }
  my $is_empty = $gv->is_empty;
  my $gvname   = $gv->NAME;
  my $package  = $gv->STASH->NAME;
  my $fullname = $package . "::" . $gvname;
  my $name     = cstring($fullname);
  warn "  GV name is $name\n" if $debug{gv};
  my $egvsym;
  my $is_special = $gv->isa("B::SPECIAL");

  if ( !$is_empty ) {
    my $egv = $gv->EGV;
    unless ($egv->isa("B::SPECIAL")) {
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
  $init->add(qq[$sym = gv_fetchpv($name, TRUE, SVt_PV);]);
  my $svflags    = $gv->FLAGS;
  my $savefields = 0;
  sub Save_HV()   { 1 }
  sub Save_AV()   { 2 }
  sub Save_SV()   { 4 }
  sub Save_CV()   { 8 }
  sub Save_FORM() { 16 }
  sub Save_IO()   { 32 }

  if ( $PERL510 and $gv->isGV_with_GP ) {
    if ($fullname eq 'main::ARGV') {
      warn "Skip overwriting main::ARGV GP\n" if $debug{gv};
    } else {
      my $gp = $gv->GP;    # B limitation
      if ( $gp and !$is_empty ) {
        warn(sprintf(
                     "New GvGP for $name: 0x%x%s %s FILEGV:0x%x GP:0x%x\n",
                     $svflags, $debug{flags} ? "(".$gv->flagspv.")" : "",
                     $gv->FILE, ${ $gv->FILEGV }, $gp
                    )) if $debug{gv};
        # XXX !PERL510 and OPf_COP_TEMP we need to fake PL_curcop for gp_file hackery
        $init->add( sprintf("GvGP($sym) = Perl_newGP(aTHX_ $sym);") );
        $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
      }
      else {
        $init->add( sprintf("GvGP($sym) = Perl_newGP(aTHX_ $sym);") );
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
  # XXX will always be > 1!!!
  my $refcnt = $gv->REFCNT + 1;
  $init->add( sprintf( "SvREFCNT($sym) += %u;", $refcnt - 1 ) ) if $refcnt > 1;

  return $sym if $is_empty;

  # XXX B::walksymtable creates an extra reference to the GV
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
  elsif ( $gvname eq '!' ) {
    $savefields = Save_HV;
  }

  # attributes::bootstrap is created in perl_parse
  # saving it would overwrite it, because perl_init() is
  # called after perl_parse()
  $savefields &= ~Save_CV if $fullname eq 'attributes::bootstrap';

  # save it
  # XXX is that correct?
  if ( defined($egvsym) && $egvsym !~ m/Null/ ) {
    # Shared glob *foo = *bar
    $init->add( "gp_free($sym);", "GvGP($sym) = GvGP($egvsym);" );
  }
  elsif ($savefields) {
    # Don't save subfields of special GVs (*_, *1, *# and so on)
    warn "GV::save saving subfields $savefields\n" if $debug{gv};
    my $gvsv = $gv->SV;
    if ( $$gvsv && $savefields & Save_SV ) {
      warn "GV::save gvsv $sym\n" if $debug{gv};
      $gvsv->save; #mostly NULL. $gvsv->isa("B::NULL");
      $init->add( sprintf( "GvSVn($sym) = (SV*)s\\_%x;", $$gvsv ) );
      warn "GV::save \$$name\n" if $debug{gv};
    }
    my $gvav = $gv->AV;
    if ( $$gvav && $savefields & Save_AV ) {
      if ($PERL510 and $fullname eq 'main::ARGV') {
        $init->add( '/* Skip overwriting @main::ARGV */' );
        warn "Skipping GV::save \@$name\n" if $debug{gv};
      } else {
        $gvav->save;
        $init->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
        warn "GV::save \@$name\n" if $debug{gv};
      }
    }
    my $gvhv = $gv->HV;
    if ( $$gvhv && $savefields & Save_HV ) {
      $gvhv->save;
      $init->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
      warn "GV::save \%$name\n" if $debug{gv};
    }
    my $gvcv = $gv->CV;
    if ( $$gvcv && $savefields & Save_CV and ref($gvcv->GV->EGV) ne 'B::SPECIAL') {
      my $origname =
        cstring( $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME );
      if ( $gvcv->XSUB && $name ne $origname ) {    #XSUB alias
	my $package = $gvcv->GV->EGV->STASH->NAME;
        warn "Save $package, XS alias of $name to $origname\n" if $debug{pkg};
        {
          no strict 'refs';
          svref_2object( \*{"$package\::bootstrap"} )->save if $package;# and defined ${"$package\::bootstrap"};
        }
        mark_package($package);
        # must save as a 'stub' so newXS() has a CV to populate
        $init->add("{\tCV *cv;");
        $init->add("\tcv = get_cv($origname,TRUE);");
        $init->add("\tGvCV($sym) = cv;");
        $init->add("\tSvREFCNT_inc((SV *)cv);");
        $init->add("}");
      }
      else {
        # TODO: may need fix CvGEN if >0 to re-validate the CV methods
        # on PERL510 (>0 + <subgeneration)
        warn "GV::save &$name ($origname)...\n" if $debug{gv};
        $init->add( sprintf( "GvCV($sym) = (CV*)(%s);", $gvcv->save ) );
        warn "GV::save &$name\n" if $debug{gv};
      }
    }
    if ( !$$gvcv && $savefields & Save_CV ) {
      no strict 'refs';
      # Fix test 31, catch unreferenced AUTOLOAD. The downside:
      # It stores the whole optree and all its children.
      svref_2object( \*{"$package\::AUTOLOAD"} )->save
        if $package and exists ${"$package\::"}{AUTOLOAD};
      svref_2object( \*{"$package\::CLONE"} )->save
        if $package and exists ${"$package\::"}{CLONE};
      # wrong. This causes B::C::bootstrap be added without XSLoader. or set $use_xsloader = 1
      #svref_2object( \*{"$package\::bootstrap"} )->save
      #	if $package and exists ${"$package\::"}{bootstrap};
    }
    if ( $] > 5.009 ) {
      # XXX TODO implement heksect to place all heks at the beginning
      #$heksect->add($gv->FILE);
      #$init->add(sprintf("GvFILE_HEK($sym) = hek_list[%d];", $heksect->index));
      $init->add(sprintf("GvFILE_HEK($sym) = %s;", save_hek($gv->FILE)))
        unless $optimize_cop;
      $init->add(sprintf("GvNAME_HEK($sym) = %s;", save_hek($gv->NAME))) if $gv->NAME;
    }
    else {
      # XXX ifdef USE_ITHREADS and PL_curcop->op_flags & OPf_COP_TEMP
      # GvFILE is at gp+1
      $init->add( sprintf( "GvFILE($sym) = %s;", cstring( $gv->FILE ) ))
        unless $optimize_cop;
      warn "GV::save GvFILE(*$name) " . cstring( $gv->FILE ) . "\n"
        if $debug{gv};
    }
    my $gvform = $gv->FORM;
    if ( $$gvform && $savefields & Save_FORM ) {
      warn "GV::save gvform->save ...\n" if $debug{gv};
      $gvform->save;
      $init->add( sprintf( "GvFORM($sym) = (CV*)s\\_%x;", $$gvform ) );
      warn "GV::save GvFORM(*$name)\n" if $debug{gv};
    }
    my $gvio = $gv->IO;
    if ( $$gvio && $savefields & Save_IO ) {
      warn "GV::save gvio->save $fullname...\n" if $debug{gv};
      $gvio->save;
      $init->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
      if ( $fullname =~ m/::DATA$/ && $B::C::save_data_fh ) { # -O3 or 5.8
        no strict 'refs';
        my $fh = *{$fullname}{IO};
        use strict 'refs';
        warn "GV::save_data $sym, $fullname ...\n" if $debug{gv};
        $gvio->save_data( $sym, $fullname, <$fh> ) if $fh->opened;
      }
      elsif ( $fullname =~ m/::DATA$/ && !$B::C::save_data_fh ) {
        warn "Warning: __DATA__ handle $fullname not stored. Need -O3 or -fsave-data.\n";
      }
      warn "GV::save GvIO(*$name)\n" if $debug{gv};
    }
    $init->add("");
  }
  warn "GV::save $name done\n" if $debug{gv};
  return $sym;
}

sub B::AV::save {
  my ($av) = @_;
  my $sym = objsym($av);
  return $sym if defined $sym;

  my ($fill, $avreal);
  # cornercase: tied array without FETCHSIZE
  eval { $fill = $av->FILL; };
  $fill = -1 if $@;    # catch error in tie magic

  my $alloc;
  if ($PERL513) {
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
    # 5.9.4+: nvu fill max iv mg stash
    my $line = "{0}, -1, -1, {0}, {0}, Nullhv";
    $line = "{0}, $fill, $fill, {0}, {0}, Nullhv" if $B::C::av_init or $B::C::av_init2;
    $line = "Nullhv, {0}, $fill, $fill, NULL" if $PERL513;
    $xpvavsect->add($line);
    $svsect->add(sprintf("&xpvav_list[%d], %lu, 0x%x, {%s}",
                         $xpvavsect->index, $av->REFCNT, $av->FLAGS,
                         '0'));
    #$avreal = $av->FLAGS & 0x40000000; # SVpav_REAL (unused)
  }
  else {
    # 5.8: array fill max off nv mg stash alloc arylen flags
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
    #foreach my $i ( 0 .. $#array ) {
    #  $acc .= "\t*svp++ = (SV*)" . $array[$i]->save . ";\n\t";
    #}
    # Init optimization by Nick Koston
    # The idea is to create loops so there is less c code. In the real world this seems
    # to reduce the memory usage ~ 3% and speed up startup time by about 8%.
    my $count;
    my @values = map { $_->save() || () } @array;
    for (my $i=0;$i<=$#array;$i++) {
      if ( $use_av_undef_speedup
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
	       && $values[$i] eq "ptr_undef"
	       && $values[$i+1] eq "ptr_undef"
	       && $values[$i+2] eq "ptr_undef")
      {
	$count=0;
	while ($values[$i+$count+1] eq "ptr_undef") {
	  $count++;
	}
	$acc .= "\tfor (gcount=0; gcount<" . ($count+1) . "; gcount++) {"
	  ." *svp++ = (SV*)&PL_sv_undef; };\n\t";
	$i += $count;
      } else {
	$acc .= "\t*svp++ = (SV*)" . $values[$i] . ";\n\t";
      }
    }
    $init->no_split;

    # With -fav-init2 use independent_comalloc()
    if ($B::C::av_init2) {
      my $i = $av_index;
      $xpvav_sizes[$i] = $fill;
      $init->add("{",
		 "\tSV **svp = avchunks[$i];",
                 "\tAV *av = $sym;");
      if ($fill > -1) {
        if ($PERL510) {
          $init->add("\tAvALLOC(av) = svp;",
                     "\tAvARRAY(av) = svp;");
        } else {
          $init->add("\tAvALLOC(av) = svp;",
                     # XXX Dirty hack from av.c:Perl_av_extend()
                     "\tSvPVX(av) = (char*)svp;");
        }
      }
      $init->add( substr( $acc, 0, -2 ) );
      $init->add( "}" );
    }
    # With -fav-init faster initialize the array as the initial av_extend()
    # is very expensive
    # The problem was calloc, not av_extend.
    # Since we are always initializing every single element we don't need
    # calloc, only malloc. wmemset'ting the pointer to PL_sv_undef
    # might be faster also.
    elsif ($B::C::av_init) {
      $init->add(
                 "{", "\tSV **svp;",
                 "\tAV *av = $sym;");
      if ($fill > -1) {
        if ($PERL510) {
          # Perl_safesysmalloc (= calloc => malloc) or Perl_malloc (= mymalloc)?
          $init->add(sprintf(($MYMALLOC
			     ? "\tNewx(svp, %d, SV*);"
			     : "\tsvp = (SV**)malloc(%d * sizeof(SV*));"),
			     $fill < 3 ? 3 : $fill+1),
                     "\tAvALLOC(av) = svp;",
                     "\tAvARRAY(av) = svp;");
        } else { # read-only AvARRAY macro
          $init->add(sprintf(($MYMALLOC
			     ? "\tNewx(svp, %d, SV*)"
			     : "\tsvp = (SV**)malloc(%d * sizeof(SV*));"),
                             $fill < 3 ? 3 : $fill+1),
                     "\tAvALLOC(av) = svp;",
                     # XXX Dirty hack from av.c:Perl_av_extend()
                     "\tSvPVX(av) = (char*)svp;");
        }
      }
      $init->add( substr( $acc, 0, -2 ) );
      $init->add( "}" );
    }
    else { # unoptimized with the full av_extend()
      my $fill1 = $fill < 3 ? 3 : $fill+1;
      $init->add(
                 "{", "\tSV **svp;",
                 "\tAV *av = $sym;",
                 "\tav_extend(av, $fill1);",
                 "\tsvp = AvARRAY(av);"
                );
      $init->add( substr( $acc, 0, -2 ) );
      $init->add( "\tAvFILLp(av) = $fill1;", "}" );
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
  my ($hv) = @_;
  my $sym = objsym($hv);
  return $sym if defined $sym;
  my $name = $hv->NAME;
  if ($name) {

    # It's a stash
    warn sprintf( "saving stash HV \"%s\" 0x%x MAX=%d\n",
                  $name, $$hv, $hv->MAX ) if $debug{hv};

    # A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
    # the only symptom is that sv_reset tries to reset the PMf_USED flag of
    # a trashed op but we look at the trashed op_type and segfault.
    #my $adpmroot = ${$hv->PMROOT};
    my $adpmroot = 0;
    $decl->add("static HV *hv$hv_index;");

    # Fix weird package names containing double-quotes, \n analog to gv_fetchpv
    $name = cstring($name);
    $init->add(qq[hv$hv_index = gv_stashpv($name, TRUE);]);
    if ($adpmroot) {
      $init->add(sprintf( "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;",
			  $adpmroot ) );
    }
    $sym = savesym( $hv, "hv$hv_index" );
    $hv_index++;
    return $sym;
  }

  # It's just an ordinary HV
  if ($PERL510) {
    if ($PERL513) { # fill removed with 5.13.1
      $xpvhvsect->comment( "stash mgu max keys" );
      $xpvhvsect->add(sprintf( "Nullhv, {0}, %d, %d",
			       $hv->MAX, 0 ));
    } else {
      $xpvhvsect->comment( "gvstash fill max keys mg stash" );
      $xpvhvsect->add(sprintf( "{0}, %d, %d, {%d}, {0}, Nullhv",
			       0, $hv->MAX, 0 ));
    }
    $svsect->add(sprintf("&xpvhv_list[%d], %lu, 0x%x, {0}",
			 $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS));
    if ($hv->MAGICAL) { # riter,eiter only for magic required
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
  }
  else {
    $xpvhvsect->comment( "array fill max keys nv mg stash riter eiter pmroot name" );
    $xpvhvsect->add(sprintf( "0, 0, %d, 0, 0.0, 0, Nullhv, %d, 0, 0, 0",
			     $hv->MAX, $hv->RITER));
    $svsect->add(sprintf( "&xpvhv_list[%d], %lu, 0x%x",
			  $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS));
  }
  $svsect->debug($hv->flagspv) if $debug{flags};
  warn sprintf( "saving HV 0x%x MAX=%d\n",
                $$hv, $hv->MAX ) if $debug{hv};
  my $sv_list_index = $svsect->index;
  my @contents     = $hv->ARRAY;
  # protect against recursive self-reference
  # i.e. with use Moose at stash Class::MOP::Class::Immutable::Trait
  # value => rv => cv => ... => rv => same hash
  $sym = savesym( $hv, "(HV*)&sv_list[$sv_list_index]" );
  if (@contents) {
    my $i;
    for ( $i = 1 ; $i < @contents ; $i += 2 ) {
      my $sv = $contents[$i];
      warn sprintf("HV recursion? with $sv -> %s\n", $sv->RV)
        if $sv->isa("B::RV")
          #and $sv->RV->isa('B::CV')
          and defined objsym($sv)
          and $debug{hv};
      $contents[$i] = $sv->save;
    }
    $init->no_split;
    $init->add( "{", "\tHV *hv = $sym;" );
    while (@contents) {
      my ( $key, $value ) = splice( @contents, 0, 2 );
      $init->add(sprintf( "\thv_store(hv, %s, %u, %s, %s);",
			  cstring($key), length( pack "a*", $key ),
			  "(SV*)$value", hash($key) ));
      warn sprintf( "  HV key %s=%s\n", $key, $value) if $debug{hv};
    }
    $init->add("}");
    $init->split;
  }
  $hv->save_magic;
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
  #if (!$PERL510 or $ITHREADS) {   # or ($PERL510 and !$PERL511)
  $use_xsloader = 1 if !$PERL56; # for PerlIO::scalar
  $init->add_eval( sprintf 'open(%s, "<", $%s)', $globname, $globname );
  #}
}

sub B::IO::save {
  my ($io) = @_;
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
  if ($PERL513) {
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
  if (!$PERL56) { # PerlIO
    # deal with $x = *STDIN/STDOUT/STDERR{IO}
    my $perlio_func;
    foreach (qw(stdin stdout stderr)) {
      $io->IsSTD($_) and $perlio_func = $_;
    }
    if ($perlio_func) {
      $init->add("IoIFP(${sym}) = PerlIO_${perlio_func}();");
      $init->add("IoOFP(${sym}) = PerlIO_${perlio_func}();");
    }
  }

  my ( $field, $fsym );
  foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
    $fsym = $io->$field();
    if ($$fsym) {
      $init->add( sprintf( "Io$field($sym) = (GV*)s\\_%x;", $$fsym ) );
      $fsym->save;
    }
  }
  $io->save_magic; # XXX TODO: does this handle the stash also?

  #my $stash = $io->STASH;
  #if ($$stash) {
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
  confess
    sprintf( "cannot save that type of SV: %s (0x%x)\n", class($sv), $$sv );
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
  if ($ITHREADS) {
    print "#define ptr_undef 0\n";
  } else {
    print "#define ptr_undef &PL_sv_undef\n";
    if ($PERL510) { # XXX const sv SIGSEGV
      print "#undef CopFILE_set\n";
      print "#define CopFILE_set(c,pv)  CopFILEGV_set((c), gv_fetchfile(pv))\n";
    }
  }
  if ($] < 5.013007 ) {
    print "#ifndef CvSTASH_set\n";
    print "#define CvSTASH_set(cv,hv) CvSTASH((cv)) = (hv)\n";
    print "#endif\n";
  }
  if ($use_av_undef_speedup || $use_svpop_speedup) {
    print "int gcount;\n";
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
      printf "static %s %s_list[%u] = {\n", $typename, $name, $lines;
      printf "\t/* %s */\n", $section->comment
        if $section->comment and $verbose;
      $section->output( \*STDOUT, "\t{ %s }, /* %d */%s\n" );
      print "};\n\n";
    }
  }
  printf "\t/* %s */\n", $init->comment if $init->comment and $verbose;
  $init->output( \*STDOUT, "\t%s\n", $init_name );
  if ($verbose) {
    warn compile_stats();
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
    print <<'EOT';
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
# if (PERL_VERSION < 11)
    U32		sv_debug_serial;	/* 5.10 only */
# endif
    char *	sv_debug_file;
#endif
} SVPV;
EOT
  }
  if ($PERL511) {
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
    print "# define RX_EXTFLAGS(prog) ((prog)->extflags)\n";
    print "#endif\n";
  }
  print "static GV *gv_list[$gv_index];\n" if $gv_index;
  if ($PERL510 and $^O eq 'MSWin32') {
    # mingw and msvc does not export newGP
    print << '__EOGP';
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
__EOGP
  }
  print "\n";
}

sub output_boilerplate {
  print <<'EOT';
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

#define XS_DynaLoader_boot_DynaLoader boot_DynaLoader
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void xs_init (pTHX);
static void dl_init (pTHX);
EOT
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
      $decl->add("static void* avchunks[$size];");
      $decl->add("static size_t avsizes[$size] = ");
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

  $init->add( split /\n/, <<EOT );
{
    register int i;
    for( i = 0; i < ${num}; ++i ) {
        ${op_list}\[i].op_ppaddr = PL_ppaddr[PTR2IV(${op_list}\[i].op_ppaddr)];
    }
}
EOT
}

sub init_op_warn {
  my ( $op_type, $num ) = @_;
  my $op_list = $op_type . "_list";

  # for reasons beyond imagination, MSVC5 considers pWARN_ALL non-const
  $init->add( split /\n/, <<EOT );
{
    register int i;
    for( i = 0; i < ${num}; ++i )
    {
        switch( (int)(${op_list}\[i].cop_warnings) )
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
EOT
}

sub output_main {

  # -fno-destruct only >5.8
  if ( !$B::C::destruct ) {
    print <<'EOT';
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
EOT
  }
  # special COW handling for 5.10 because of S_unshare_hek_or_pvn limitations
  # XXX This fails in S_doeval SAVEFREEOP(PL_eval_root): test 15
  elsif ( $PERL510 and (%strtable or $B::C::pv_copy_on_grow)) {
    print <<'EOT';
int my_perl_destruct( PerlInterpreter *my_perl );
int my_perl_destruct( PerlInterpreter *my_perl ) {
    /* set all our static pv and hek to &PL_sv_undef so perl_destruct() will not cry */
EOT
    for (0 .. $#static_free) {
      # set the sv/xpv to &PL_sv_undef, not the pv itself. 
      # If set to NULL pad_undef will fail in SvPVX_const(namesv) == '&'
      # XXX Another idea >5.10 is SvFLAGS(pv) = SVTYPEMASK
      my $s = $static_free[$_];
      if ($s =~ /^sv_list/) {
	print "    SvPV_set(&$s, (char*)&PL_sv_undef);\n";
      } elsif ($s =~ /^cop_list/) {
	print "    CopFILE_set(&$s, NULL);\n";
	print "    CopSTASHPV_set(&$s, NULL);\n";
      }
    }
    for (0 .. $hek_index-1) {
      # XXX who stores this hek? GvNAME and GvFILE most likely
      my $hek = sprintf( "hek%d", $_ );
      printf ("    %s = NULL;\n", $hek);
    }
    print "    return perl_destruct( my_perl );\n}\n\n";
  }

  print <<'EOT';
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
EOT
  if ($ITHREADS and $] > 5.007) {
    # XXX init free elems!
    my $pad_len = regex_padav->FILL + 1 - 1;    # first is an avref
    print <<EOT;
#ifdef USE_ITHREADS
    for( i = 0; i < $pad_len; ++i ) {
        av_push( PL_regex_padav, newSViv(0) );
    }
    PL_regex_pad = AvARRAY( PL_regex_padav );
#endif
EOT
  }

  if (!$PERL510) {
    print <<'EOT';
#if defined(CSH)
    if (!PL_cshlen)
      PL_cshlen = strlen(PL_cshname);
#endif
EOT
  }

  # XXX With -e "" we need to fake parse_body() scriptname = BIT_BUCKET
  print <<'EOT';
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
EOT

  # honour -T
  if (!$PERL56 and ${^TAINT}) {
   print <<'EOT';
    fakeargv[options_count] = "-T";
    ++options_count;
EOT
  }
  print <<'EOT';
#ifndef ALLOW_PERL_OPTIONS
    fakeargv[options_count] = "--";
    ++options_count;
#endif /* ALLOW_PERL_OPTIONS */
    for (i = 1; i < argc; i++)
	fakeargv[i + options_count - 1] = argv[i];
    fakeargv[argc + options_count - 1] = 0;

    exitstatus = perl_parse(my_perl, xs_init, argc + options_count - 1,
			    fakeargv, NULL);

    if (exitstatus)
	exit( exitstatus );

    TAINT;
EOT

  if ($use_perl_script_name) {
    my $dollar_0 = $0;
    $dollar_0 =~ s/\\/\\\\/g;
    $dollar_0 = '"' . $dollar_0 . '"';

    print <<EOT;
    if ((tmpgv = gv_fetchpv("0", TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, ${dollar_0});
        SvSETMAGIC(tmpsv);
    }
EOT
  }
  else {
    print <<EOT;
    if ((tmpgv = gv_fetchpv("0", TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, argv[0]);
        SvSETMAGIC(tmpsv);
    }
EOT
  }

  print <<'EOT';
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

    /* PL_main_cv = PL_compcv; */
    PL_compcv = 0;

    exitstatus = perl_init(aTHX);
    if (exitstatus)
	exit( exitstatus );
    dl_init(aTHX);

    exitstatus = perl_run( my_perl );
EOT
  if ( !$B::C::destruct) {
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
  print <<'EOT';
    perl_free( my_perl );

    PERL_SYS_TERM();

    exit( exitstatus );
}

/* yanked from perl.c */
static void
xs_init(pTHX)
{
	char *file = __FILE__;
	/* dXSUB_SYS; */
	dTARG;
	dSP;
EOT

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
  print "#ifdef USE_DYNAMIC_LOADING\n";
  foreach my $stashname ( keys %static_ext ) {
    my $stashxsub = $stashname;
    $stashxsub =~ s/::/__/g;
    #if ($stashxsub =~ m/\/(\w+)\.\w+$/ {$stashxsub = $1;}
    # cygwin has Win32CORE in static_ext
    warn "bootstrapping static $stashname added to xs_init\n" if $verbose;
    print "\tnewXS(\"${stashname}::bootstrap\", boot_$stashxsub, file);\n";
  }
  print "#endif\n";
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
    if ( $xsub{$stashname} !~ m/^Dynamic/ and !$static_ext{$stashname}) {
      my $stashxsub = $stashname;
      warn "bootstrapping $stashname added to xs_init\n" if $verbose;
      $stashxsub =~ s/::/__/g;
      print "\tPUSHMARK(sp);\n";
      printf "\tXPUSHp(\"%s\", %d);\n", $stashname, length($stashname);
      print "\tPUTBACK;\n";
      print "\tboot_$stashxsub(aTHX_ NULL);\n";
      print "\tSPAGAIN;\n";
    }
  }
  print "\tFREETMPS;\n/* end XS bootstrapping code */\n";
  print "}\n";

  print <<'EOT';

static void
dl_init(pTHX)
{
	char *file = __FILE__;
EOT
  my ($dl, $xs);
  my @dl_modules = @DynaLoader::dl_modules;
  my @PERLMODS = split(/\,/, $ENV{'PERLMODS'}); # from cpanel
  foreach my $perlmod (@PERLMODS) {
    warn "Extra module ${perlmod}\n";
    push @dl_modules, $perlmod unless grep { $_ ne $perlmod } @dl_modules;
  }
  if (!$unused_sub_packages{B}) { # filter out unused B. used within the compiler only
    warn "no dl_init for B, not marked\n" if $verbose;
    @dl_modules = grep { $_ ne 'B' } @dl_modules;
  }
  foreach my $stashname (@dl_modules) {
    if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/^Dynamic/ ) {
      # XSLoader.pm: $modlibname = (caller())[1]; needs a path at caller[1] to find auto,
      # otherwise we only have -e
      $xs++ if $xsub{$stashname} ne 'Dynamic';
      $dl++;
    }
  }
  if ($dl) {
    print "\tdTARG; dSP;\n";
    print "/* DynaLoader bootstrapping */\n";
    print "\tENTER;\n";
    print "\t++cxstack_ix; cxstack[cxstack_ix].blk_oldcop = PL_curcop;\n" if $xs;
    print "\tSAVETMPS;\n";
    print "\ttarg = sv_newmortal();\n";
    foreach my $stashname (@dl_modules) {
      if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/^Dynamic/ ) {
        warn "dl_init $stashname\n" if $verbose;
        print "\tPUSHMARK(sp);\n";
	# XXX -O1 needs XPUSHs with dynamic pv
        printf "\tXPUSHp(\"%s\", %d);\n", $stashname, length($stashname);
        print "\tPUTBACK;\n";
        print "#ifdef USE_DYNAMIC_LOADING\n";
        warn "bootstrapping $stashname added to dl_init\n" if $verbose;
        if ( $xsub{$stashname} eq 'Dynamic' ) {
          print qq/\tcall_method("DynaLoader::bootstrap_inherit",G_VOID|G_DISCARD);\n/;
        }
        else { # XS: need to fix cx for caller[1] to find auto/...
	  my ($stashfile) = $xsub{$stashname} =~ /^Dynamic-(.+)$/;
          #warn "$xsub{$stashname}\n" if $verbose;
          # i.e. PUSHBLOCK
	  printf qq/\tCopFILE_set(cxstack[0].blk_oldcop,"%s");\n/, $stashfile if $stashfile;
          print qq/\tcall_pv("XSLoader::load",G_VOID|G_DISCARD);\n/;
        }
        print "#else\n";
        my $stashxsub = $stashname;
        $stashxsub =~ s/::/__/g;
        print "\tboot_$stashxsub(aTHX_ NULL);\n";
        print "#endif\n";
        print "\tSPAGAIN;\n";
        #print "\tPUTBACK;\n";
      } else {
        warn "no dl_init for $stashname, ".
          (!$xsub{$stashname} ? "not marked\n" : "marked as $xsub{$stashname}\n") if $verbose;
      }
    }
    print "\tFREETMPS;\n";
    print "\tcxstack_ix--;\n" if $xs;  	# i.e. POPBLOCK
    print "\tLEAVE;\n";
    print "/* end DynaLoader bootstrapping */\n";
  }
  print "}\n";
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
  warn sprintf( "Checking GV method 0x%x \"$fullname\"\n", $$gv ) if $debug{gv};

  # We may be looking at this package just because it is a branch in the
  # symbol table which is on the path to a package which we need to save
  # e.g. this is 'Getopt' and we need to save 'Getopt::Long'
  #
  #return unless ( $unused_sub_packages{$package} );
  return if ( $package ne 'main' and !$unused_sub_packages{$package} );
  return if ( $package eq 'main' and
  	      $name =~ /^([^_A-Za-z].*|_\<.*|INC|STDIN|STDOUT|STDERR|ARGV|SIG|ENV|BEGIN|main::)$/ );
    # this regex was too greedy and was taking out something like sub _update {} in main (because of the _)

  warn sprintf( "Used GV method 0x%x \"$fullname\"\n", $$gv ) if $debug{gv};
  return unless ( $$cv || $$av || $$sv || $$hv );
  if ($$cv and $name eq 'bootstrap' and $cv->XSUB) {
    warn sprintf( "Skip 0x%x XS \"$fullname\"\n", $$cv ) if $debug{gv};
    return;
  }
  warn sprintf( "Saving GV method 0x%x \"$fullname\"\n", $$gv ) if $debug{gv};
  $gv->save;
}

sub mark_package {
  my $package = shift;
  unless ( $unused_sub_packages{$package} ) {
    no strict 'refs';
    $unused_sub_packages{$package} = 1;
    if ( defined @{ $package . '::ISA' } ) {
      foreach my $isa ( @{ $package . '::ISA' } ) {
        if ( $isa eq 'DynaLoader' ) {
          unless ( defined( &{ $package . '::bootstrap' } ) ) {
            warn "Forcing bootstrap of $package\n" if $verbose;
            eval { $package->bootstrap };
          }
        }
        # else
        {
          unless ( $unused_sub_packages{$isa} ) {
            warn "$isa saved (it is in $package\'s \@ISA)\n" if $verbose;
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
  push @pkg, qw(version Tie::Hash::NamedCapture) if $] >= 5.010;
  push @pkg, qw(DynaLoader)		if $Config{usedl};
  # Win32CORE only in official cygwin pkg. And it needs to be bootstrapped,
  # handled by static_ext.
  push @pkg, qw(Cygwin)			if $^O eq 'cygwin';
  push @pkg, qw(NetWare)		if $^O eq 'NetWare';
  push @pkg, qw(OS2)			if $^O eq 'os2';
  push @pkg, qw(VMS VMS::Filespec vmsish) if $^O eq 'VMS';
  #push @pkg, qw(PerlIO) if $] >= 5.008006; # get_layers only
  return @pkg;
}

sub should_save {
  no strict qw(vars refs);
  my $package = shift;
  $package =~ s/::$//;
  return $unused_sub_packages{$package} = 0
    if ( $package =~ /::::/ );    # skip ::::ISA::CACHE etc.
  warn "Considering $package\n" if $debug{pkg};
  return if index($package, " ") != -1; # XXX skip invalid package names
  return if index($package, "(") != -1; # XXX this causes the compiler to abort
  foreach my $u ( grep( $unused_sub_packages{$_}, keys %unused_sub_packages ) )
  {
    # If this package is a prefix to something we are saving, traverse it
    # but do not mark it for saving if it is not already
    # e.g. to get to Getopt::Long we need to traverse Getopt but need
    # not save Getopt
    return 1 if ( $u =~ /^$package\:\:/ );
  }
  if ( exists $unused_sub_packages{$package} ) {
    warn "Cached $package is " . $unused_sub_packages{$package} . "\n"
      if $debug{pkg};
    delete_unsaved_hashINC($package) unless $unused_sub_packages{$package};
    return $unused_sub_packages{$package};
  }

  # Omit the packages which we use (and which cause grief
  # because of fancy "goto &$AUTOLOAD" stuff).
  # XXX Surely there must be a nicer way to do this.
  if ( $package eq "FileHandle"
    || $package eq "Config"
    || $package eq "SelectSaver"
    || $package =~ /^(B|PerlIO|Internals|IO)::/ )
  {
    delete_unsaved_hashINC($package);
    return $unused_sub_packages{$package} = 0;
  }

  # keep core packages
  #my $qrpkg = "^".join("|",core_packages)."\$";
  #if ($package =~ /$qrpkg/) {
  #   warn "Keep core package $package\n" if $debug{pkg};
      # XXX this does not seem right. better fix the XSUB stub generation for those
      # return mark_package($package);
  #}

  # Now see if current package looks like an OO class. This is probably too strong.
  foreach my $m (qw(new DESTROY TIESCALAR TIEARRAY TIEHASH TIEHANDLE)) {
    # 5.10 introduced version and Regexp::DESTROY, which we dont want automatically
    if ( UNIVERSAL::can( $package, $m ) and $package !~ /^(version|Regexp)$/ ) {
      warn "$package has method $m: saving package\n" if $debug{pkg};
      return mark_package($package);
    }
  }
  delete_unsaved_hashINC($package);
  return $unused_sub_packages{$package} = 0;
}

sub delete_unsaved_hashINC {
  my $packname = shift;
  $packname =~ s/\:\:/\//g;
  $packname .= '.pm';
  warn "Deleting $packname\n" if $INC{$packname} and $debug{pkg};
  delete $INC{$packname};
}

sub walkpackages {
  my ( $symref, $recurse, $prefix ) = @_;
  my $sym;
  my $ref;
  no strict 'vars';
  $prefix = '' unless defined $prefix;
  while ( ( $sym, $ref ) = each %$symref ) {
    local (*glob);
    next unless $ref;
    *glob = $ref;
    warn("Walkpackages $prefix$sym\n") if $debug{pkg} and $debug{walk};
    if ( $sym =~ /::$/ ) {
      $sym = $prefix . $sym;
      # The walker was missing main subs to avoid recursion into O compiler subs again
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
  if ($verbose) {
    warn "Prescan for unused subs" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  &descend_marked_unused;
  walkpackages( \%{"main::"}, sub { should_save( $_[0] ); return 1 } );
  if ($verbose) {
    warn "Saving unused subs" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  walksymtable( \%{"main::"}, "savecv", \&should_save );
  if ( $sav_debug{unused} ) {
    %debug = %sav_debug;
  }
}

sub save_context {
  # forbid run-time extends of curpad syms, names and INC
  local $B::C::pv_copy_on_grow = 1 if $B::C::ro_inc;
  warn "save context:\n" if $verbose;
  $init->add("/* save context */",
	     "/* curpad names */");
  warn "curpad names:\n" if $verbose;
  my $curpad_nam      = ( comppadlist->ARRAY )[0]->save;
  warn "curpad syms:\n" if $verbose;
  $init->add("/* curpad syms */");
  my $curpad_sym      = ( comppadlist->ARRAY )[1]->save;
  warn "\%INC and \@INC:\n" if $verbose;
  $init->add('/* %INC */');
  my $inc_hv          = svref_2object( \%INC )->save;
  $init->add('/* @INC */');
  my $inc_av          = svref_2object( \@INC )->save;
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
  foreach my $pack ( keys %unused_sub_packages ) {
    mark_package($pack);
  }
}

sub save_main {

  # this is mainly for the test suite
  my $warner = $SIG{__WARN__};
  local $SIG{__WARN__} = sub { print STDERR @_ };

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
  local $SIG{__WARN__} = shift;
  $init->no_split;
  $init->add( "/* save %SIG */" ) if $verbose;
  $init->add( "{", "\tHV* hv = get_hv(\"main::SIG\",1);" );
  foreach my $k ( keys %SIG ) {
    next unless ref $SIG{$k};
    my $cv = svref_2object( \$SIG{$k} );
    my $sv = $cv->save;
    $init->add( '{', sprintf "\t".'SV* sv = (SV*)%s;', $sv );
    $init->add( sprintf("\thv_store(hv, %s, %u, %s, %s);",
                        cstring($k), length( pack "a*", $k ),
                        'sv', hash($k) ) );
    $init->add( "\t".'mg_set(sv);', '}' );
  }
  $init->add('}');
  $init->split;
}

sub save_main_rest {
  # this is mainly for the test suite
  my $warner = $SIG{__WARN__};
  local $SIG{__WARN__} = sub { print STDERR @_ };

  warn "done main optree, walking symtable for extras\n"
    if $verbose or $debug{cv};
  $init->add("");
  $init->add("/* done main optree, extra subs which might be unused */");

  save_unused_subs();

  # XSLoader was used, force saving of XSLoader::load
  if ($use_xsloader) {
    $init->add("/* force saving of XSLoader::load */");
    eval { XSLoader::load; };
    #svref_2object( \*XSLoader::load )->save;
    svref_2object( \&XSLoader::load )->save;
    $use_xsloader = 0;
  }
  $init->add("/* done extras */");

  save_sig($warner) if $B::C::save_sig;

  # honour -w
  $init->add( "/* honor -w */",
    sprintf "PL_dowarn = ( %s ) ? G_WARN_ON : G_WARN_OFF;", $^W );

  # startpoints
  warn "Writing initav\n" if $debug{av};
  my $init_av = init_av->save;
  my $end_av;
  {
    # >=5.10 need to defer nullifying of all vars in END, not only new ones.
    local ($B::C::pv_copy_on_grow, $B::C::const_strings);
    $in_endav = 1;
    warn "Writing endav\n" if $debug{av};
    $end_av  = end_av->save;
  }
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

  # XSLoader used later
  if ($use_xsloader) {
    $init->add("/* force saving of XSLoader::load */");
    eval { XSLoader::load; };
    svref_2object( \&XSLoader::load )->save;
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
  output_all("perl_init");
  print "\n";
  output_main();
}

sub init_sections {
  my @sections = (
    decl   => \$decl,
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
  my ( $arg, $val ) = @_;
  $unused_sub_packages{$arg} = $val;
}

sub compile {
  my @options = @_;
  my ( $option, $opt, $arg );
  my @eval_at_startup;
  $B::C::destruct = 1;
  my %option_map = (
    'cog'             => \$B::C::pv_copy_on_grow,
    'const-strings'   => \$B::C::const_strings,
    'save-data'       => \$B::C::save_data_fh,
    'ppaddr'          => \$B::C::optimize_ppaddr,
    'warn-sv'         => \$B::C::optimize_warn_sv,
    'av-init'         => \$B::C::av_init,
    'av-init2'        => \$B::C::av_init2,
    'ro-inc'          => \$B::C::ro_inc,
    'destruct'        => \$B::C::destruct,
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => \$B::C::save_sig,
    'cop'             => \$optimize_cop, # XXX very unsafe!
					 # Better do it in CC, but get rid of
					 # NULL cops also there.
  );
  my %optimization_map = (
    0 => [qw()],                # special case
    1 => [qw(-fcog -fav-init)],
    2 => [qw(-fwarn-sv -fppaddr -fav-init2 -fro-inc)],
    3 => [qw(-fsave-sig-hash -fsave-data -fno-destruct -fconst-strings)],
    4 => [qw(-fcop)],
  );
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
        $arg = 'oOcAHCMGSpWF';
      }
      elsif ($arg eq 'ufull') {
        $arg = 'uoOcAHCMGSpWF';
      }
      foreach $arg ( split( //, $arg ) ) {
        if ( $arg eq "o" ) {
	  $verbose++;
	  B->debug(1);
        }
        elsif ( $arg eq "O" ) {
          $debug{op}++;
        }
        elsif ( $arg eq "c" ) {
          $debug{cops}++;
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
        elsif ( $arg eq "G" ) {
          $debug{gv}++;
        }
        elsif ( $arg eq "S" ) {
          $debug{sv}++;
        }
        elsif ( $arg eq "p" ) {
          $debug{pkg}++;
        }
        elsif ( $arg eq "F" ) {
          $debug{flags}++ if eval "require B::Flags;";
        }
        elsif ( $arg eq "W" ) {
          $debug{walk}++;
        }
        elsif ( $arg eq "u" ) {
          $debug{unused}++;
        }
        else {
          warn "ignoring unknown debug option: $arg\n";
        }
      }
    }
    elsif ( $opt eq "o" ) {
      $arg ||= shift @options;
      open( STDOUT, ">$arg" ) or return "$arg: $!\n";
    }
    elsif ( $opt eq "v" ) {
      $verbose = 1;
    }
    elsif ( $opt eq "u" ) {
      $arg ||= shift @options;
      mark_unused( $arg, undef );
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
  $B::C::save_data_fh = 1 if $] >= 5.008 and (($] < 5.009004) or $ITHREADS);
  $B::C::destruct = 1 if $] < 5.008;
  if ($B::C::pv_copy_on_grow and $PERL510 and $B::C::destruct) {
    warn "Warning: -fcog / -O1 static PV copy-on-grow disabled.\n";
    # XXX Still trying custom destructor.
    undef $B::C::pv_copy_on_grow;
  }

  init_sections();
  foreach my $i (@eval_at_startup) {
    $init->add_eval($i);
  }
  if (@options) {
    return sub {
      my $objname;
      foreach $objname (@options) {
        eval "save_object(\\$objname)";
      }
      output_all();
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

=item B<-ofilename>

Output to filename instead of STDOUT

=item B<-v>

Verbose compilation. Currently gives a few compilation statistics.

=item B<-->

Force end of options

=item B<-uPackname>

Force apparently unused subs from package Packname to be compiled.
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

=item B<-D>C<[OPTIONS]>

Debug options (concatenated or separate flags like C<perl -D>).
Verbose debugging options are crucial, because we have no interactive
debugger at the early CHECK step, where the compilation happens.

=item B<-Dfull>

Enable all full debugging, as with C<-DoOcAHCMGSpWF>.
All but C<-Du>.

=item B<-Do>

All Walkop'ed OPs

=item B<-DO>

OP Type,Flags,Private

=item B<-DS>

Scalar SVs, prints B<SV/RE/RV> information on saving

=item B<-Dc>

B<COPs>, prints COPs as processed (incl. file & line num)

=item B<-DA>

prints B<AV> information on saving

=item B<-DH>

prints B<HV> information on saving

=item B<-DC>

prints B<CV> information on saving

=item B<-DG>

prints B<GV> information on saving

=item B<-DM>

prints B<MAGIC> information on saving

=item B<-Dp>

prints cached B<package> information, if used or not.

=item B<-DF>

Add Flags info to the code.

=item B<-DW>

Together with B<-Dp> also prints every B<walked> package symbol.

=item B<-Du>

do not print B<-D> information when parsing for the unused subs.

=item B<-f>I<OPTIM>

Force options/optimisations on or off one at a time. You can explicitly
disable an option using B<-fno-option>. All options default to
B<disabled>.

=over 4

=item B<-fcog>

Copy-on-grow: PVs declared and initialised statically.
Does not work yet with Perl 5.10 and higher unless
-fno-destruct is added.

=item B<-fconst-strings>

Declares readonly strings as const. Enables -fcog.
Note that readonly strings in eval'd string code will
cause a run-time failure.

=item B<-fsave-data>

Save package::DATA filehandles ( only available with PerlIO ).
Does not work yet on Perl 5.6, 5.12 and non-threaded 5.10, and is
enabled automatically where it is known to work.

=item B<-fppaddr>

Optimize the initialization of op_ppaddr.

=item B<-fwarn-sv>

Optimize the initialization of cop_warnings.

=item B<-fav-init>

Faster pre-initialization of AVs (arrays and pads)

=item B<-fav-init2>

Even more faster pre-initialization of AVs with independent_comalloc if supported.
Excludes -fav_init if so, uses -fav_init if independent_comalloc is not supported.

=item B<-fro-inc>

Set read-only @INC and %INC pathnames (-fconst-string, not the AV) and
also curpad names and symbols, to store them const and statically, not
via malloc at run-time.

This forbid run-time extends of curpad syms, names and INC strings.

=item B<-fno-destruct>

Does no global perl_destruct() at the end of the process, leaving
the memory cleanup to operating system.

This will cause problems if used embedded or as shared library/module,
but not in long-running processes.

This helps with destruction problems of static data in the
default perl destructor, and enables -fcog since 5.10.

=item B<-fuse-script-name>

Use the script name instead of the program name as $0.

=item B<-fsave-sig-hash>

Save compile-time modifications to the %SIG hash.


=item B<-fcop>

DO NOT USE YET!

Omit COP info (nextstate without labels, unneeded NULL ops,
files, linenumbers) for ~10% faster execution and less space,
but warnings and errors will have no file and line infos.

It will most likely not work yet. I<(was -fbypass-nullops in earlier
compilers)>

=back

=item B<-On>

Optimisation level (n = 0, 1, 2, 3, 4). B<-O> means B<-O1>.

=over 4

=item B<-O0>

Disable all optimizations.

=item B<-O1>

Enable B<-fcog>, B<-fav-init>.

Note that -fcog without -fno-destruct will be disabled >= 5.10.

=item B<-O2>

Enable -O1 plus B<-fppaddr>, B<-fwarn-sv>, B<-fav-init2>, B<-fro-inc>.

=item B<-O3>

Enable -O2 plus B<-fsave-sig-hash>, B<-fsave-data>, B<-fno-destruct>,
B<-fconst-strings>

=item B<-O4>

Enable -O3 plus B<-fcop>. Very unsafe, very fast, very small.

=back

=item B<-llimit>

Some C compilers impose an arbitrary limit on the length of string
constants (e.g. 2048 characters for Microsoft Visual C++).  The
B<-llimit> options tells the C backend not to generate string literals
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
    xsloader argument missing
    reading from __DATA__ handles (15) non-threaded
    handling npP magic for shared threaded variables (41-43)

=head1 AUTHOR

Malcolm Beattie C<MICB at cpan.org> I<(retired)>,
Reini Urban C<perl-compiler@googlegroups.com>

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
