package Devel::Trace::Method;

use strict;
use warnings;

our $VERSION = '0.07';

use Exporter 'import';

our @ISA = qw( Exporter );

our %EXPORT_TAGS = ( 
                all => [ qw(
                        track_object_methods    
                        track_method
                        fetch_trace
                        )
                    ],
                );
our @EXPORT_OK = (  @{ $EXPORT_TAGS{ all } }, ) ;

my @track_functions = qw(
                        CODEFLOW
                        STACK_TRACING
                    );
sub _track_functions { return @track_functions; }

my @fetch_functions = qw(
                        codeflow
                        stacktrace
                    );
sub _fetch_functions { return @fetch_functions; }

{ # create the tracking/retrieving functions  

    my $debugging_functions;

    { # CODEFLOW

        my $codeflow_storage;
        my $call_count = 0;

        sub CODEFLOW {
            my $self = shift;
            
            return $codeflow_storage if @_;

            $call_count++;
            
            $codeflow_storage->{$call_count} = (caller(2))[3];
        }
        $debugging_functions->{CODEFLOW} = \&CODEFLOW;

        sub codeflow {

            my $self = shift;

            my @sorted_codeflow;
            
            foreach my $key (sort { ($a) <=> ($b) } keys %$codeflow_storage) {
                push @sorted_codeflow, "$key => $codeflow_storage->{$key}";
            }
        
            return \@sorted_codeflow;
        }
        $debugging_functions->{codeflow} = \&codeflow;
    }

    { # STACK_TRACING

        my @stack;

        sub STACK_TRACING {

            my $self = shift;

            return @stack if @_;
            
            my $caller = (caller(3))[3] ? (caller(3))[3] : 0;
            push @stack, {
                    caller   => $caller,
                    package  => (caller(1))[0],
                    filename => (caller(1))[1],
                    line     => (caller(1))[2],
                    sub      => (caller(2))[3],
                };
        }
        $debugging_functions->{STACK_TRACING} = \&STACK_TRACING;

        sub stacktrace { return \@stack; }
        
        $debugging_functions->{stacktrace} = \&stacktrace;
    }

    sub DEBUGGING_FUNCTIONS { return $debugging_functions; }
}

sub track_object_methods {

    my $self = shift;

    for my $function ( @track_functions ){
        $self->{ DTM_functions }{ track }{ $function } 
            = DEBUGGING_FUNCTIONS()->{ $function };
    }
    for my $function ( @fetch_functions ){
        $self->{ DTM_functions }{ fetch }{ $function }
            = DEBUGGING_FUNCTIONS()->{ $function };
    }

    return $self;   
}

sub track_method {

    my $self = shift;

    for my $track_function ( @track_functions ){
        $self->{ DTM_functions }{ track }{ $track_function }();
    }

    return 0;
}

sub fetch_trace {
    
    my $self = shift;
    my $param = shift;

    if ( ! $param ){
        my $return_href;
        for my $data ( @fetch_functions ){
            $return_href->{ $data } = $self->{ DTM_functions }{ fetch }{ $data }();
        }
        return $return_href;
    }   
    return $self->{ DTM_functions }{ fetch }{ $param }();
}

1;

__END__


=head1 NAME

Devel::Trace::Method - Follow the flow of your object's method calls 



=head1 SYNOPSIS

  use Devel::Trace::Method qw( 
                                track_object_methods    
                                track_method
                                fetch_trace
                            );

  # configure your object for method tracking within your
  # new() method
 
  track_object_methods( $self ); 

  # add the tracking call within each of your methods

  track_method( $self );
  
  # retrieve the data  
    
  my $all        = fetch_trace( $obj ); # or $self
  my $codeflow   = fetch_trace( $obj, 'codeflow' );
  my $stacktrace = fetch_trace( $obj, 'stacktrace' );


=head1 DESCRIPTION

This module takes any object, and injects into it the ability to
have it track its own method calls, and store this information for
later retrieval. It creates and stores an ordered stack trace, 
and a list of ordered method calls.

NOTE: This is alpha software, and *will* go through API changes
in the early stages.


=head1 FUNCTIONS


=head2 track_object_methods( OBJ )

Prepares and configures your object so that it can create
and retain its own codeflow and stack trace data over time.

Takes an object as its only parameter, and returns the object.

This function should be called within your new() method, after
blessing your object, and prior to returning it.


=head2 track_method( OBJ )

This function appends tracking data to what is currently saved
for each method call that calls this function.

Currently, this function call must be manually listed in each
method you want to track. It should be entered in all of your
class methods, or the program flow won't make much sense ;)

Takes your $self object as the only parameter, and returns 0
upon success.


=head2 fetch_trace( OBJ, STRING )

Retrieves the stored data that had accumulated thus far in
the run of your program. Can be called from within one of your
methods, or by a program using one of your methods.

Takes an object as the first mandatory parameter. The second
optional string parameter states which data you'd like returned:

    'codeflow'   -returns an arrayref containing the list of methods
                  called, in the order they were called.

    'stacktrace' -returns an arrayref of hash references, where
                  each hash ref contains details of each method call

Given no optional parameters, returns a hash reference that contains 
an array reference for each of the available data.



=head1 EXAMPLES

    # print the stack trace

    my $stack = fetch_trace( $obj, 'stacktrace' );
    print Dumper $stack;

    $VAR1 = [
          {
            'caller' => 0,
            'sub' => 'Dude::say_hi',
            'filename' => './dude.pl',
            'line' => 26,
            'package' => 'Dude'
          },
          {
            'caller' => 'Dude::say_hi',
            'sub' => 'Dude::say_bye',
            'filename' => './dude.pl',
            'line' => 46,
            'package' => 'Dude'
          }
        ];

    # print the code flow

    my $codeflow = fetch_trace( $obj, 'codeflow' );
    print Dumper $codeflow;

    $VAR1 = [
          '0 => Dude::say_hi',
          '1 => Dude::say_bye'
        ];



=head1 LIMITATIONS ETC

This is pure alpha software. Although the code works well, there
are some serious limitations, and for large class hierarchies, 
there may be a significant performance hit. There is no internal
method to bypass the work this module does (yet), so use it only
for testing, or wrap the track_method() calls within an if($debug)
type block.

Until I figure out how to get around it, the trace_method() call
must be manually placed in all methods you want to keep track of.

Currently, we do not munge the symbol table of the object to create
its own methods, therefore your object has to pass itself in  
as an argument. In the future, we'll have an option to have it either
way.



=head1 AUTHOR
Steve Bertrand, E<lt>steveb@cpan.orgE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
