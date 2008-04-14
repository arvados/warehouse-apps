#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts "m:", \%args);


my $whc;
$whc = new Warehouse ($args{'m'} ? (warehouse_name => $args{'m'}) : ());

my $joblist = $whc->job_list (%opt);
if ($joblist) {
    foreach my $j (@$joblist) {
	print join (", ", map { $_ . "=" . $j->{$_} } sort keys %$j) . "\n";
    }
}
else { 
    warn ($whc->errstr . "\n"); 
}


sub job_new
{
    my @knobs = split (/\n/, $opt{'knobs'});
    foreach (sort keys %opt)
    {
	if (!/[a-z]/)		# treat uppercase wh opts as job knobs
	{
	    push @knobs, $_."=".$opt{$_};
	    delete $opt{$_};
	}
    }
    $opt{'knobs'} = join ("\n", @knobs);

    my $jobid = $whc->job_new (%opt);
    if ($jobid) { print ($jobid . "\n"); }
    else { warn ($whc->errstr . "\n"); }
}
