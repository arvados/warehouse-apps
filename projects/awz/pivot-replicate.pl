#!/usr/bin/perl

use strict;

use Warehouse;
use Digest::MD5;
use HTTP::Request::Common;
use LWP::UserAgent;
use Getopt::Std;

my %args;
getopts ("rn:m:c:", \%args);

my $whc = new Warehouse ();

my $manifestkey = $args{'m'}; 

my $new_manifestname = $args{'n'}; 

my $copies = $args{'c'}; 

print "Expanding $manifestkey into $new_manifestname with $copies copies\n"; 

my @manifesthash= split (",", $manifestkey); 

#read first manifest block but there could be others... 
my $manifest = $whc->fetch_block (shift @manifesthash)
    or die "fetch_block failed";

my $new_manifest = ""; 

foreach my $rep (0 .. ($copies-1)) {

  my @streams = split /\n/, $manifest;
  my @blocks;
  my @files; 
  my $bytes_in_files = 0;
  my $bytes_in_blocks = 0; 

  while (my $length = scalar(@streams)) { 
    my $i = 0; 
    if ($args{'r'}) { 
      $i = rand @streams;    
    } 
    my $stream = splice (@streams, $i, 1);
    
    my @tokens; 
    #if ($stream !~ m/random|hap/) {
      @tokens = split ' ',$stream;
    #print "***@tokens $stream***\n"; 
    #}

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
  $new_manifest .= "./$rep @blocks @files\n";
}
   
$whc->write_start;
$whc->write_data ($new_manifest);
my $new_manifest_key = $whc->write_finish;

print "Manifest key is: $new_manifest_key\n";

my $oldkey = $whc->fetch_manifest_key_by_name ($new_manifestname);
$whc->store_manifest_by_name ($new_manifest_key, $oldkey, $new_manifestname);
my $checkkey = $whc->fetch_manifest_key_by_name ($new_manifestname);
    
print "fetch says: $new_manifestname => $checkkey\n";

