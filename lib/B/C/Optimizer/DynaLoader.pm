package B::C::Optimizer::DynaLoader;

use strict;
use warnings;

use B qw(svref_2object);
use Config;
use B::C::Config qw/verbose debug/;
use B::C::Packages qw/is_package_used mark_package_deleted/;

sub new {
    my $class = shift or die;
    my $self  = shift or die;
    ref $self eq 'HASH' or die( ref $self );

    $self->{'xsub'}            or die;
    $self->{'skip_package'}    or die;
    $self->{'curINC'}          or die;
    $self->{'output_file'}     or die;
    exists $self->{'staticxs'} or die;

    # Initialize in case there's no dynaloader and we return early.
    $self->{'stash'} = {
        'dl'         => 0,
        'xs'         => 0,
        'dl_modules' => [],
        'fixups'     => {},
      },

      return bless $self, $class;
}

sub stash {
    my $self = shift or die;

    return $self->{'stash'};
}

sub optimize {
    my $self = shift or die;
    ref $self eq __PACKAGE__ or die;

    my ( $dl, $xs );
    my @dl_modules = @DynaLoader::dl_modules;

    # filter out unused dynaloaded B modules, used within the compiler only.
    for my $c (qw(B B::C)) {
        if ( !$self->{'xsub'}->{$c} and !is_package_used($c) ) {

            # (hopefully, see test 103)
            verbose("no dl_init for $c, not marked") if !$self->{'skip_package'}->{$c};

            # RT81332 pollute
            @dl_modules = grep { $_ ne $c } @dl_modules;

            # XXX Be sure to store the new @dl_modules
            # QUESTION: WHY??? we're rendering already and done walking the code tree, right? There's no value
        }
    }

    for my $c ( sort keys %{ $self->{'skip_package'} } ) {
        verbose("no dl_init for $c, skipped") if $self->{'xsub'}->{$c};
        delete $self->{'xsub'}->{$c};
        mark_package_deleted($c);    # TODO: It's WAAAAY to late to do this?
        @dl_modules = grep { $_ ne $c } @dl_modules;
    }

    # QUESTION: There's no readon to pump this back in if we're just rendering a template at this point.
    @DynaLoader::dl_modules = @dl_modules;
    verbose( "\@dl_modules: " . join( " ", @dl_modules ) );

    foreach my $stashname (@dl_modules) {
        if ( $stashname eq 'attributes' ) {
            $self->{'xsub'}->{$stashname} = 'Dynamic-' . $INC{'attributes.pm'};
        }

        if ( $stashname eq 'Moose' and is_package_used('Moose') and $Moose::VERSION gt '2.0' ) {
            $self->{'xsub'}->{$stashname} = 'Dynamic-' . $INC{'Moose.pm'};
        }
        if ( exists( $self->{'xsub'}->{$stashname} ) && $self->{'xsub'}->{$stashname} =~ m/^Dynamic/ ) {

            # XSLoader.pm: $modlibname = (caller())[1]; needs a path at caller[1] to find auto,
            # otherwise we only have -e
            $xs++ if $self->{'xsub'}->{$stashname} ne 'Dynamic';
            $dl++;
        }
    }
    debug( cv => "\%B::C::xsub: " . join( " ", sort keys %{ $self->{'xsub'} } ) ) if verbose();

    # XXX Adding DynaLoader is too late here! The sections like $init are already dumped (#125)
    # QUESTION: What do we need to alter? cause now we're uding template, it's not too late.
    # (Though technically I've never seen this die.)
    # Something to do with 5.20? https://code.google.com/p/perl-compiler/issues/detail?id=125
    if ( $dl and !$self->{'curINC'}->{'DynaLoader.pm'} ) {
        die "Error: DynaLoader required but not dumped. Too late to add it.\n";
    }
    elsif ( $xs and !$self->{'curINC'}->{'XSLoader.pm'} ) {
        die "Error: XSLoader required but not dumped. Too late to add it.\n";
    }

    return 0 if !$dl;

    my $xsfh;    # Will close automatically when it goes out of scope.

    if ( grep { $_ eq 'attributes' } @dl_modules ) {

        # enforce attributes at the front of dl_init, #259
        @dl_modules = grep { $_ ne 'attributes' } @dl_modules;
        unshift @dl_modules, 'attributes';
    }

    if ( $self->{'staticxs'} ) {
        my $file = $self->{'output_file'} . '.lst';
        open( $xsfh, ">", $file ) or die("Can't open $file: $!");
    }

    foreach my $stashname (@dl_modules) {
        if ( exists( $self->{'xsub'}->{$stashname} ) && $self->{'xsub'}->{$stashname} =~ m/^Dynamic/ ) {
            $B::C::use_xsloader = 1;    # TODO: This setting is totally worthless since the code that uses this variable has already been run??
            if ( $self->{'xsub'}->{$stashname} eq 'Dynamic' ) {
                no strict 'refs';
                verbose("dl_init $stashname");

                # just in case we missed it. DynaLoader really needs the @ISA (#308)
                svref_2object( \@{ $stashname . "::ISA" } )->save;
            }
            else {                      # XS: need to fix cx for caller[1] to find auto/...
                verbose("bootstrapping $stashname added to XSLoader dl_init");
            }

            # TODO: Why no strict refs? Also why are we doing a second save here?
            no strict 'refs';
            unless ( grep /^DynaLoader$/, B::C::get_isa($stashname) ) {
                push @{ $stashname . "::ISA" }, 'DynaLoader';
                svref_2object( \@{ $stashname . "::ISA" } )->save;
            }

            debug( gv => '@', $stashname, "::ISA=(", join( ",", @{ $stashname . "::ISA" } ), ")" );

            if ( $self->{'staticxs'} ) {
                my ($laststash) = $stashname =~ /::([^:]+)$/;
                my $path = $stashname;
                $path =~ s/::/\//g;
                $path .= "/" if $path;    # can be empty
                $laststash = $stashname unless $laststash;    # without ::
                my $sofile = "auto/" . $path . $laststash . '\.' . $Config{'dlext'};

                #warn "staticxs search $sofile in @DynaLoader::dl_shared_objects\n"
                #  if verbose() and $self->{'debug'}->{pkg};
                for (@DynaLoader::dl_shared_objects) {
                    if (m{^(.+/)$sofile$}) {
                        print $xsfh $stashname, "\t", $_, "\n";
                        verbose("staticxs $stashname\t$_");
                        $sofile = '';
                        last;
                    }
                }
                print {$xsfh} $stashname, "\n" if $sofile;    # error case
                verbose("staticxs $stashname\t - $sofile not loaded") if $sofile;
            }
        }
        else {
            verbose( "no dl_init for $stashname, " . ( !$self->{'xsub'}->{$stashname} ? "not marked\n" : "marked as $self->{'xsub'}->{$stashname}" ) );

            # XXX Too late. This might fool run-time DynaLoading.
            # We really should remove this via init from @DynaLoader::dl_modules
            @DynaLoader::dl_modules = grep { $_ ne $stashname } @DynaLoader::dl_modules;
        }
    }

    $self->{'stash'} = {
        'dl'         => $dl,
        'xs'         => $xs,
        'dl_modules' => \@dl_modules,
        'fixups'     => {
            'coro' => ( exists $self->{'xsub'}->{"Coro::State"} and grep { $_ eq "Coro::State" } @dl_modules ) ? 1 : 0,
        },
    };
    return 1;
}

1;
