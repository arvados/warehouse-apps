#!/usr/bin/perl -w
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Getopt::Std; 

my %args;
getopts ("n:m:", \%args); 

my %queries;

while (<>) {
  
  chomp;
  
  my $input  = $_; 

  my ($run,$run_count,$query_string,$chr,$strand,$ref_string,$id) =
      split (/;/, $input, 7); 


  my $trace_id; 
  if ($id =~ m/\|ti\|([0-9]+)/) {
    $trace_id = $1;
    #print "*** $id *** $trace_id ***\n";
  }
  else {
    warn "Couldn't parse trace id in ***$id***\n"; 
    next; 
  }
   
  my @query_pos = split (' ', $query_string); 
  my @query_delta; 
  
  for (my $i = 1; $i < $run_count; $i++ ) {
    push @query_delta, $query_pos[$i] - $query_pos[$i-1];  
  }


  if (median (\@query_delta) >= $args{'n'} && 
      $query_pos[$run_count-1] - $query_pos[0] >= $args{'m'} ) {
    print "$input;";

    my $string = './query_tracedb "retrieve fasta '.$trace_id.'"';
    my $test = qx/$string/;
    $test =~ s/^.*//; 
    $test =~ s/\n//g; 

    for (my $i = 0; $i < $run_count; $i++ ) {
      print " ".substr ($test, $query_pos[$i], 1);
    }
    print "\n"; 
  }
}

sub median {
  @_ == 1 or die ('Sub usage: $median = median(\@array);');
  my ($array_ref) = @_;
  my $count = scalar @$array_ref;
  # Sort a COPY of the array, leaving the original untouched
  my @array = sort { $a <=> $b } @$array_ref;
  if ($count % 2) {
    return $array[int($count/2)];
  } else {
    return ($array[$count/2] + $array[$count/2 - 1]) / 2;
  }
} 
