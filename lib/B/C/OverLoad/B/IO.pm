package B::IO;

use strict;

use B qw/cstring cchar svref_2object/;
use B::C::Setup;
use B::C::Save qw(savepv);
use B::C::File qw/init init2 svsect xpviosect/;

use B::C::Helpers qw/mark_package/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save_data {
    my ( $io, $sym, $globname, @data ) = @_;
    my $data = join '', @data;

    # XXX using $DATA might clobber it!
    my $ref = svref_2object( \\$data )->save;
    init()->add("/* save $globname in RV ($ref) */") if verbose();
    init()->add("GvSVn( $sym ) = (SV*)$ref;");

    # force inclusion of PerlIO::scalar as it was loaded in BEGIN.
    init2()->add_eval( sprintf 'open(%s, \'<:scalar\', $%s);', $globname, $globname );

    # => eval_pv("open(main::DATA, '<:scalar', $main::DATA);",1); DATA being a ref to $data
    init()->pre_destruct( sprintf 'eval_pv("close %s;", 1);', $globname );
    $B::C::use_xsloader = 1;    # layers are not detected as XSUB CV, so force it
    require PerlIO         unless $B::C::savINC{'PerlIO.pm'};
    require PerlIO::scalar unless $B::C::savINC{'PerlIO/scalar.pm'};
    mark_package( "PerlIO", 1 );

    $B::C::curINC{'PerlIO.pm'} = $INC{'PerlIO.pm'};    # as it was loaded from BEGIN
    mark_package( "PerlIO::scalar", 1 );

    $B::C::curINC{'PerlIO/scalar.pm'} = $INC{'PerlIO/scalar.pm'};
    $B::C::xsub{'PerlIO::scalar'}     = 'Dynamic-' . $INC{'PerlIO/scalar.pm'};    # force dl_init boot
}

sub save {
    my ( $io, $fullname, $is_DATA ) = @_;

    my $sym = objsym($io);
    return $sym if defined $sym;
    my $pv = $io->PV;
    $pv = '' unless defined $pv;
    my ( $pvsym, $len, $cur );
    if ($pv) {
        $pvsym = savepv($pv);
        $cur   = $io->CUR;
    }
    else {
        $pvsym = 'NULL';
        $cur   = 0;
    }
    if ($cur) {
        $len = $cur + 1;
        $len++ if B::C::IsCOW($io);
    }
    else {
        $len = 0;
    }
    debug( sv => "IO $fullname sv_list[%d] 0x%x (%s) = '%s'\n", svsect()->index + 1, $$io, $io->SvTYPE, $pv );

    # no method "SvTYPE" via package "B::IO"

    # IFP in sv.sv_u.svu_fp
    xpviosect()->comment("STASH, xmg_u, cur, len, xiv_u, xio_ofp, xio_dirpu, page, page_len, ..., type, flags");
    my $tmpl =
      "Nullhv, /*STASH later*/\n\t{0}, /*MAGIC later*/\n\t%u, /*cur*/\n\t{%u}, /*len*/\n\t{%d}, /*LINES*/\n\t0, /*OFP later*/\n\t{0}, /*dirp_u later*/\n\t%d, /*PAGE*/\n\t%d, /*PAGE_LEN*/\n\t%d, /*LINES_LEFT*/\n\t%s, /*TOP_NAME*/\n\tNullgv, /*top_gv later*/\n\t%s, /*fmt_name*/\n\tNullgv, /*fmt_gv later*/\n\t%s, /*bottom_name*/\n\tNullgv, /*bottom_gv later*/\n\t%s, /*type*/\n\t0x%x /*flags*/";
    $tmpl =~ s{ /\*.+?\*/\n\t}{}g unless verbose();
    $tmpl =~ s{ /\*flags\*/$}{}   unless verbose();
    xpviosect()->add(
        sprintf(
            $tmpl,
            $cur, $len,
            $io->LINES,    # moved to IVX with 5.11.1
            $io->PAGE,            $io->PAGE_LEN,
            $io->LINES_LEFT,      "NULL",
            "NULL",               "NULL",
            cchar( $io->IoTYPE ), $io->IoFLAGS
        )
    );
    svsect()->add(
        sprintf(
            "&xpvio_list[%d], %Lu, 0x%x, {%s}",
            xpviosect()->index, $io->REFCNT, $io->FLAGS,
            $B::C::pv_copy_on_grow ? $pvsym : 0
        )
    );

    svsect()->debug( $fullname, $io );
    $sym = savesym( $io, sprintf( "(IO*)&sv_list[%d]", svsect()->index ) );

    if ( !$B::C::pv_copy_on_grow and $cur ) {
        init()->add( sprintf( "SvPVX(sv_list[%d]) = %s;", svsect()->index, $pvsym ) );
    }
    my ($field);
    foreach $field (qw(TOP_GV FMT_GV BOTTOM_GV)) {
        my $fsym = $io->$field();
        if ($$fsym) {
            init()->add( sprintf( "Io%s(%s) = (GV*)s\\_%x;", $field, $sym, $$fsym ) );
            $fsym->save;
        }
    }
    foreach $field (qw(TOP_NAME FMT_NAME BOTTOM_NAME)) {
        my $fsym = $io->$field;
        if ($fsym) {
            init()->add( sprintf( "Io%s(%s) = savepvn(%s, %u);", $field, $sym, cstring($fsym), length $fsym ) );
        }
    }
    $io->save_magic($fullname);    # This handle the stash also (we need to inc the refcnt)
    if ( !$is_DATA ) {             # PerlIO
                                   # deal with $x = *STDIN/STDOUT/STDERR{IO} and aliases
        my $perlio_func;

        # Note: all single-direction fp use IFP, just bi-directional pipes and
        # sockets use OFP also. But we need to set both, pp_print checks OFP.
        my $o = $io->object_2svref();
        eval "require " . ref($o) . ";";
        my $fd = $o->fileno();

        # use IO::Handle ();
        # my $fd = IO::Handle::fileno($o);
        my $i = 0;
        foreach (qw(stdin stdout stderr)) {
            if ( $io->IsSTD($_) or ( defined($fd) and $fd == -$i ) ) {
                $perlio_func = $_;
            }
            $i++;
        }
        if ($perlio_func) {
            init()->add("IoIFP(${sym}) = IoOFP(${sym}) = PerlIO_${perlio_func}();");

            #if ($fd < 0) { # fd=-1 signals an error
            # XXX print may fail at flush == EOF, wrong init-time?
            #}
        }
        else {
            my $iotype  = $io->IoTYPE;
            my $ioflags = $io->IoFLAGS;

            # If an IO handle was opened at BEGIN, we try to re-init it, based on fd and IoTYPE.
            # IOTYPE:
            #  -    STDIN/OUT           HANDLE IoIOFP alias
            #  I    STDIN/OUT/ERR       HANDLE IoIOFP alias
            #  <    read-only           HANDLE fdopen
            #  >    write-only          HANDLE if fd<3 or IGNORE warn and comment
            #  a    append              HANDLE     -"-
            #  +    read and write      HANDLE fdopen
            #  s    socket              DIE
            #  |    pipe                DIE
            #  #    NUMERIC             HANDLE fdopen
            #  space closed             IGNORE
            #  \0   ex/closed?          IGNORE
            if ( $iotype eq "\c@" or $iotype eq " " ) {
                debug(
                    gv => "Ignore closed IO Handle %s %s (%d)\n",
                    cstring($iotype), $fullname, $ioflags
                );
            }
            elsif ( $iotype =~ /[a>]/ ) {    # write-only
                WARN("Warning: Write BEGIN-block $fullname to FileHandle $iotype \&$fd")
                  if $fd >= 3 or verbose();
                my $mode = $iotype eq '>' ? 'w' : 'a';

                init()->add(
                    sprintf(
                        "%sIoIFP(%s) = IoOFP(%s) = PerlIO_fdopen(%d, %s);%s",
                        $fd < 3 ? '' : '/*', $sym, $sym, $fd, cstring($mode), $fd < 3 ? '' : '*/'
                    )
                );
            }
            elsif ( $iotype =~ /[<#\+]/ ) {

                # skips warning if it's one of our PerlIO::scalar __DATA__ handles
                WARN("Warning: Read BEGIN-block $fullname from FileHandle $iotype \&$fd")
                  if $fd >= 3 or verbose();    # need to setup it up before
                init()->add(
                    "/* XXX WARNING: Read BEGIN-block $fullname from FileHandle */",
                    "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"r\");"
                );
                my $tell;
                if ( $io->can("tell") and $tell = $io->tell() ) {
                    init()->add("PerlIO_seek(IoIFP($sym), $tell, SEEK_SET);");
                }
            }
            else {
                # XXX We should really die here
                FATAL(
                    "ERROR: Unhandled BEGIN-block IO Handle %s\&%d (%d) from %s\n",
                    cstring($iotype), $fd, $ioflags, $fullname
                );
                init()->add(
                    "/* XXX WARNING: Unhandled BEGIN-block IO Handle ",
                    "IoTYPE=$iotype SYMBOL=$fullname, IoFLAGS=$ioflags */",
                    "IoIFP($sym) = IoOFP($sym) = PerlIO_fdopen($fd, \"$iotype\");"
                );
            }
        }
    }

    my $stash = $io->SvSTASH;
    if ( $stash and $$stash ) {
        my $stsym = $stash->save( "%" . $stash->NAME );
        init()->add(
            sprintf( "SvREFCNT(%s) += 1;", $stsym ),
            sprintf( "SvSTASH_set(%s, %s);", $sym, $stsym )
        );
        debug( gv => "done saving STASH %s %s for IO %s", $stash->NAME, $stsym, $sym );
    }

    return $sym;
}

1;
