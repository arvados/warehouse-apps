#!/usr/bin/perl

use strict;

use Warehouse;
use Digest::MD5;
use HTTP::Request::Common;
use LWP::UserAgent;

my $whc = new Warehouse ();

my $manifestkey = "4b0e254eb53972c6ad053365fc8004bf";
my @manifesthash= split (",", $manifestkey); 

#read first manifest block 
my $manifest = $whc->fetch_block (shift @manifesthash)
    or die "fetch_block failed";

#split manifest into separate lines (what perlism am I missing here?) 
my @streams = split /\n/, $manifest;

my @blocks;
my @files; 
my $bytes_in_files = 0;
my $bytes_in_blocks = 0; 

foreach my $stream (@streams) { 
  my @tokens = split ' ',$stream;
  foreach my $x (@tokens) { 	
    if ($x =~ m/^[0-9a-f]{32}\+([0-9]+)/) {
      push @blocks, $x; 
      $bytes_in_blocks+=$1;
    } 
    elsif ($x =~ m/^[0-9]+:([0-9]+):(.+)/) {
      push @files, "$bytes_in_files:$1:$2";
      $bytes_in_files+=$1;
    }
  }
}

if ($bytes_in_blocks ne $bytes_in_files) {
  die "error!\n";
}

my $new_manifest = ""; 
  
foreach my $rep (1 .. 20) {
  $new_manifest .= "./$rep @blocks @files\n";
}
   
$whc->write_start;
$whc->write_data ($new_manifest);
my $new_manifest_key = $whc->write_finish;

print "Manifest key is: $new_manifest_key\n";

my $manifestname = "test"; 

my $oldkey = $whc->fetch_manifest_key_by_name ($manifestname);
$whc->store_manifest_by_name ($new_manifest_key, $oldkey, $manifestname);
my $checkkey = $whc->fetch_manifest_key_by_name ($manifestname);
    
print "fetch says: $manifestname => $checkkey\n";

