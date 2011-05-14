#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:m:", \%args); 

#sample input line  
#ti|445782010; chr2L; M; 13896139; 54; 561; gaggt}gaagt 1 0 (19), gaggt}gangt 1 0 (290), tcgag}tcnan 1 0 (331), gaggt}nangt 1 0 (333), tggga}tgnga 1 0 (399), gagca}gaaca 1 0 (402), cagcg}caacg 1 0 (491), tcgca}tctca 1 0 (536), cagtg}cantg 1 0 (539), tagct}tanct 1 0 (545), 


while(<>) {
  my $input_line = $_;

  my ($ti,$chr,$strand,$chr_pos,$tr_pos,$tr_len,$runs) = split (/;/, $_, 7);

  #$ti =~ s/ti\|//; 
    
  #strip off white space 
  $chr =~ s/ //; 
  $strand =~ s/ //; 
  $chr_pos =~ s/ //; 
  $tr_pos =~ s/ //; 
  $tr_len =~ s/ //; 
 
  my $chrpos0;
  my $chrpos1; 

  if ($strand =~ m/P/) { 
    $chrpos0 = $chr_pos-1; 
    $chrpos1 = $chr_pos+$tr_len;
  }
  else {
    $chrpos0 = $chr_pos-$tr_len-1;
    $chrpos1 = $chr_pos; 
  }

  print "$chr $chrpos0 $chrpos1 TRACE|$strand|$tr_pos|".
      ($tr_pos+$tr_len)."|$ti\n";

  my @edits = split (/,/,$runs); 
  foreach my $edit (@edits) {
    if ($edit =~ m/(.....}.....) \d+ \d+ \((.*)\)/) {
      my $type = $1;
      my @runpos = split (/ /, $2); 
      foreach my $pos (@runpos) {
        if ($strand =~ m/P/) {
          $chrpos0= $chr_pos+$pos-3;
	  $chrpos1= $chr_pos+$pos+2;
        }
        elsif ($strand =~ m/M/) {
          $chrpos0= $chr_pos-$pos-3;
	  $chrpos1= $chr_pos-$pos+2;
        }
        else {
          warn "parse error in ti|$ti\n";
        }
	print "$chr $chrpos0 $chrpos1 $type|".($tr_pos+$pos)."|$strand|$ti\n";
      }      
    }
  }
}

