package B::UNOP;

use strict;

use B::C::Setup;
use B::C::File qw/unopsect init/;
use B::C::Helpers qw/do_labels mark_package padop_name svop_name curcv/;
use B::C::Helpers::Symtable qw/objsym savesym/;

sub save {
    my ( $op, $level ) = @_;

    my $sym = objsym($op);
    return $sym if defined $sym;

    $level ||= 0;

    unopsect()->comment_common("first");
    unopsect()->add( sprintf( "%s, s\\_%x", $op->_save_common, ${ $op->first } ) );
    unopsect()->debug( $op->name, $op );
    my $ix = unopsect()->index;
    init()->add( sprintf( "unop_list[%d].op_ppaddr = %s;", $ix, $op->ppaddr ) )
      unless $B::C::optimize_ppaddr;
    $sym = savesym( $op, "(OP*)&unop_list[$ix]" );

    if ( $op->name eq 'method' and $op->first and $op->first->name eq 'const' ) {
        my $method = svop_name( $op->first );
        if ( !$method and USE_ITHREADS() ) {
            $method = padop_name( $op->first, curcv() );    # XXX (curpad[targ])
        }
        debug( pkg => "method -> const $method" ) if USE_ITHREADS();

        #324,#326 need to detect ->(maybe::next|maybe|next)::(method|can)
        if ( $method =~ /^(maybe::next|maybe|next)::(method|can)$/ ) {
            debug( pkg => "mark \"$1\" for method $method" );
            mark_package( $1,    1 );
            mark_package( "mro", 1 );
        }    # and also the old 5.8 NEXT|EVERY with non-fixed method names und subpackages
        elsif ( $method =~ /^(NEXT|EVERY)::/ ) {
            debug( pkg => "mark \"$1\" for method $method" );
            mark_package( $1, 1 );
            mark_package( "NEXT", 1 ) if $1 ne "NEXT";
        }
    }
    do_labels( $op, $level + 1, 'first' );
    $sym;
}

1;
