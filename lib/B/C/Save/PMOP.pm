package B::PMOP;

use strict;

use B qw/cstring svref_2object/;
use B::C ();
use B::C::File qw/pmopsect init/;
use B::C::Helpers qw/objsym savesym/;

# FIXME really required ?
BEGIN {
    eval q[sub PMf_ONCE(){ 0x8000 }];
}

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;

    # 5.8.5-thr crashes here (7) at pushre
    if ( B::C::USE_ITHREADS() and $$op < 256 ) {    # B bug. split->first->pmreplroot = 0x1
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
    if ( B::C::USE_ITHREADS() && $op->name eq "pushre" ) {
        warn "PMOP::save saving a pp_pushre as int ${replroot}\n" if $B::C::debug{gv};
        $replrootfield = "INT2PTR(OP*,${replroot})";
    }
    elsif ($$replroot) {

        # OP_PUSHRE (a mutated version of OP_MATCH for the regexp
        # argument to a split) stores a GV in op_pmreplroot instead
        # of a substitution syntax tree. We don't want to walk that...
        if ( $op->name eq "pushre" ) {
            warn "PMOP::save saving a pp_pushre with GV $gvsym\n" if $B::C::debug{gv};
            $gvsym         = $replroot->save;
            $replrootfield = 0;
        }
        else {
            $replstartfield = B::C::saveoptree( "*ignore*", $replroot, $replstart );
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
            ${ $op->last }, ( B::C::USE_ITHREADS() ? $op->pmoffset : 0 ),
            $op->pmflags, $replrootfield, 'NULL'
        )
    );
    init()->add(
        sprintf(
            "pmop_list[%d].op_pmstashstartu.op_pmreplstart = (OP*)$replstartfield;",
            pmopsect()->index
        )
    );

    pmopsect()->debug( $op->name, $op );
    my $pm = sprintf( "pmop_list[%d]", pmopsect()->index );
    init()->add( sprintf( "$pm.op_ppaddr = %s;", $ppaddr ) )
      unless $B::C::optimize_ppaddr;
    my $re = $op->precomp;

    if ( defined($re) ) {
        $B::C::Regexp{$$op} = $op;

        # TODO minor optim: fix savere( $re ) to avoid newSVpvn;
        my $qre = cstring($re);
        my $relen = length( pack "a*", $re );

        # FIXME: this looks like a good helper...
        #	we can also cache the status...
        # precomp does not set the utf8 flag (#333, #338)
        my $isutf8 = 0;    # ($] > 5.008 and utf8::is_utf8($re)) ? SVf_UTF8 : 0;
        for my $c ( split //, $re ) {
            if ( ord($c) > 127 ) { $isutf8 = 1; next }
        }

        if ($isutf8) {
            if ( utf8::is_utf8($re) ) {
                my $pv = $re;
                utf8::encode($pv);
                $relen = length $pv;
            }
        }
        my $pmflags = $op->pmflags;
        warn "pregcomp $pm $qre:$relen" . ( $isutf8 ? " SVf_UTF8" : "" ) . sprintf( " 0x%x\n", $pmflags )
          if $B::C::debug{pv} or $B::C::debug{gv};

        # Since 5.13.10 with PMf_FOLD (i) we need to swash_init("utf8::Cased").
        if ( $pmflags & 4 ) {

            # Note: in CORE utf8::SWASHNEW is demand-loaded from utf8 with Perl_load_module()
            require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
            svref_2object( \&{"utf8\::SWASHNEW"} )->save;                     # for swash_init(), defined in lib/utf8_heavy.pl
        }

        init()->add(                                                          # XXX Modification of a read-only value attempted. use DateTime - threaded
            "PM_SETRE(&$pm,",
            "  CALLREGCOMP(newSVpvn_flags($qre, $relen, "
              . sprintf( "SVs_TEMP|%s), 0x%x));", $isutf8 ? 'SVf_UTF8' : '0', $pmflags ),
            sprintf( "RX_EXTFLAGS(PM_GETRE(&$pm)) = 0x%x;", $op->reflags )
        );

        # See toke.c:8964
        # set in the stash the PERL_MAGIC_symtab PTR to the PMOP: ((PMOP**)mg->mg_ptr) [elements++] = pm;
        if ( $op->pmflags & PMf_ONCE() ) {
            my $stash =
                $B::C::MULTI                ? $op->pmstashpv
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
