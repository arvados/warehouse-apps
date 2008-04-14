#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts ("m:", \%args);


my $whc;
$whc = new Warehouse ($args{'m'} ? (warehouse_name => $args{'m'}) : ());

my $joblist = $whc->job_list ();
if ($joblist) {
    foreach my $j (@$joblist) {

	if ($j->{"metakey"}) {
	    print $j->{"metakey"}; 
	}
}
else { 
    warn ($whc->errstr . "\n"); 
}
