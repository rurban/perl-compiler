package B::C::Optimizer::UnusedPackages;

use strict;
use Exporter ();

use B qw/svref_2object/;
use B::C::Config;    # import everything
use B::C::Packages qw/mark_package_unused mark_package_used mark_package_deleted is_package_used get_all_packages_used include_package_list is_package_used/;

# imports from B::C
# todo: check & move these to a better place
*can_delete             = \&B::C::can_delete;
*skip_pkg               = \&B::C::skip_pkg;
*mark_package           = \&B::C::mark_package;
*walkpackages           = \&B::C::walkpackages;
*inc_packname           = \&B::C::inc_packname;
*delete_unsaved_hashINC = \&B::C::delete_unsaved_hashINC;
*walksymtable           = \&B::C::walksymtable;
*dump_rest              = \&B::C::dump_rest;
*add_hashINC            = \&B::C::add_hashINC;
*packname_inc           = \&B::C::packname_inc;
*force_saving_xsloader  = \&B::C::force_saving_xsloader;

# B::C::Packages Aliases

sub descend_marked_unused {

    foreach my $pack ( sort keys %INC ) {
        my $p = packname_inc($pack);
        mark_package($p) if !skip_pkg($p) and !$B::C::all_bc_deps{$p};
    }

    if ( verbose() ) {
        debug( pkg => "\%include_package: " . join( " ", get_all_packages_used() ) );
        debug( pkg => "\%skip_package: " . join( " ", sort keys %B::C::skip_package ) );
    }

    foreach my $pack ( include_package_list() ) {
        mark_package($pack) unless skip_pkg($pack);
    }
    debug( pkg => "descend_marked_unused: " . join( " ", include_package_list() ) );
}

# previously known as sub save_unused_subs
sub optimize {
    no strict qw(refs);

    my $sav_debug;
    if ( debug('unused') ) {
        $sav_debug = B::C::Config::Debug::save();
        B::C::Config::Debug::init();
    }
    my $module = B::C::module();
    my $main = $module ? $module . "::" : "main::";

    # -fwalkall: better strategy for compile-time added and required packages:
    # loop savecv and check pkg cache for new pkgs.
    # if so loop again with those new pkgs only, until the list of new pkgs is empty
    my ( $walkall_cnt, @init_unused, @unused, @dumped ) = (0);

    #do
    @init_unused = get_all_packages_used();

    verbose( "Prescan for unused subs in $main " . ( $sav_debug->{unused} ? " (silent)\n" : "\n" ) );

    # XXX TODO better strategy for compile-time added and required packages:
    # loop savecv and check pkg cache for new pkgs.
    # if so loop again with those new pkgs only, until the list of new pkgs is empty
    descend_marked_unused();
    walkpackages( \%{$main}, \&should_save, $main eq 'main::' ? undef : $main );
    verbose( "Saving unused subs in $main" . ( $sav_debug->{unused} ? " (silent)\n" : "\n" ) );
    walksymtable( \%{$main}, "savecv", \&should_save );
    @unused = get_all_packages_used();
    @dumped = grep { $B::C::dumped_package{$_} and $_ ne 'main' } keys %B::C::dumped_package;
    verbose( "old unused: %d, new: %d, dumped: %d", scalar @init_unused, scalar @unused, scalar @dumped );

    if ( !$B::C::walkall ) {
        @unused = @init_unused = ();
    }
    else {
        my $done;

        do {
            $done   = dump_rest();
            @unused = get_all_packages_used();
            @dumped = grep { $B::C::dumped_package{$_} and $_ ne 'main' } keys %B::C::dumped_package;
        } while @unused > @dumped and $done;
        last if $walkall_cnt++ > 3;
    }

    #} while @unused > @init_unused;

    if ( $sav_debug->{unused} ) {
        B::C::Config::Debug::restore($sav_debug);
    }

    # todo: move B::C:savINC
    # If any m//i is run-time loaded we'll get a "Undefined subroutine utf8::SWASHNEW"
    # With -fno-fold we don't insist on loading utf8_heavy and Carp.
    # Until it is compile-time required.
    if (
           exists( $INC{'unicore/To/Title.pl'} )
        or exists( $INC{'unicore/To/Tc.pl'} )    #242
        or exists( $INC{'unicore/Heavy.pl'} )    #242
        or ( $B::C::savINC{'utf8_heavy.pl'} and ( $B::C::fold or exists( $B::C::savINC{'utf8.pm'} ) ) )
      ) {
        require "utf8.pm" unless $B::C::savINC{"utf8.pm"};
        mark_package('utf8');
        require "utf8_heavy.pl" unless $B::C::savINC{"utf8_heavy.pl"};    # bypass AUTOLOAD
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
    if ( $B::C::warnings and exists $B::C::dumped_package{Carp} ) {
        svref_2object( \&{"warnings\::register_categories"} )->save;    # 68Kb 32bit
        add_hashINC("warnings");
        add_hashINC("warnings::register");
    }
    if ($B::C::use_xsloader) {
        force_saving_xsloader();
    }
}

sub should_save {
    no strict qw(vars refs);
    my $package = shift;
    $package =~ s/::$//;
    if ( skip_pkg($package) ) {
        delete_unsaved_hashINC($package) if can_delete($package);
        return 0;
    }
    if ( $package =~ /::::/ ) {

        # skip ::::ISA::CACHE etc.
        mark_package_unused($package);
        return 0;
    }
    debug( pkg => "Considering $package" );
    return if index( $package, " " ) != -1;    # XXX skip invalid package names
    return if index( $package, "(" ) != -1;    # XXX this causes the compiler to abort
    return if index( $package, ")" ) != -1;    # XXX this causes the compiler to abort
                                               # core static mro has exactly one member, ext/mro has more
    if ( $package eq 'mro' ) {

        if ( keys %{mro::} == 1 ) {            # core or ext?
            debug( pkg => "ext/mro not loaded - skip" );
            return;
        }
        else {
            debug( pkg => "ext/mro already loaded" );

            return is_package_used('mro');
        }
    }
    if ( $package eq 'attributes'
        and grep { $_ eq 'attributes' } @DynaLoader::dl_modules ) {
        B::C::mark_package( $package, 1 );
        return 1;
    }
    if ( exists $B::C::all_bc_deps{$package} ) {
        foreach my $u ( get_all_packages_used() ) {

            # If this package is a prefix to something we are saving, traverse it
            # but do not mark it for saving if it is not already
            # e.g. to get to B::OP we need to traverse B:: but need not save B
            my $p = $package;
            $p =~ s/(\W)/\\$1/g;
            return 1 if ( $u =~ /^$p\:\:/ ) && is_package_used($package);
        }
    }

    # Needed since 5.12.2: Check already if deleted
    my $incpack = inc_packname($package);
    if (    exists $B::C::all_bc_deps{$package}
        and !exists $B::C::curINC{$incpack}
        and $B::C::savINC{$incpack} ) {
        mark_package_unused($package);
        debug( 'pkg' => "Cached $package not in \%INC, already deleted (early)" );
        return 0;
    }

    # issue348: only drop B::C packages, not any from user code.
    if (   ( $package =~ /^DynaLoader|XSLoader$/ and $use_xsloader )
        or ( !exists $B::C::all_bc_deps{$package} ) ) {
        mark_package_used($package);
    }

    # If this package is in the same file as main:: or our source, save it. (72, 73)
    if ($mainfile) {

        # Find the first cv in this package for CV->FILE
        no strict 'refs';
        for my $sym ( sort keys %{ $package . '::' } ) {
            if ( defined &{ $package . '::' . $sym } ) {

                # compare cv->FILE to $mainfile
                my $cv = svref_2object( \&{ $package . '::' . $sym } );
                if ( $cv and $cv->can('FILE') and $cv->FILE ) {
                    mark_package_used($package) if $mainfile eq $cv->FILE;
                    last;
                }
            }
        }
    }

    # add overloaded but otherwise empty packages (#172)
    if ( $B::C::savINC{'overload.pm'} and exists ${ $package . '::' }{OVERLOAD} and exists ${ $package . '::' }{'()'} ) {
        mark_package( $package,   1 );
        mark_package( 'overload', 1 );
        return 1;
    }

    # Omit the packages which we use (and which cause grief
    # because of fancy "goto &$AUTOLOAD" stuff).
    # XXX Surely there must be a nicer way to do this.
    my $is_package_used = is_package_used($package);
    if ( defined $is_package_used ) {
        if ( !exists $B::C::all_bc_deps{$package} ) {
            mark_package_used($package);
            $B::C::curINC{$incpack} = $B::C::savINC{$incpack};
            debug( pkg => "Cached new $package is kept" );
        }
        elsif ( !$is_package_used ) {
            delete_unsaved_hashINC($package) if can_delete($package);
            debug( pkg => "Cached $package is already deleted" );
        }
        else {
            debug( pkg => "Cached $package is cached" );
        }
        return is_package_used($package);
    }

    # Now see if current package looks like an OO class. This is probably too strong.
    if ( !$B::C::all_bc_deps{$package} ) {
        foreach my $m (qw(new DESTROY TIESCALAR TIEARRAY TIEHASH TIEHANDLE)) {

            # 5.10 introduced version and Regexp::DESTROY, which we dont want automatically.
            # XXX TODO This logic here is wrong and unstable. Fixes lead to more failures.
            # The walker deserves a rewrite.
            if ( UNIVERSAL::can( $package, $m ) and $package !~ /^(B::C|version|Regexp|utf8|SelectSaver)$/ ) {
                next if $package eq 'utf8'                              and $m eq 'DESTROY';    # utf8::DESTROY is empty
                                                                                                # we load Errno by ourself to avoid double Config warnings [perl #]
                                                                                                # and we have special logic to detect and include it
                next if $package =~ /^(Errno|Tie::Hash::NamedCapture)$/ and $m eq 'TIEHASH';

                # XXX Config and FileHandle should not just return. If unneeded skip em.
                return 0 if $package eq 'Config'                            and $m =~ /DESTROY|TIEHASH/;    # Config detected in GV
                                                                                                            # IO::File|IO::Handle added for B::CC only
                return 0 if $package =~ /^(FileHandle|IO::File|IO::Handle)/ and $m eq 'new';
                debug( pkg => "$package has method $m: saving package" );
                return mark_package($package);
            }
        }
    }
    if ( $package !~ /^PerlIO/ and can_delete($package) ) {
        delete_unsaved_hashINC($package);
    }
    if ( can_delete($package) ) {
        debug( pkg => "Delete $package" );
        mark_package_unused($package);
    }
    elsif ( !exists $B::C::all_bc_deps{$package} ) {    # and not in @deps
        debug( pkg => "Keep $package" );
        mark_package_used($package);
    }

    return is_package_used($package);                   # 1 / 0 or undef
}

1;

# use B::C::Optimizer::UnusedPackages;
