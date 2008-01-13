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

@lines = split /^/m, $manifest;

my @blocks;
my @files; 
my $totalfiles = 0;
my $totalblocks = 0; 

foreach $x (@lines) { 
  if ($x =~ m/^[0-9a-f]{32}\+([0-9]+)/) {
    push @blocks, $x; 
    $totalblocks+=$1} 
  elsif ($x =~ m/^[0-9]+:([0-9]+):(.+)/) {
    push @files, "$totalfiles:$1:$2";
    $totalfiles+=$1}}; 
}
if ($totalblocks ne $totalfiles) 
  {die "error!\n"}; 
  
foreach $rep (1 .. 10) {
  $new_manifest .= "$rep @blocks @files\n"}
   
    
$whc->write_start;
$whc->write_data ($new_manifest);
my $new_manifest_key = $whc->write_finish;

print "Manifest key is: $new_manifest_key\n";

my $manifestname = "test"; 

my $oldkey = $whc->fetch_manifest_key_by_name ($manifestname);
$whc->store_manifest_by_name ($new_manifest_key, $oldkey, $manifestname);
my $checkkey = $whc->fetch_manifest_key_by_name ($manifestname);
    
print "fetch says: $manifestname => $checkkey\n";

