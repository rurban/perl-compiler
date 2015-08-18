package B::SPECIAL;

use B::Asmdata qw(@specialsv_name);

sub save {
    my ( $sv, $fullname ) = @_;

    # # special case: $$sv is not the address but an index into specialsv_list
    # #   warn "SPECIAL::save specialsv $$sv\n"; # debug
    # @specialsv_name = qw(Nullsv &PL_sv_undef &PL_sv_yes &PL_sv_no pWARN_ALL pWARN_NONE)
    #   unless @specialsv_name;    # 5.6.2 Exporter quirks. pWARN_STD was added to B with 5.8.9
    my $sym = $specialsv_name[$$sv];
    if ( !defined($sym) ) {
        warn "unknown specialsv index $$sv passed to B::SPECIAL::save";
    }

    return $sym;
}

1;
