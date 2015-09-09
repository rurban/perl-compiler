package B::OP;

use strict;

use B qw/peekop cstring threadsv_names opnumber/;

use B::C::Config;
use B::C::Debug::Walker qw/walkoptree_debug/;
use B::C::File qw/svsect init copsect opsect/;
use B::C::Helpers qw/do_labels mark_package/;
use B::C::Helpers::Symtable qw/savesym objsym/;

my @threadsv_names;

BEGIN {
    @threadsv_names = threadsv_names();
}

# special handling for nullified COP's.
my %OP_COP = ( opnumber('nextstate') => 1 );
debug( cops => %OP_COP );

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

        verbose("enabling -ffold with ucfirst");
        require "utf8.pm" unless $B::C::savINC{"utf8.pm"};
        require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
        B::C::mark_package("utf8");
        B::C::mark_package("utf8_heavy.pl");

    }
    if ( ref($op) eq 'B::OP' ) {    # check wrong BASEOPs
                                    # [perl #80622] Introducing the entrytry hack, needed since 5.12, fixed with 5.13.8 a425677
                                    #   ck_eval upgrades the UNOP entertry to a LOGOP, but B gets us just a B::OP (BASEOP).
                                    #   op->other points to the leavetry op, which is needed for the eval scope.
        if ( $op->name eq 'entertry' ) {
            verbose("[perl #80622] Upgrading entertry from BASEOP to LOGOP...");
            bless $op, 'B::LOGOP';
            return $op->save($level);
        }
    }

    # since 5.10 nullified cops free their additional fields
    if ( !$type and $OP_COP{ $op->targ } ) {
        debug( cops => "Null COP: %d\n", $op->targ );

        if (USE_ITHREADS()) {
            copsect()->comment_common("line, stashoff, file, hints, seq, warnings, hints_hash");
            copsect()->add(
                sprintf(
                    "%s, 0, 0, (char *)NULL, 0, 0, NULL, NULL",
                    $op->_save_common
                )
            );
        }
        else {
            copsect()->comment_common("line, stash, file, hints, seq, warnings, hints_hash");
            copsect()->add(
                sprintf(
                    "%s, 0, %s, NULL, 0, 0, NULL, NULL",
                    $op->_save_common, "Nullhv"
                )
            );
        }

        my $ix = copsect()->index;
        init()->add( sprintf( "cop_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
          unless $B::C::optimize_ppaddr;
        savesym( $op, "(OP*)&cop_list[$ix]" );
    }
    else {
        opsect()->comment( B::C::opsect_common() );
        opsect()->add( $op->_save_common );

        opsect()->debug( $op->name, $op );
        my $ix = opsect()->index;
        init()->add( sprintf( "op_list[$ix].op_ppaddr = %s;", $op->ppaddr ) )
          unless $B::C::optimize_ppaddr;
        debug(
            op => "  OP=%s targ=%d flags=0x%x private=0x%x\n",
            peekop($op), $op->targ, $op->flags, $op->private
        );
        savesym( $op, "&op_list[$ix]" );
    }
}

my %fake_cache;

# See also init_op_ppaddr below; initializes the ppaddr to the
# OpTYPE; init_op_ppaddr iterates over the ops and sets
# op_ppaddr to PL_ppaddr[op_ppaddr]; this avoids an explicit assignment
# in perl_init ( ~10 bytes/op with GCC/i386 )
sub fake_ppaddr {
    my $type = ref $_[0] || '';
    if ( !exists $fake_cache{$type} ) {
        $fake_cache{$type} = $_[0]->can('name');
    }
    return "NULL" unless $fake_cache{$type};
    my $name = uc( $_[0]->name );
    return $B::C::optimize_ppaddr
      ? "INT2PTR(void*,OP_$name)"
      : ( verbose() ? "/*OP_$name*/NULL" : "NULL" );
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
        and

        # Foo->bar()  compile-time lookup, 34 = BARE in all versions
        (
            ( $op->first->next->name eq 'const' and $op->first->next->flags == 34 )
            or $op->first->next->name eq 'padsv'    # or $foo->bar() run-time lookup
        )
        and $op->first->name eq 'pushmark'
        and $op->first->can('name')

      ) {
        my $pkgop = $op->first->next;
        if ( !$op->first->next->type ) {            # 5.8 ex-gvsv
            $pkgop = $op->first->next->next;
        }
        debug( cv => "check package_pv " . $pkgop->name . " for method_name" );
        my $pv = B::C::svop_or_padop_pv($pkgop);    # 5.13: need to store away the pkg pv
        if ( $pv and $pv !~ /[! \(]/ ) {
            $B::C::package_pv = $pv;
            B::C::push_package($B::C::package_pv);
        }
        else {
            # mostly optimized-away padsv NULL pads with 5.8
            WARN("package_pv for method_name not found") if debug('cv') or debug('pkg');
        }
    }

    return sprintf(
        "s\\_%x, s\\_%x, %s",
        ${ $op->next },
        ${ $op->sibling },
        $op->_save_common_middle
    );
}

use constant STATIC => '0, 0, 0, 1, 0, 0';
my $PATTERN = "%s," . ( MAD() ? "0," : "" ) . " %u, %u, " . STATIC . ", 0x%x, 0x%x";

sub _save_common_middle {
    my $op = shift;

    # XXX maybe add a ix=opindex string for debugging if debug('flags')
    return sprintf(
        $PATTERN,
        $op->fake_ppaddr, $op->targ, $op->type, $op->flags, $op->private
    );
}

# XXX HACK! duct-taping around compiler problems
sub isa { UNIVERSAL::isa(@_) }    # walkoptree_slow misses that
sub can { UNIVERSAL::can(@_) }

1;
