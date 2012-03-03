use strict;
use warnings;

use Test::More qw( no_plan );

# dummy package for testing

package Class;

use Devel::Trace::Method qw( :all );

sub new { 
    my $self = bless {}, 'Class'; 
    track_object_methods( $self ) unless shift;
    return $self;
}
sub trace_ret { 
    my $self = shift;
    my $trace_ret = track_method( $self );
    return $trace_ret;
}
sub then {
    my $self = shift;
    track_method( $self );
}
1;

sub _nothing{} ### Tests

package main;

use Devel::Trace::Method qw( :all );

{ # bug 5 test

    # ensure the first element in fetch_trace( 'codeflow' )
    # is 1 not 0

    my $obj = Class::new();
    $obj->trace_ret();
    $obj->then();

    my $codeflow = fetch_trace( $obj, 'codeflow' );

    ok ( $codeflow->[0] =~ /^1/, "codeflow return has 1 as the first entry" );
}
