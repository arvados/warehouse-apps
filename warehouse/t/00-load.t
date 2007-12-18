#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Warehouse' );
	use_ok( 'Warehouse::Server' );
	use_ok( 'Warehouse::Stream' );
	use_ok( 'Warehouse::Manifest' );
}

diag( "Testing Warehouse $Warehouse::VERSION, Perl $], $^X" );
