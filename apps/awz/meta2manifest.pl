#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts ("w:m:", \%args);


my $whc;
$whc = new Warehouse ($args{'w'} ? (warehouse_name => $args{'w'}) : ());

my $manifest = new Warehouse::Manifest (whc => $whc,
					key => $);
  


my $joblist = $whc->job_list ();
if ($joblist) {
  foreach my $j (@$joblist) {
    
    if ($j->{"metakey"}) {
      $data = whc->fetch_block($j->{"metakey"});
      print $data; 
    }
  }
}
else { 
  warn ($whc->errstr . "\n"); 
}

