#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:", \%args); 

my %queries;

while (<>) {
  
  chomp;
  
  my $input  = $_; 

  my ($query, $chr, $strand, $variant_summary, $variant_strings) = 
      split (/;/, $input, 5); 

  my @variants = split (/;/, $variant_strings); 
  
  my $current_run = "";
  my $current_run_count = 0; 
  my $current_run_ref_pos;
  my $current_run_query_pos;

  my $best_run = "";
  my $best_run_count = 0; 
  my $best_run_ref_pos;
  my $best_run_query_pos;

  foreach my $variant (@variants) {
    my ($snp, $ref_pos, $query_pos) = split (/ /, $variant);

    if ($snp =~ m/[acgt][acgt]/) {
      if ($snp eq $current_run) {
        $current_run_count++;
	$current_run_ref_pos .= " $ref_pos";
 	$current_run_query_pos .= " $query_pos";
	if ($current_run_count > $best_run_count) {
	  $best_run = $current_run; 
	  $best_run_count = $current_run_count;
	  $best_run_ref_pos = $current_run_ref_pos;
	  $best_run_query_pos = $current_run_query_pos; 
	}
      }
      else {
        $current_run = $snp; 
        $current_run_count = 1; 
	$current_run_ref_pos = " $ref_pos";
	$current_run_query_pos = " $query_pos";
      }
    }
  }

  if (exists($queries{$query})) {
    $queries{$query} = "REDUNDANT"; 
  }
  elsif ($best_run_count >= $args{'n'}) {
    $queries{$query} = 
	"$best_run; $best_run_count; $best_run_query_pos; ".
	"$chr; $strand; $best_run_ref_pos";
  }
}  

foreach my $k (keys %queries) {
  if ($queries{$k} ne "REDUNDANT") {
    print "$queries{$k}; $k\n"; 
  }
}
