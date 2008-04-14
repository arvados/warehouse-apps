#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Getopt::Std;

my %args;
getopts ("w:m:", \%args);


my $whc = new Warehouse 
    ($args{'w'} ? (warehouse_name => $args{'w'}) : ());

my $manifest = "";
my $manifestname = $args{'m'}; 


my $joblist = $whc->job_list ();
if ($joblist) {
  foreach my $j (@$joblist) {
    
    my $metakey = $j->{"metakey"}; 

    if ($metakey) {
      my $data = $whc->fetch_block($metakey);
      my $id = $j->{"id"}; 
      my $meta_length = length ($data); 
      $manifest .= 
	  "./meta/$id $metakey+$meta_length 0:$meta_length:meta.txt\n"; 

      print STDERR "grabbed $metakey $id\n"; 
    }
  }
  $whc->write_start;
  $whc->write_data ($manifest);
  my $manifest_key = $whc->write_finish;

  print "storing: $manifestname => $manifest_key\n";

  my $oldkey = $whc->fetch_manifest_key_by_name ($manifestname);
  $whc->store_manifest_by_name ($manifest_key, $oldkey, $manifestname);

  my $checkkey = $whc->fetch_manifest_key_by_name ($manifestname);
  print "fetch says: $manifestname => $checkkey\n";
}
else { 
  warn ($whc->errstr . "\n"); 
}

