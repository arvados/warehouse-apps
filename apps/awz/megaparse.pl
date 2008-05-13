#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:", \%args); 

my $query; 
my $chr;
my $alt; 

my @pos_query;
my @bp_query;
my @pos_ref;
my @bp_ref;
my $strand; 

while (<>) {
  
  chomp;
  
  my $input  = $_; 

  if ($input =~ m/Query= (.*)$/) { 
    my $variants = ""; 
    my $pos_var = 0; 
    while (@pos_ref) {
      my $bp_ref = shift @bp_ref;
      my $bp_query = shift @bp_query; 
      my $pos_ref = shift @pos_ref; 
      my $pos_query = shift @pos_query;

      for (my $i=0; $i < length ($bp_ref); $i++) {
	my $x = substr($bp_ref, $i, 1);
	my $y = substr($bp_query, $i, 1);
	
	if ($x eq "-") {
	  $pos_ref--; 
	}
	elsif ($y eq "-") {
	  $pos_query--; 
	}
	elsif ($x ne $y) {
	  if ($pos_query+$i < $pos_var) {
	    print_variant ($query, $chr, $variants); 
	    $variants = "";
	  }
	  $pos_var = $pos_query+$i; 
	  $variants .= "$x$y ".($pos_ref+$i)." $pos_var;"; 
	}
      }
    }
    if ($variants) {
       print_variant ($query, $chr, $variants); 
    }
    $query = $1;
  }
  elsif ($input =~ m/([0-9]+)\s+?([acgtn\-]+)/) { 
    if ($alt) {
      $alt = 0;
      push @pos_ref, $1;
      push @bp_ref, $2; 
    }
    else {
      $alt = 1; 
      push @pos_query, $1;
      push @bp_query, $2;
    } 
  }
  elsif ($input =~ m/Strand = Plus \/ (.)/) {
    $strand = $1; 
  }
  elsif ($input =~ m/^>(.*)/) {
    $chr = $1; 
  }
}  

sub print_variant{
  my ($query, $chr, $variant_strings) = @_; 

  my $variant_summary = "";

  my @variants = split (/;/, $variant_strings);  

  my %hash; 

  foreach my $variant (@variants) {
    my ($snp, $ref_pos, $query_pos) = split (/ /, $variant);
    $hash{$snp}++;
  }
  

  my $flag = 0; 
  foreach my $k (sort {$hash{$b} cmp $hash{$a}} keys %hash) { 
    if ($hash{$k} >= $args{'n'}) {
      $flag  = 1;
    }
    $variant_summary .= "$k ".$hash{$k}." ";
  }
  if ($flag) {
    print "$query; $chr; $strand; $variant_summary; $variant_strings\n"; 
  }
}
