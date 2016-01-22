package B::C::Optimizer::ForceHeavy;

use strict;
use B qw/svref_2object/;
use B::C::Setup;
use B::C::Packages qw/is_package_used/;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw/force_heavy/;

my %cache;

my $RULE = q{(bytes|utf8)};

# for bytes and utf8 only
# TODO: Carp::Heavy, Exporter::Heavy
# special case: warnings::register via -fno-warnings
sub force_heavy {
    my ( $pkg, $fullname ) = @_;

    # only for bytes and utf8
    # QUESTION: what about Config_heavy.pl ?
    return unless $pkg && $pkg =~ m/^$RULE$/;

    # optional
    return if $fullname && $fullname !~ /^${RULE}::AUTOLOAD$/;

    my $pkg_heavy = $pkg . "_heavy.pl";
    no strict 'refs';

    if (
            !$cache{$pkg}
        and !is_package_used($pkg_heavy)
        and !exists $B::C::savINC{$pkg_heavy}

      ) {
        $cache{$pkg} = 1;

        #eval qq[sub $pkg\::AUTOLOAD {
        #    require '$pkg_heavy';
        #    goto &\$AUTOLOAD if defined &\$AUTOLOAD;
        #    warn("Undefined subroutine \$AUTOLOAD called");
        #  }];
        debug( pkg => "Forcing early $pkg_heavy" );
        if ( eval qq{ require $pkg_heavy; 1 } ) {
            WARN "Error while loading $pkg_heavy: $@";
            B::C::mark_package( $pkg_heavy, 1 );
        }

        #walk_syms($pkg); #before we stub unloaded CVs
    }
    return svref_2object( \*{ $pkg . "::AUTOLOAD" } );
}

1;
