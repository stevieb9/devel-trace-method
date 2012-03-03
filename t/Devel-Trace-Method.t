# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Devel-Method-Matrix.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok('Devel::Method::Matrix') };

use Devel::Method::Matrix qw( :all );

#can_ok( 'Devel::Method::Matrix', 'configure_method_debug' );
#can_ok( 'Devel::Method::Matrix', 'track_method' );

{

}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

