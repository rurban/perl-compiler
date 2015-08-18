package SV;

sub save {
    my $sv = shift;

    # This is where we catch an honest-to-goodness Nullsv (which gets
    # blessed into B::SV explicitly) and any stray erroneous SVs.
    return 0 unless $$sv;
    warn sprintf( "cannot save that type of SV: %s (0x%x)\n", class($sv), $$sv );
}

1;
