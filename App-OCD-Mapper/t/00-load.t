#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::OCD::Mapper' ) || print "Bail out!\n";
}

diag( "Testing App::OCD::Mapper $App::OCD::Mapper::VERSION, Perl $], $^X" );
