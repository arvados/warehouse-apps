#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2; -*-

use strict;
use Warehouse;
use Warehouse::Manifest;
use Warehouse::Stream;

use Getopt::Std;

my %args;
getopts ("w:m:", \%args);

my $whc = new Warehouse 
    ($args{'w'} ? (warehouse_name => $args{'w'}) : ());

my $manifestkey;
my $manifestname = $args{'m'}; 

if ($manifestname =~ m/[0-9a-f]{32}/) {
  $manifestkey = $manifestname; 
}
else {
  $manifestkey = $whc->fetch_manifest_key_by_name ($manifestname);
}

my $manifest = new Warehouse::Manifest (whc => $whc,
					key => $manifestkey);

$manifest->rewind; 

while (my $instream = $manifest->subdir_next ) {
  while (my ($pos, $size, $filename) = $instream->file_next) {
    last if !defined $pos;
    print STDERR "."; 
    $instream->seek ($pos);    
    while (my $buf = $instream->read_until($pos+$size)) {
      print $$buf;
    }
  }
}
