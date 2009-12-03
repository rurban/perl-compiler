#      C.pm
#
#      Copyright (c) 1996, 1997, 1998 Malcolm Beattie
#      Copyright (c) 2008, 2009 Reini Urban
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#

package B::C;

our $VERSION = '1.04_27';

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

sub output {
  my ( $section, $fh, $format ) = @_;
  my $sym = $section->symtable || {};
  my $default = $section->default;
  my $i;
  foreach ( @{ $section->[-1]{values} } ) {
    s{(s\\_[0-9a-f]+)}{ exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
    printf $fh $format, $_, $i;
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

sub output {
  my ( $section, $fh, $format, $init_name ) = @_;
  my $sym = $section->symtable || {};
  my $default = $section->default;
  push @{ $section->[-1]{chunks} }, $section->[-1]{current};

  my $name = "aaaa";
  foreach my $i ( @{ $section->[-1]{chunks} } ) {
    print $fh <<"EOT";
static int perl_init_${name}()
{
	dTARG;
	dSP;
EOT
    foreach my $j (@$i) {
      $j =~ s{(s\\_[0-9a-f]+)}
                   { exists($sym->{$1}) ? $sym->{$1} : $default; }ge;
      print $fh "\t$j\n";
    }
    print $fh "\treturn 0;\n}\n";

    $section->SUPER::add("perl_init_${name}();");
    ++$name;
  }
  foreach my $i ( @{ $section->[-1]{evals} } ) {
    $section->SUPER::add( sprintf q{eval_pv("%s",1);}, $i );
  }

  print $fh <<"EOT";
static int ${init_name}()
{
	dTARG;
	dSP;
EOT
  $section->SUPER::output( $fh, $format );
  print $fh "\treturn 0;\n}\n";
}

package B::C;
use Exporter ();
our %REGEXP;

{    # block necessary for caller to work
  my $caller = caller;
  if ( $caller eq 'O' ) {
    require XSLoader;
    XSLoader::load('B::C');
  }
}

@ISA       = qw(Exporter);
@EXPORT_OK = qw(output_all output_boilerplate output_main mark_unused
  init_sections set_callback save_unused_subs objsym save_context);
# for 5.6 better use the native B::C
# 5.6.2 works fine though.
use B
  qw(minus_c sv_undef walkoptree walkoptree_slow walksymtable main_root main_start peekop
  class cchar svref_2object compile_stats comppadlist hash
  threadsv_names main_cv init_av end_av opnumber amagic_generation cstring
  HEf_SVKEY SVf_POK SVf_ROK);
BEGIN {
  if ($] >=  5.008) {
    @B::NV::ISA = 'B::IV';		  # add IVX to nv. This fixes test 23 for Perl 5.8
    B->import(qw(regex_padav CVf_CONST)); # both unsupported for 5.6
  }
}
use B::Asmdata qw(@specialsv_name);

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

my %symtable;
my %xsub;
my $warn_undefined_syms;
my $verbose = 0;
my %unused_sub_packages;
my %static_ext;
my $use_xsloader;
my $nullop_count         = 0;
my $pv_copy_on_grow      = 0;
my $optimize_ppaddr      = 0;
my $optimize_warn_sv     = 0;
my $use_perl_script_name = 0;
my $save_data_fh         = 0;
my $save_sig             = 0;
my %debug;
my $max_string_len;

my $ITHREADS = $Config{useithreads};
my $PERL510  = ( $] >= 5.009005 );
my $PERL511  = ( $] >= 5.011 );
my $PERL56   = ( $] <  5.008 );
my $MAD      = $Config{mad};

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
  $xpvcvsect, $xpvivsect, $xpvnvsect,  $xpvmgsect, $xpvlvsect,
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
sub save_main_rest2;

# fixup PVBM names which contain garbage after the ending \000
sub cstring_wrong {
  my $s = B::cstring($_[0]);
  if ($s !~ /^\"/ || $s !~ /\\000/ ) { return $s; }	
  $s =~ s/\\000.*\"$/\"/;
  return $s;	 #now clean
}

sub cstring_try1 {
  my $sv = shift or return "";
  my $s = B::cstring($sv);
  if ($sv->LEN > $sv->CUR and substr($sv->PVX,$sv->CUR,1) eq '\000') {
    return substr($s, 0, $sv->CUR);
  } else {
    return $s;
  }
}

sub walk_and_save_optree {
  my ( $name, $root, $start ) = @_;
  $verbose ? walkoptree_slow( $root, "save" ) : walkoptree( $root, "save" );
  return objsym($start);
}

# Look this up here so we can do just a number compare
# rather than looking up the name of every BASEOP in B::OP
my $OP_THREADSV = opnumber('threadsv');

# special handling for nullified COP's.
my %OP_COP = ( opnumber('nextstate') => 1, opnumber('setstate') => 1 );
$OP_COP{ opnumber('dbstate') } = 1 unless $PERL511;
warn %OP_COP if $debug{cops};

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
  if ( 0 and $PERL511 ) {
    # TODO Fill in at least the engine pointer? Or let CALLREGCOMP do that?
    $orangesect->add(
      sprintf(
        "0,%u,%u, 0,0,NULL, NULL,NULL,"
          . "0,0,0,0,NULL,0,0,NULL,0,0, NULL,NULL,NULL,0,0,0",
        $len, $pvmax
      )
    );
    $resect->add(
      sprintf(
        "&orange_list[%d], 1, %d, %s",
        $orangesect->index, $flags, cstring($re)
      )
    );
    $sym = sprintf( "re_list[%d]", $resect->index );
    warn sprintf( "Saving RE $sym->orangesect[%d] $re\n", $orangesect->index )
      if $debug{sv};
  }
  elsif ($PERL510) {
    # BUG! Should be the same as newSVpvn($resym, $relen) but is not
    #$sym = sprintf("re_list[%d]", $re_index++);
    #$resect->add(sprintf("0,0,0,%s", cstring($re)));
    $xpvsect->add( sprintf( "0, %u, %u", $len, $pvmax ) );
    $svsect->add( sprintf( "&xpv_list[%d], 1, %x", $xpvsect->index, 0x4405 ) );
    $init->add(
      savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    $sym = sprintf( "&sv_list[%d]", $svsect->index );
    # $resect->add(sprintf("&xpv_list[%d], %lu, 0x%x", $xpvsect->index, 1, 0x4405));
  }
  else {
    $sym = sprintf( "re%d", $re_index++ );
    $decl->add( sprintf( "static char *$sym = %s;\n", cstring($re) ) );
  }
  return ( $sym, length( pack "a*", $re ) );
}

sub savepv {
  my $pv    = pack "a*", shift;
  my $pvsym = 0;
  my $pvmax = 0;
  if ($pv_copy_on_grow) {
    $pvsym = sprintf( "pv%d", $pv_index++ );

    if ( defined $max_string_len && length($pv) > $max_string_len ) {
      my $chars = join ', ', map { cchar $_ } split //, $pv;
      $decl->add( sprintf( "static char %s[] = { %s };", $pvsym, $chars ) );
    }
    else {
      my $cstring = cstring($pv);
      if ( $cstring ne "0" ) {    # sic
        $decl->add( sprintf( "static char %s[] = %s;", $pvsym, $cstring ) );
      }
    }
  }
  else {
    $pvmax = length( pack "a*", $pv ) + 1;
  }
  return ( $pvsym, $pvmax );
}

sub save_rv {
  my $sv = shift;

  #    confess "Can't save RV: not ROK" unless $sv->FLAGS & SVf_ROK;
  my $rv = $sv->RV->save;

  $rv =~ s/^\(([AGHS]V|IO)\s*\*\)\s*(\&sv_list.*)$/$2/;

  return $rv;
}

# savesym, pvmax, len, pv
sub save_pv_or_rv {
  my $sv = shift;

  my $rok = $sv->FLAGS & SVf_ROK;
  my $pok = $sv->FLAGS & SVf_POK;
  my ( $len, $pvmax, $savesym, $pv ) = ( 0, 0 );
  if ($rok) {
    $savesym = '(char*)' . save_rv($sv);
  }
  else {
    $pv = $pok ? ( pack "a*", $sv->PV ) : undef;
    $len = $pok ? length($pv) : 0;
    ( $savesym, $pvmax ) = $pok ? savepv($pv) : ( 'NULL', 0 );
  }

  return ( $savesym, $pvmax, $len, $pv );
}

# global string table
sub save_hek {
  my $str = shift;
  my $len = length $str;
  return ( "NULL", 0 ) unless $len;
  my $sym = sprintf( "hek%d", $hek_index++ );

  # (HEK*)ptr_table_fetch(PL_ptr_table, source);
  # $heksect->add("hv_store(PL_strtab, \"$str\", $len, NULL, hash($str));");
  return ( "$sym", length( pack "a*", $str ) );
}

# See also init_op_ppaddr below; initializes the ppaddr to the
# OpTYPE; init_op_ppaddr iterates over the ops and sets
# op_ppaddr to PL_ppaddr[op_ppaddr]; this avoids an explicit assignment
# in perl_init ( ~10 bytes/op with GCC/i386 )
sub B::OP::fake_ppaddr {
  return $optimize_ppaddr
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
      $op->fake_ppaddr, $madprop, $op->targ, $op->type, $op->flags,
      $op->private );
  }
  $opsect_common .= ", flags, private";
}

sub B::OP::_save_common {
  my $op = shift;
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

  # since 5.10 nullified cops free their additional fields
  if ( $PERL510 and !$type and $OP_COP{ $op->targ } ) {
    warn sprintf( "Null COP: %d\n", $op->targ ) if $verbose or $debug{cops};
    if ($PERL511) {
      $copsect->comment(
        "$opsect_common, line, stash, file, hints, seq, warnings, hints_hash");
      $copsect->add(
        sprintf(
          "%s, 0, Nullhv, " . "NULL, 0, 0, " . "%u, NULL",
          $op->_save_common, 0, 'NULL'
        )
      );
    }
    elsif ($PERL510) {
      $copsect->comment(
        "$opsect_common, line, label, seq, warnings, hints_hash");
      $copsect->add(
        sprintf(
          "%s, %u, NULL, " . "NULL, NULL, 0, " . "%u, %s, NULL",
          $op->_save_common, 0, 0, 'NULL'
        )
      );
    }
    else {
      $copsect->comment(
        "$opsect_common, label, seq, arybase, line, warnings, hints_hash");
      $copsect->add(
        sprintf( "%s, NULL, NULL, NULL, 0, 0, 0, NULL", $op->_save_common ) );
    }
    my $ix = $copsect->index;
    $init->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $optimize_ppaddr;
    savesym( $op, "(OP*)&cop_list[$ix]" );
  }
  else {
    $opsect->comment($opsect_common);
    $opsect->add( $op->_save_common );
    my $ix = $opsect->index;
    $init->add( sprintf( "op_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $optimize_ppaddr;
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
    unless $optimize_ppaddr;
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

sub B::UNOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $unopsect->comment("$opsect_common, first");
  $unopsect->add( sprintf( "%s, s\\_%x", $op->_save_common, ${ $op->first } ) );
  my $ix = $unopsect->index;
  $init->add( sprintf( "unop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&unop_list[$ix]" );
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
  my $ix = $binopsect->index;
  $init->add( sprintf( "binop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&binop_list[$ix]" );
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
  my $ix = $listopsect->index;
  $init->add( sprintf( "listop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&listop_list[$ix]" );
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
  my $ix = $logopsect->index;
  $init->add( sprintf( "logop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&logop_list[$ix]" );
}

sub B::LOOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;

  #warn sprintf("LOOP: redoop %s, nextop %s, lastop %s\n",
  #		 peekop($op->redoop), peekop($op->nextop),
  #		 peekop($op->lastop)); # debug
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
  my $ix = $loopsect->index;
  $init->add( sprintf( "loop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&loop_list[$ix]" );
}

sub B::PVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $loopsect->comment("$opsect_common, pv");
  $pvopsect->add( sprintf( "%s, %s", $op->_save_common, cstring( $op->pv ) ) );
  my $ix = $pvopsect->index;
  $init->add( sprintf( "pvop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  savesym( $op, "(OP*)&pvop_list[$ix]" );
}

sub B::SVOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  my $sv            = $op->sv;
  my $svsym         = '(SV*)' . $sv->save;
  my $is_const_addr = $svsym =~ m/Null|\&/;
  $svopsect->comment("$opsect_common, sv");
  $svopsect->add(
    sprintf( "%s, %s",
      $op->_save_common, ( $is_const_addr ? $svsym : 'Nullsv' ) )
  );
  my $ix = $svopsect->index;
  $init->add( sprintf( "svop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  $init->add("svop_list[$ix].op_sv = $svsym;")
    unless $is_const_addr;
  savesym( $op, "(OP*)&svop_list[$ix]" );
}

sub B::PADOP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;
  $padopsect->comment("$opsect_common, padix");
  $padopsect->add( sprintf( "%s, %d", $op->_save_common, $op->padix ) );
  my $ix = $padopsect->index;
  $init->add( sprintf( "padop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  # padix already initialized
  # $init->add(sprintf("padop_list[$ix].op_padix = %ld;", $op->padix)); # was commented
  savesym( $op, "(OP*)&padop_list[$ix]" );
}

sub B::COP::save {
  my ( $op, $level ) = @_;
  my $sym = objsym($op);
  return $sym if defined $sym;

  # TODO: if it is a nullified COP we must save it with all cop fields!
  warn sprintf( "COP: line %d file %s\n", $op->line, $op->file )
    if $debug{cops};

  # shameless cut'n'paste from B::Deparse
  my $warn_sv;
  my $warnings   = $op->warnings;
  my $is_special = $warnings->isa("B::SPECIAL");
  if ( $is_special && $$warnings == 4 ) {
    # use warnings 'all';
    $warn_sv =
      $optimize_warn_sv
      ? 'INT2PTR(SV*,1)'.($verbose ?' /*pWARN_ALL*/':'')
      : 'pWARN_ALL';
  }
  elsif ( $is_special && $$warnings == 5 ) {
    # no warnings 'all';
    $warn_sv =
      $optimize_warn_sv
      ? 'INT2PTR(SV*,2)'.($verbose ?' /*pWARN_NONE*/':'')
      : 'pWARN_NONE';
  }
  elsif ($is_special) {
    # use warnings;
    $warn_sv =
      $optimize_warn_sv
      ? 'INT2PTR(SV*,3)'.($verbose ?' /*pWARN_STD*/':'')
      : 'pWARN_STD';
  }
  else {
    # something else
    $warn_sv = $warnings->save;
  }

  if ($PERL511) {
    # cop_label now in hints_hash (Change #33656)
    $copsect->comment(
      "$opsect_common, line, stash, file, hints, seq, warn_sv, hints_hash");
    $copsect->add(
      sprintf(
        "%s, %u, Nullhv, " . "NULL, 0, %u, " . "NULL, NULL",
        $op->_save_common, $op->line,
        $op->cop_seq, ( $optimize_warn_sv ? $warn_sv : 'NULL' )
      )
    );
    if ( $op->label ) {
      $init->add(
        sprintf(
          "cop_list[%d].cop_hints_hash = Perl_store_cop_label(aTHX_ cop_list[%d].cop_hints_hash, %s);",
          $copsect->index, $copsect->index, cstring( $op->label )
        )
      );
    }
  }
  elsif ($PERL510) {
    $copsect->comment("$opsect_common, line, label, seq, warn_sv");
    $copsect->add(
      sprintf(
        "%s, %u, %s, " . "NULL, NULL, 0, " . "%u, %s, NULL",
        $op->_save_common,     $op->line,
        cstring( $op->label ), $op->cop_seq,
        ( $optimize_warn_sv ? $warn_sv : 'NULL' )
      )
    );
  }
  else {
    $copsect->comment("$opsect_common, label, seq, arybase, line, warn_sv");
    $copsect->add(
      sprintf(
        "%s, %s, NULL, NULL, %u, %d, %u, %s",
        $op->_save_common, cstring( $op->label ),
        $op->cop_seq,      $op->arybase,
        $op->line, ( $optimize_warn_sv ? $warn_sv : 'NULL' )
      )
    );
  }
  my $ix = $copsect->index;
  $init->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
    unless $optimize_ppaddr;
  $init->add( sprintf( "cop_list[$ix].cop_warnings = %s;", $warn_sv ) )
    unless $optimize_warn_sv;

  # Trim the .pl extension, to print the executable name only.
  my $file = $op->file;
  $file =~ s/\.pl$//;
  $init->add(
    sprintf( "CopFILE_set(&cop_list[$ix], %s);",    cstring($file) ),
    sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", cstring( $op->stashpv ) )
  );

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
        "%s, s\\_%x, s\\_%x, %u, 0x%x, %s, %s",
        $op->_save_common, ${ $op->first },
        ${ $op->last }, ( $ITHREADS ? $op->pmoffset : 0 ),
        $op->pmflags, $replrootfield,
        $replstartfield
      )
    );
  }
  elsif ($PERL56) {
    $pmopsect->comment(
"$opsect_common, first, last, pmreplroot, pmreplstart, pmnext, pmregexp, pmpermflags, pmdynflags"
    );
    $pmopsect->add(
      sprintf(
        "%s, s\\_%x, s\\_%x, %s, %s, 0, 0, 0x%x, 0x%x",
        $op->_save_common,
	${ $op->first }, ${ $op->last },
	$replrootfield,  $replstartfield,
        $op->pmpermflags, $op->pmflags # XXX original 5.6 B::C has this reversed!
      )
    );
  } else {
    $pmopsect->comment(
"$opsect_common, first, last, pmreplroot, pmreplstart, pmoffset, pmflags, pmpermflags, pmdynflags"
    );
    $pmopsect->add(
      sprintf(
        "%s, s\\_%x, s\\_%x, %s, %s, 0, %u, 0x%x, 0x%x, 0x%x",
        $op->_save_common, ${ $op->first },
        ${ $op->last },    $replrootfield,
        $replstartfield, ( $ITHREADS ? $op->pmoffset : 0 ),
        $op->pmflags, $op->pmpermflags,
        $op->pmdynflags
      )
    );
  }
  my $pm = sprintf( "pmop_list[%d]", $pmopsect->index );
  $init->add( sprintf( "$pm.op_ppaddr = %s;", $ppaddr ) )
    unless $optimize_ppaddr;
  my $re = $op->precomp;
  if ( defined($re) ) {
    if ($PERL510) {
      # TODO minor optim: fix savere( $re ) to avoid newSVpvn;
      my $resym = cstring($re);
      my $relen = length($re);
      $init->add(
        sprintf("PM_SETRE(&$pm, CALLREGCOMP(newSVpvn($resym, $relen), %u));",
		$op->pmflags ),
        sprintf("RX_EXTFLAGS(PM_GETRE(&$pm)) = 0x%x;", $op->reflags )
      );
    }
    elsif ($PERL56) {
      my ( $resym, $relen ) = savere( $re, 0 );
      $init->add(
        sprintf("$pm.op_pmregexp = pregcomp($resym, $resym + %u, &$pm);",
		$relen )
      );
    }
    else { # 5.8
      my ( $resym, $relen ) = savere( $re, 0 );
      $init->add(
        sprintf(
          "PM_SETRE(&$pm, CALLREGCOMP(aTHX_ $resym, $resym + %u, &$pm));",
          $relen )
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
  warn "Saving SVt_NULL SV\n" if $debug{sv};

  # debug
  if ( $$sv == 0 ) {
    warn "NULL::save for sv = 0 called from @{[(caller(1))[3]]}\n" if $verbose;
    return savesym( $sv, "(void*)Nullsv /* XXX */" );
  }
  $svsect->add( sprintf( "0, %lu, 0x%x", $sv->REFCNT, $sv->FLAGS ) );
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::IV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  $xpvivsect->add( sprintf( "0, 0, 0, %d", $sv->IVX ) );
  $svsect->add(
    sprintf(
      "&xpviv_list[%d], %lu, 0x%x",
      $xpvivsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  warn sprintf( "Saving IV 0x%x to xpviv_list[%d], sv_list[%d]\n",
    $sv->IVX, $xpvivsect->index, $svsect->index )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::NV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $val = $sv->NVX;
  $val .= '.00' if $val =~ /^-?\d+$/;
  if ($PERL510) { # not fixed by NV isa IV >= 5.8
    $xpvnvsect->add( sprintf( "%s, 0, 0, 0", $val ) );
  }
  else {
    $xpvnvsect->add( sprintf( "0, 0, 0, %d, %s", $sv->IVX, $val ) );
  }
  $svsect->add(
    sprintf(
      "&xpvnv_list[%d], %lu, 0x%x",
      $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  warn sprintf( "Saving NV %s to xpvnv_list[%d], sv_list[%d]",
    $val, $xpvnvsect->index, $svsect->index )
    if $debug{sv};
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub savepvn {
  my ( $dest, $pv ) = @_;
  my @res;

  # work with byte offsets/lengths
  my $pv = pack "a*", $pv;
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
  return $sym if defined $sym;
  my $pv  = $sv->PV;
  my $len = length($pv);
  my ( $pvsym, $pvmax ) = savepv($pv);
  my ( $lvtarg, $lvtarg_sym );
  if ($PERL510) {
    $xpvlvsect->comment('xnv_u, CUR, LEN, GvNAME, MAGIC, STASH, TARGOFF, TARGLEN, TYPE');
    $xpvlvsect->add
      (
       sprintf(
	       "%u, %u, %d, 0/*GvNAME later*/, 0, Nullhv, %u, %u, 0, %s",
	       $sv->NVX, $len, $pvmax, 
	       $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE )
	      )
      );
  } else {
    $xpvlvsect->comment('PVX, CUR, LEN, IVX, NVX, TARGOFF, TARGLEN, TYPE');
    $xpvlvsect->add
      (
       sprintf(
	       "%s, %u, %u, %d, %g, 0, 0, %u, %u, 0, %s",
	       $pvsym,   $len,         $pvmax,       $sv->IVX,
	       $sv->NVX, $sv->TARGOFF, $sv->TARGLEN, cchar( $sv->TYPE )
	      )
      );
  }
  $svsect->add(
    sprintf(
      "&xpvlv_list[%d], %lu, 0x%x",
      $xpvlvsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );

  if ( !$pv_copy_on_grow ) {
    if ($PERL510) {
      $init->add(
        savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    }
    else {
      $init->add(
        savepvn( sprintf( "xpvlv_list[%d].xpv_pv", $xpvlvsect->index ), $pv ) );
    }
  }
  $sv->save_magic;
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::PVIV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  $xpvivsect->comment('$savesym, $len, $pvmax, $sv->IVX');
  $xpvivsect->add(
    sprintf( "%s, %u, %u, %d", $savesym, $len, $pvmax, $sv->IVX ) );
  $svsect->add(
    sprintf(
      "&xpviv_list[%d], %u, 0x%x",
      $xpvivsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  if ( defined($pv) && !$pv_copy_on_grow ) {
    if ($PERL510) {
      $init->add(
        savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    }
    else {
      $init->add(
        savepvn( sprintf( "xpviv_list[%d].xpv_pv", $xpvivsect->index ), $pv ) );
    }
  }
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::PVNV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  my $val = $sv->NVX;
  $val .= '.00' if $val =~ /^-?\d+$/;
  $val = "0" if $val eq 'nan';
  if ($PERL510) {
    $xpvnvsect->comment('$val, $len, $pvmax, $sv->IVX');
    $xpvnvsect->add(
      sprintf( "%s, %u, %u, %d", $val, $len, $pvmax, $sv->IVX ) );    # ??
  }
  else {
    $xpvnvsect->add(
      sprintf( "%s, %u, %u, %d, %s", $savesym, $len, $pvmax, $sv->IVX, $val ) );
  }
  $svsect->add(
    sprintf(
      "&xpvnv_list[%d], %lu, 0x%x",
      $xpvnvsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  if ( defined($pv) && !$pv_copy_on_grow ) {
    if ($PERL510) {
      $init->add(
        savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    }
    else {
      $init->add(
        savepvn( sprintf( "xpvnv_list[%d].xpv_pv", $xpvnvsect->index ), $pv ) );
    }
  }
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::BM::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $pv = pack "a*", ( $sv->PV . "\0" . $sv->TABLE );
  my $len = length($pv);
  $xpvbmsect->comment(
    '0,len,len+258,sv->IVX,sv->NVX,0,0,sv->USEFUL,sv->PREVIOUS,sv->RARE');
  $xpvbmsect->add(
    sprintf(
      "0, %u, %u, %d, %s, 0, 0, %d, %u, 0x%x",
      $len,        $len + 258,    $sv->IVX, $sv->NVX,
      $sv->USEFUL, $sv->PREVIOUS, $sv->RARE
    )
  );
  $svsect->add(
    sprintf(
      "&xpvbm_list[%d], %lu, 0x%x",
      $xpvbmsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  $sv->save_magic;

  if ($PERL510) {
    $init->add(
      savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
  }
  else {
    $init->add(
      savepvn( sprintf( "xpvbm_list[%d].xpv_pv", $xpvbmsect->index ), $pv ) );
  }
  $init->add(
    sprintf( "xpvbm_list[%d].xpv_cur = %u;", $xpvbmsect->index, $len - 257 ) );
  # TODO fbm_compile since 5.8 is doing something we haven't caught yet
  $init->add(
    sprintf( "fbm_compile(&sv_list[%d], 0);", $svsect->index) ) unless $PERL56;
  savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
}

sub B::PV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);
  if ($PERL510) {

# Before 5.10 in the PV SvANY was pv,len,pvmax. Since 5.10 the pv alone is below in the SV.sv_u
# Oh my!
    $xpvsect->add( sprintf( "0, %u, %u", $len, $pvmax ) );
    $svsect->add(
      sprintf(
        "&xpv_list[%d], %lu, 0x%x",
        $xpvsect->index, $sv->REFCNT, $sv->FLAGS
      )
    );
    if ( defined($pv) && !$pv_copy_on_grow ) {
      $init->add(
        savepvn( sprintf( "sv_list[%d].sv_u.svu_pv", $svsect->index ), $pv ) );
    }
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
  else {
    $xpvsect->add( sprintf( "%s, %u, %u", $savesym, $len, $pvmax ) );
    $svsect->add(
      sprintf(
        "&xpv_list[%d], %lu, 0x%x",
        $xpvsect->index, $sv->REFCNT, $sv->FLAGS
      )
    );
    if ( defined($pv) && !$pv_copy_on_grow ) {
      $init->add(
        savepvn( sprintf( "xpv_list[%d].xpv_pv", $xpvsect->index ), $pv ) );
    }
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
}

sub B::PVMG::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my ( $savesym, $pvmax, $len, $pv ) = save_pv_or_rv($sv);

  if ($PERL510) {
    $xpvmgsect->comment("xnv_u, pv_cur, pv_len, xiv_u, xmg_u, xmg_stash");
    $xpvmgsect->add(
      sprintf(
        "%s, %u, %u, %d, 0, 0",
        $sv->NVX, $len, $pvmax, $sv->IVX
      ) # $savesym
    );
  }
  else {
    $xpvmgsect->add(
      sprintf(
        "%s, %u, %u, %d, %s, 0, 0",
        $savesym, $len, $pvmax, $sv->IVX, $sv->NVX
      )
    );
  }
  $svsect->add(
    sprintf(
      "&xpvmg_list[%d], %lu, 0x%x",
      $xpvmgsect->index, $sv->REFCNT, $sv->FLAGS
    )
  );
  if ( defined($pv) && !$pv_copy_on_grow ) {
    my $pvx =
      $] < 5.009 ? "xpvmg_list[%d].xpv_pv" : "xpvmg_list[%d].xiv_u.xivu_p1";
    $init->add( savepvn( sprintf( $pvx, $xpvmgsect->index ), $pv ) );
  }
  $sym = savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  $sv->save_magic;
  return $sym;
}

sub B::PVMG::save_magic {
  my ($sv) = @_;
  warn sprintf( "saving magic for %s (0x%x)\n", class($sv), $$sv )
    if $debug{mg};
  my $stash = $sv->SvSTASH;
  $stash->save;
  if ($$stash) {
    warn sprintf( "xmg_stash = %s (0x%x)\n", $stash->NAME, $$stash )
      if $debug{mg} or $debug{gv};
    # XXX Hope stash is already going to be saved.
    $init->add( sprintf( "SvSTASH(s\\_%x) = s\\_%x;", $$sv, $$stash ) );
  }
  my @mgchain = $sv->MAGIC;
  my ( $mg, $type, $obj, $ptr, $len, $ptrsv );
  foreach $mg (@mgchain) {
    $type = $mg->TYPE;
    $ptr  = $mg->PTR;
    $len  = $mg->LENGTH;
    if ( $debug{mg} ) {
      eval {
        warn sprintf( "magic %s (0x%x), obj %s (0x%x), type %s, ptr %s\n",
          class($sv), $$sv, class($obj), $$obj, cchar($type), cstring($ptr) );
      };
    }

    unless ( $type eq 'r' ) { # FIXME test 23
      $obj = $mg->OBJ;
      # 5.10: Can't call method "save" on unblessed reference: perl -Mblib script/perlcc t/c.t
      #warn "Save MG ". $obj . "\n" if $PERL510;
      $obj->save
        unless $PERL510 and ref $obj eq 'SCALAR';
    }

    if ( $len == HEf_SVKEY ) {
      #The pointer is an SV*
      $ptrsv = svref_2object($ptr)->save;
      $init->add(
        sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s,(char *) %s, %d);",
          $$sv, $$obj, cchar($type), $ptrsv, $len
        )
      );
    }
    elsif ( $type eq 'r' ) {
      my $rx   = $mg->REGEX;
      my $pmop = $REGEXP{$rx};

      confess "PMOP not found for REGEXP $rx" unless $pmop;

      my ( $resym, $relen ) =
        savere( $mg->precomp );    # string that generated the regexp
      my $pmsym = $pmop->save;
      if ($PERL510) {
        $init->add( split /\n/,
          sprintf
            <<CODE, $mg->pmflags, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = CALLREGCOMP($resym, %d);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE
      }
      else {
        $init->add( split /\n/,
          sprintf <<CODE, $$sv, cchar($type), cstring($ptr), $len );
{
    REGEXP* rx = pregcomp($resym, $resym + $relen, (PMOP*)$pmsym);
    sv_magic((SV*)s\\_%x, (SV*)rx, %s, %s, %d);
}
CODE
      }
    }
    else {
      $init->add(
        sprintf(
          "sv_magic((SV*)s\\_%x, (SV*)s\\_%x, %s, %s, %d);",
          $$sv, $$obj, cchar($type), cstring($ptr), $len
        )
      );
    }
  }
}

# TODO: Test 5.11 changes (SV -> IV)
sub B::RV::save {
  my ($sv) = @_;
  my $sym = objsym($sv);
  return $sym if defined $sym;
  my $rv = save_rv($sv);
  if ($PERL510) {

    # 5.10 has no struct xrv anymore, just sv_u.svu_rv. Set all at runtime.
    $svsect->add( sprintf( "0, %lu, 0x%x", $sv->REFCNT, $sv->FLAGS ) );
    $init->add(
      sprintf( "sv_list[%d].sv_u.svu_rv = (SV*)%s;\n", $svsect->index, $rv ) );
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
  else {

    # GVs need to be handled at runtime
    if ( ref( $sv->RV ) eq 'B::GV' ) {
      $xrvsect->add("(SV*)Nullgv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;\n", $xrvsect->index, $rv ) );
    }

    # and stashes, too
    elsif ( $sv->RV->isa('B::HV') && $sv->RV->NAME ) {
      $xrvsect->add("(SV*)Nullhv");
      $init->add(
        sprintf( "xrv_list[%d].xrv_rv = (SV*)%s;\n", $xrvsect->index, $rv ) );
    }
    else {
      $xrvsect->add($rv);
    }
    $svsect->add(
      sprintf(
        "&xrv_list[%d], %lu, 0x%x",
        $xrvsect->index, $sv->REFCNT, $sv->FLAGS
      )
    );
    return savesym( $sv, sprintf( "&sv_list[%d]", $svsect->index ) );
  }
}

sub try_autoload {
  my ( $cvstashname, $cvname ) = @_;
  warn sprintf( "No definition for sub %s::%s\n", $cvstashname, $cvname );

  # Handle AutoLoader classes explicitly. Any more general AUTOLOAD
  # use should be handled by the class itself.
  no strict 'refs';
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
}
sub Dummy_initxs { }

sub B::CV::save {
  my ($cv) = @_;
  my $sym = objsym($cv);
  if ( defined($sym) ) {
    warn sprintf( "CV 0x%x already saved as $sym\n", $$cv ) if $debug{cv};
    return $sym;
  }

  # Reserve a place in svsect and xpvcvsect and record indices
  my $gv = $cv->GV;
  my ( $cvname, $cvstashname );
  if ($$gv) {
    $cvname      = $gv->NAME;
    $cvstashname = $gv->STASH->NAME;
    warn sprintf( "CV as PVGV 0x%x %s::%s\n", $$gv, $cvstashname, $cvname )
      if $debug{cv};
  }
  my $root    = $cv->ROOT;
  my $cvxsub  = $cv->XSUB;
  my $isconst;
  { no strict 'subs';
    $isconst = $PERL56 ? 0 : $cv->CvFLAGS & CVf_CONST;
  }
  if ($isconst) {
    my $value = $cv->XSUBANY;
    my $stash = $gv->STASH;
    if ($value) {
      my $vsym  = $value->save;
      my $stsym = $stash->save;
      my $name  = cstring($cvname);
      $decl->add("static CV* cv$cv_index;");
      $init->add("cv$cv_index = newCONSTSUB( $stsym, NULL, $vsym );");
      my $sym = savesym( $cv, "cv$cv_index" );
      $cv_index++;
      return $sym;
    }
  }

  #INIT is removed from the symbol table, so this call must come
  # from PL_initav->save. Re-bootstrapping  will push INIT back in
  # so nullop should be sent.
  if ( !$isconst && $cvxsub && ( $cvname ne "INIT" ) ) {
    my $egv       = $gv->EGV;
    my $stashname = $egv->STASH->NAME;
    if ( $cvname eq "bootstrap" ) {
      my $file = $gv->FILE;
      $decl->add("/* bootstrap $file */");
      warn "Bootstrap $stashname $file\n" if $verbose;

      # if it not isa('DynaLoader'), it should hopefully be XSLoaded
      # ( attributes being an exception, of course )
      if ( $stashname ne 'attributes'
        && !UNIVERSAL::isa( $stashname, 'DynaLoader' ) )
      {
        $xsub{$stashname} = 'Dynamic-XSLoaded';
        $use_xsloader = 1;
      }
      else {
        $xsub{$stashname} = 'Dynamic';
      }

      # $xsub{$stashname}='Static' unless  $xsub{$stashname};
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
    warn sprintf( "stub for XSUB $cvstashname\:\:$cvname CV 0x%x\n", $$cv )
      if $debug{cv};
    return qq/(perl_get_cv("$stashname\:\:$cvname",TRUE))/;
  }
  if ( $cvxsub && $cvname eq "INIT" ) {
    no strict 'refs';
    return svref_2object( \&Dummy_initxs )->save;
  }
  my $sv_ix = $svsect->index + 1;
  $svsect->add("SVIX$sv_ix");
  my $xpvcv_ix = $xpvcvsect->index + 1;
  # $xpvcvsect->add("XPVCVIX$xpvcv_ix");

  # Save symbol now so that GvCV() doesn't recurse back to us via CvGV()
  $sym = savesym( $cv, "(CV*)&sv_list[$sv_ix]" );
  warn sprintf( "saving $cvstashname\:\:$cvname CV 0x%x as $sym\n", $$cv )
    if $debug{cv};
  if ( !$$root && !$cvxsub ) {
    if ( try_autoload( $cvstashname, $cvname ) ) {
      # Recalculate root and xsub
      $root   = $cv->ROOT;
      $cvxsub = $cv->XSUB;
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
    warn sprintf( "saving op tree for CV 0x%x, root = 0x%x\n", $$cv, $$root )
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
    warn sprintf( "done saving op tree for CV 0x%x, name %s, root 0x%x => start=%s\n",
      $$cv, $ppname, $$root, $startfield )
      if $debug{cv};
    if ($$padlist) {
      warn sprintf( "saving PADLIST 0x%x for CV 0x%x", $$padlist, $$cv )
        if $debug{cv};
      $padlistsym = $padlist->save;
      warn sprintf( "done saving PADLIST %s 0x%x for CV 0x%x\n",
        $padlistsym, $$padlist, $$cv )
        if $debug{cv};
      $init->add( sprintf( "CvPADLIST(%s) = %s;", $sym, $padlistsym ) );
    }
  }
  else {
    warn sprintf( "No definition for sub %s::%s (unable to autoload)\n",
      $cvstashname, $cvname );    # debug
  }
  $pv = '' unless defined $pv;    # Avoid use of undef warnings
  if ($PERL510) {
    my ( $pvsym, $len ) = save_hek($pv);
    if ($len) {
      $init->add(
        sprintf( "HEK *%s = share_hek(%s,%u,0);", $pvsym, cstring($pv), $len )
      );
      $pvsym = "(HEK *)$pvsym";

      # $pvsym = $heksect->add(cstring($pv));
    }
    else {
      $pvsym = "0";
    }
    # TODO:
    my $ourstash = "0";  #Nullhv"
    $xpvcvsect->comment('GvSTASH cur len  depth mg_u mg_stash cv_stash start_u root_u cv_gv cv_file cv_padlist cv_outside outside_seq cv_flags');
    $xpvcvsect->add
      (sprintf("s\\_%x, /*GvSTASH*/\n\t %u, /*cur*/\n\t %u, /*len*/\n\t %s, /*DEPTH*/\n\t %s, /*MAGIC later*/\n\t %s, /*STASH later*/\n\t"
	       ." %s, /*CvSTASH later*/\n\t %s, /*START*/\n\t s\\_%x, /*ROOT*/\n\t %s, /*GV later*/\n\t %s, /*FILE*/\n\t (PADLIST *)%s,\n\t"
	       ." (CV*)s\\_%x,\n\t %s, /*OUTSIDE_SEQ later*/\n\t 0x%x/*CvFLAGS*/",
	       $gv->STASH, # TODO!
	       length($pv), length($pv),
	       $cv->DEPTH,
	       "NULL", "Nullhv", #MAGIC + STASH later
	       "Nullhv",#CvSTASH later
	       $startfield,
	       $$root,
	       "0",    #GV later
	       "NULL", #cv_file later (now a HEK)
	       $padlistsym,
	       ${ $cv->OUTSIDE }, #if main_cv set later
	       $cv->OUTSIDE_SEQ,  #later
	       $cv->CvFLAGS
	      )
      );
    if ( $cv->OUTSIDE_SEQ ) {
      my $cop = $symtable{ sprintf( "s\\_%x", $cv->OUTSIDE_SEQ ) };
      $init->add( sprintf( "CvOUTSIDE_SEQ(%s) = %s;", $sym, $cop ) ) if $cop;
    }
  }
  elsif ($PERL56) {
    $xpvcvsect->comment('pv cur len off nv magic mg_stash cv_stash start root xsub xsubany cv_gv cv_file cv_depth cv_padlist cv_outside cv_flags');
    $xpvcvsect->add(
      sprintf("%s, %u, 0, %d, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub, $xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)s\\_%x, 0x%x",
        cstring($pv),      length($pv),    $cv->IVX,
        $cv->NVX,  $startfield,       ${ $cv->ROOT }, $cv->DEPTH,
        $$padlist, ${ $cv->OUTSIDE }, $cv->CvFLAGS
      )
    );
  }
  else {
    $xpvcvsect->comment('pv cur len off nv magic mg_stash cv_stash start root xsub xsubany cv_gv cv_file cv_depth cv_padlist cv_outside cv_flags outside_seq');
    $xpvcvsect->add(
      sprintf("%s, %u, 0, %d, %s, 0, Nullhv, Nullhv, %s, s\\_%x, $xsub, $xsubany, Nullgv, \"\", %d, s\\_%x, (CV*)s\\_%x, 0x%x, 0x%x",
        cstring($pv),      length($pv),    $cv->IVX,
        $cv->NVX,  $startfield,       ${ $cv->ROOT }, $cv->DEPTH,
        $$padlist, ${ $cv->OUTSIDE }, $cv->CvFLAGS,   $cv->OUTSIDE_SEQ
      )
    );
  }

  if ( ${ $cv->OUTSIDE } == ${ main_cv() } ) {
    $init->add( sprintf( "CvOUTSIDE(s\\_%x)=PL_main_cv;", $$cv ) );
    $init->add( sprintf("SvREFCNT_inc(PL_main_cv);") );
  }
  if ($$gv) {
    warn sprintf( "Saving GV 0x%x for CV 0x%x\n", $$gv, $$cv ) if $debug{cv};
    $gv->save;
    $init->add( sprintf( "CvGV(%s) = %s;", $sym, objsym($gv) ) );
    #warn sprintf("done saving GV 0x%x for CV 0x%x\n",
    #		   $$gv, $$cv) if $debug{cv};
  }
  if ($ITHREADS) {
    $init->add( savepvn( "CvFILE($sym)", $cv->FILE ) );
  }
  else {
    $init->add( sprintf( "CvFILE(%s) = %s;", $sym, cstring( $cv->FILE ) ) );
  }
  my $stash = $cv->STASH;
  if ($$stash) {
    $stash->save;
    $init->add( sprintf( "CvSTASH(s\\_%x) = s\\_%x;", $$cv, $$stash ) );
    warn sprintf( "done saving STASH 0x%x for CV 0x%x\n", $$stash, $$cv )
      if $debug{cv};
  }
  $symsect->add(
    sprintf(
      "SVIX%d\t(XPVCV*)&xpvcv_list[%u], %lu, 0x%x",
      $sv_ix, $xpvcv_ix, $cv->REFCNT + 1 * 0, $cv->FLAGS
    )
  );
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
  warn sprintf( "  GV type=%d, flags=0x%x\n", B::SV::SvTYPE($gv), B::SV::FLAGS($gv) )
    if $debug{gv} and !$PERL56; # B::SV::SvTYPE not with 5.6
  # only PVGV or PVLV have names. crash in test 11: 2nd GV "x" is a (CV*) but of type 9 (GV)
  my $is_empty = $gv->is_empty;
  my $gvname   = $gv->NAME;
  my $fullname = $gv->STASH->NAME . "::" . $gvname;
  my $name     = cstring($fullname);
  warn "  GV name is $name\n" if $debug{gv};
  my $egvsym;
  my $is_special = $gv->isa("B::SPECIAL");

  if ( !$is_empty ) {
    my $egv = $gv->EGV;
    if ( $$gv != $$egv ) {
      warn(
        sprintf( "EGV name is %s, saving it now\n",
          $egv->STASH->NAME . "::" . $egv->NAME )
      ) if $debug{gv} and !$egv->isa("B::SPECIAL");
      $egvsym = $egv->save;
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
    my $gp = $gv->GP;    # B limitation
    if ( $gp and !$is_empty ) {
      warn(
        sprintf(
          "New GvGP for $name: 0x%x %s 0x%x 0x%x\n",
          $svflags, $gv->FILE, ${ $gv->FILEGV }, $gp
        )
      ) if $debug{gv};
      $init->add( sprintf("GvGP($sym) = Perl_newGP(aTHX_ $sym);") );
      $savefields = Save_HV | Save_AV | Save_SV | Save_CV | Save_FORM | Save_IO;
    }
    else {
      # Remove SVpgv_GP (GV has a valid GP) SvFLAGS(sv) &= ~SVpgv_GP
      # 5.8 had SvFLAGS 0x600d, 5.11 has 0x8009
      #$svflags = $gv->FLAGS && 0x8000 ? $gv->FLAGS - 0x8000 : $gv->FLAGS; #SVpgv_GP
      #$init->add(sprintf("GvGP($sym) = 0;"));
      #warn("Removing empty GP from $name\n") if $debug{gv};
      $init->add( sprintf("GvGP($sym) = Perl_newGP(aTHX_ $sym);") );
    }
  }
  my $gvflags = $gv->GvFLAGS;
  if ($gvflags > 256) { $gvflags = $gvflags && 256 }; # $gv->GvFLAGS as U8
  $init->add(
    sprintf( "SvFLAGS($sym) = 0x%x;", $svflags ),
    sprintf( "GvFLAGS($sym) = %d;",   $gvflags )
  );
  $init->add( sprintf( "GvLINE($sym) = %d;",
		       ($gv->LINE > 2147483647  # S32 INT_MAX
			? 4294967294 - $gv->LINE
			: $gv->LINE )))
	      unless $is_empty;

# XXX hack for when Perl accesses PVX of GVs, only if SvPOK
#if (!($svflags && 0x400)) { # defer to run-time (0x400 -> SvPOK) for convenience
  if ( !$PERL510 ) {
    $init->add("if (SvPOK($sym)) SvPVX($sym) = emptystring;") unless $is_empty;
  }

  # Shouldn't need to do save_magic since gv_fetchpv handles that
  #$gv->save_magic;
  # XXX will always be > 1!!!
  my $refcnt = $gv->REFCNT + 1;
  $init->add( sprintf( "SvREFCNT($sym) += %u;", $refcnt - 1 ) ) if $refcnt > 1;

  return $sym if $is_empty;

  # XXX B::walksymtable creates an extra reference to the GV
  my $gvrefcnt = $gv->GvREFCNT;
  if ( $gvrefcnt > 1 ) {
    $init->add( sprintf( "GvREFCNT($sym) += %u;", $gvrefcnt - 1 ) );
  }

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
    warn "GV::save saving subfields\n" if $debug{gv};
    my $gvsv = $gv->SV;
    if ( $$gvsv && $savefields & Save_SV ) {
      warn "GV::save gvsv $sym\n" if $debug{gv};
      $gvsv->save; #mostly NULL. $gvsv->isa("B::NULL");
      $init->add( sprintf( "GvSVn($sym) = s\\_%x;", $$gvsv ) );
      warn "GV::save \$$name\n" if $debug{gv};
#save_main_rest();exit; # test 11 crashes around here
    }
    my $gvav = $gv->AV;
    if ( $$gvav && $savefields & Save_AV ) {
      $gvav->save;
      $init->add( sprintf( "GvAV($sym) = s\\_%x;", $$gvav ) );
      warn "GV::save \@$name\n" if $debug{gv};
    }
    my $gvhv = $gv->HV;
    if ( $$gvhv && $savefields & Save_HV ) {
      $gvhv->save;
      $init->add( sprintf( "GvHV($sym) = s\\_%x;", $$gvhv ) );
      warn "GV::save \%$name\n" if $debug{gv};
    }
    my $gvcv = $gv->CV;
    if ( $$gvcv && $savefields & Save_CV ) {
      my $origname =
        cstring( $gvcv->GV->EGV->STASH->NAME . "::" . $gvcv->GV->EGV->NAME );
      if ( $gvcv->XSUB && $name ne $origname ) {    #XSUB alias
            # must save as a 'stub' so newXS() has a CV to populate
        $init->add("{ CV *cv;");
        $init->add("\tcv=perl_get_cv($origname,TRUE);");
        $init->add("\tGvCV($sym)=cv;");
        $init->add("\tSvREFCNT_inc((SV *)cv);");
        $init->add("}");
      }
      else {
        warn "GV::save &$name..\n" if $debug{gv};
        $init->add( sprintf( "GvCV($sym) = (CV*)(%s);", $gvcv->save ) );
        warn "GV::save &$name\n" if $debug{gv};
      }
    }
    if ( $] > 5.009 ) {
      my $file = cstring( $gv->FILE );
      #my $heksym = $heksect->add($file);
      $init->add(
                 sprintf(
                         "{ U32 hash1; PERL_HASH(hash1,%s,%u);",
                         $file, length($file) - 2
                        ),
                 sprintf(
                         " GvFILE_HEK($sym) = share_hek(%s,%u,hash1);}",
                         $file, length($file) - 2
                        )
                );
      warn "GV::save GvFILE_HEK(*$name) $file\n" if $debug{gv};
      if ($gv->NAME) {
        my $name = cstring( $gv->NAME );
        $init->add(
                   sprintf(
                           "{ U32 hash2; PERL_HASH(hash2,%s,%u);",
                           $name, length($name) - 2
                          ),
                   sprintf(
                           " GvNAME_HEK($sym) = share_hek(%s,%u,hash2);}",
                           $name, length($name) - 2
                          )
                  );
        warn "GV::save GvNAME_HEK(*$name) $name\n" if $debug{gv};
      }
    }
    else {
      $init->add( sprintf( "GvFILE($sym) = %s;", cstring( $gv->FILE ) ) );
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
      warn "GV::save gvio->save ...\n" if $debug{gv};
      $gvio->save;
      $init->add( sprintf( "GvIOp($sym) = s\\_%x;", $$gvio ) );
      if ( $fullname =~ m/::DATA$/ && $save_data_fh ) {
        no strict 'refs';
        my $fh = *{$fullname}{IO};
        use strict 'refs';
        $gvio->save_data( $fullname, <$fh> ) if $fh->opened;
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
  my $line;
  if ($PERL510) {

    # 5.9.4+: nv fill max iv mg stash
    $line = "0.0, -1, -1, 0, 0, Nullhv";
  }
  else {

    # 5.8: array fill max off nv mg stash alloc arylen flags
    $line = "0, -1, -1, 0, 0.0, 0, Nullhv, 0, 0";
    $line .= sprintf( ", 0x%x", $av->AvFLAGS ) if $] < 5.009;
  }
  $xpvavsect->add($line);
  $svsect->add(
    sprintf(
      "&xpvav_list[%d], %lu, 0x%x",
      $xpvavsect->index, $av->REFCNT, $av->FLAGS
    )
  );
  my $sv_list_index = $svsect->index;
  $av->save_magic;

  # cornercase: tied array without FETCHSIZE
  my $fill;
  eval { $fill = $av->FILL; };
  $fill = -1 if $@;    # catch error in tie magic
  if ( $debug{av} ) {
    $line = sprintf( "saving AV 0x%x FILL=$fill", $$av );
    $line .= sprintf( " AvFLAGS=0x%x", $av->AvFLAGS ) if $] < 5.009;
    warn "$line\n";
  }

  # XXX AVf_REAL is wrong test: need to save comppadlist but not stack
  #if ($fill > -1 && ($avflags & AVf_REAL)) {
  if ( $fill > -1 ) {
    my @array = $av->ARRAY;
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
    foreach my $i ( 0 .. $#array ) {
      $acc .= "\t*svp++ = (SV*)" . $array[$i]->save . ";\n\t";
    }
    $init->no_split;
    $init->add(
      "{", "\tSV **svp;",
      "\tAV *av = (AV*)&sv_list[$sv_list_index];",
      "\tav_extend(av, $fill);",
      "\tsvp = AvARRAY(av);"
    );
    $init->add( substr( $acc, 0, -2 ) );
    $init->add( "\tAvFILLp(av) = $fill;", "}" );
    $init->split;

    # we really added a lot of lines ( B::C::InitSection->add
    # should really scan for \n, but that would slow
    # it down
    $init->inc_count($#array);
  }
  else {
    my $max = $av->MAX;
    $init->add("av_extend((AV*)&sv_list[$sv_list_index], $max);")
      if $max > -1;
  }
  return savesym( $av, "(AV*)&sv_list[$sv_list_index]" );
}

sub B::HV::save {
  my ($hv) = @_;
  my $sym = objsym($hv);
  return $sym if defined $sym;
  my $name = $hv->NAME;
  if ($name) {

    # It's a stash

    # A perl bug means HvPMROOT isn't altered when a PMOP is freed. Usually
    # the only symptom is that sv_reset tries to reset the PMf_USED flag of
    # a trashed op but we look at the trashed op_type and segfault.
    #my $adpmroot = ${$hv->PMROOT};
    my $adpmroot = 0;
    $decl->add("static HV *hv$hv_index;");

    # XXX Beware of weird package names containing double-quotes, \n, ...?
    $init->add(qq[hv$hv_index = gv_stashpv("$name", TRUE);]);
    if ($adpmroot) {
      $init->add(
        sprintf( "HvPMROOT(hv$hv_index) = (PMOP*)s\\_%x;", $adpmroot ) );
    }
    $sym = savesym( $hv, "hv$hv_index" );
    $hv_index++;
    return $sym;
  }

  # It's just an ordinary HV
  if ($PERL510) {

    # 5.9: nvu fill max ivu mg stash.
    $xpvhvsect->add( sprintf( "0.0, 0, %d, 0, 0, Nullhv", $hv->MAX ) );
    $svsect->add(
      sprintf(
        "&xpvhv_list[%d], %lu, 0x%x",
        $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS
      )
    );

    # riter went to a private _aux struct
    $init->add(
      sprintf( "HvRITER_set(&sv_list[%d], %d);", $svsect->index, $hv->RITER ) );

# $init->add(sprintf("HvEITER_set(&sv_list[%d], 0x%x);", $svsect->index, $hv->EITER));
  }
  else {
    # 5.8: array fill max keys nv mg stash riter eiter pmroot name
    $xpvhvsect->add(
      sprintf(
        "0, 0, %d, 0, 0.0, 0, Nullhv, %d, 0, 0, 0",
        $hv->MAX, $hv->RITER
      )
    );
    $svsect->add(
      sprintf(
        "&xpvhv_list[%d], %lu, 0x%x",
        $xpvhvsect->index, $hv->REFCNT, $hv->FLAGS
      )
    );
  }
  my $sv_list_index = $svsect->index;
  my @contents      = $hv->ARRAY;
  if (@contents) {
    my $i;
    for ( $i = 1 ; $i < @contents ; $i += 2 ) {
      $contents[$i] = $contents[$i]->save;
    }
    $init->no_split;
    $init->add( "{", "\tHV *hv = (HV*)&sv_list[$sv_list_index];" );
    while (@contents) {
      my ( $key, $value ) = splice( @contents, 0, 2 );
      $init->add(
        sprintf(
          "\thv_store(hv, %s, %u, %s, %s);",
          cstring($key), length( pack "a*", $key ),
          $value, hash($key)
        )
      );
    }
    $init->add("}");
    $init->split;
  }
  $hv->save_magic();
  return savesym( $hv, "(HV*)&sv_list[$sv_list_index]" );
}

sub B::IO::save_data {
  my ( $io, $globname, @data ) = @_;
  my $data = join '', @data;

  # XXX using $DATA might clobber it!
  my $sym = svref_2object( \\$data )->save;
  $init->add( split /\n/, <<CODE );
    {
        GV* gv = (GV*)gv_fetchpv( "$globname", TRUE, SVt_PV );
        SV* sv = $sym;
        GvSVn( gv ) = sv;
    }
CODE

  # for PerlIO::scalar
  $use_xsloader = 1;
  $init->add_eval( sprintf 'open(%s, "<", $%s)', $globname, $globname );
}

# TODO in B. But apparently not needed
sub B::IO::SUBPROCESS {
  warn "B::IO::SUBPROCESS missing\n";
}

sub B::IO::save {
  my ($io) = @_;
  my $sym = objsym($io);
  return $sym if defined $sym;
  my $pv = $io->PV;
  $pv = '' unless defined $pv;
  my $len = length($pv);
  if ($PERL511) {
    warn sprintf( "IO 0x%x (%s) = '%s'\n", $$io, $io->SvTYPE, $pv ) if $debug{sv};
    $xpviosect->comment("xnv_u, cur, len, lines, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, ..., type, flags");
    $xpviosect->add(
      sprintf(
"0, /*xnv_u*/\n\t%u, /*cur*/\n\t%u, /*len*/\n\t%d, /*LINES*/\n\t0, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t0, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/",
        $len,                     $len + 1,
	$io->LINES, # moved to IVX
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          cstring( $io->TOP_NAME ),
        cstring( $io->FMT_NAME ), cstring( $io->BOTTOM_NAME ),
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
  }
  elsif ($PERL510) {
    warn sprintf( "IO 0x%x (%s) = '%s'\n", $$io, $io->SvTYPE, $pv ) if $debug{sv};
    $xpviosect->comment("xnv_u, cur, len, xiv_u, xmg_u, xmg_stash, xio_ifp, xio_ofp, xio_dirpu, ..., type, flags");
    $xpviosect->add(
      sprintf(
"0, /*xnv_u*/\n\t0, /*cur*/\n\t%u, /*len*/\n\t%d, /*IVX*/\n\t0, /*MAGIC later*/\n\t(HV*)NULL, /*STASH  later*/\n\t0, /*IFP later*/\n\t0, /*OFP later*/\n\t0, /*dirp_u later*/\n\t%d, /*LINES*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/",
        $len,                     $len + 1,
        $io->IVX,
	$io->LINES,
        $io->PAGE,                $io->PAGE_LEN,
        $io->LINES_LEFT,          cstring( $io->TOP_NAME ),
        cstring( $io->FMT_NAME ), cstring( $io->BOTTOM_NAME ),
        cchar( $io->IoTYPE ),     $io->IoFLAGS
      )
    );
  }
  else {
    $xpviosect->comment("xpv_pv, cur, len, iv, nv, magic, stash, xio_ifp, xio_ofp, xio_dirpu, ..., subprocess, type, flags");
    $xpviosect->add(
      sprintf(
"0, %u, %u, %d, %s, 0, 0, 0, 0, 0, %d, %d, %d, %d, %s, Nullgv, %s, Nullgv, %s, Nullgv, %d, %s, 0x%x",
        $len,                        $len + 1,
        $io->IVX,                    $io->NVX,
        $io->LINES,                  $io->PAGE,
        $io->PAGE_LEN,               $io->LINES_LEFT,
        cstring( $io->TOP_NAME ),    cstring( $io->FMT_NAME ),
        cstring( $io->BOTTOM_NAME ), $io->SUBPROCESS,
        cchar( $io->IoTYPE ),        $io->IoFLAGS
      )
    );
  }
  $svsect->add(
    sprintf(
      "&xpvio_list[%d], %lu, 0x%x",
      $xpviosect->index, $io->REFCNT, $io->FLAGS
    )
  );
  $sym = savesym( $io, sprintf( "(IO*)&sv_list[%d]", $svsect->index ) );

  if (!$PERL56) { # PerlIO
    # deal with $x = *STDIN/STDOUT/STDERR{IO}
    my $perlio_func;
    foreach (qw(stdin stdout stderr)) {
      $io->IsSTD($_) and $perlio_func = $_;
    }
    if ($perlio_func) {
      $init->add("IoIFP(${sym})=PerlIO_${perlio_func}();");
      $init->add("IoOFP(${sym})=PerlIO_${perlio_func}();");
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
  $io->save_magic; # TODO: does this handle the stash also?

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
    $xpvnvsect,  $xpvmgsect, $xpvlvsect, $xrvsect,   $xpvbmsect,
    $xpviosect
  );
  printf "\t/* %s */\n", $symsect->comment if $symsect->comment and $verbose;
  $symsect->output( \*STDOUT, "#define %s\n" );
  print "\n";
  output_declarations();
  foreach $section (@sections) {
    my $lines = $section->index + 1;
    if ($lines) {
      my $name = $section->name;
      my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);

      # if ($typename eq 'XPV' and $] >= 5.009) { $typename = "SV"; }
      print "Static $typename ${name}_list[$lines];\n";
    }
  }

  # XXX hack for when Perl accesses PVX of GVs
  print 'Static char emptystring[] = "\0";';
  print "\n";

  printf "\t/* %s */\n", $decl->comment if $decl->comment and $verbose;
  $decl->output( \*STDOUT, "%s\n" );
  print "\n";
  foreach $section (@sections) {
    my $lines = $section->index + 1;
    if ($lines) {
      my $name = $section->name;
      my $typename = ( $name eq "xpvcv" ) ? "XPVCV_or_similar" : uc($name);

      #if ($typename eq 'XPV' and $] >= 5.009) {$typename = "SV";}
      printf "static %s %s_list[%u] = {\n", $typename, $name, $lines;
      printf "\t/* %s */\n", $section->comment
        if $section->comment and $verbose;
      $section->output( \*STDOUT, "\t{ %s }, /* %d */\n" );
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
  if ($PERL511) {
    print "typedef struct p5rx RE;\n";
  }
  elsif ($PERL510) {
    print "typedef SV * RE;\n";
  }
  else {
    print "typedef char * RE;\n";
  }
  print "static GV *gv_list[$gv_index];\n" if $gv_index;
  print "\n";
}

sub output_boilerplate {
  print <<'EOT';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Workaround for mapstart: the only op which needs a different ppaddr */
#undef Perl_pp_mapstart
#define Perl_pp_mapstart Perl_pp_grepstart
#undef OP_MAPSTART
#define OP_MAPSTART OP_GREPSTART
#define XS_DynaLoader_boot_DynaLoader boot_DynaLoader
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

static void xs_init (pTHX);
static void dl_init (pTHX);
static PerlInterpreter *my_perl;
EOT
  if ($PERL56) {
    print "#define GvSVn(s) GvSV(s)\n";
  }
}

sub init_op_addr {
  my ( $op_type, $num ) = @_;
  my $op_list = $op_type . "_list";

  $init->add( split /\n/, <<EOT );
    {
        register int i;
        for( i = 0; i < ${num}; ++i ) {
            ${op_list}\[i].op_ppaddr = PL_ppaddr[INT2PTR(int,${op_list}\[i].op_ppaddr)];
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
        int i;

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

    PERL_SYS_INIT3(&argc,&argv,&env);

    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct( my_perl );
	PL_perl_destruct_level = 0;
    }
EOT
  if ($ITHREADS and $] > 5.006) {

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

  print <<'EOT';
#if defined(CSH) && (PERL_VERSION < 10)
    if (!PL_cshlen)
      PL_cshlen = strlen(PL_cshname);
#endif

#ifdef ALLOW_PERL_OPTIONS
#define EXTRA_OPTIONS 3
#else
#define EXTRA_OPTIONS 4
#endif /* ALLOW_PERL_OPTIONS */
    New(0,fakeargv, argc + EXTRA_OPTIONS + 1, char *);

    fakeargv[0] = argv[0];
    fakeargv[1] = "-e";
    fakeargv[2] = "";
    options_count = 3;
EOT

  # honour -T
  if (!$PERL56) {
   print <<EOT;
    if( ${^TAINT} ) {
        fakeargv[options_count] = "-T";
        ++options_count;
    }
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
    if ((tmpgv = gv_fetchpv("0",TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, ${dollar_0});
        SvSETMAGIC(tmpsv);
    }
EOT
  }
  else {
    print <<EOT;
    if ((tmpgv = gv_fetchpv("0",TRUE, SVt_PV))) {/* $0 */
        tmpsv = GvSVn(tmpgv);
        sv_setpv(tmpsv, argv[0]);
        SvSETMAGIC(tmpsv);
    }
EOT
  }

  print <<'EOT';
    if ((tmpgv = gv_fetchpv("\030",TRUE, SVt_PV))) {/* $^X */
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

    exitstatus = perl_init();
    if (exitstatus)
	exit( exitstatus );
    dl_init(aTHX);

    exitstatus = perl_run( my_perl );
EOT
  if ( $] >= 5.007003 ) {
    print "    perl_destruct( my_perl );";
  }
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

  #if ($^O eq 'cygwin') { #FIXME!
  #  print "\n#undef USE_DYNAMIC_LOADING /* temp. HACK! */";
  #}
  print "\n#ifdef USE_DYNAMIC_LOADING";
  print qq/\n\tnewXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);/;
  print "\n#endif\n";

  # delete $xsub{'DynaLoader'};
  delete $xsub{'UNIVERSAL'};
  print("/* bootstrapping code*/\n\tSAVETMPS;\n");
  print("\ttarg=sv_newmortal();\n");
  print "#ifdef USE_DYNAMIC_LOADING\n";
  foreach my $stashname ( keys %static_ext ) {
    my $stashxsub = $stashname;
    $stashxsub =~ s/::/__/g;
    #if ($stashxsub =~ m/\/(\w+)\.\w+$/ {$stashxsub = $1;}
    # cygwin has Win32CORE
    print "\tnewXS(\"${stashname}::bootstrap\", boot_$stashxsub, file);\n";
  }
  print "#endif\n";
  print "#ifdef USE_DYNAMIC_LOADING\n";
  print "\tPUSHMARK(sp);\n";
  print qq/\tXPUSHp("DynaLoader", strlen("DynaLoader"));\n/;
  print qq/\tPUTBACK;\n/;
  print "\tboot_DynaLoader(aTHX_ NULL);\n";
  print qq/\tSPAGAIN;\n/;
  print "#endif\n";

  foreach my $stashname ( keys %xsub ) {
    if ( $xsub{$stashname} !~ m/Dynamic/ and !$static_ext{$stashname} ) {
      my $stashxsub = $stashname;
      $stashxsub =~ s/::/__/g;
      print "\tPUSHMARK(sp);\n";
      print qq/\tXPUSHp("$stashname",strlen("$stashname"));\n/;
      print qq/\tPUTBACK;\n/;
      print "\tboot_$stashxsub(aTHX_ NULL);\n";
      print qq/\tSPAGAIN;\n/;
    }
  }
  print("\tFREETMPS;\n/* end bootstrapping code */\n");
  print "}\n";

  print <<'EOT';
static void
dl_init(pTHX)
{
    char *file = __FILE__;
    dTARG;
    dSP;
EOT
  print("/* Dynamicboot strapping code*/\n\tSAVETMPS;\n");
  print("\ttarg=sv_newmortal();\n");
  foreach my $stashname (@DynaLoader::dl_modules) {
    warn "Loaded $stashname\n" if $verbose;
    if ( exists( $xsub{$stashname} ) && $xsub{$stashname} =~ m/Dynamic/ ) {
      my $stashxsub = $stashname;
      $stashxsub =~ s/::/__/g;
      print "\tPUSHMARK(sp);\n";
      print qq/\tXPUSHp("$stashname",/, length($stashname), qq/);\n/;
      print qq/\tPUTBACK;\n/;
      print "#ifdef USE_DYNAMIC_LOADING\n";
      warn "bootstrapping $stashname added to xs_init\n" if $verbose;
      if ( $xsub{$stashname} eq 'Dynamic' ) {
        print qq/\tperl_call_method("bootstrap",G_DISCARD);\n/;
      }
      else {
        print qq/\tperl_call_pv("XSLoader::load",G_DISCARD);\n/;
      }
      print "#else\n";
      print "\tboot_$stashxsub(aTHX_ NULL);\n";
      print "#endif\n";
      print qq/\tSPAGAIN;\n/;
    }
  }
  print("\tFREETMPS;\n/* end Dynamic bootstrapping code */\n");
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
  	      $name =~ /^([^A-Za-z].*|INC|STDIN|STDOUT|STDERR|ARGV|SIG|ENV|BEGIN|main::)$/i );
  warn sprintf( "Used GV method 0x%x \"$fullname\"\n", $$gv ) if $debug{gv};
  return unless ( $$cv || $$av || $$sv || $$hv );
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

sub should_save {
  no strict qw(vars refs);
  my $package = shift;
  $package =~ s/::$//;
  return $unused_sub_packages{$package} = 0
    if ( $package =~ /::::/ );    # skip ::::ISA::CACHE etc.
  warn "Considering $package\n" if $debug{pkg};
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
    || $package =~ /^(B|IO)::/ )
  {
    delete_unsaved_hashINC($package);
    return $unused_sub_packages{$package} = 0;
  }

# Now see if current package looks like an OO class this is probably too strong.
  foreach my $m (qw(new DESTROY TIESCALAR TIEARRAY TIEHASH TIEHANDLE)) {
    if ( UNIVERSAL::can( $package, $m ) ) {
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
    *glob = $ref;
    warn("Walkpackages $sym") if $debug{p};
    if ( $sym =~ /::$/ ) {
      $sym = $prefix . $sym;
      # XXX The walker was missing main subs to avoid recursion into O compiler subs again
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
  if ($verbose) {
    warn "Prescan for unused subs" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  &descend_marked_unused;
  walkpackages( \%{"main::"}, sub { should_save( $_[0] ); return 1 } );
  if ($verbose) {
    warn "Saving unused subs" . ($sav_debug{unused} ? " (silent)\n" : "\n");
  }
  walksymtable( \%{"main::"}, "savecv", \&should_save );
  if ( $debug{unused} ) {
    %debug = %sav_debug;
  }
}

sub save_context {
  my $curpad_nam      = ( comppadlist->ARRAY )[0]->save;
  my $curpad_sym      = ( comppadlist->ARRAY )[1]->save;
  my $inc_hv          = svref_2object( \%INC )->save;
  my $inc_av          = svref_2object( \@INC )->save;
  my $amagic_generate = amagic_generation;
  $init->add(
    "/* save context */",
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

sub save_main_rest {
  # this is mainly for the test suite
  my $warner = $SIG{__WARN__};
  local $SIG{__WARN__} = sub { print STDERR @_ };

  warn "done main optree, walking symtable for extras\n"
    if $verbose
      or $debug{cv};
  save_unused_subs();

  save_main_rest2();
}

sub save_main_rest2 {
  # this is mainly for the test suite
  my $warner = $SIG{__WARN__};
  local $SIG{__WARN__} = sub { print STDERR @_ };
  # XSLoader was used, force saving of XSLoader::load
  if ($use_xsloader) {
    my $cv = svref_2object( \&XSLoader::load );
    $cv->save;
  }

  # save %SIG ( in case it was set in a BEGIN block )
  if ($save_sig) {
    local $SIG{__WARN__} = $warner;
    $init->no_split;
    $init->add( "{", "\tHV* hv = get_hv(\"main::SIG\",1);" );
    foreach my $k ( keys %SIG ) {
      next unless ref $SIG{$k};
      my $cv = svref_2object( \$SIG{$k} );
      my $sv = $cv->save;
      $init->add( '{', sprintf 'SV* sv = (SV*)%s;', $sv );
      $init->add(
        sprintf(
          "\thv_store(hv, %s, %u, %s, %s);",
          cstring($k), length( pack "a*", $k ),
          'sv', hash($k)
        )
      );
      $init->add( 'mg_set(sv);', '}' );
    }
    $init->add('}');
    $init->split;
  }

  # honour -w
  $init->add( "/* honor -w */",
    sprintf "PL_dowarn = ( %s ) ? G_WARN_ON : G_WARN_OFF;", $^W );

  # startpoints
  my $init_av = init_av->save;
  my $end_av  = end_av->save;
  $init->add(
    "/* startpoints */",
    sprintf( "PL_main_root = s\\_%x;",  ${ main_root() } ),
    sprintf( "PL_main_start = s\\_%x;", ${ main_start() } ),
    "PL_initav = (AV *) $init_av;",
    "PL_endav = (AV*) $end_av;\n"
  );
  save_context();

  # init op addrs must be the last action, otherwise
  # some ops might not be initialized
  if ($optimize_ppaddr) {
    foreach my $i (@op_sections) {
      my $section = $$i;
      next unless $section->index >= 0;
      init_op_addr( $section->name, $section->index + 1 );
    }
  }
  init_op_warn( $copsect->name, $copsect->index + 1 )
    if $optimize_warn_sv && $copsect->index >= 0;

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
  my %option_map = (
    'cog'             => \$pv_copy_on_grow,
    'save-data'       => \$save_data_fh,
    'ppaddr'          => \$optimize_ppaddr,
    'warn-sv'         => \$optimize_warn_sv,
    'use-script-name' => \$use_perl_script_name,
    'save-sig-hash'   => \$save_sig,
  );
  my %optimization_map = (
    0 => [qw()],                     # special case
    1 => [qw(-fcog)],
    2 => [qw(-fwarn-sv -fppaddr)],
    3 => [qw(-fsave-sig-hash -fsave-data)],
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
      foreach $arg ( split( //, $arg ) ) {
        if ( $arg eq "o" ) {
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
    }
    elsif ( $opt eq "e" ) {
      push @eval_at_startup, $arg;
    }
    elsif ( $opt eq "l" ) {
      $max_string_len = $arg;
    }
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

=item B<-Do>

All Walkop'ed OPs

=item B<-DO>

OP Type,Flags,Private

=item B<-DS>

prints SV/RE information on saving

=item B<-Dc>

COPs, prints COPs as processed (incl. file & line num)

=item B<-DA>

prints AV information on saving

=item B<-DC>

prints CV information on saving

=item B<-DG>

prints GV information on saving

=item B<-DM>

prints MAGIC information on saving

=item B<-Dp>

prints cached package information, if used or not.

=item B<-Du>

do not print -D information when parsing for the unused subs.

=item B<-f>I<OPTIM>

Force options/optimisations on or off one at a time. You can explicitly
disable an option using B<-fno-option>. All options default to
B<disabled>.

=over 4

=item B<-fcog>

Copy-on-grow: PVs declared and initialised statically.

=item B<-fsave-data>

Save package::DATA filehandles ( only available with PerlIO ).

=item B<-fppaddr>

Optimize the initialization of op_ppaddr.

=item B<-fwarn-sv>

Optimize the initialization of cop_warnings.

=item B<-fuse-script-name>

Use the script name instead of the program name as $0.

=item B<-fsave-sig-hash>

Save compile-time modifications to the %SIG hash.

=back

=item B<-On>

Optimisation level (n = 0, 1, 2, ...). B<-O> means B<-O1>.

=over 4

=item B<-O0>

Disable all optimizations.

=item B<-O1>

Enable B<-fcog>.

=item B<-O2>

Enable B<-fppaddr>, B<-fwarn-sv>.

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

3-4. Current status: experimental.

5.6:
    reading from __DATA__ handles (15)
    calling nested subs (24)
    XSUB load order via B::Stash (?)

5.8:
    +
    open our (14)
    $VERSION magic (23)

5.10:
    +
    sort by key (18)
    qr// in main (20)
    loop in sub (21)

5.11:
    4-5, 14-16, 21, 23

=head1 AUTHOR

Malcolm Beattie, C<mbeattie@sable.ox.ac.uk>,
Reini Urban, C<rurban@cpan.org>

=cut
