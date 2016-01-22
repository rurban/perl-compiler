package B::PMOP;

use strict;

use B qw/cstring svref_2object RXf_EVAL_SEEN PMf_EVAL/;
use B::C::Setup;
use B::C::File qw/pmopsect init init1/;
use B::C::Helpers qw/read_utf8_string strlen_flags/;
use B::C::Helpers::Symtable qw/objsym savesym/;

# Global to this space?
my ($swash_init);

# FIXME really required ?
sub PMf_ONCE() { 0x10000 };    # PMf_ONCE also not exported

sub save {
    my ( $op, $level, $fullname ) = @_;
    my ( $replrootfield, $replstartfield, $gvsym ) = ( 'NULL', 'NULL' );
    my $sym = objsym($op);
    return $sym if defined $sym;

    $level    ||= 0;
    $fullname ||= '????';

    # 5.8.5-thr crashes here (7) at pushre
    if ( USE_ITHREADS() and $$op < 256 ) {    # B bug. split->first->pmreplroot = 0x1
        die "Internal B::walkoptree error: invalid PMOP for pushre\n";
        return;
    }
    my $replroot  = $op->pmreplroot;
    my $replstart = $op->pmreplstart;
    my $ppaddr    = $op->ppaddr;

    # under ithreads, OP_PUSHRE.op_replroot is an integer. multi not.
    $replrootfield = sprintf( "s\\_%x", $$replroot ) if ref $replroot;
    if ( USE_ITHREADS() && $op->name eq "pushre" ) {
        debug( gv => "PMOP::save saving a pp_pushre as int ${replroot}" );
        $replrootfield = "INT2PTR(OP*,${replroot})";
    }
    elsif ($$replroot) {

        # OP_PUSHRE (a mutated version of OP_MATCH for the regexp
        # argument to a split) stores a GV in op_pmreplroot instead
        # of a substitution syntax tree. We don't want to walk that...
        if ( $op->name eq "pushre" ) {
            debug( gv => "PMOP::save saving a pp_pushre with GV $gvsym" );
            $gvsym          = $replroot->save;
            $replrootfield  = "NULL";
            $replstartfield = $replstart->save if $replstart;
        }
        else {
            $replstart->save if $replstart;
            $replstartfield = B::C::saveoptree( "*ignore*", $replroot, $replstart );
            $replstartfield =~ s/^hv/(OP*)hv/;
        }
    }

    # pmnext handling is broken in perl itself, we think. Bad op_pmnext
    # fields aren't noticed in perl's runtime (unless you try reset) but we
    # segfault when trying to dereference it to find op->op_pmnext->op_type

    pmopsect()->comment_common("first, last, pmoffset, pmflags, pmreplroot, pmreplstart");
    pmopsect()->add(
        sprintf(
            "%s, s\\_%x, s\\_%x, %u, 0x%x, {%s}, {%s}",
            $op->_save_common, ${ $op->first },
            ${ $op->last }, ( USE_ITHREADS() ? $op->pmoffset : 0 ),
            $op->pmflags, $replrootfield, $replstartfield
        )
    );

    my $code_list = $op->code_list;
    if ( $code_list and $$code_list ) {
        debug( gv => "saving pmop_list[%d] code_list $code_list (?{})", pmopsect()->index );
        my $code_op = $code_list->save;
        if ($code_op) {

            # (?{}) code blocks
            init()->add( sprintf( 'pmop_list[%d].op_code_list = %s;', pmopsect()->index, $code_op ) );
        }
        debug( gv => "done saving pmop_list[%d] code_list $code_list (?{})", pmopsect()->index );
    }

    pmopsect()->debug( $op->name, $op );
    my $pm = sprintf( "pmop_list[%d]", pmopsect()->index );
    init()->add( sprintf( "%s.op_ppaddr = %s;", $pm, $ppaddr ) )
      unless $B::C::optimize_ppaddr;
    my $re = $op->precomp;

    if ( defined($re) ) {
        $B::C::Regexp{$$op} = $op;

        # TODO minor optim: fix savere( $re ) to avoid newSVpvn;
        my ( $qre, $relen, $utf8 ) = strlen_flags($re);

        my $pmflags = $op->pmflags;
        debug( gv => "pregcomp $pm $qre:$relen" . ( $utf8 ? " SVf_UTF8" : "" ) . sprintf( " 0x%x\n", $pmflags ) );

        # Since 5.13.10 with PMf_FOLD (i) we need to swash_init("utf8::Cased").
        if ( $pmflags & 4 ) {

            # Note: in CORE utf8::SWASHNEW is demand-loaded from utf8 with Perl_load_module()
            require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
            svref_2object( \&{"utf8\::SWASHNEW"} )->save;                     # for swash_init(), defined in lib/utf8_heavy.pl

            my $swash_ToCf = B::HV::swash_ToCf_value();
            if ( !$swash_init and $swash_ToCf ) {
                init()->add("PL_utf8_tofold = $swash_ToCf;");
                $swash_init++;
            }
        }

        # some pm need early init (242), SWASHNEW needs some late GVs (GH#273)
        # esp with 5.22 multideref init. i.e. all \p{} \N{}, \U, /i, ...
        # But XSLoader and utf8::SWASHNEW itself needs to be early.
        my $initpm = init();

        # needs SWASHNEW (case fold)
        # also SWASHNEW, now needing a multideref GV. 0x5000000 is just a hack. can be more
        if ( ( $utf8 and $pmflags & 4 ) or ( $pmflags & 0x5000000 == 0x5000000 ) ) {
            $initpm = init1();
            debug( sv => sprintf( "deferred PMOP %s %s 0x%x\n", $qre, $fullname, $pmflags ) );
        }
        else {
            debug( sv => sprintf( "normal PMOP %s %s 0x%x\n", $qre, $fullname, $pmflags ) );
        }

        my $eval_seen = $op->reflags & RXf_EVAL_SEEN;
        my @init_block;
        if ($eval_seen) {    # set HINT_RE_EVAL on
            $pmflags |= PMf_EVAL;
            push @init_block, '{', '    U32 hints_sav = PL_hints;', '    PL_hints |= HINT_RE_EVAL;';
        }

        # XXX Modification of a read-only value attempted. use DateTime - threaded
        push @init_block, "PM_SETRE(&$pm, CALLREGCOMP(newSVpvn_flags($qre, $relen, " . sprintf( "SVs_TEMP|%s), 0x%x));", $utf8 ? 'SVf_UTF8' : '0', $pmflags ) . sprintf( "RX_EXTFLAGS(PM_GETRE(&%s)) = 0x%x;", $pm, $op->reflags );

        if ($eval_seen) {    # set HINT_RE_EVAL off
            push @init_block, '    PL_hints = hints_sav;', '}';
        }
        $initpm->no_split();
        $initpm->add(@init_block);
        $initpm->split();

        # See toke.c:8964
        # set in the stash the PERL_MAGIC_symtab PTR to the PMOP: ((PMOP**)mg->mg_ptr) [elements++] = pm;
        if ( $op->pmflags & PMf_ONCE() ) {
            my $stash =
                USE_MULTIPLICITY()          ? $op->pmstashpv
              : ref $op->pmstash eq 'B::HV' ? $op->pmstash->NAME
              :                               '__ANON__';
            $B::C::Regexp{$$op} = $op;    #188: restore PMf_ONCE, set PERL_MAGIC_symtab in $stash
        }
    }

    if ($gvsym) {

        # XXX need that for subst
        init()->add("$pm.op_pmreplrootu.op_pmreplroot = (OP*)$gvsym;");
    }

    return savesym( $op, "(OP*)&$pm" );
}

1;
