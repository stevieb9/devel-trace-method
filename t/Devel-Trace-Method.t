use strict;
use warnings;
use Data::Dumper;

use Test::More qw( no_plan );
BEGIN { use_ok('Devel::Trace::Method') };

# dummy package for testing

package Class;

use Devel::Trace::Method qw( :all );

sub new { 
    my $self = bless {}, 'Class'; 
    track_object_methods( $self ) unless shift;
    return $self;
}
sub now { 
    my $self = shift;
    trace_method( $self );
}
sub then {
    my $self = shift;
    trace_method{ $self };
}
1;

sub _nothing{} ### Tests

package main;

use Devel::Trace::Method qw( :all );

{
    my $obj = Class::new(1);
    my $ret = track_object_methods( $obj );

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

}
