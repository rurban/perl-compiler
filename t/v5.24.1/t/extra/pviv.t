#!./perl

eval q{use Devel::Peek};

print "1..14\n";

#my ( $A, $B, $C, $D, $E, $F, $G, $H);

{
    note("a - a simple IV");
    my $A;
    BEGIN { $A = 42 }

    my $dump = mydump($A);

    like( $dump, qr{\bSV = IV\b}, "regular IV" );
}

{
    note("c - Downgrade one PVIV with IOK");
    my $C;

    BEGIN {
        $C = 9876543;
        $C = "wert";     # IV upgraded as PVIV
        $C = 1234567;    # then go back to iOK
    }

    my $dump = mydump($C);

    if ( is_compiled() ) {
        like( $dump, qr{\bSV = IV\b},   "IV uncompiled" );
        like( $dump, qr{IV =.+1234567}, "value" );
    }
    else {
        like( $dump, qr{\bSV = PVIV\b}, "PVIV uncompiled" );
        like( $dump, qr{IV =.+1234567}, "value" );
    }
}

{
    note("d - downgrade PVIV as a regular IV at compilation");
    my $x;
    my $D;

    BEGIN {
        $D = 424143;
        $x = "upgrade variable d to PVIV $D";
    }

    my $dump = mydump($D);

    ok( $D == 424143, 'check value' );

    if ( is_compiled() ) {

        like( $dump, qr{\bSV = IV\b},  "IV uncompiled" );
        like( $dump, qr{IV =.+424143}, "value" );           # FIXME: value is incorrect ???
    }
    else {
        like( $dump, qr{\bSV = PVIV\b}, "PVIV uncompiled" );
        like( $dump, qr{IV =.+424143},  "value" );
    }
}

{
    note("e - downgrading a PVIV to an IV");
    my $E;

    BEGIN {
        $E = 98765;
        $E .= "";
    }

    my $dump = mydump($E);

    if ( is_compiled() ) {
        like( $dump, qr{\bSV = IV\b}, "downgrade as a IV" );
        like( $dump, qr{IV =.+98765}, "value" );
    }
    else {
        like( $dump, qr{\bSV = PVIV\b}, "PVIV uncompiled" );
        like( $dump, qr{PV =.+"98765"}, "value" );
    }
}

{
    note("f - downgrading a PVIV to a PV");
    my $F;

    BEGIN {
        $F = 13579;
        $F = "abcd";
    }

    my $dump = mydump($F);

    if ( is_compiled() ) {
        like( $dump, qr{\bSV = PV\b}, "downgrade as a PV" );
    }
    else {
        like( $dump, qr{\bSV = PVIV\b}, "PVIV uncompiled" );
    }
    like( $dump, qr{PV =.+"abcd"}, "PV string" );
}

{
    note("G - downgrading a PVIV to an IV when the PV looks like a valid integer");
    my $G;

    BEGIN {
        $G = 24680;
        $G .= "1";
    }

    my $dump = mydump($G);

    if ( is_compiled() ) {
        like( $dump, qr{\bSV = IV\b}, "downgrade as an IV" );
        like( $dump, qr{IV = 246801}, "value" );
    }
    else {
        like( $dump, qr{\bSV = PVIV\b},  "PVIV uncompiled" );
        like( $dump, qr{PV =.+"246801"}, "PV string" );
    }

}

{
    note("H - Do not downgrade a PVIV to an IV when the PV is too long");
    my $H;

    BEGIN {
        $H = 1;
        $H .= "1" x 18;
    }

    my $dump = mydump($H);

    # same compiled / uncompiled
    if ( is_compiled() ) {
        like( $dump, qr{\bSV = PV\b}, "do not downgrade as an IV (but as a PV ?)" );    # might preserve the PVIV in this case
    }
    else {
        like( $dump, qr{\bSV = PVIV\b}, "do not downgrade as an IV" );
    }

    like( $dump, qr{\bPV =.+ "1111111111111111111"}m, "PV string" );
}

exit;

# ... helpers ....

sub is_compiled {
    return $0 =~ qr{\.bin$} ? 1 : 0;
}

my $closed;

my $out;

sub mydump {
    $out = '';

    close STDERR;
    {
        local *STDERR;
        open STDERR, ">", \$out;

        Dump( $_[0] );
        note("[ $out ]");
    }

    return $out;
}

{
    my $_counter = 0;

    sub ok {
        my ( $t, $msg ) = @_;

        $msg ||= '';
        ++$_counter;

        if ($t) {
            print "ok $_counter - $msg\n";
            return 1;
        }
        else {
            print "not ok $_counter - $msg\n";
            return 0;
        }
    }
}

sub like {
    my ( $s, $re, $msg ) = @_;

    if ( defined $re ) {
        my $ok = $s =~ $re ? 1 : 0;
        return ok( $ok, $msg );
    }

    die;
}

sub note {
    my $s = shift;
    return unless defined $s;
    map { print "# $_\n" } split( qr{\n}, $s );    # map in void context, yea

    return;
}
