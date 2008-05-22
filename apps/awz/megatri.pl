#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:m:", \%args); 

my $query; 
my $chr; 
my $strand; 
my $bp_r;
my $bp_q; 

my $pos_r  = "";
my $pos_q = ""; 
my $alt = 0;

my $n = $args{'n'};
my $m = $args{'m'}; 

sub parse_variants() {
  
  if ($bp_r && $bp_q) {
    my $length_r = length ($bp_r);
    my $length_q = length ($bp_q);

    if ($length_r == $length_q) {
       
      my $summary; 

      my $run = 0; 
      my @run_string = (""); 
      my @run_length = (0);

      for (my $i = $m; $i < $length_q-$m; $i++) {
	my $x = substr($bp_r, $i-$m, 1+2*$m);
	my $y = substr($bp_q, $i-$m, 1+2*$m);
	
	if (substr($x,$m,1) ne substr($y, $m, 1)) {
	  my $edit = $x."}".$y;
	  
	  if ($edit eq $run_string[$run]) {
	    $run_length[$run]++; 	    
	  }
	  else {
	    $run++;
	    $run_string[$run] = $edit; 
	    $run_length[$run] = 1; 
	  }
	}
      }
      for (my $i=1; $i <=$run; $i++) {
	if ($run_length[$i] >= $n) {

	  $summary .= "$run_string[$i] $run_length[$i], ";
	}
      }
      if ($summary) {
	print "$query; $summary; $chr; $strand; $pos_r; $pos_q;". 
	    "$bp_r; $bp_q\n";
      }
      $bp_r = ""; 
      $bp_q = ""; 
      $pos_r = "";
      $pos_q = ""; 
    }
    else {
      warn "query and reference mismatch\n***$bp_r***\n***$bp_q***\n";
    }
  } 
}

while (<>) {
  
  chomp;
  
  my $input  = $_; 

  if ($input =~ m/Query= (.*)$/) { 
    parse_variants();
    $query = $1;
  }
  elsif ($input =~ m/^.....: ([0-9]+)\s+(.+) [0-9]+/ ) { 
    if ($alt) {
      $alt = 0;
 
      if ($pos_r eq "") {
	$pos_r = $1;
      }
      $bp_r .= $2;
    }
    else {
      $alt = 1;  

      if ($pos_q eq "") {
	$pos_q = $1; 
      }
      $bp_q .= $2;
    } 
  }
  elsif ($input =~ m/Strand = Plus \/ (.)/) {
    parse_variants();
    $strand = $1;     
  }
  elsif ($input =~ m/^>(.*)/) {
    $chr = $1; 
  }
}  

