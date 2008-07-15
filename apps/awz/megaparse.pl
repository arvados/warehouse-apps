#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:m:", \%args); 

#sample input line  
#example: m=1 n=5 ga gnl|ti|128860174 ana19b09.y1; agg}aag 5 335 (168 361 412 498 503), ; chr7; M; 117488075; 193;


while(<>) {
  my $input_line = $_;

  my $est=""; 
  if ($input_line =~ m/est/i) {
    $est="EST"; 
  }
  my ($first, $runs, $chr, $strand, $chr_pos, $tr_pos, $other) = 
      split (/;/, $_,7);

  my $source_type = "";
  if ($other =~ m/;source_type:\s*(.*?);/) {
    $source_type = $1; 
  } 
  my $center_name = "";
  if ($other =~ m/;center_name:\s*(.*?);/) {
    $center_name = $1; 
  }
  my $ti = ""; 
  if ( $first =~ m/ti\|(\d+)/ ) {
    $ti = $1;
  }
  my @quality; 
  my $name = ""; 
  if ( $other =~ m/<quality>>gnl\|ti\|(\d+) (.*)<\/quality>/) {
    if ($ti ne $1) {
      warn "$ti <> $1; $input_line\n"; 
      next;       
    }
    @quality = split (/\s+/, $2); 
  }
  my $fasta = ""; 
  if ( $other =~ m/<fasta>>gnl\|ti\|(\d+).*?([ACGTN]*)<\/fasta>/) {
    if ($ti ne $1) {
      warn "$ti <> $1; $input_line\n"; 
      next; 
    }
    $fasta = $2;
  }
  if (@quality != (length($fasta) + 1)) {
    warn "$fasta; $input_line \n"; 
    next;
  } 
  
  #strip off white space 
  $chr =~ s/ //; 
  $strand =~ s/ //; 
  $chr_pos =~ s/ //; 
  $tr_pos =~ s/ //; 
 
  my @edits = split (/,/,$runs); 
  foreach my $edit (@edits) {
    if ($edit =~ m/(...}...) \d+ (\d+) \((.*)\)/ && $2 >= 100) {
      my $type = $1;
      my $length = $2; 
      my @runpos = split (/ /, $3); 
      foreach my $pos (@runpos) {
        my $chrpos0;
	my $chrpos1; 
        if ($strand =~ m/P/) {
          $chrpos0= $chr_pos+$pos-2;
	  $chrpos1= $chr_pos+$pos+1;
        }
        elsif ($strand =~ m/M/) {
          $chrpos0= $chr_pos-$pos-2;
	  $chrpos1= $chr_pos-$pos+1;
        }
        else {
          warn "parse error in ti|$ti\n";
        }
	my $mm;
	my $mmM; 
	my $mmP;
	if ($type =~ m/...}(.)(.)(.)/) {
	  $mmM = $1;
	  $mm = $2; 
	  $mmP = $3;   
	}
	if (uc(substr($fasta, $tr_pos+$pos-2, 3)) ne uc("$mmM$mm$mmP")) {
	  warn "parse error in ti|$ti -".
	      substr($fasta, $tr_pos+$pos-2, 3)." <> ".
	      uc("$mmM$mm$mmP")."\n";
	}
	print "$chr $chrpos0 $chrpos1 $type|".
	    ($tr_pos+$pos)."|".
	    $quality[$tr_pos+$pos-1]."|".
	    $quality[$tr_pos+$pos]."|".
	    $quality[$tr_pos+$pos+1]."|".
	    "$strand|$length|$source_type|$est|$center_name|ti|$ti\n";
      }
    }
  }
}

