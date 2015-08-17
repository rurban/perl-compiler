#! perl

package generate::perlcc;

use Config;
use File::Basename qw(&basename &dirname);
use File::Spec;
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.
# Wanted:  $archlibexp

generate() unless caller();

sub _perlcc_filename {
    my $file = basename( $0, '.PL' );
    $file .= '.com' if $^O eq 'VMS';

    return $file;
}

sub src_template { return '../templates/' . basename( $0, '.PL' ) . '.pl' }

sub _switch_dir {
    my $origdir = cwd;
    chdir dirname($0) or die $!;

    END { chdir $origdir }

    return;
}

sub generate {

    # This forces PL files to create target in same directory as PL file.
    # This is so that make depend always knows where to find PL derivatives.
    _switch_dir();

    my $file = _perlcc_filename();
    open OUT, ">", $file or die "Can't create $file: $!";

    print "Extracting $file (with variable substitutions)\n";

    # In this section, perl variables will be expanded during extraction.
    # You can use $Config{...} to use Configure variables.

    print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
    if \$running_under_some_shell;
--\$running_under_some_shell;
!GROK!THIS!

    my $template;
    {
        my $src = src_template();
        local $/;
        open my $fh, '<', $src or die "Cannot open $template $!";
        $template = <$fh>;
    }

    print OUT $template;

    close OUT or die "Can't close $file: $!";
    chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
    exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';

    return;
}

1;
