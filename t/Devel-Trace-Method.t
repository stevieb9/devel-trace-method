use strict;
use warnings;
use Data::Dumper;

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

{
    my $obj = Class::new(1);
    my $ret = track_object_methods( $obj );
    $obj = $ret;

    ok ( ref $ret eq 'Class', "track_object_method() returns an object" );

    ok ( exists $obj->{ DTM_functions }, "object is populated with our container" );
    ok ( exists $obj->{ DTM_functions }{ track }, "container has track" );
    ok ( exists $obj->{ DTM_functions }{ fetch }, "container has fetch" );
   
    { # track subs

        my $sub_count = 0;
        my $track_subs = $obj->{ DTM_functions }{ track };
        for my $sub ( keys %{ $track_subs } ){ 
            $sub_count++;
            ok ( ref $track_subs->{ $sub }  eq 'CODE', "sub $sub_count is actually a coderef" );
        }
        ok ( $sub_count == 2, "there are only two 'track' subs" );
    }
    { # fetch subs

        my $sub_count = 0;
        my $fetch_subs = $obj->{ DTM_functions }{ fetch };
        for my $sub ( keys %{ $fetch_subs } ){ 
            $sub_count++;
            ok ( ref $fetch_subs->{ $sub }  eq 'CODE', "sub $sub_count is actually a coderef" );
        }
        ok ( $sub_count == 2, "there are only two 'fetch' subs" );
    }

    { # track_method() return
        my $track_method_return = $obj->trace_ret();
        is ( $track_method_return, 0, "success in track_method_return() returns 0" );
    }

} ### end test block 1

{ ### Test block 2 (basic function return testing)

    my $obj = Class::new();
    $obj->trace_ret();
    $obj->then();

    { # fetch_trace

        # all of the data

        my $all = fetch_trace( $obj );
        ok ( ref $all eq 'HASH', "given no params, fetch_trace() returns an href at the top level" );

        for my $data ( keys %$all ){
            ok ( ref $all->{ $data } eq 'ARRAY', "element in fetch_trace() array with no args is an arrayref" );
        }
    }

    { # fetch_trace with param

        my @fetch_functions = Devel::Trace::Method::_fetch_functions();
        ok ( scalar @fetch_functions == 2, "we're testing all of the fetch functions" );
       
        # stacktrace()

        my $stacktrace = fetch_trace( $obj, 'stacktrace' );
        ok ( ref $stacktrace eq 'ARRAY', "fetch_trace() with param 'stacktrace' returns an aref" );
        ok ( ref $stacktrace->[0] eq 'HASH', "the aref returned from fetch_trace( 'stacktrace' ) contains hrefs" );
        my $key_count = keys ( %{ $stacktrace->[0] } );
        is ( $key_count, 5, "each href in stacktrace() return aref contains 5 entries" );

        # codeflow

        my $codeflow = fetch_trace( $obj, 'codeflow' );
        ok ( ref $codeflow eq 'ARRAY', "fetch_trace() with param 'codeflow' returns an aref" );
        
    } 
}
