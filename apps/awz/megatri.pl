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

my %hits; 

sub parse_variants() {
  
  if ($bp_r && $bp_q) {

    my $length_r = length ($bp_r);
    my $length_q = length ($bp_q);

    if ($length_r == $length_q) {
       
      my $summary; 

      my $run = 0; 
      my @run_string = ("");
      my @run_pos_string = (""); 
      my @run_length = (0);

      for (my $i = $m; $i < $length_q-$m; $i++) {
	my $x = substr($bp_r, $i-$m, 1+2*$m);
	my $y = substr($bp_q, $i-$m, 1+2*$m);
	
	if (substr($x,$m,1) ne substr($y, $m, 1)) {
     
	  my $edit = $x."}".$y;
	  
	  if ($edit eq $run_string[$run]) {
	    $run_length[$run]++; 	
	    $run_pos_string[$run] .= " $i"; 
	  }
	  else {
	    $run++;
	    $run_string[$run] = $edit;
	    $run_pos_string[$run] .= "$i"; 
	    $run_length[$run] = 1;
	  }
	}
      }
      for (my $i=1; $i <=$run; $i++) {
	if ($run_length[$i] >= $n) {

	  $summary .= "$run_string[$i] $run_length[$i] ".
	      span($run_pos_string[$i]). 
	      " ($run_pos_string[$i]), ";
	}
      }
      if ($hits{$query} ne "EMPTY") {
	$hits {$query} = "REDUNDANT"; 
      }
      elsif ($summary) {
	$hits {$query} = "$summary; $chr; $strand; $pos_r; $pos_q;". 
	    "$bp_r; $bp_q";
      }
      else {
	$hits {$query} = "UNIQUE"; 
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

  if ($input =~ m/^Query= (.*)$/) { 
    parse_variants();    
    $query = $1;
    if ( !$hits {$query}) {
      $hits {$query} = "EMPTY"; 
    }
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
  elsif ($input =~ m/^ Strand = Plus \/ (.)/) {
    parse_variants();
    $strand = $1;     
  }
  elsif ($input =~ m/^>(.*)/) {
    $chr = $1; 
  }
}  
parse_variants(); 

my $unique_hits = 0;
my $unique_miss = 0; 
my $empty_hits = 0;
my $redundant_hits = 0; 

while ( my ($key, $value) = each(%hits) ) {
  if ($value eq "EMPTY") {
    $empty_hits++;
  }
  elsif ($value eq "REDUNDANT" ) {
    $redundant_hits++; 
  }
  elsif ($value eq "UNIQUE") {
    $unique_miss++; 
  }
  else {
    $unique_hits++; 
    print "$key; $value\n";   
  }
}
print STDERR "$unique_hits $unique_miss $redundant_hits $empty_hits\n";

sub median {
  my ($input) = @_;
  my @array = split (/ /, $input);  
  for (my $i = 1; $i < @array; $i++) {
    $array[$i-1] = $array[$i]-$array[$i-1]; 
  }
  pop (@array);
  
  @array = sort {$a<=>$b} @array; 

  if (@array % 2) {
    return $array[int(@array/2)];
  } else {
    return ($array[@array/2] + $array[@array/2 - 1]) / 2;
  }
} 
sub span {
  my ($input) = @_;
  my @array = split (/ /, $input);
  return ($array[-1]-$array[0]);
}
