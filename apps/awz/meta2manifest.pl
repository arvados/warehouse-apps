#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts ("w:m:", \%args);


my $whc;
$whc = new Warehouse ($args{'w'} ? (warehouse_name => $args{'w'}) : ());


my $joblist = $whc->job_list ();
if ($joblist) {
  foreach my $j (@$joblist) {
    
    if ($j->{"metakey"}) {
      my $data = $whc->fetch_block($j->{"metakey"});
      while ($data =~ m/success in ([0-9]+)/g) {
	print "$1\n";
      } 
    }
  }
}
else { 
  warn ($whc->errstr . "\n"); 
}

