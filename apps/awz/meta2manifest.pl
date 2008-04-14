#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts "m:", \%args);


my $whc;
$whc = new Warehouse ($args{'m'} ? (warehouse_name => $args{'m'}) : ());

my $joblist = $whc->job_list ();
if ($joblist) {
    foreach my $j (@$joblist) {
	print join (", ", map { $_ . "=" . $j->{$_} } sort keys %$j) . "\n";
    }
}
else { 
    warn ($whc->errstr . "\n"); 
}

