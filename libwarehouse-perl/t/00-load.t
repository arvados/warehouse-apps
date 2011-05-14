#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Warehouse' );
	use_ok( 'Warehouse::Server' );
	use_ok( 'Warehouse::Stream' );
	use_ok( 'Warehouse::Manifest' );
	use_ok( 'Warehouse::Keep' );
}

diag( "Testing Warehouse $Warehouse::VERSION, Perl $], $^X" );
