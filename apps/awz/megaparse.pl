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
  my ($first,$runs,$chr,$strand,$chr_pos,$tr_pos,$other) = split (/;/, $_,7); 
  $first =~ m/ti\|(\d+)/;
  my $ti = $1;

  #strip off white space 
  $chr =~ s/ //; 
  $strand =~ s/ //; 
  $chr_pos =~ s/ //; 
  $tr_pos =~ s/ //; 
 
  my @edits = split (/,/,$runs); 
  foreach my $edit (@edits) {
    if ($edit =~ m/(...}...) \d+ (\d+) \((.*)\)/ && $2 >= 100) {
      my $type = $1; 
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
          die "parse error\n"
        }
        print "$chr $chrpos0 $chrpos1 $type|$strand|$chr_pos|$pos|$tr_pos|ti|$ti\n";
      }
    }
  }
}
