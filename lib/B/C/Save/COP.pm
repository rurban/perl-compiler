package B::COP;

use B qw/cstring/;
use B::C qw();
use B::C::File qw/objsym savesym init copsect/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;

    # we need to keep CvSTART cops, so check $level == 0
    if ( $B::C::optimize_cop and $level and !$op->label ) {    # XXX very unsafe!
        my $sym = savesym( $op, $op->next->save );
        warn sprintf(
            "Skip COP (0x%x) => %s (0x%x), line %d file %s\n",
            $$op, $sym, $op->next, $op->line, $op->file
        ) if $debug{cops};
        return $sym;
    }

    # TODO: if it is a nullified COP we must save it with all cop fields!
    warn sprintf( "COP: line %d file %s\n", $op->line, $op->file )
      if $debug{cops};

    # shameless cut'n'paste from B::Deparse
    my $warn_sv;
    my $warnings   = $op->warnings;
    my $is_special = ref($warnings) eq 'B::SPECIAL';
    my $warnsvcast = "(STRLEN*)";
    if ( $is_special && $$warnings == 4 ) {    # use warnings 'all';
        $warn_sv = 'pWARN_ALL';
    }
    elsif ( $is_special && $$warnings == 5 ) {    # no warnings 'all';
        $warn_sv = 'pWARN_NONE';
    }
    elsif ($is_special) {                         # use warnings;
        $warn_sv = 'pWARN_STD';
    }
    else {
        # LEXWARN_on: Original $warnings->save from 5.8.9 was wrong,
        # DUP_WARNINGS copied length PVX bytes.
        my $warn = bless $warnings, "B::LEXWARN";
        $warn_sv = $warn->save;
        my $ix = copsect()->index + 1;

        # XXX No idea how a &sv_list[] came up here, a re-used object. Anyway.
        $warn_sv = substr( $warn_sv, 1 ) if substr( $warn_sv, 0, 3 ) eq '&sv';
        $warn_sv = $warnsvcast . '&' . $warn_sv;
        free()->add( sprintf( "    cop_list[%d].cop_warnings = NULL;", $ix ) )
          if !$B::C::optimize_warn_sv;

        #push @B::C::static_free, sprintf("cop_list[%d]", $ix);
    }

    my $dynamic_copwarn = !$is_special ? 1 : !$B::C::optimize_warn_sv;

    # Trim the .pl extension, to print the executable name only.
    my $file = $op->file;

    # $file =~ s/\.pl$/.c/;

    # cop_label now in hints_hash (Change #33656)
    copsect()->comment_common("line, stash, file, hints, seq, warn_sv, hints_hash");
    copsect()->add(
        sprintf(
            "%s, %u, " . "%s, %s, %u, " . "%s, %s, NULL",
            $op->_save_common, $op->line,

            # we cannot store this static (attribute exit)
            B::C::USE_ITHREADS() ? ( "NULL", "NULL" ) : ( "Nullhv", "Nullgv" ),
            $op->hints, B::C::ivx( $op->cop_seq ), !$dynamic_copwarn ? $warn_sv : 'NULL'
        )
    );

    if ( $op->label ) {

        # test 29 and 15,16,21. 44,45
        init()->add(
            sprintf(
                "Perl_store_cop_label(aTHX_ &cop_list[%d], %s, %d, %d);",
                copsect()->index,  cstring( $op->label ),
                length $op->label, 0
            )
        );
    }

    copsect()->debug( $op->name, $op );
    my $ix = copsect()->index;
    init()->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    if ( !$is_special ) {
        my $copw = $warn_sv;
        $copw =~ s/^\(STRLEN\*\)&//;

        # on cv_undef (scope exit, die, ...) CvROOT and all its kids are freed.
        # lexical cop_warnings need to be dynamic, but just the ptr to the static string.
        if ($copw) {
            my $cop = "cop_list[$ix]";
            init()->add( "$cop.cop_warnings = (STRLEN*)savepvn((char*)&" . $copw . ", sizeof($copw));" );
        }
    }
    else {
        init()->add( sprintf( "cop_list[$ix].cop_warnings = %s;", $warn_sv ) )
          unless $B::C::optimize_warn_sv;
    }

    if ( !$B::C::optimize_cop ) {
        if ( !B::C::USE_ITHREADS() ) {
            if ($B::C::const_strings) {
                init()->add( sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", B::C::constpv( $op->stashpv ) ) );
                init()->add( sprintf( "CopFILE_set(&cop_list[$ix], %s);",    B::C::constpv($file) ) );
            }
            else {
                init()->add( sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", cstring( $op->stashpv ) ) );
                init()->add( sprintf( "CopFILE_set(&cop_list[$ix], %s);",    cstring($file) ) );
            }
        }
        else {    # cv_undef e.g. in bproto.t and many more core tests with threads
            my $stlen = "";
            init()->add( sprintf( "CopSTASHPV_set(&cop_list[$ix], %s);", cstring( $op->stashpv ) . $stlen ) );
            init()->add( sprintf( "CopFILE_set(&cop_list[$ix], %s);",    cstring($file) ) );
        }
    }

    # our root: store all packages from this file
    if ( !$mainfile ) {
        $mainfile = $op->file if $op->stashpv eq 'main';
    }
    else {
        B::C::mark_package( $op->stashpv ) if $mainfile eq $op->file and $op->stashpv ne 'main';
    }
    savesym( $op, "(OP*)&cop_list[$ix]" );
}

1;
