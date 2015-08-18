package B::OP;

use B qw/peekop/;
use B::C ();
use B::C::File qw/objsym savesym svsect save_rv init copsect opsect/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;
    my $type = $op->type;
    $B::C::nullop_count++ unless $type;
    if ( $type == $B::C::OP_THREADSV ) {

        # saves looking up ppaddr but it's a bit naughty to hard code this
        init()->add( sprintf( "(void)find_threadsv(%s);", cstring( $threadsv_names[ $op->targ ] ) ) );
    }
    if ( $type == $B::C::OP_UCFIRST ) {
        $B::C::fold = 1;

        warn "enabling -ffold with ucfirst\n" if B::C::verbose();
        require "utf8.pm" unless $B::C::savINC{"utf8.pm"};
        require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
        mark_package("utf8");
        mark_package("utf8_heavy.pl");

    }
    if ( ref($op) eq 'B::OP' ) {    # check wrong BASEOPs
                                    # [perl #80622] Introducing the entrytry hack, needed since 5.12, fixed with 5.13.8 a425677
                                    #   ck_eval upgrades the UNOP entertry to a LOGOP, but B gets us just a B::OP (BASEOP).
                                    #   op->other points to the leavetry op, which is needed for the eval scope.
        if ( $op->name eq 'entertry' ) {
            warn "[perl #80622] Upgrading entertry from BASEOP to LOGOP...\n" if B::C::verbose();
            bless $op, 'B::LOGOP';
            return $op->save($level);
        }
    }

    # since 5.10 nullified cops free their additional fields
    if ( !$type and $OP_COP{ $op->targ } ) {
        warn sprintf( "Null COP: %d\n", $op->targ ) if $B::C::debug{cops};

        copsect()->comment_common("line, stash, file, hints, seq, warnings, hints_hash");
        copsect()->add(
            sprintf(
                "%s, 0, %s, NULL, 0, 0, NULL, NULL",
                $op->_save_common, B::C::USE_ITHREADS ? "(char *)NULL" : "Nullhv"
            )
        );

        my $ix = copsect()->index;
        init()->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
          unless $B::C::optimize_ppaddr;
        savesym( $op, "(OP*)&cop_list[$ix]" );
    }
    else {
        opsect()->comment_common();
        opsect()->add( $op->_save_common );

        opsect()->debug( $op->name, $op );
        my $ix = opsect()->index;
        init()->add( sprintf( "op_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
          unless $B::C::optimize_ppaddr;
        warn(
            sprintf(
                "  OP=%s targ=%d flags=0x%x private=0x%x\n",
                peekop($op), $op->targ, $op->flags, $op->private
            )
        ) if $B::C::debug{op};
        savesym( $op, "&op_list[$ix]" );
    }
}

# See also init_op_ppaddr below; initializes the ppaddr to the
# OpTYPE; init_op_ppaddr iterates over the ops and sets
# op_ppaddr to PL_ppaddr[op_ppaddr]; this avoids an explicit assignment
# in perl_init ( ~10 bytes/op with GCC/i386 )
sub fake_ppaddr {
    return "NULL" unless $_[0]->can('name');
    return $B::C::optimize_ppaddr
      ? sprintf( "INT2PTR(void*,OP_%s)", uc( $_[0]->name ) )
      : ( $verbose ? sprintf( "/*OP_%s*/NULL", uc( $_[0]->name ) ) : "NULL" );
}

sub _save_common {
    my $op = shift;

    # compile-time method_named packages are always const PV sM/BARE, they should be optimized.
    # run-time packages are in gvsv/padsv. This is difficult to optimize.
    #   my Foo $obj = shift; $obj->bar(); # TODO typed $obj
    # entersub -> pushmark -> package -> args...
    # See perl -MO=Terse -e '$foo->bar("var")'
    # See also http://www.perl.com/pub/2000/06/dougpatch.html
    # XXX TODO 5.8 ex-gvsv
    # XXX TODO Check for method_named as last argument
    if (
            $op->type > 0
        and $op->name eq 'entersub'
        and $op->first
        and $op->first->can('name')
        and $op->first->name eq 'pushmark'
        and

        # Foo->bar()  compile-time lookup, 34 = BARE in all versions
        (
            ( $op->first->next->name eq 'const' and $op->first->next->flags == 34 )
            or $op->first->next->name eq 'padsv'    # or $foo->bar() run-time lookup
        )
      ) {
        my $pkgop = $op->first->next;
        if ( !$op->first->next->type ) {            # 5.8 ex-gvsv
            $pkgop = $op->first->next->next;
        }
        warn "check package_pv " . $pkgop->name . " for method_name\n" if $debug{cv};
        my $pv = B::C::svop_or_padop_pv($pkgop);    # 5.13: need to store away the pkg pv
        if ( $pv and $pv !~ /[! \(]/ ) {
            $package_pv = $pv;
            B::C::push_package($package_pv);
        }
        else {
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

use constant STATIC => '0, 1, 0, 0, 0';

sub _save_common_middle {
    my $op = shift;
    my $madprop = $B::C::MAD ? "0," : "";

    # XXX maybe add a ix=opindex string for debugging if $debug{flags}
    sprintf(
        "%s,%s %u, %u, " . STATIC . ", 0x%x, 0x%x",
        $op->fake_ppaddr, $madprop, $op->targ, $op->type, $op->flags, $op->private
    );
}

# XXX HACK! duct-taping around compiler problems
sub isa { UNIVERSAL::isa(@_) }    # walkoptree_slow misses that
sub can { UNIVERSAL::can(@_) }

1;
